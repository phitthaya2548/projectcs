import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wash_and_dry/service/session_service.dart';
import 'package:wash_and_dry/widgets/appbarrider.dart';

class _OrderDest {
  final String addressText;
  final double lat;
  final double lng;
  final String customerName;
  final String? customerImageUrl;
  final String? customerPhone;
  final String? orderNote;
  String? distanceText;
  String? durationText;

  _OrderDest({
    required this.addressText,
    required this.lat,
    required this.lng,
    required this.customerName,
    this.customerImageUrl,
    this.customerPhone,
    this.orderNote,
  });
}

class RiderMapScreen extends StatefulWidget {
  const RiderMapScreen({super.key});

  @override
  State<RiderMapScreen> createState() => _RiderMapScreenState();
}

class _RiderMapScreenState extends State<RiderMapScreen> {
  static const List<String> _activeStatuses = [
    'pickup_in_progress',
    'pickup_completed',
    'delivery_in_progress',
    'store_pickup_in_progress',
  ];

  static const List<Color> _routeColors = [
    Color(0xFF0593FF),
    Color(0xFFFF6B35),
    Color(0xFF22C55E),
  ];

  String _riderName = '';
  String? _riderImage;
  String? _riderId;

  GoogleMapController? _mapController;
  LatLng? _myPosition;
  bool _isLocating = true;
  String? _locationError;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final Map<String, _OrderDest> _jobs = {};
  final Map<String, List<LatLng>> _routeCache = {};

  StreamSubscription<DocumentSnapshot>? _myPositionSub;
  StreamSubscription<QuerySnapshot>? _pickupSub;
  StreamSubscription<QuerySnapshot>? _deliverySub;
  StreamSubscription<Position>? _gpsSub;

  String? _gpsWarning;
  BitmapDescriptor? _motoIcon;

  bool _hasCenteredCameraOnce = false;
  bool _isFollowingRider = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pickupSub?.cancel();
    _deliverySub?.cancel();
    _myPositionSub?.cancel();
    _gpsSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final session = Session();
    final name = await session.getFullname();
    final image = await session.getProfileImage();
    final riderId = await session.getRiderId();

    if (!mounted) return;
    setState(() {
      _riderName = name ?? 'Rider';
      _riderImage = image;
      _riderId = riderId;
    });

    if (riderId == null) {
      setState(() {
        _isLocating = false;
        _locationError = 'ไม่พบข้อมูลไรเดอร์';
      });
      return;
    }

    _motoIcon = await _makeProfileMarker(_riderImage, const Color(0xFF0593FF));

