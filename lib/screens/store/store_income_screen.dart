import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/res/customer/store/res_profile_store.dart';
import 'package:wash_and_dry/models/res/customer/store/res_report_store.dart';

import 'package:wash_and_dry/service/session_service.dart';
import 'package:wash_and_dry/widgets/appbarstore.dart';

// สีหลักของธีม ปรับตรงนี้ที่เดียวถ้าต้องการเปลี่ยนโทนสี
const Color kPrimaryBlue = Color(0xFF2E9FE8);
const Color kPrimaryBlueDark = Color(0xFF1C7FC4);
const Color kRevenueGreen = Color(0xFF2ECC71);
const Color kCardBg = Colors.white;
const Color kScreenBg = Color(0xFFF4F6F8);

class StoreIncomeScreen extends StatefulWidget {
  const StoreIncomeScreen({super.key});

  @override
  State<StoreIncomeScreen> createState() => _StoreIncomeScreenState();
}

class _StoreIncomeScreenState extends State<StoreIncomeScreen> {
  String url = '';
  StoreData? storeData;
  bool isLoading = true;
  String? errorMessage;
  String? storeId;

  String selectedRange = 'day'; // day, week, month, year
  RevenueReportResponse? reportData;
  bool isLoadingReport = false;
  String? reportError;

  // แท่งกราฟที่ผู้ใช้กำลังกดดูรายละเอียดอยู่ (null = ยังไม่ได้เลือก)
  int? selectedChartIndex;

