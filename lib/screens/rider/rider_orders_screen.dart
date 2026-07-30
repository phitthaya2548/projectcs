import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/res/customer/rider/res_work_of_rider.dart';
import 'package:wash_and_dry/service/session_service.dart';
import 'package:wash_and_dry/widgets/appbarrider.dart';

const _blue = Color(0xFF0593FF);
const _green = Color(0xFF16A34A);
const _surface = Color(0xFFF9FAFB);
const _border = Color(0xFFE5E7EB);
const _textPrimary = Color(0xFF111827);
const _textSecondary = Color(0xFF6B7280);

abstract class _S {
  static const pickedUp = 'pickup_in_progress';
  static const pickupCompleted = 'pickup_completed';
  static const arrivedAtShop = 'arrived_at_shop';
  static const deliveryHeadingToShop = 'delivery_heading_to_shop';
  static const deliveryPickupCompleted = 'delivery_pickup_completed';
  static const delivering = 'delivery_in_progress';
  static const waitingWash = 'waiting_wash';
  static const waitingDry = 'waiting_dry';
  static const completed = 'completed';
}

String _serviceLabel(String? t) => switch (t) {
  'wash' => 'ซักผ้าอย่างเดียว',
  'dry' => 'อบผ้าอย่างเดียว',
  'wash_dry' => 'ซัก + อบ',
  _ => t ?? '-',
};

String _formatTs(Timestamp ts) {
  final d = ts.toDate().toLocal();
  return '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} น.';
}

double? _calcDistance(double? lat1, double? lng1, double? lat2, double? lng2) {
  if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return null;
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

Widget _chip(
  String label,
  Color color, {
  bool small = false,
  bool isService = false,
}) => Container(
  padding: EdgeInsets.symmetric(
    horizontal: small ? 8 : 10,
    vertical: small ? 3 : 4,
  ),
  decoration: BoxDecoration(
    color: color.withOpacity(0.08),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isService) ...[
        Icon(Icons.local_laundry_service, size: 14, color: color),
        const SizedBox(width: 4),
      ],
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
);

Widget _addressRow(String text) => Padding(
  padding: const EdgeInsets.only(top: 4),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.location_on_outlined, size: 14, color: _textSecondary),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: _textSecondary),
        ),
      ),
    ],
  ),
);

Widget _customerRow(String? name, String? phone, String? profileImage) {
  if (name == null) return const SizedBox.shrink();
  return Row(
    children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE8F3FF),
        backgroundImage: profileImage != null
            ? NetworkImage(profileImage)
            : null,
        child: profileImage == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              )
            : null,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _textPrimary,
              ),
            ),
            if (phone != null)
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 12,
                    color: _textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    phone,
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );
}

Widget _cardShell({required Widget child, required Color leftColor}) =>
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: leftColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(14), child: child),
            ),
          ],
        ),
      ),
    );

Widget _emptyState(IconData icon, String label, {Widget? action}) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 52, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(color: _textSecondary, fontSize: 14)),
      if (action != null) ...[const SizedBox(height: 16), action],
    ],
  ),
);

