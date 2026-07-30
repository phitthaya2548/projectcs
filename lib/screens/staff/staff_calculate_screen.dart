import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/res/customer/store/res_machine_store.dart';
import 'package:wash_and_dry/service/session_service.dart';

class StaffCalculateScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const StaffCalculateScreen({super.key, required this.order});

  @override
  State<StaffCalculateScreen> createState() => _StaffCalculateScreenState();
}

class _StaffCalculateScreenState extends State<StaffCalculateScreen> {
  final _weightCtrl = TextEditingController();
  List<Machine> _machines = [];
  Machine? _washer, _dryer;
  double? _price, _delivery_price,_detergentFee;
  bool _loadingMachines = false, _loadingFee = false, _submitting = false;
  bool _weightDone = false;
  String _url = '', _staffId = '';



  String? get _svcType => widget.order['service_type'] as String?;
  String? get _detergent => widget.order['detergent_option'] as String?;
  bool get _needWash => _svcType == 'wash' || _svcType == 'wash_dry';
  bool get _needDry => _svcType == 'dry' || _svcType == 'wash_dry';
  bool get _hasDetergent => _detergent == 'detergent';
  double get _weight => double.tryParse(_weightCtrl.text) ?? 0;
  double _mp(Machine? m) => m?.price ?? 0;
  List<Machine> _byType(String t) =>
      _machines.where((m) => m.type == t).toList();

@override
void initState() {
  super.initState();
  log(jsonEncode(widget.order));
  _init();
}

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final cfg = await Configuration.getConfig();
      _staffId = await Session().getStaffId() ?? '';
      _url = cfg['apiEndpoint']?.toString() ?? '';
      if (mounted) setState(() {});
    } catch (_) {}
    await Future.wait([_fetchMachines(), _fetchDelivetyPrice()]);
  }

