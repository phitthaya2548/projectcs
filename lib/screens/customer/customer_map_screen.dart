import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CustomerMapScreen extends StatefulWidget {
  const CustomerMapScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};

  String  _riderName        = '';
  String? _riderImage;
  String? _riderPhone;
  String? _riderLicensePlate;
  String? _riderVehicleType;
  String? _distanceText;
  String? _durationText;

  LatLng? _riderPosition;
  LatLng? _destPosition;
  String  _destAddress  = '';
  String? _customerImage;

  bool    _isLoading = true;
  String? _error;

  BitmapDescriptor? _riderIcon;
  BitmapDescriptor? _destIcon;
  List<LatLng>      _routeCache = [];

  // ── สถานะออเดอร์ + ตัวติดตามว่าไรเดอร์ที่กำลังแสดงอยู่คือคนรับ (pickup) หรือไม่ ──
  String  _orderStatus   = '';
  bool    _isPickupRider = false;

  StreamSubscription<DocumentSnapshot>? _riderSub;
  StreamSubscription<DocumentSnapshot>? _orderSub;

  static const _routeColor = Color(0xFF0593FF);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _riderSub?.cancel();
    _orderSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final orderDocRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId);

      final orderSnap = await orderDocRef.get();

      if (!orderSnap.exists) {
        setState(() { _error = 'ไม่พบข้อมูลออเดอร์'; _isLoading = false; });
        return;
      }

      final data = orderSnap.data()!;
      _orderStatus = (data['status'] ?? '') as String;

      // ── ดึงโปรไฟล์ลูกค้า ──
      final customerRef = data['customer_id'] as DocumentReference?;
      if (customerRef != null) {
        final customerSnap = await customerRef.get();
        final customerData = customerSnap.data() as Map<String, dynamic>?;
        _customerImage = customerData?['profile_image'] as String?;
      }

      // ── ดึงที่อยู่ปลายทาง + สร้างหมุดโปรไฟล์ลูกค้า ──
      final addressRef = data['address_id'] as DocumentReference?;
      if (addressRef != null) {
        final addrSnap = await addressRef.get();
        final addr     = addrSnap.data() as Map<String, dynamic>?;
        final lat      = (addr?['latitude']  as num?)?.toDouble();
        final lng      = (addr?['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _destPosition = LatLng(lat, lng);
          _destAddress  = addr?['address_text'] ?? 'ปลายทาง';
          _destIcon     = await _makeProfileMarker(_customerImage, Colors.red);

          _markers.add(Marker(
            markerId:   const MarkerId('dest'),
            position:   _destPosition!,
            icon:       _destIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: '📍 ปลายทาง', snippet: _destAddress),
          ));
        }
      }

      await _setupRiderTracking(data);

      // ── ฟังการเปลี่ยนแปลงสถานะออเดอร์แบบเรียลไทม์ ──
      _orderSub = orderDocRef.snapshots().listen(_onOrderUpdate);

    } catch (e) {
      debugPrint('_init error: $e');
      setState(() { _error = 'เกิดข้อผิดพลาด: $e'; _isLoading = false; });
    }
  }

  /// เลือกไรเดอร์ที่จะติดตามตามสถานะออเดอร์ปัจจุบัน แล้วเริ่ม/สลับการฟังตำแหน่ง
  Future<void> _setupRiderTracking(Map<String, dynamic> data) async {
    final pickupRef   = data['rider_pickup_id']   as DocumentReference?;
    final deliveryRef = data['rider_delivery_id'] as DocumentReference?;

    DocumentReference? riderRef;
    bool isPickup = false;

    if (_orderStatus == 'pickup_completed') {
      // รับของเสร็จแล้ว: ห้ามใช้ rider_pickup_id อีกต่อไป
      riderRef = deliveryRef;
      isPickup = false;
    } else {
      riderRef = pickupRef ?? deliveryRef;
      isPickup = riderRef == pickupRef;
    }

    if (riderRef == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final riderSnap = await riderRef.get();
    final riderData = riderSnap.data() as Map<String, dynamic>?;

    _riderName         = (riderData?['fullname'] ?? riderData?['username'] ?? 'ไรเดอร์') as String;
    _riderImage        = riderData?['profile_image']  as String?;
    _riderPhone        = riderData?['phone']          as String?;
    _riderLicensePlate = riderData?['license_plate']  as String?;
    _riderVehicleType  = riderData?['vehicle_type']   as String?;

    _riderIcon = await _makeProfileMarker(_riderImage, _routeColor);

    _isPickupRider = isPickup;
    _riderSub?.cancel();
    _riderSub = riderRef.snapshots().listen(_onRiderUpdate);
  }

  /// เรียกทุกครั้งที่เอกสารออเดอร์เปลี่ยน ใช้เช็คว่าสถานะเปลี่ยนเป็น pickup_completed หรือยัง
  void _onOrderUpdate(DocumentSnapshot snap) {
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    final newStatus = (data['status'] ?? '') as String;

    if (newStatus == _orderStatus) return; // สถานะไม่เปลี่ยน ไม่ต้องทำอะไร
    _orderStatus = newStatus;

    if (_orderStatus == 'pickup_completed' && _isPickupRider) {
      // หยุดติดตามไรเดอร์รับของ + ลบออกจากแผนที่ทันที
      _stopRiderTracking();
      // ถ้ามีไรเดอร์ส่งของแล้ว ให้เริ่มติดตามคนใหม่แทน
      _setupRiderTracking(data);
    }
  }

  /// หยุดฟังตำแหน่งไรเดอร์ปัจจุบัน และลบ marker/polyline/ข้อมูลที่เกี่ยวข้องออกจากแผนที่
  void _stopRiderTracking() {
    _riderSub?.cancel();
    _riderSub = null;

    if (!mounted) return;
    setState(() {
      _riderPosition = null;
      _distanceText  = null;
      _durationText  = null;
      _routeCache    = [];
      _markers.removeWhere((m) => m.markerId.value == 'rider');
      _polylines.removeWhere((p) => p.polylineId.value == 'route');
    });
  }

  void _onRiderUpdate(DocumentSnapshot snap) {
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;

    final lat = (data['latitude']  as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final pos = LatLng(lat, lng);

    if (!mounted) return;
    setState(() {
      _riderPosition = pos;
      _isLoading     = false;

      _markers
        ..removeWhere((m) => m.markerId.value == 'rider')
        ..add(Marker(
          markerId:   const MarkerId('rider'),
          position:   pos,
          icon:       _riderIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: '🛵 $_riderName'),
        ));

      if (_routeCache.isNotEmpty) {
        _polylines
          ..removeWhere((p) => p.polylineId.value == 'route')
          ..add(Polyline(
            polylineId: const PolylineId('route'),
            points:     _routeCache,
            color:      _routeColor,
            width:      5,
          ));
      }
    });

    if (_destPosition != null) {
      _fetchAndDrawRoute(pos, _destPosition!);
      _fitBounds(pos, _destPosition!);
    }
  }

  Future<void> _fetchAndDrawRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final body  = jsonDecode(res.body);
      final route = (body['routes'] as List?)?.first;
      if (route == null) return;

      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();
      final points    = (route['geometry']['coordinates'] as List)
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      if (!mounted) return;
      _routeCache = points;

      setState(() {
        _distanceText = distanceM >= 1000
            ? '${(distanceM / 1000).toStringAsFixed(1)} กม.'
            : '${distanceM.toInt()} ม.';
        _durationText = '${(durationS / 60).ceil()} นาที';
        _polylines
          ..removeWhere((p) => p.polylineId.value == 'route')
          ..add(Polyline(
            polylineId: const PolylineId('route'),
            points:     points,
            color:      _routeColor,
            width:      5,
          ));
      });
    } catch (e) {
      debugPrint('OSRM error: $e');
    }
  }

  void _fitBounds(LatLng a, LatLng b) {
    final bounds = LatLngBounds(
      southwest: LatLng(min(a.latitude, b.latitude),  min(a.longitude, b.longitude)),
      northeast: LatLng(max(a.latitude, b.latitude),  max(a.longitude, b.longitude)),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<BitmapDescriptor> _makeProfileMarker(String? imageUrl, Color borderColor) async {
    const double size        = 120;
    const double borderWidth = 6;
    const double photoRadius = size / 2 - borderWidth;

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2,
        Paint()..color = borderColor);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final codec = await ui.instantiateImageCodec(
              res.bodyBytes, targetWidth: size.toInt(), targetHeight: size.toInt());
          final frame = await codec.getNextFrame();
          canvas
            ..save()
            ..clipPath(Path()..addOval(Rect.fromCircle(
                center: const Offset(size / 2, size / 2), radius: photoRadius)))
            ..drawImageRect(
              frame.image,
              Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
              Rect.fromCircle(center: const Offset(size / 2, size / 2), radius: photoRadius),
              Paint(),
            )
            ..restore();
          return _toDescriptor(recorder, size);
        }
      } catch (_) {}
    }

    // fallback icon
    canvas.drawCircle(Offset(size / 2, size / 2), photoRadius,
        Paint()..color = borderColor.withOpacity(0.2));
    final fill = Paint()..color = borderColor;
    canvas.drawCircle(Offset(size / 2, size / 2 - photoRadius * 0.2), photoRadius * 0.3, fill);
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(size / 2, size / 2 + photoRadius * 0.35),
          width: photoRadius * 0.9, height: photoRadius * 0.55),
      0, pi, true, fill,
    );
    return _toDescriptor(recorder, size);
  }

  Future<BitmapDescriptor> _toDescriptor(ui.PictureRecorder recorder, double size) async {
    final img      = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
            ),
          ),
        ),
        title: const Text(
          "ติดตามไรเดอร์",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
         onPressed: () => Get.back(result: true),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Color(0xFF0593FF)),
          SizedBox(height: 16),
          Text('กำลังโหลดข้อมูล...', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() { _isLoading = true; _error = null; });
                _init();
              },
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('ลองใหม่'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0593FF)),
            ),
          ]),
        ),
      );
    }

    final initialPos = _riderPosition ?? _destPosition ?? const LatLng(13.7563, 100.5018);
    final hasRider   = _riderPosition != null;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initialPos, zoom: 14),
          onMapCreated: (ctrl) {
            _mapController = ctrl;
            if (_riderPosition != null && _destPosition != null) {
              _fitBounds(_riderPosition!, _destPosition!);
            } else if (_destPosition != null) {
              ctrl.animateCamera(CameraUpdate.newLatLngZoom(_destPosition!, 15));
            }
          },
          markers:             _markers,
          polylines:           _polylines,
          zoomControlsEnabled: false,
          mapToolbarEnabled:   false,
        ),

        if (hasRider)
          Positioned(
            left: 16, right: 16, bottom: 32,
            child: _buildRiderCard(),
          ),

        if (!hasRider)
          Positioned(
            left: 16, right: 16, bottom: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )],
              ),
              child: const Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2, color: _routeColor),
                  SizedBox(width: 14),
                  Text('กำลังรอไรเดอร์รับงาน...',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRiderCard() {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildAvatar(_riderImage),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _riderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0593FF).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'กำลังจัดส่ง',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0593FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_distanceText != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _distanceText!,
                    style: const TextStyle(
                      color: Color(0xFF0593FF),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _durationText ?? '',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
                  ),
                ],
              )
            else if (_riderPosition != null)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0593FF)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_riderPhone != null && _riderPhone!.isNotEmpty)
              Expanded(
                child: _infoChip(icon: Icons.phone_rounded, label: 'เบอร์โทร', value: _riderPhone!),
              ),
            if (_riderLicensePlate != null && _riderLicensePlate!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _infoChip(
                  icon: Icons.confirmation_number_rounded,
                  label: 'ทะเบียน',
                  value: _riderLicensePlate!.toUpperCase(),
                ),
              ),
            ],
            if (_riderVehicleType != null && _riderVehicleType!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _infoChip(
                  icon: Icons.two_wheeler_rounded,
                  label: 'ประเภทรถ',
                  value: _riderVehicleType!,
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

Widget _infoChip({required IconData icon, required String label, required String value}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF0593FF)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _buildAvatar(String? imageUrl) {
  return Container(
    padding: const EdgeInsets.all(2.5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFF0593FF), Color(0xFF6DC1FF)],
      ),
    ),
    child: CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderAvatar(),
              )
            : _placeholderAvatar(),
      ),
    ),
  );
}

Widget _placeholderAvatar() {
  return Container(
    width: 44,
    height: 44,
    color: const Color(0x1A0593FF),
    child: const Icon(Icons.delivery_dining_rounded, size: 22, color: Color(0xFF0593FF)),
  );
}
}