  final List<_RangeOption> _rangeOptions = const [
    _RangeOption(value: 'day', label: 'วัน'),
    _RangeOption(value: 'week', label: 'สัปดาห์'),
    _RangeOption(value: 'month', label: 'เดือน'),
    _RangeOption(value: 'year', label: 'ปี'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
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
      await _getRevenueReport(selectedRange);
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
      if (mounted) {
        setState(() {
          errorMessage = 'เซิร์ฟเวอร์ช้า';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  Future<void> _getRevenueReport(String range) async {
    if (!mounted || storeId == null || url.isEmpty) return;
    setState(() {
      isLoadingReport = true;
      reportError = null;
      // เคลียร์แท่งที่เคยเลือกไว้ เพราะข้อมูลชุดใหม่จะมีจำนวนแท่ง/ความหมายไม่เหมือนเดิม
      selectedChartIndex = null;
    });
    try {
      final uri = Uri.parse('$url/report/store/revenue/$storeId?range=$range');
      final res = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) throw Exception('เกิดข้อผิดพลาด (${res.statusCode})');

      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['ok'] != true) throw Exception(body['message'] ?? 'ดึงรายงานไม่สำเร็จ');

      if (mounted) {
        setState(() {
          reportData = RevenueReportResponse.fromJson(body);
          isLoadingReport = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          reportError = 'เซิร์ฟเวอร์ช้า';
          isLoadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          reportError = e.toString().replaceAll('Exception: ', '');
          isLoadingReport = false;
        });
      }
    }
  }

  void _onRangeSelected(String range) {
    if (range == selectedRange) return;
    setState(() => selectedRange = range);
    _getRevenueReport(range);
  }

  void _onBarTap(int index) {
    setState(() {
      // กดแท่งเดิมซ้ำ = ยกเลิกการเลือก, กดแท่งใหม่ = เลือกแท่งนั้น
      selectedChartIndex = selectedChartIndex == index ? null : index;
    });
  }

  // ใส่ comma คั่นหลักพัน เช่น 12450 -> "12,450"
  String _formatNumber(num value) {
    final isNegative = value < 0;
    final intPart = value.abs().round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < intPart.length; i++) {
      final posFromEnd = intPart.length - i;
      buffer.write(intPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    return (isNegative ? '-' : '') + buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScreenBg,
      appBar: storeData == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: StoreAppBar(
                title: storeData?.storeName ?? '',
                profileImage: storeData?.profileImage,
                storeId: storeData?.storeId ?? '',
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
              : RefreshIndicator(
                  onRefresh: () => _getRevenueReport(selectedRange),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildRangeTabs(),
                        const SizedBox(height: 16),
                        _buildChartCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ---------- การ์ดสรุป: รายได้รวม + จำนวนออเดอร์ ----------
  Widget _buildSummaryCard() {
    final revenue = reportData?.summary.totalRevenue ?? 0;
    final orderCount = reportData?.summary.orderCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รายได้รวม',
                style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
              if (isLoadingReport)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(revenue),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: kRevenueGreen,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('บาท', style: TextStyle(fontSize: 16, color: Colors.black54)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimaryBlue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '$orderCount',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlueDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'ออเดอร์',
                  style: TextStyle(fontSize: 13, color: kPrimaryBlueDark),
                ),
              ],
            ),
          ),
          if (reportError != null) ...[
            const SizedBox(height: 12),
            Text(
              reportError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ---------- แท็บเลือกช่วงเวลา: วัน / สัปดาห์ / เดือน / ปี ----------
  Widget _buildRangeTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: _rangeOptions.map((option) {
          final isSelected = option.value == selectedRange;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onRangeSelected(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- การ์ดกราฟรายได้ ----------
  Widget _buildChartCard() {
    final chart = reportData?.chart ?? [];
    final RevenueChartItem? selectedItem =
        (selectedChartIndex != null && selectedChartIndex! < chart.length)
            ? chart[selectedChartIndex!]
            : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'กราฟรายได้',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const Icon(Icons.bar_chart_rounded, color: kPrimaryBlue),
            ],
          ),
          const SizedBox(height: 8),
          // แถบรายละเอียดของแท่งที่กำลังเลือกดูอยู่ (รายได้ + จำนวนออเดอร์ของวัน/สัปดาห์/เดือน/ปีนั้น)
          _buildSelectedDetailBar(selectedItem),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: chart.isEmpty
                ? Center(
                    child: Text(
                      isLoadingReport ? 'กำลังโหลด...' : 'ไม่มีข้อมูล',
                      style: const TextStyle(color: Colors.black38),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // แท่งกราฟแคบสุดที่ยังอ่านง่าย ถ้าจำนวนแท่งเยอะ (เช่น เดือน = 12 แท่ง)
                      // จนล้นพื้นที่ ให้เลื่อนซ้าย-ขวาแทนการบีบให้แคบจนตัวเลข/ชื่อเดือนทับกัน
                      const minBarWidth = 46.0;
                      final evenWidth = constraints.maxWidth / chart.length;
                      final needsScroll = evenWidth < minBarWidth;
                      final barWidth = needsScroll ? minBarWidth : evenWidth;

                      final chartWidget = _RevenueBarChart(
                        chart: chart,
                        formatNumber: _formatNumber,
                        barWidth: barWidth,
                        selectedIndex: selectedChartIndex,
                        onBarTap: _onBarTap,
                      );

                      if (!needsScroll) return chartWidget;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: barWidth * chart.length,
                          child: chartWidget,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDetailBar(RevenueChartItem? item) {
    if (item == null) {
      return const Text(
        'แตะแท่งกราฟเพื่อดูรายละเอียด',
        style: TextStyle(fontSize: 12, color: Colors.black38),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPrimaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          Row(
            children: [
              Text(
                '${_formatNumber(item.revenue)} บาท',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kRevenueGreen),
              ),
              const SizedBox(width: 10),
              Text(
                '${item.orderCount} ออเดอร์',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryBlueDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeOption {
  final String value;
  final String label;
  const _RangeOption({required this.value, required this.label});
}


class _RevenueBarChart extends StatelessWidget {
  final List<RevenueChartItem> chart;
  final String Function(num) formatNumber;
  final double barWidth;
  final int? selectedIndex;
  final ValueChanged<int> onBarTap;

  const _RevenueBarChart({
    required this.chart,
    required this.formatNumber,
    required this.barWidth,
    required this.selectedIndex,
    required this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxRevenue = chart.map((e) => e.revenue).fold<num>(0, max);
    final safeMax = maxRevenue <= 0 ? 1 : maxRevenue;

    // หา index ที่มีรายได้สูงสุด เพื่อไฮไลต์แท่งนั้นเป็นค่าเริ่มต้น (ตอนยังไม่ได้เลือกแท่งไหนเอง)
    int highestIndex = 0;
    for (int i = 1; i < chart.length; i++) {
      if (chart[i].revenue > chart[highestIndex].revenue) highestIndex = i;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(chart.length, (index) {
        final item = chart[index];
        final heightRatio = item.revenue <= 0 ? 0.02 : (item.revenue / safeMax);
        final isSelected = selectedIndex == null ? index == highestIndex && item.revenue > 0 : selectedIndex == index;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onBarTap(index),
          child: SizedBox(
            width: barWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ความสูงคงที่เสมอ กันไม่ให้ตัวเลขรายได้ที่ยาว/สั้นไม่เท่ากันทำให้แท่งกราฟ
                  // แต่ละคอลัมน์เลื่อนขึ้น-ลงไม่ตรงกัน (ปัญหาที่เจอตอนแสดงกราฟรายเดือน 12 แท่ง)
                  SizedBox(
                    height: 14,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.revenue > 0 ? formatNumber(item.revenue) : '-',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? kPrimaryBlueDark : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: (110.0 * heightRatio).clamp(4.0, 110.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isSelected
                              ? [kPrimaryBlue, kPrimaryBlueDark]
                              : [kPrimaryBlue.withOpacity(0.55), kPrimaryBlue.withOpacity(0.35)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ความสูงคงที่ + maxLines:1 กันชื่อเดือน/ป้ายกำกับยาวๆ ดันเลย์เอาต์จนแท่งอื่นเยื้องกัน
                  SizedBox(
                    height: 14,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}