Future<void> _fetchMachines() async {
  final sid = widget.order['store']?['id'];
  log('sid: $sid');
  if (sid == null || _url.isEmpty) return;
  setState(() => _loadingMachines = true);
  try {
    final res = await http.get(Uri.parse('$_url/store/machines/$sid'));
    if (!mounted) return;
    log(res.body); 
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List raw = body is List
          ? body
          : (body['data'] ?? body['machines'] ?? []);
      setState(
        () => _machines = raw.map((e) => Machine.fromJson(e)).toList(),
      );
    }
  } catch (e) {
    log('$e');
  } finally {
    if (mounted) setState(() => _loadingMachines = false);
  }
}

  Future<void> _fetchDelivetyPrice() async {
    if (_url.isEmpty || _staffId.isEmpty) return;
    setState(() => _loadingFee = true);
    try {
      final uri = Uri.parse(
        '$_url/order/staff/calculate/preview/${widget.order['id']}',
      ).replace(queryParameters: {'staff_id': _staffId});
      final res = await http.get(uri);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as Map<String, dynamic>?;
        setState(() {
  _delivery_price = (data?['delivery_price'] as num?)?.toDouble() ?? 0;
  _detergentFee = (data?['detergent_price'] as num?)?.toDouble() ?? 0;
});
      }
    } catch (e) {
      log('$e');
    } finally {
      if (mounted) setState(() => _loadingFee = false);
    }
  }

  void _confirmWeight() {
    if (_weight <= 0) {
      _snack('กรุณากรอกน้ำหนักให้ถูกต้อง', type: SnackType.error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _weightDone = true;
      _washer = null;
      _dryer = null;
      _price = null;
    });
  }

  void _calc() {
    if (_needWash && _washer == null) return;
    if (_needDry && _dryer == null) return;
    final machine = switch (_svcType) {
      'wash' => _mp(_washer),
      'dry' => _mp(_dryer),
      _ => _mp(_washer) + _mp(_dryer),
    };
    setState(
  () => _price =
      machine + (_hasDetergent ? (_detergentFee ?? 0) : 0) + (_delivery_price ?? 0),
);
  }

  Future<void> _submit() async {
  setState(() => _submitting = true);
  try {
    final res = await http.put(
      Uri.parse('$_url/order/staff/calculate/${widget.order['id']}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'staff_id': _staffId,
        'weight': _weight,
        'washer_id': _washer?.machineId,
        'dryer_id': _dryer?.machineId,
      }),
    );
    if (!mounted) return;

    log('status: ${res.statusCode}, body: ${res.body}');

    final ok = res.statusCode == 200 || res.statusCode == 201;
    String message = ok ? 'สำเร็จ' : 'เกิดข้อผิดพลาด';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {

    }

 _snack(message, type: ok ? SnackType.success : SnackType.error);
if (ok) {
  await Future.delayed(const Duration(milliseconds: 600));
  if (mounted) Get.back(result: true);
}
  } catch (e) {
    log('submit error: $e');
    _snack('เกิดข้อผิดพลาด', type: SnackType.error);
  } finally {
    if (mounted) setState(() => _submitting = false);
  }
}

  /// แจ้งเตือนสวย ๆ ด้วย GetX Snackbar
  void _snack(String msg, {SnackType type = SnackType.info}) {
    final (icon, color, title) = switch (type) {
      SnackType.success => (FontAwesomeIcons.circleCheck, const Color(0xFF34A853), 'สำเร็จ'),
      SnackType.error => (FontAwesomeIcons.circleExclamation, const Color(0xFFEA4335), 'ผิดพลาด'),
      SnackType.info => (FontAwesomeIcons.circleInfo, const Color(0xFF0593FF), 'แจ้งเตือน'),
    };

    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      borderRadius: 14,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      titleText: Row(
        children: [
          FaIcon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
      messageText: Text(
        msg,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      leftBarIndicatorColor: color,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      duration: const Duration(seconds: 3),
      snackStyle: SnackStyle.FLOATING,
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.order['customer'] as Map<String, dynamic>?;
    final beforeImg = widget.order['before_wash_image'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'คำนวณราคา',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0E0E0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _card(
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE8F0FE),
                  backgroundImage: customer?['profile_image'] != null
                      ? NetworkImage(customer!['profile_image'])
                      : null,
                  child: customer?['profile_image'] == null
                      ? const FaIcon(
                          FontAwesomeIcons.user,
                          size: 20,
                          color: Color(0xFF1A73E8),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer?['name'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.phone,
                            size: 11,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customer?['phone'] ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.locationDot,
                            size: 11,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.order['address'] ?? '-',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (beforeImg != null && beforeImg.isNotEmpty) ...[
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      FaIcon(
                        FontAwesomeIcons.image,
                        size: 15,
                        color: Color(0xFF0593FF),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'รูปก่อนซัก',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
  onTap: () => showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.loose,
        children: [
          Center(
            child: InteractiveViewer(
              maxScale: 5.0,
              child: Hero(
                tag: beforeImg,
                child: Image.network(
                  beforeImg,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  child: Hero(
    tag: beforeImg,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        beforeImg,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
              ),
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.grey.shade100,
          child: const Center(
            child: Icon(Icons.broken_image_outlined,
                color: Colors.grey, size: 40),
          ),
        ),
      ),
    ),
  ),
),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          _card(
            Row(
              children: [
                Expanded(
                  child: _infoChip(
                    'บริการ',
                    _svcLabel(),
                    FontAwesomeIcons.shirt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoChip(
                    'น้ำยาซักผ้า',
                    _hasDetergent ? 'ร้านจัดให้' : 'ลูกค้าเตรียมมาแล้ว',
                    _hasDetergent
                        ? FontAwesomeIcons.soap
                        : FontAwesomeIcons.ban,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    FaIcon(
                      FontAwesomeIcons.weight,
                      size: 13,
                      color: Color(0xFF0593FF),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'น้ำหนักผ้า (กก.)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _weightField()),
                    const SizedBox(width: 8),
                    _weightDone
                        ? TextButton.icon(
                            onPressed: () => setState(() {
                              _weightDone = false;
                              _price = null;
                              _washer = null;
                              _dryer = null;
                            }),
                            icon: const FaIcon(
                              FontAwesomeIcons.penToSquare,
                              size: 13,
                            ),
                            label: const Text('แก้ไข'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0593FF),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _confirmWeight,
                            icon: const FaIcon(
                              FontAwesomeIcons.check,
                              size: 14,
                            ),
                            label: const Text('ยืนยัน'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0593FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),

          if (_weightDone) ...[
            const SizedBox(height: 10),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/machine.png',
                            width: 13,
                            height: 13,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'เลือกเครื่อง',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (_loadingMachines)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        GestureDetector(
                          onTap: _fetchMachines,
                          child: const FaIcon(
                            FontAwesomeIcons.arrowsRotate,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_needWash) ...[
                    _dropdown(
                      'เครื่องซัก',
                      _byType('washer'),
                      _washer?.machineId,
                      (m) {
                        setState(() {
                          _washer = m;
                          _price = null;
                        });
                        _calc();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_needDry)
                    _dropdown(
                      'เครื่องอบ',
                      _byType('dryer'),
                      _dryer?.machineId,
                      (m) {
                        setState(() {
                          _dryer = m;
                          _price = null;
                        });
                        _calc();
                      },
                    ),
                ],
              ),
            ),
          ],

          // ── Summary ──
          if (_weightDone) ...[
            const SizedBox(height: 10),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      FaIcon(
                        FontAwesomeIcons.fileInvoiceDollar,
                        size: 13,
                        color: Color(0xFF0593FF),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'สรุปราคา',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_needWash)
                    _row(
                      'เครื่องซัก',
                      _washer != null
                          ? '฿${_mp(_washer).toStringAsFixed(0)}'
                          : '-',
                      "assets/icons/machine1.png",
                    ),
                  if (_needDry)
                    _row(
                      'เครื่องอบ',
                      _dryer != null
                          ? '฿${_mp(_dryer).toStringAsFixed(0)}'
                          : '-',
                      "assets/icons/machine1.png",
                    ),
                  _row(
                    'น้ำยาซักผ้า',
                    _hasDetergent
                        ? '฿${(_detergentFee ?? 0).toStringAsFixed(0)}'
                        : 'ฟรี',
                     "assets/icons/detergent.png",
                  ),
                  _loadingFee
                      ? _row('ค่าส่ง', '...', "assets/icons/motorbike.png")
                      : _row(
                          'ค่าส่ง',
                          _delivery_price != null
                              ? '฿${_delivery_price!.toStringAsFixed(0)}'
                              : '-',
                          "assets/icons/motorbike.png",
                        ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          FaIcon(
                            FontAwesomeIcons.moneyBill,
                            size: 14,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'รวม',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _price != null ? '฿${_price!.toStringAsFixed(0)}' : '-',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: _price != null
                              ? const Color(0xFF0593FF)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_price != null && !_submitting) ? _submit : null,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const FaIcon(
                        FontAwesomeIcons.circleCheck,
                        size: 18,
                        color: Colors.white,
                      ),
                label: _submitting
                    ? const SizedBox.shrink()
                    : const Text(
                        'ยืนยันและเริ่มซัก',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _svcLabel() => switch (_svcType) {
    'wash' => 'ซักอย่างเดียว',
    'dry' => 'อบอย่างเดียว',
    'wash_dry' => 'ซัก + อบ',
    _ => _svcType ?? '-',
  };

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _infoChip(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            FaIcon(icon, size: 12, color: const Color(0xFF0593FF)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _weightField() => TextField(
    controller: _weightCtrl,
    enabled: !_weightDone,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      hintText: '0.0',
      prefixIcon: const Padding(
        padding: EdgeInsets.all(12),
        child: FaIcon(
          FontAwesomeIcons.weight,
          size: 16,
          color: Colors.grey,
        ),
      ),
      suffixText: 'กก.',
      filled: true,
      fillColor: _weightDone ? const Color(0xFFF8F9FA) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0593FF), width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
    ),
  );

  Widget _dropdown(
    String label,
    List<Machine> list,
    String? selected,
    ValueChanged<Machine?> onChange,
  ) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Image.asset("assets/icons/machine1.png",width: 13,height: 13,
            color: Color(0xFF0593FF),),
            const SizedBox(width: 4),
            Text(
              'ไม่มี$label',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<String>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset("assets/icons/machine1.png",width: 13,height: 13,
            color: Color(0xFF0593FF),),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0593FF), width: 2),
        ),
      ),
      hint: Text('เลือก$label', style: const TextStyle(fontSize: 13)),
      items: list.map((m) {
        final ok = m.status == MachineStatus.available;
        return DropdownMenuItem<String>(
          value: m.machineId,
          enabled: ok,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${m.name}  ${m.capacity}กก. • ${m.workMinutes}น. • ฿${m.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: ok ? Colors.black87 : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _badge(m.status),
            ],
          ),
        );
      }).toList(),
      onChanged: (id) {
        if (id == null) return;
        onChange(list.firstWhere((m) => m.machineId == id));
      },
    );
  }

  Widget _badge(MachineStatus s) {
    final (label, color) = switch (s) {
      MachineStatus.available => ('ว่าง', const Color(0xFF34A853)),
      MachineStatus.busy => ('ใช้งาน', const Color(0xFFFBBC04)),
      MachineStatus.maintenance => ('ปิดชั่วคราว', const Color(0xFFEA4335)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

 Widget _row(String label, String value, String imagePath) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Image.asset(
            imagePath,
            width: 16,
            height: 16,
            color: Colors.black38,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
      Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ],
  ),
);
}

enum SnackType { success, error, info }