    _listenOrders(riderId);
    _listenMyPosition(riderId);
    _startGps(riderId);
  }

  void _listenMyPosition(String riderId) {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    _myPositionSub = FirebaseFirestore.instance
        .collection('riders')
        .doc(riderId)
        .snapshots()
        .listen(_onMyPositionSnapshot, onError: _onMyPositionError);
  }

  void _onMyPositionSnapshot(DocumentSnapshot snap) {
    if (!mounted) return;

    final data = snap.data() as Map<String, dynamic>?;
    final lat = (data?['latitude'] as num?)?.toDouble();
    final lng = (data?['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      setState(() {
        _isLocating = false;
        _locationError = 'ยังไม่มีตำแหน่งของไรเดอร์ในระบบ';
      });
      return;
    }

    final newPos = LatLng(lat, lng);
    final newMarker = Marker(
      markerId: const MarkerId('rider'),
      position: newPos,
      anchor: const Offset(0.5, 0.5),
      infoWindow: const InfoWindow(title: '🛵 ตำแหน่งของฉัน'),
      icon: _motoIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {
      _myPosition = newPos;
      _isLocating = false;
      _locationError = null;
      _markers
        ..removeWhere((m) => m.markerId.value == 'rider')
        ..add(newMarker);
    });

    _updateCameraForNewPosition(newPos);
    _rebuildJobsOnMap();
  }

  void _updateCameraForNewPosition(LatLng newPos) {
    if (!_hasCenteredCameraOnce) {
      _hasCenteredCameraOnce = true;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPos, zoom: 14),
        ),
      );
    } else if (_isFollowingRider) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
    }
  }

  void _onMyPositionError(Object e) {
    debugPrint('listenMyPosition error: $e');
    if (!mounted) return;
    setState(() {
      _isLocating = false;
      _locationError = 'ไม่สามารถโหลดตำแหน่งได้';
    });
  }

  Future<void> _startGps(String riderId) async {
    setState(() => _gpsWarning = null);

    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _gpsWarning = 'กรุณาเปิด GPS เพื่อให้ตำแหน่งอัปเดตสด');
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      setState(() => _gpsWarning = 'แอปไม่ได้รับอนุญาตเข้าถึงตำแหน่ง');
      return;
    }

    _gpsSub?.cancel();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (pos) => _updateRiderPositionInFirestore(riderId, pos),
      onError: (e) {
        debugPrint('GPS stream error: $e');
        if (!mounted) return;
        setState(() => _gpsWarning = 'สัญญาณ GPS ขาดหาย');
      },
    );
  }

  void _updateRiderPositionInFirestore(String riderId, Position pos) {
    FirebaseFirestore.instance.collection('riders').doc(riderId).update({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
    });
  }

  void _listenOrders(String riderId) {
    final riderRef =
        FirebaseFirestore.instance.collection('riders').doc(riderId);

    _pickupSub = FirebaseFirestore.instance
        .collection('orders')
        .where('rider_pickup_id', isEqualTo: riderRef)
        .where('status', whereIn: _activeStatuses)
        .snapshots()
        .listen(_handleOrderSnapshot);

    _deliverySub = FirebaseFirestore.instance
        .collection('orders')
        .where('rider_delivery_id', isEqualTo: riderRef)
        .where('status', whereIn: _activeStatuses)
        .snapshots()
        .listen(_handleOrderSnapshot);
  }

  Future<void> _handleOrderSnapshot(QuerySnapshot snap) async {
    final incoming = <String>{};

    for (final doc in snap.docs) {
      incoming.add(doc.id);
      final data = doc.data() as Map<String, dynamic>;

      final addressRef = data['address_id'] as DocumentReference?;
      if (addressRef == null) continue;

      final addressSnap = await addressRef.get();
      final addr = addressSnap.data() as Map<String, dynamic>?;
      final lat = (addr?['latitude'] as num?)?.toDouble();
      final lng = (addr?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final customer = await _fetchCustomer(data['customer_id']);

      _jobs[doc.id] = _OrderDest(
        addressText: addr?['address_text'] ?? 'ปลายทาง',
        lat: lat,
        lng: lng,
        customerName: customer.$1,
        customerImageUrl: customer.$2,
        customerPhone: customer.$3,
        orderNote: data['note'] as String?,
      );
    }

    _jobs.removeWhere((id, _) => !incoming.contains(id));
    _routeCache.removeWhere((id, _) => !incoming.contains(id));

    if (mounted) setState(() {});
    _rebuildJobsOnMap();
  }

  Future<(String, String?, String?)> _fetchCustomer(
    dynamic customerIdRaw,
  ) async {
    DocumentReference? ref;

    if (customerIdRaw is DocumentReference) {
      ref = customerIdRaw;
    } else if (customerIdRaw is String && customerIdRaw.isNotEmpty) {
      ref =
          FirebaseFirestore.instance.collection('customers').doc(customerIdRaw);
    }

    if (ref == null) return ('ลูกค้า', null, null);

    try {
      final snap = await ref.get();
      final data = snap.data() as Map<String, dynamic>?;
      final name = (data?['fullname'] ?? data?['username'] ?? 'ลูกค้า') as String;
      final img = data?['profile_image'] as String?;
      final phone = data?['phone'] as String?;
      return (name, img, phone);
    } catch (e) {
      debugPrint('fetchCustomer error: $e');
      return ('ลูกค้า', null, null);
    }
  }

  void _rebuildJobsOnMap() {
    if (_myPosition == null) return;

    _markers.removeWhere((m) => m.markerId.value != 'rider');

    var i = 0;
    for (final entry in _jobs.entries) {
      final orderId = entry.key;
      final job = entry.value;
      final dest = LatLng(job.lat, job.lng);
      final color = _routeColors[i % _routeColors.length];

      _updateDestinationMarker(orderId, job, dest, color);
      _drawCachedRouteIfAny(orderId, color);
      _fetchAndDrawRoute(orderId, _myPosition!, dest, color);

      i++;
    }
  }

  void _updateDestinationMarker(
    String orderId,
    _OrderDest job,
    LatLng dest,
    Color color,
  ) {
    _makeProfileMarker(job.customerImageUrl, color).then((icon) {
      if (!mounted) return;
      setState(() {
        _markers
          ..removeWhere((m) => m.markerId.value == 'dest_$orderId')
          ..add(Marker(
            markerId: MarkerId('dest_$orderId'),
            position: dest,
            icon: icon,
            infoWindow: InfoWindow(
              title: '👤 ${job.customerName}',
              snippet: job.addressText,
            ),
          ));
      });
    });
  }

  void _drawCachedRouteIfAny(String orderId, Color color) {
    final cached = _routeCache[orderId];
    if (cached == null) return;

    setState(() {
      _polylines
        ..removeWhere((p) => p.polylineId.value == 'route_$orderId')
        ..add(Polyline(
          polylineId: PolylineId('route_$orderId'),
          points: cached,
          color: color,
          width: 5,
        ));
    });
  }

  Future<BitmapDescriptor> _makeProfileMarker(
    String? imageUrl,
    Color borderColor,
  ) async {
    const double size = 120;
    const double borderWidth = 6;
    const double photoRadius = size / 2 - borderWidth;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = borderColor,
    );

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final res =
            await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final codec = await ui.instantiateImageCodec(
            res.bodyBytes,
            targetWidth: size.toInt(),
            targetHeight: size.toInt(),
          );
          final frame = await codec.getNextFrame();

          canvas
            ..save()
            ..clipPath(Path()
              ..addOval(Rect.fromCircle(
                center: const Offset(size / 2, size / 2),
                radius: photoRadius,
              )))
            ..drawImageRect(
              frame.image,
              Rect.fromLTWH(
                0,
                0,
                frame.image.width.toDouble(),
                frame.image.height.toDouble(),
              ),
              Rect.fromCircle(
                center: const Offset(size / 2, size / 2),
                radius: photoRadius,
              ),
              Paint(),
            )
            ..restore();

          return _toDescriptor(recorder, size);
        }
      } catch (e) {
        debugPrint('marker image error: $e');
      }
    }

    _drawPersonIcon(canvas, size, photoRadius, borderColor);
    return _toDescriptor(recorder, size);
  }

  void _drawPersonIcon(Canvas canvas, double size, double r, Color color) {
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      r,
      Paint()..color = color.withOpacity(0.2),
    );
    final fill = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2 - r * 0.2), r * 0.3, fill);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size / 2, size / 2 + r * 0.35),
        width: r * 0.9,
        height: r * 0.55,
      ),
      0,
      pi,
      true,
      fill,
    );
  }

  Future<BitmapDescriptor> _toDescriptor(
    ui.PictureRecorder recorder,
    double size,
  ) async {
    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _fetchAndDrawRoute(
    String orderId,
    LatLng from,
    LatLng to,
    Color color,
  ) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;

      final body = jsonDecode(res.body);
      final route = (body['routes'] as List?)?.first;
      if (route == null) return;

      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();
      final points = (route['geometry']['coordinates'] as List)
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      if (!mounted) return;

      _routeCache[orderId] = points;

      setState(() {
        final job = _jobs[orderId];
        if (job != null) {
          job.distanceText = distanceM >= 1000
              ? '${(distanceM / 1000).toStringAsFixed(1)} กม.'
              : '${distanceM.toInt()} ม.';
          job.durationText = '${(durationS / 60).ceil()} นาที';
        }
        _polylines
          ..removeWhere((p) => p.polylineId.value == 'route_$orderId')
          ..add(Polyline(
            polylineId: PolylineId('route_$orderId'),
            points: points,
            color: color,
            width: 5,
          ));
      });
    } catch (e) {
      debugPrint('OSRM error: $e');
    }
  }

  void _moveToMyLocation() {
    if (_myPosition == null) return;
    setState(() => _isFollowingRider = !_isFollowingRider);
    if (_isFollowingRider) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _myPosition!, zoom: 15),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBarRider(
        riderName: _riderName,
        riderId: _riderId ?? '',
        profileImage: _riderImage,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLocating && _myPosition == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF0593FF)),
            SizedBox(height: 16),
            Text('กำลังดึงตำแหน่ง...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_locationError != null && _myPosition == null) {
      return _buildLocationErrorView();
    }

    return Stack(
      children: [
        _buildMap(),
        if (_gpsWarning != null) _buildGpsWarningBanner(),
        if (_jobs.isNotEmpty) _buildJobCardsList(),
        _buildFollowButton(),
      ],
    );
  }

  Widget _buildLocationErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _locationError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _riderId != null ? _listenMyPosition(_riderId!) : null,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองใหม่'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0593FF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _myPosition!, zoom: 14),
      onMapCreated: (ctrl) => _mapController = ctrl,
      onCameraMove: (_) {
        if (_isFollowingRider) {
          setState(() => _isFollowingRider = false);
        }
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildGpsWarningBanner() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.gps_not_fixed_rounded, size: 18, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _gpsWarning!,
                style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900),
              ),
            ),
            TextButton(
              onPressed: () => _riderId != null ? _startGps(_riderId!) : null,
              child: const Text('ลองใหม่', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCardsList() {
    return Positioned(
      top: _gpsWarning != null ? 64 : 16,
      left: 16,
      right: 16,
      child: Column(
        children: _jobs.entries.toList().asMap().entries.map((e) {
          final index = e.key;
          final job = e.value.value;
          final color = _routeColors[index % _routeColors.length];
          return _buildJobCard(job, color);
        }).toList(),
      ),
    );
  }

  Widget _buildFollowButton() {
    return Positioned(
      right: 16,
      bottom: 32,
      child: FloatingActionButton(
        onPressed: _moveToMyLocation,
        backgroundColor: _isFollowingRider ? const Color(0xFF0593FF) : Colors.white,
        foregroundColor: _isFollowingRider ? Colors.white : const Color(0xFF0593FF),
        elevation: 6,
        shape: const CircleBorder(),
        child: Icon(
          _isFollowingRider ? Icons.my_location_rounded : Icons.location_searching_rounded,
        ),
      ),
    );
  }

  Widget _buildJobCard(_OrderDest job, Color color) {
    return GestureDetector(
      onTap: () => _showJobDetail(job, color),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _buildAvatar(job.customerImageUrl, color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.addressText,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              job.distanceText != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          job.distanceText!,
                          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          job.durationText ?? '',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetail(_OrderDest job, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildAvatar(job.customerImageUrl, color),
                const SizedBox(width: 12),
                Text(
                  job.customerName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (job.distanceText != null)
              Row(
                children: [
                  _infoChip(Icons.straight_rounded, job.distanceText!, color),
                  const SizedBox(width: 10),
                  _infoChip(Icons.access_time_rounded, job.durationText ?? '', color),
                ],
              ),
            if (job.distanceText != null) const SizedBox(height: 16),
            _detailRow(Icons.location_on_rounded, job.addressText, color),
            if (job.customerPhone != null && job.customerPhone!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailRow(Icons.phone_rounded, job.customerPhone!, color),
            ],
            if (job.orderNote != null && job.orderNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailRow(Icons.sticky_note_2_rounded, job.orderNote!, color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl, Color color) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderAvatar(color),
        ),
      );
    }
    return _placeholderAvatar(color);
  }

  Widget _placeholderAvatar(Color color) {
    return CircleAvatar(
      radius: 21,
      backgroundColor: color.withOpacity(0.15),
      child: Icon(Icons.person_rounded, size: 22, color: color),
    );
  }
}