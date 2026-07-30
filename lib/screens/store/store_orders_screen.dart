import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/res/customer/store/res_orderItem_store.dart';
import 'package:wash_and_dry/models/res/customer/store/res_profile_store.dart';

import 'package:wash_and_dry/screens/store/store_completed_screen.dart';
import 'package:wash_and_dry/screens/store/store_afterorder_detail_screen.dart';
import 'package:wash_and_dry/service/session_service.dart';
import 'package:wash_and_dry/widgets/appbarstore.dart';

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF29B6F6);
  static const _dark = Color(0xFF1A1A2E);
  static const _bg = Color(0xFFF5F5F5);

  static const _divider = Divider(
    height: 1,
    thickness: 1,
    color: Color(0xFFF1F5F9),
  );
  static final _btnRadius = BorderRadius.circular(10);
  static const _btnPadding = EdgeInsets.symmetric(vertical: 12);
  static const _btnTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  late final TabController _tab = TabController(length: 3, vsync: this);

  String url = '';
  StoreData? storeData;
  bool isLoading = true;
  String? errorMessage;
  String? storeId;

  bool _ordersLoading = true;
  String? _ordersError;
  List<StoreOrderItem> _allOrders = [];
  final Map<String, StreamSubscription<DocumentSnapshot>> _subscriptions = {};
  final Map<String, String> _statuses = {};
  final Map<String, Timestamp> _liveDatetimes = {};

  static const _activeStatuses = {
    'waiting_payment',
    'waiting_pickup',
    'pickup_in_progress',
    'pickup_completed',
    'waiting_wash',
    'washing',
    'waiting_dry',
    'drying',
    'waiting_delivery',
    'store_pickup_in_progress',
    'delivery_in_progress',
  };
  static const _doneStatuses = {'completed'};
  static const _cancelStatuses = {'cancelled'};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final config = await Configuration.getConfig();
      url = config['apiEndpoint']?.toString() ?? '';
      log('API URL: $url');

      final session = Session();
      storeId = await session.getStoreId();
      log('Store ID: $storeId');

      if (url.isEmpty) throw Exception('ไม่พบ API URL');
      if (storeId == null || storeId!.isEmpty) {
        throw Exception('ไม่พบ Store ID - กรุณาเข้าสู่ระบบใหม่');
      }

      await _getStoreProfile();
      await _fetchOrders();
    } catch (e) {
      log('Error: $e');
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _getStoreProfile() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final uri = Uri.parse('$url/store/profile/$storeId');
      final res = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception('เกิดข้อผิดพลาด (${res.statusCode})');

      final body = json.decode(res.body);
      if (body['ok'] != true) throw Exception(body['message'] ?? 'ดึงข้อมูลไม่สำเร็จ');

      final storeJson = body['data'];
      if (storeJson == null) throw Exception('ไม่พบข้อมูลร้านค้า');

      if (mounted) {
        setState(() {
          storeData = StoreData.fromJson(storeJson);
          isLoading = false;
        });
      }
    } on TimeoutException {
      if (mounted) setState(() { errorMessage = 'เซิร์ฟเวอร์ช้า'; isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { errorMessage = e.toString().replaceAll('Exception: ', ''); isLoading = false; });
    }
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _ordersLoading = true;
      _ordersError = null;
    });
    try {
      final uri = Uri.parse('$url/order/store/list/$storeId');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() {
          _ordersError = 'โหลดข้อมูลไม่สำเร็จ (${res.statusCode})';
          _ordersLoading = false;
        });
        return;
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['ok'] != true) {
        setState(() {
          _ordersError = body['message'] as String? ?? 'เกิดข้อผิดพลาด';
          _ordersLoading = false;
        });
        return;
      }

      final list = (body['data'] as List<dynamic>? ?? [])
          .map((e) => StoreOrderItem.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final order in list) {
        _statuses.putIfAbsent(order.orderId, () => order.initialStatus);
        _listenToOrder(order.orderId);
      }

      setState(() {
        _allOrders = list;
        _ordersLoading = false;
      });
    } catch (e) {
      log('_fetchOrders error: $e');
      if (!mounted) return;
      setState(() {
        _ordersError = 'เกิดข้อผิดพลาด';
        _ordersLoading = false;
      });
    }
  }

  void _listenToOrder(String orderId) {
    if (_subscriptions.containsKey(orderId)) return;

    _subscriptions[orderId] = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          if (!snap.exists) return;

          final data = snap.data() as Map<String, dynamic>?;
          if (data == null) return;

          final newStatus = data['status'] as String?;
          final newDatetime = data['order_datetime'];

          final statusChanged = newStatus != null && newStatus != _statuses[orderId];
          final gotTimestamp = newDatetime is Timestamp;
          final datetimeChanged = gotTimestamp && newDatetime != _liveDatetimes[orderId];

          if (!statusChanged && !datetimeChanged) return;

          setState(() {
            if (statusChanged) _statuses[orderId] = newStatus;
            if (gotTimestamp) _liveDatetimes[orderId] = newDatetime;
          });
        }, onError: (e) {
          log('listen order $orderId error: $e');
        });
  }

  String _statusLabel(String s) =>
      {
        'waiting_payment': 'รอชำระเงิน',
        'waiting_pickup': 'รอรับผ้า',
        'pickup_in_progress': 'กำลังไปรับผ้า',
        'pickup_completed': 'กำลังเดินทางไปร้าน',
        'waiting_wash': 'รอซัก',
        'waiting_dry': 'รออบ',
        'washing': 'กำลังซักผ้า',
        'drying': 'กำลังอบผ้า',
        'waiting_delivery': 'รอส่งผ้า',
        'delivery_in_progress': 'กำลังจัดส่ง',
        'completed': 'เสร็จสิ้น',
        'cancelled': 'ยกเลิก',
      }[s] ??
      s;

  Color _statusColor(String s) {
    if (_activeStatuses.contains(s)) return const Color(0xFF0EA5E9);
    if (s == 'completed') return const Color(0xFF22C55E);
    return const Color(0xFFEF4444);
  }

  String _serviceLabel(String s) =>
      {
        'wash': 'ซักอย่างเดียว',
        'dry': 'อบอย่างเดียว',
        'wash_dry': 'ซัก + อบ',
      }[s] ??
      s;

  static const _months = [
    '',
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  String _formatDt(DateTime dt) {
    return '${dt.day} ${_months[dt.month]} ${dt.year + 543} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(Map<String, dynamic>? raw) {
    if (raw == null) return '-';
    final seconds = raw['_seconds'];
    if (seconds == null) return '-';
    return _formatDt(DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000));
  }

  String _formatTs(Timestamp ts) => _formatDt(ts.toDate());

  String _orderDatetimeText(StoreOrderItem order) {
    final live = _liveDatetimes[order.orderId];
    if (live != null) return _formatTs(live);
    return _formatDate(order.orderDatetime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: storeData == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(128),
              child: Column(
                children: [
                  StoreAppBar(
                    title: storeData?.storeName ?? '',
                    profileImage: storeData?.profileImage,
                    storeId: storeData?.storeId ?? '',
                  ),
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tab,
                      indicatorColor: _primary,
                      indicatorWeight: 3,
                      labelColor: _primary,
                      unselectedLabelColor: Colors.black45,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(fontSize: 13),
                      tabs: const [
                        Tab(text: 'กำลังดำเนินการ'),
                        Tab(text: 'เสร็จสิ้น'),
                        Tab(text: 'ยกเลิก/ล้มเหลว'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังโหลดข้อมูลร้าน...'),
                ],
              ),
            )
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(errorMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            )
          : _ordersLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _ordersError != null
          ? Center(
              child: Text(
                _ordersError!,
                style: TextStyle(color: Colors.red.shade400),
              ),
            )
          : TabBarView(
              controller: _tab,
              children: [
                _buildTab(_activeStatuses),
                _buildTab(_doneStatuses),
                _buildTab(_cancelStatuses),
              ],
            ),
    );
  }

  Widget _buildTab(Set<String> bucket) {
    final filtered = _allOrders
        .where((o) => bucket.contains(_statuses[o.orderId] ?? ''))
        .toList();
    if (filtered.isEmpty) return _emptyView();
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: filtered.length,
        itemBuilder: (_, i) {
          final order = filtered[i];
          return _card(order, _statuses[order.orderId] ?? '');
        },
      ),
    );
  }

  Widget _emptyView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16),
            ],
          ),
          child: const Icon(
            Icons.inbox_outlined,
            size: 36,
            color: Colors.black26,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ไม่มีรายการ',
          style: TextStyle(
            color: Colors.black38,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _card(StoreOrderItem order, String status) {
    final shortId =
        '#${order.orderId.substring(0, order.orderId.length.clamp(0, 8)).toUpperCase()}';
    final statusColor = _statusColor(status);
    final isActive = _activeStatuses.contains(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  shortId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _dark,
                  ),
                ),
                const Spacer(),
                _StatusBadge(
                  label: _statusLabel(status),
                  color: statusColor,
                  isActive: isActive,
                ),
              ],
            ),
          ),
          _divider,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                _infoRow(
                  Icons.access_time_rounded,
                  _orderDatetimeText(order),
                  _dark,
                ),
                _infoRow(
                  Icons.person_rounded,
                  order.customerFullname,
                  _dark,
                ),
                _infoRow(
                  Icons.location_on_rounded,
                  order.addressFull,
                  Colors.black54,
                ),
                _infoRow(
                  Icons.phone_rounded,
                  order.customerPhone,
                  Colors.black54,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_laundry_service_rounded,
                    size: 18,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'บริการ: ${_serviceLabel(order.serviceType)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _divider,
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: status == 'completed'
                ? _actionButton(
                    label: 'ใบเสร็จ',
                    filled: true,
                    color: Colors.green,
                    onPressed: () => Get.to(
                      () => StoreCompletedScreen(orderId: order.orderId),
                    ),
                  )
                : _actionButton(
                    label: 'รายละเอียด',
                    filled: false,
                    color: _dark,
                    onPressed: () {
                      Get.to(
                        () => StoreOrderDetailScreen(orderId: order.orderId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool filled,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: filled
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: _btnRadius),
                padding: _btnPadding,
              ),
              onPressed: onPressed,
              child: Text(label, style: _btnTextStyle),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: _btnRadius),
                padding: _btnPadding,
              ),
              onPressed: onPressed,
              child: Text(label, style: _btnTextStyle),
            ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color textColor) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color.fromARGB(255, 188, 188, 189)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: textColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.isActive,
  });

  final String label;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) _PulsingDot(color: color),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> {
  bool _bright = true;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_bright),
      tween: Tween(begin: _bright ? 0.3 : 1.0, end: _bright ? 1.0 : 0.3),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      onEnd: () {
        if (mounted) setState(() => _bright = !_bright);
      },
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}