Widget _step(String label, bool on) => Column(
  children: [
    CircleAvatar(
      radius: 16,
      backgroundColor: on ? _green : Colors.grey.shade100,
      child: Icon(
        Icons.check,
        size: 16,
        color: on ? Colors.white : Colors.grey.shade300,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: on ? _green : Colors.grey.shade400,
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
);

Widget _line(bool on) => Expanded(
  child: Container(
    height: 2,
    margin: const EdgeInsets.only(bottom: 18),
    color: on ? _green : _border,
  ),
);

/// Progress bar สำหรับงานฝั่งไรเดอร์
/// ฝั่งรับผ้า มี 4 ขั้น: รับงาน -> รับผ้า -> ถึงร้าน -> เสร็จ
/// ฝั่งส่งผ้า มี 4 ขั้นเช่นกัน และแต่ละขั้นคือสถานะจริงที่ต้องกดปุ่มยืนยันทีละขั้น:
/// รับงาน (deliveryHeadingToShop) -> รับผ้าที่ร้าน (deliveryPickupCompleted)
///   -> ส่งผ้า (delivering) -> เสร็จ (completed)
Widget _progressBar(String status) {
  const deliveryStatuses = [
    _S.deliveryHeadingToShop,
    _S.deliveryPickupCompleted,
    _S.delivering,
    _S.completed,
  ];
  if (deliveryStatuses.contains(status)) {
    // ติ๊กเขียวเฉพาะขั้นที่ "ผ่านมาแล้วจริง" ตามลำดับสถานะ ไม่ข้ามขั้น
    final pickedUpDone =
        status == _S.deliveryPickupCompleted ||
        status == _S.delivering ||
        status == _S.completed;
    final deliveringDone = status == _S.delivering || status == _S.completed;
    final isDone = status == _S.completed;
    return Row(
      children: [
        _step('รับงาน', true),
        _line(pickedUpDone),
        _step('รับผ้าที่ร้าน', pickedUpDone),
        _line(deliveringDone),
        _step('ส่งผ้า', deliveringDone),
        _line(isDone),
        _step('เสร็จ', isDone),
      ],
    );
  }

  final pickedUpDone =
      status == _S.pickupCompleted || status == _S.arrivedAtShop;
  final arrivedDone = status == _S.arrivedAtShop;

  return Row(
    children: [
      _step('รับงาน', true),
      _line(true),
      _step('รับผ้า', pickedUpDone),
      _line(pickedUpDone),
      _step('ถึงร้าน', arrivedDone),
      _line(arrivedDone),
      _step('เสร็จ', arrivedDone),
    ],
  );
}

Widget _successDialog(String label) => Dialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: _green, size: 34),
        ),
        const SizedBox(height: 16),
        const Text(
          'สำเร็จ!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: _textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: Get.back,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'ตกลง',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  ),
);

class RiderOrdersScreen extends StatefulWidget {
  const RiderOrdersScreen({super.key});
  @override
  State<RiderOrdersScreen> createState() => _RiderOrdersScreenState();
}

class _RiderOrdersScreenState extends State<RiderOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final _tab = TabController(length: 2, vsync: this);
  String _name = '';
  String? _image, _riderId, _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = Session();
    final results = await Future.wait([
      s.getFullname(),
      s.getProfileImage(),
      s.getRiderId(),
      Configuration.getConfig()
          .then((c) => c['apiEndpoint']?.toString() ?? '')
          .catchError((_) => ''),
    ]);
    if (!mounted) return;
    setState(() {
      _name = (results[0] as String?) ?? 'Rider';
      _image = results[1] as String?;
      _riderId = results[2] as String?;
      _url = results[3] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = _riderId != null && (_url?.isNotEmpty ?? false);
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBarRider(
        riderName: _name,
        riderId: _riderId ?? '',
        profileImage: _image,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              labelColor: _blue,
              unselectedLabelColor: _textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              indicatorColor: _blue,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'กำลังดำเนินการ'),
                Tab(text: 'เสร็จสิ้น'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: ready
                  ? [
                      _ActiveTab(riderId: _riderId!, url: _url!),
                      _CompletedTab(riderId: _riderId!),
                    ]
                  : List.generate(
                      2,
                      (_) => const Center(
                        child: CircularProgressIndicator(color: _blue),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedTab extends StatelessWidget {
  final String riderId;
  const _CompletedTab({required this.riderId});

  Future<Map<String, DocumentSnapshot>> _batchGet(
    List<DocumentReference?> refs,
  ) async {
    final valid = refs.whereType<DocumentReference>().toList();
    if (valid.isEmpty) return {};
    final snaps = await Future.wait(valid.map((r) => r.get()));
    return {for (final s in snaps) s.reference.path: s};
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(
            'rider_pickup_id',
            isEqualTo: FirebaseFirestore.instance.doc('riders/$riderId'),
          )
          .where(
            'status',
            whereIn: [
              _S.arrivedAtShop,
              _S.waitingWash,
              _S.waitingDry,
              _S.completed,
            ],
          )
          .orderBy('order_datetime', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: _blue));
        if (snap.hasError)
          return _emptyState(Icons.error_outline, 'เกิดข้อผิดพลาด');

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty)
          return _emptyState(
            Icons.inbox_outlined,
            'ยังไม่มีออเดอร์ที่เสร็จสิ้น',
          );

        final customerRefs = docs
            .map((d) => (d.data() as Map)['customer_id'] as DocumentReference?)
            .toList();
        final addressRefs = docs
            .map((d) => (d.data() as Map)['address_id'] as DocumentReference?)
            .toList();

        return FutureBuilder(
          future: Future.wait([
            _batchGet(customerRefs),
            _batchGet(addressRefs),
          ]),
          builder: (_, s) {
            final customerMap =
                s.data?[0] as Map<String, DocumentSnapshot>? ?? {};
            final addressMap =
                s.data?[1] as Map<String, DocumentSnapshot>? ?? {};
            final loading = s.connectionState == ConnectionState.waiting;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String?;
                final isArrived = status == _S.arrivedAtShop;
                final isWaiting =
                    status == _S.waitingWash || status == _S.waitingDry;
                final color = isArrived
                    ? _blue
                    : isWaiting
                    ? _blue
                    : _green;
                final label = isArrived
                    ? 'ถึงร้านแล้ว'
                    : isWaiting
                    ? 'รอซัก'
                    : 'เสร็จสิ้น';
                final shortId = doc.id
                    .substring(0, doc.id.length.clamp(0, 8))
                    .toUpperCase();
                final cRef = data['customer_id'] as DocumentReference?;
                final aRef = data['address_id'] as DocumentReference?;
                final customer = cRef != null
                    ? customerMap[cRef.path]?.data() as Map<String, dynamic>?
                    : null;
                final address = aRef != null
                    ? addressMap[aRef.path]?.data() as Map<String, dynamic>?
                    : null;

                return _cardShell(
                  leftColor: color,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#$shortId',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _textPrimary,
                            ),
                          ),
                          _chip(label, color),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (loading)
                        const SizedBox(
                          height: 20,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _blue,
                            ),
                          ),
                        )
                      else ...[
                        _customerRow(
                          customer?['fullname'],
                          customer?['phone'],
                          customer?['profile_image'],
                        ),
                        if (address?['address_text'] != null)
                          _addressRow(address!['address_text']),
                      ],
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: _border),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _chip(
                            _serviceLabel(data['service_type'] as String?),
                            _textSecondary,
                            small: true,
                            isService: true,
                          ),
                          if (data['order_datetime'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatTs(data['order_datetime'] as Timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ActiveTab extends StatefulWidget {
  final String riderId, url;
  const _ActiveTab({required this.riderId, required this.url});
  @override
  State<_ActiveTab> createState() => _ActiveTabState();
}

class _ActiveTabState extends State<_ActiveTab> {
  List<WorkOfRider> _orders = [];
  bool _loading = true, _fetching = false;
  String? _error;
  double? _lat, _lng;
  final Map<String, File?> _photos = {};
  final Map<String, bool> _uploading = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _resolveLocation().then((_) {
      if (mounted && _lat != null) _recomputeDistances();
    });
  }

  Future<void> _resolveLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return;

      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _lat = last.latitude;
        _lng = last.longitude;
        if (mounted) _recomputeDistances();
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lat = pos.latitude;
      _lng = pos.longitude;
    } catch (e) {
      log('resolveLocation: $e');
    }
  }

  void _recomputeDistances() {
    if (_orders.isEmpty) return;
    setState(() {
      _orders = _orders.map((o) {
        final km = _calcDistance(_lat, _lng, o.addressLat, o.addressLng);
        return o.copyWith(
          distanceKm: km != null ? double.parse(km.toStringAsFixed(1)) : null,
        );
      }).toList();
    });
  }

  Future<void> _fetchOrders() async {
    if (_fetching) return;
    _fetching = true;
    if (!mounted) return;
    setState(() {
      _loading = _orders.isEmpty;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${widget.url}/order/rider/${widget.riderId}'),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['ok'] == true) {
        setState(
          () => _orders = (body['data'] as List)
              .map((e) => WorkOfRider.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        _recomputeDistances();
      } else {
        setState(() => _error = body['message'] as String? ?? 'ไม่พบออเดอร์');
      }
    } catch (e) {
      log('fetchOrders: $e');
      if (mounted) setState(() => _error = 'ไม่สามารถเชื่อมต่อได้');
    } finally {
      _fetching = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto(String id) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _blue),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _blue),
              title: const Text('เลือกจากแกลเลอรี่'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (src == null) return;
    final p = await ImagePicker().pickImage(source: src, imageQuality: 80);
    if (p != null && mounted) setState(() => _photos[id] = File(p.path));
  }

  /// หา "สถานะถัดไป" ตามสถานะปัจจุบันของออเดอร์
  String _nextStatus(WorkOfRider o) {
    switch (o.status) {
      case _S.pickedUp:
        return _S.pickupCompleted;
      case _S.pickupCompleted:
        return _S.arrivedAtShop;
      case _S.arrivedAtShop:
        return o.serviceType == 'dry' ? _S.waitingDry : _S.waitingWash;
      case _S.deliveryHeadingToShop:
        return _S.deliveryPickupCompleted;
      case _S.deliveryPickupCompleted:
        return _S.delivering;
      case _S.delivering:
        return _S.completed;
      default:
        return _S.completed;
    }
  }

  /// ข้อความแจ้งเตือนสำเร็จ ตามสถานะปัจจุบันก่อนกด
  String _successMessage(WorkOfRider o) {
    switch (o.status) {
      case _S.pickedUp:
        return 'รับผ้าจากลูกค้าเรียบร้อยแล้ว';
      case _S.pickupCompleted:
        return 'ถึงร้านเรียบร้อยแล้ว';
      case _S.arrivedAtShop:
        return 'ส่งผ้าเข้าคิวเรียบร้อยแล้ว';
      case _S.deliveryHeadingToShop:
        return 'รับผ้าที่ร้านเรียบร้อยแล้ว';
      case _S.deliveryPickupCompleted:
        return 'เริ่มจัดส่งเรียบร้อยแล้ว';
      case _S.delivering:
        return 'ส่งผ้าถึงลูกค้าเรียบร้อยแล้ว';
      default:
        return 'ส่งผ้าถึงลูกค้าเรียบร้อยแล้ว';
    }
  }

  Future<void> _confirm(WorkOfRider o) async {
    final isPickup = o.status == _S.pickedUp;
    // ต้องแนบรูปตอน "ส่งผ้าถึงลูกค้า" คือขั้นตอนสุดท้ายของฝั่งส่งผ้า (delivering -> completed)
    // ไม่ใช่ตอน "deliveryHeadingToShop" หรือ "deliveryPickupCompleted" อีกต่อไป
    final needsPhoto = isPickup || o.status == _S.delivering;
    final photo = _photos[o.id];

    if (needsPhoto && photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกหรือถ่ายรูปก่อนกด'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _uploading[o.id] = true);
    try {
      final next = _nextStatus(o);
      final msg = _successMessage(o);

      final req =
          http.MultipartRequest(
              'PUT',
              Uri.parse('${widget.url}/order/rider/update/status/${o.id}'),
            )
            ..fields['status'] = next
            ..fields['rider_id'] = widget.riderId;
      if (needsPhoto && photo != null)
        req.files.add(await http.MultipartFile.fromPath('image', photo.path));

      final res = await http.Response.fromStream(await req.send());
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;

      if (res.statusCode == 200 && body['ok'] == true) {
        await Get.dialog<void>(_successDialog(msg));
        if (!mounted) return;
        setState(() => _photos.remove(o.id));
        _fetchOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] as String? ?? 'เกิดข้อผิดพลาด'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      log('confirm: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเชื่อมต่อได้ กรุณาลองใหม่'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _uploading.remove(o.id));
    }
  }

  Widget _photoBox(String id, File? photo, bool uploading) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'แนบรูปภาพ',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: _textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: uploading ? null : () => _pickPhoto(id),
        child: photo != null
            ? Stack(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        photo,
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _photos.remove(id)),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _pickPhoto(id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'เปลี่ยนรูป',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(10),
                  color: _surface,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'แตะเพื่อเพิ่มรูป',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      const SizedBox(height: 14),
    ],
  );

  Widget _buildCard(WorkOfRider o) {
    final isPickup = o.status == _S.pickedUp;
    final isDrop = o.status == _S.pickupCompleted;
    final isArrived = o.status == _S.arrivedAtShop;
    final isHeadingToShop = o.status == _S.deliveryHeadingToShop;
    final isDeliveryPickupCompleted = o.status == _S.deliveryPickupCompleted;
    final isDelivering = o.status == _S.delivering;
    final uploading = _uploading[o.id] ?? false;
    final shortId = o.id.substring(0, o.id.length.clamp(0, 8)).toUpperCase();
    final statusLabel = switch (o.status) {
      _S.pickedUp => 'กำลังไปรับผ้า',
      _S.pickupCompleted => 'รับผ้าแล้ว กำลังไปร้าน',
      _S.arrivedAtShop => 'ถึงร้านแล้ว',
      _S.deliveryHeadingToShop => 'กำลังไปที่ร้าน (รับผ้ากลับ)',
      _S.deliveryPickupCompleted => 'รับผ้าที่ร้านแล้ว',
      _S.delivering => 'กำลังจัดส่ง',
      _ => o.status,
    };
    final distText = o.distanceKm != null
        ? '${o.distanceKm} กม.'
        : 'กำลังหาตำแหน่ง...';

    // ปุ่มกดของแต่ละสถานะ - ต้องกดยืนยันทีละขั้น สถานะจะไม่เปลี่ยนเองจนกว่าจะกด
    final buttonLabel = isPickup
        ? 'รับผ้าจากลูกค้าแล้ว'
        : isDrop
        ? 'ถึงร้านแล้ว'
        : isArrived
        ? 'เสร็จ'
        : isHeadingToShop
        ? 'รับผ้าที่ร้านแล้ว'
        : isDeliveryPickupCompleted
        ? 'เริ่มจัดส่ง'
        : isDelivering
        ? 'ส่งผ้าถึงลูกค้าแล้ว'
        : '';

    final showActionArea = isPickup ||
        isDrop ||
        isArrived ||
        isHeadingToShop ||
        isDeliveryPickupCompleted ||
        isDelivering;
    // แนบรูปเฉพาะ "รับผ้าจากลูกค้า" และ "ส่งผ้าถึงลูกค้า" (ขั้นตอนสุดท้ายฝั่งส่งผ้า)
    final showPhotoBox = isPickup || isDelivering;

    return _cardShell(
      leftColor: _blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#$shortId',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _textPrimary,
                ),
              ),
              _chip(statusLabel, _blue),
            ],
          ),
          const SizedBox(height: 12),
          _customerRow(
            o.customer?.name,
            o.customer?.phone,
            o.customer?.profileImage,
          ),
          if (o.address != null) _addressRow(o.address!),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip(
                _serviceLabel(o.serviceType),
                _blue,
                small: true,
                isService: true,
              ),
              const Spacer(),
              _chip(distText, _blue, small: true),
            ],
          ),
          if (o.note != null && o.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.note_alt_outlined,
                  size: 15,
                  color: _textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    o.note!,
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _progressBar(o.status),
          if (showActionArea) ...[
            const SizedBox(height: 16),
            if (showPhotoBox) _photoBox(o.id, _photos[o.id], uploading),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: uploading ? null : () => _confirm(o),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: uploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: _blue));
    if (_error != null || _orders.isEmpty) {
      return _emptyState(
        Icons.assignment_outlined,
        _error ?? 'ไม่มีงานที่กำลังดำเนินการ',
        action: TextButton.icon(
          onPressed: _fetchOrders,
          icon: const Icon(Icons.refresh, size: 18, color: _blue),
          label: const Text('โหลดใหม่', style: TextStyle(color: _blue)),
        ),
      );
    }
    return RefreshIndicator(
      color: _blue,
      onRefresh: _fetchOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildCard(_orders[i]),
      ),
    );
  }
}