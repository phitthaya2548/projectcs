import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/res/customer/res_topuphistory_customer.dart';
import 'package:wash_and_dry/screens/customer/topup_customer.dart';
import 'package:wash_and_dry/service/session_service.dart';

class WalletCustomerScreen extends StatefulWidget {
  const WalletCustomerScreen({super.key});

  @override
  State<WalletCustomerScreen> createState() => _WalletCustomerScreenState();
}

class _WalletCustomerScreenState extends State<WalletCustomerScreen> {
  final _session = Session();
  final _firestore = FirebaseFirestore.instance;

  double _balance = 0;
  List<TopupHistory> _history = [];
  bool _loading = true;
  String url = '';
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadWallet();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() => url = config['apiEndpoint']?.toString() ?? '');
    } catch (_) {
      setState(() => url = '');
    }
  }

  Future<void> _loadWallet() async {
    _customerId = await _session.getCustomerId();

    if (_customerId == null || _customerId!.isEmpty) {
      _showSnackbar("ไม่พบข้อมูล Customer ID");
      setState(() => _loading = false);
      return;
    }

    _listenBalance();
    _listenHistory();
  }

  void _listenBalance() {
    _firestore
        .collection('customers')
        .doc(_customerId)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists && mounted) {
              setState(() {
                _balance = (doc.data()?['wallet_balance'] ?? 0).toDouble();
              });
            }
          },
          onError: (e) {
            _showSnackbar("เกิดข้อผิดพลาดในการโหลด wallet: $e");
          },
        );
  }

  void _listenHistory() {

  final customerRef = _firestore.collection('customers').doc(_customerId);
  
  _firestore
      .collection('topup_history')
      .where('customer_id', isEqualTo: customerRef)
      .orderBy('topup_datetime', descending: true)
      .limit(20)
      .snapshots()
      .listen(
        (snapshot) {
          if (mounted) {
            setState(() {
              _history = snapshot.docs.map((doc) {
                final data = doc.data();
                return TopupHistory(
                  id: doc.id,
                  amount: (data['amount'] ?? 0).toDouble(),
                  transRef: data['trans_ref'] ?? '',
                  datetime:
                      (data['topup_datetime'] as Timestamp?)
                          ?.toDate()
                          .toIso8601String() ??
                      '',
                );
              }).toList();
              _loading = false;
            });
          }
        },
        onError: (e) {
          print('History listen error: $e'); // ✅ เพิ่ม log
          _showSnackbar("เกิดข้อผิดพลาดในการโหลดประวัติ: $e");
          if (mounted) setState(() => _loading = false);
        },
      );
}

  void _showSnackbar(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  String _formatDate(String datetime) {
    try {
      final date = DateTime.parse(datetime);
      final thaiDate = DateTime(
        date.year + 543,
        date.month,
        date.day,
        date.hour,
        date.minute,
      );
      return DateFormat('dd/MM/yyyy HH:mm').format(thaiDate);
    } catch (_) {
      return datetime;
    }
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
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

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
    if (_history.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            "ไม่มีประวัติการเติมเงิน",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return _TransactionCard(
            type: "เติมเงิน",
            subtitle: "บริการเติมเงิน",
            datetime: _formatDate(item.datetime),
            amount: item.amount,
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

  const _TransactionCard({
    required this.type,
    required this.subtitle,
    required this.datetime,
    required this.amount,
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
                    "assets/icons/topup.png",
                    width: 36,
                    height: 36,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "+${amount.toStringAsFixed(0)} ฿",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
