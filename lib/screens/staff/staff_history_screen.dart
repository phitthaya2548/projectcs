import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/req/staff/req_updateorder_status_staff.dart';
import 'package:wash_and_dry/models/res/customer/staff/res_history_order_staff.dart';
import 'package:wash_and_dry/models/req/staff/req_update_status_staff.dart';
import 'package:wash_and_dry/screens/staff/staff_calculate_screen.dart';
import 'package:wash_and_dry/service/session_service.dart';
import 'package:wash_and_dry/widgets/appbarstaff.dart';

class StaffHistoryScreen extends StatefulWidget {
  const StaffHistoryScreen({super.key});

  @override
  State<StaffHistoryScreen> createState() => _StaffHistoryScreenState();
}

class _StaffHistoryScreenState extends State<StaffHistoryScreen>
    with SingleTickerProviderStateMixin {
  String _url = '';
  String _staffName = '';
  String? _profileImage;
  String? _staffId;

  late TabController _tabController;
  List<StaffOrder> _activeOrders = [];
  List<StaffOrder> _doneOrders = [];
  bool _isLoading = false;

  static const _activeStatuses = [
    'waiting_wash',
    'waiting_dry',
    'waiting_payment',
    'payment_completed',
    'washing',
    'drying',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final config = await Configuration.getConfig();
      if (!mounted) return;
      setState(() => _url = config['apiEndpoint']?.toString() ?? '');
    } catch (_) {}

    final session = Session();
    final name = await session.getFullname();
    final image = await session.getProfileImage();
    final id = await session.getStaffId();
    if (!mounted) return;

    setState(() {
      _staffName = name ?? 'Staff';
      _profileImage = image;
      _staffId = id;
    });

    await _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (_staffId == null || _url.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('$_url/order/staff/historynow/$_staffId');
      log('>>> URL: $uri');

      final res = await http.get(uri);
      log('>>> STATUS: ${res.statusCode}');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final response = staffOrderListResponseFromJson(res.body);
        setState(() {
          _activeOrders = response.data
              .where((o) => _activeStatuses.contains(o.status))
              .toList();
          _doneOrders = response.data
              .where((o) => o.status == 'waiting_delivery')
              .toList();
        });
      }
    } catch (e) {
      log('>>> ERROR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBarStaff(
        staffName: _staffName,
        staffId: _staffId ?? '',
        profileImage: _profileImage,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(_activeOrders, isDone: false),
                      _buildOrderList(_doneOrders, isDone: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tabController,
      indicatorColor: const Color(0xFF1E88E5),
      indicatorWeight: 3,
      labelColor: const Color(0xFF1E88E5),
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontSize: 14),
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'กำลังดำเนินการ'),
        Tab(text: 'ดำเนินการเสร็จสิ้น'),
      ],
    ),
  );

  Widget _buildOrderList(List<StaffOrder> orders, {required bool isDone}) {
    if (orders.isEmpty) {
      return const Center(child: Text('ไม่มีออเดอร์'));
    }
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(
          order: orders[i],
          isDone: isDone,
          onRefresh: _fetchOrders,
          url: _url,
          staffId: _staffId ?? '',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ORDER CARD
// ─────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final StaffOrder order;
  final bool isDone;
  final VoidCallback onRefresh;
  final String url;
  final String staffId;

  const _OrderCard({
    required this.order,
    required this.isDone,
    required this.onRefresh,
    required this.url,
    required this.staffId,
  });

  // ── Derived / helper getters ──────────────────────────────
  bool get _needsWash =>
      order.serviceType == 'wash' || order.serviceType == 'wash_dry';
  bool get _needsDry =>
      order.serviceType == 'dry' || order.serviceType == 'wash_dry';

  bool get _isWaiting =>
      order.status == 'waiting_wash' ||
      order.status == 'waiting_dry' ||
      order.status == 'payment_completed';
  bool get _isWashing => order.status == 'washing';
  bool get _canUpdate =>
      !isDone &&
      order.status != 'waiting_payment' &&
      order.status != 'payment_completed';
  bool get _showStartDry => _isWashing && order.serviceType == 'wash_dry';

  String _statusText(String s) => switch (s) {
    'waiting_wash' => 'รอซัก',
    'waiting_dry' => 'รออบ',
    'waiting_payment' => 'รอชำระเงิน',
    'payment_completed' => 'ชำระเงินแล้ว',
    'washing' => 'กำลังซัก',
    'drying' => 'กำลังอบ',
    'waiting_delivery' => 'รอไรเดอร์ส่ง',
    _ => s,
  };

  Color _statusColor(String s) => switch (s) {
    'waiting_wash' => Colors.orange,
    'waiting_dry' => Colors.orange,
    'waiting_payment' => Colors.red,
    'payment_completed' => Colors.green,
    'washing' => Colors.blue,
    'drying' => Colors.blue,
    'waiting_delivery' => Colors.green,
    _ => Colors.grey,
  };

  String _serviceText(String t) => switch (t) {
    'wash' => 'ซักอย่างเดียว',
    'dry' => 'อบอย่างเดียว',
    'wash_dry' => 'ซัก + อบ',
    _ => t,
  };

  void _showUpdateBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UpdateStatusSheet(
        order: order,
        url: url,
        staffId: staffId,
        onSuccess: onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(),
            const SizedBox(height: 8),
            if (order.customer != null) _buildCustomerInfo(order.customer!),
            const SizedBox(height: 8),
            _buildServiceRow(),
            _buildMachineInfo(),
            if (order.note != null && order.note!.isNotEmpty)
              _buildNoteRow(order.note!),
            const SizedBox(height: 12),
            _buildActionButton(context),
            _buildStatusBanner(),
          ],
        ),
      ),
    );
  }

  /// เลขที่ออเดอร์ + สถานะ
  Widget _buildHeaderRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        '#${order.id}'.substring(0, 10).toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(order.status),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _statusText(order.status),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ],
  );

  /// ชื่อ / ที่อยู่ / เบอร์โทรลูกค้า
  Widget _buildCustomerInfo(dynamic customer) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 2),
      Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              order.address ?? '-',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Row(
        children: [
          const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            customer.phone,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    ],
  );

  /// บรรทัด "บริการ: ..."
  Widget _buildServiceRow() => Row(
    children: [
      const Icon(
        Icons.local_laundry_service_outlined,
        size: 16,
        color: Colors.blue,
      ),
      const SizedBox(width: 6),
      Text(
        'บริการ: ${_serviceText(order.serviceType)}',
        style: const TextStyle(fontSize: 13),
      ),
    ],
  );

  /// ชื่อเครื่องซัก / เครื่องอบ แสดงต่อจากบรรทัดบริการทันที (ไม่มีไอคอน)
  Widget _buildMachineInfo() {
    final washerName = _needsWash ? order.washer?.name : null;
    final dryerName = _needsDry ? order.dryer?.name : null;

    if (washerName == null && dryerName == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (washerName != null)
            _machineChip(label: 'เครื่องซัก', value: washerName, color: Colors.blue),
          if (dryerName != null)
            _machineChip(label: 'เครื่องอบ', value: dryerName, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _machineChip({
    required String label,
    required String value,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );

  /// หมายเหตุจากลูกค้า
  Widget _buildNoteRow(String note) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.notes_outlined, size: 15, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'หมายเหตุ: $note',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  /// ปุ่มการทำงานหลัก (คำนวณราคา / เริ่มอบ / เสร็จสิ้น) ตามสถานะออเดอร์
  Widget _buildActionButton(BuildContext context) {
    if (_isWaiting) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Get.to(() => StaffCalculateScreen(order: order.toJson()))
                ?.then((_) => onRefresh());
          },
          icon: const Icon(
            Icons.calculate_outlined,
            color: Colors.white,
            size: 18,
          ),
          label: const Text(
            'คำนวณราคา',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    if (_showStartDry) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showStartDryDialog,
          label: const Text(
            'ซักเสร็จแล้ว → เริ่มอบ',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    if (_canUpdate) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showUpdateBottomSheet(context),
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 18,
          ),
          label: const Text(
            'เสร็จสิ้น  พร้อมส่ง',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// แถบแจ้งสถานะรอ/ชำระเงินแล้ว
  Widget _buildStatusBanner() {
    if (order.status == 'waiting_payment') {
      return _banner(text: 'รอลูกค้าชำระเงิน', color: Colors.red);
    }
    if (order.status == 'payment_completed') {
      return _banner(text: 'ลูกค้าชำระเงินแล้ว', color: Colors.green);
    }
    return const SizedBox.shrink();
  }

  Widget _banner({required String text, required Color color}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: color, fontSize: 13),
    ),
  );

  // ── Start-dry confirmation dialog ─────────────────────────

  void _showStartDryDialog() {
    final dryer = order.dryer;

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFFF8F9FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_laundry_service_outlined,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'เริ่มอบผ้า',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'ซักเสร็จแล้ว พร้อมเริ่มอบ?\nเครื่องซักจะถูกปล่อยว่างทันที',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: dryer == null
                    ? const Text(
                        'ไม่พบข้อมูลเครื่องอบ',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dryer.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _infoChip(
                                icon: Icons.scale_outlined,
                                label: 'ความจุ',
                                value: dryer.capacity != null
                                    ? '${dryer.capacity} kg'
                                    : '-',
                              ),
                              const SizedBox(width: 10),
                              _infoChip(
                                icon: Icons.timer_outlined,
                                label: 'เวลาอบ',
                                value: dryer.workMinutes != null
                                    ? '${dryer.workMinutes} นาที'
                                    : '-',
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        await _callStartDry();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'ยืนยัน',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// เรียก API เปลี่ยนสถานะเป็น "drying" แล้วแจ้งผลด้วย GetX snackbar
  /// (เดิมใช้ ScaffoldMessenger ซึ่งอาจ error ถ้าไม่มี Scaffold ครอบ context นั้น ๆ
  /// เปลี่ยนมาใช้ Get.snackbar ให้สอดคล้องกับจุดอื่นในไฟล์)
  Future<void> _callStartDry() async {
    try {
      final res = await http.put(
        Uri.parse('$url/order/staff/update/status/staff/${order.id}'),
        headers: {'Content-Type': 'application/json'},
        body: updateStatusRequestToJson(
          UpdateStatusRequest(staffId: staffId, status: 'drying'),
        ),
      );

      final response = updateStatusResponseFromJson(res.body);
      final success = res.statusCode == 200;
      if (success) onRefresh();

      _showSimpleSnackbar(
        message: response.message,
        success: success,
      );
    } catch (e) {
      _showSimpleSnackbar(
        message: 'เกิดข้อผิดพลาด: $e',
        success: false,
      );
    }
  }

  void _showSimpleSnackbar({required String message, required bool success}) {
    Get.snackbar(
      success ? 'สำเร็จ' : 'ผิดพลาด',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: success ? Colors.green : Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// UPDATE STATUS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _UpdateStatusSheet extends StatefulWidget {
  final StaffOrder order;
  final String url;
  final String staffId;
  final VoidCallback onSuccess;

  const _UpdateStatusSheet({
    required this.order,
    required this.url,
    required this.staffId,
    required this.onSuccess,
  });

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final res = await http.put(
        Uri.parse(
          '${widget.url}/order/staff/update/status/staff/${widget.order.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: updateStatusRequestToJson(
          UpdateStatusRequest(
            staffId: widget.staffId,
            status: 'waiting_delivery',
          ),
        ),
      );

      final response = updateStatusResponseFromJson(res.body);
      if (!mounted) return;

      if (res.statusCode == 200) {
        Navigator.pop(context);
        widget.onSuccess();
        _showSuccessSnackbar(response.message);
      } else {
        _showErrorSnackbar(response.message);
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// แจ้งเตือนสำเร็จ (สไตล์การ์ดเขียว ไล่เฉด)
  void _showSuccessSnackbar(String message) {
    Future.microtask(() {
      if (Get.context == null) return;
      Get.closeAllSnackbars();

      Get.snackbar(
        '',
        '',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.transparent,
        barBlur: 0,
        overlayBlur: 0,
        snackStyle: SnackStyle.FLOATING,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        padding: EdgeInsets.zero,
        borderRadius: 18,
        duration: const Duration(seconds: 3),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        messageText: _statusSnackbarContent(
          title: 'สำเร็จ',
          message: message,
          colors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
          shadowColor: Colors.green,
          icon: Icons.check_rounded,
        ),
      );
    });
  }

  /// แจ้งเตือนผิดพลาด (สไตล์เดียวกัน แต่โทนแดง) — ก่อนหน้านี้ error กรณีนี้ใช้ showDialog
  /// ซึ่งไม่สอดคล้องกับ success ที่ใช้ snackbar ทำให้ประสบการณ์ไม่เนียน
  /// เปลี่ยนให้ error ใช้ Get.snackbar เหมือนกันเพื่อความสม่ำเสมอ
  void _showErrorSnackbar(String message) {
    Future.microtask(() {
      if (Get.context == null) return;
      Get.closeAllSnackbars();

      Get.snackbar(
        '',
        '',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.transparent,
        barBlur: 0,
        overlayBlur: 0,
        snackStyle: SnackStyle.FLOATING,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        padding: EdgeInsets.zero,
        borderRadius: 18,
        duration: const Duration(seconds: 3),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        messageText: _statusSnackbarContent(
          title: 'ผิดพลาด',
          message: message,
          colors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
          shadowColor: Colors.red,
          icon: Icons.close_rounded,
        ),
      );
    });
  }

  /// การ์ดเนื้อหาแจ้งเตือน ใช้ร่วมกันทั้งสำเร็จ/ผิดพลาด แค่เปลี่ยนสีกับข้อความ
  Widget _statusSnackbarContent({
    required String title,
    required String message,
    required List<Color> colors,
    required Color shadowColor,
    required IconData icon,
  }) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.22),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เสร็จสิ้น / พร้อมส่ง',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'ยืนยันการเสร็จสิ้นงาน',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'ยืนยันเสร็จสิ้น',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}