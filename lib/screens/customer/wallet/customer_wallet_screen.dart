import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/screens/customer/wallet/customer_topup_screen.dart';
import 'package:wash_and_dry/service/session_service.dart';

// ── Transaction Model ──
class WalletTransaction {
  final String id;
  final String type; // 'topup' | 'payment'
  final double amount;
  final String label;
  final String subtitle;
  final DateTime? datetime;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.label,
    required this.subtitle,
    this.datetime,
  });
}

class WalletCustomerScreen extends StatefulWidget {
  const WalletCustomerScreen({super.key});

  @override
  State<WalletCustomerScreen> createState() => _WalletCustomerScreenState();
}

class _WalletCustomerScreenState extends State<WalletCustomerScreen> {
  final _session = Session();
  final _firestore = FirebaseFirestore.instance;

  double _balance = 0;
  List<WalletTransaction> _transactions = [];
  bool _loading = true;
  String? _customerId;

  // เก็บ list แยกก่อนรวม
  List<WalletTransaction> _topups = [];
  List<WalletTransaction> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    _customerId = await _session.getCustomerId();
    if (_customerId == null || _customerId!.isEmpty) {
      _showSnackbar("ไม่พบข้อมูล Customer ID");
      setState(() => _loading = false);
      return;
    }
    _listenBalance();
    _listenTopup();
    _listenPayment();
  }

  void _listenBalance() {
    _firestore.collection('customers').doc(_customerId).snapshots().listen((
      doc,
    ) {
      if (doc.exists && mounted) {
        setState(() {
          _balance = (doc.data()?['wallet_balance'] ?? 0).toDouble();
        });
      }
    }, onError: (e) => _showSnackbar("เกิดข้อผิดพลาด: $e"));
  }

  void _listenTopup() {
    final customerRef = _firestore.collection('customers').doc(_customerId);
    _firestore
        .collection('topup_history')
        .where('customer_id', isEqualTo: customerRef)
        .orderBy('topup_datetime', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          _topups = snap.docs.map((doc) {
            final data = doc.data();
            final order_datetime = (data['topup_datetime'] as Timestamp?)?.toDate();
            return WalletTransaction(
              id: doc.id,
              type: 'topup',
              amount: (data['amount'] ?? 0).toDouble(),
              label: 'เติมเงิน',
              subtitle: 'บริการเติมเงิน',
              datetime: order_datetime,
            );
          }).toList();
          _mergeAndUpdate();
        }, onError: (e) => log('topup error: $e'));
  }

  void _listenPayment() {
    final customerRef = _firestore.collection('customers').doc(_customerId);
    _firestore
        .collection('orders')
        .where('customer_id', isEqualTo: customerRef)
        .where('status', isEqualTo: 'completed')
        .orderBy('order_datetime', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          _payments = snap.docs.map((doc) {
            final data = doc.data();
            final  order_datetime = (data['order_datetime'] as Timestamp?)?.toDate();
            final serviceLabel =
                {
                  'wash': 'ซักอย่างเดียว',
                  'dry': 'อบอย่างเดียว',
                  'wash_dry': 'ซักและอบ',
                }[data['service_type']] ??
                data['service_type'] ??
                '';
            final total =
                ((data['service_price'] ?? 0) + (data['delivery_price'] ?? 0))
                    .toDouble();
            return WalletTransaction(
              id: doc.id,
              type: 'payment',
              amount: total,
              label: 'ชำระค่าบริการ',
              subtitle: serviceLabel,
              datetime: order_datetime,
            );
          }).toList();
          _mergeAndUpdate();
        }, onError: (e) => log('payment error: $e'));
  }

  void _mergeAndUpdate() {
    final all = [..._topups, ..._payments]
      ..sort((a, b) {
        if (a.datetime == null) return 1;
        if (b.datetime == null) return -1;
        return b.datetime!.compareTo(a.datetime!);
      });
    setState(() {
      _transactions = all;
      _loading = false;
    });
  }

  void _showSnackbar(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

 String _formatDate(DateTime? dt) {
  if (dt == null) return '-';

  const m = [
    '',
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
    'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
    'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  return '${dt.day} ${m[dt.month]} ${dt.year + 543} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFF5F7FB),
      body: _loading ? _buildLoading() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final bool showBack = Get.arguments?["fromGet"] == true;
    return AppBar(
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
        "กระเป๋าเงิน",
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
      ),
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Get.back(),
            )
          : null,
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildBalanceCard(),
        _buildHistoryHeader(),
        const SizedBox(height: 12),
        _buildHistoryList(),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0593FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 34, 158, 253).withOpacity(0.95),
                  const Color.fromARGB(255, 210, 236, 255).withOpacity(0.25),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/icons/wallet_white.png',
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ยอดเงินคงเหลือ",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  "${_balance.toStringAsFixed(0)} บาท",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.to(() => TopupCustomer()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0593FF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "เติมเงิน",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            "รายการล่าสุด",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_transactions.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text("ไม่มีรายการ", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          return _TransactionCard(
            type: tx.label,
            subtitle: tx.subtitle,
            datetime: _formatDate(tx.datetime),
            amount: tx.amount,
            isTopup: tx.type == 'topup',
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final String type;
  final String subtitle;
  final String datetime;
  final double amount;
  final bool isTopup;

  const _TransactionCard({
    required this.type,
    required this.subtitle,
    required this.datetime,
    required this.amount,
    required this.isTopup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  datetime,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Center(
                  child: Image.asset(
                    isTopup
                        ? "assets/icons/topup.png"
                        : "assets/icons/cut_money.png",
                    width: 36,
                    height: 36,
                    color: isTopup ? null : const Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isTopup
                    ? "+${amount.toStringAsFixed(0)} ฿"
                    : "-${amount.toStringAsFixed(0)} ฿",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isTopup
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
