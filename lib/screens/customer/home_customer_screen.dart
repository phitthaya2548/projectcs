import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/req/customer/req_address_customer.dart';
import 'package:wash_and_dry/models/res/customer/res_store_customer.dart';
import 'package:wash_and_dry/screens/customer/customer_address_screen.dart';
import 'package:wash_and_dry/screens/customer/topup_customer.dart';
import 'package:wash_and_dry/service/session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String url = "";
  String? customerId;
  double walletBalance = 0;
  Future<List<Store>>? _futureStores;
  String searchText = "";
  int selectedFilterIndex = 0;
  Address? defaultAddress;
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final config = await Configuration.getConfig();
    url = config['apiEndpoint'];
    final session = Session();
    customerId = await session.getCustomerId();
    final addr = await getDefaultAddress();
    setState(() {;
      defaultAddress = addr;
      _futureStores = fetchStores();
    });
    _getWallet();
  }

  // Public method สำหรับรีเฟรชจากภายนอก
  Future<void> refresh() async {
    await _refreshData();
  }

  Future<void> _refreshData() async {
    final addr = await getDefaultAddress();
    setState(() {
      defaultAddress = addr;
      _futureStores = fetchStores(search: searchText);
    });
  }

  void _getWallet() {
    if (customerId == null) return;
    FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .snapshots()
        .listen((doc) {
          if (doc.exists && mounted) {
            setState(() {
              walletBalance = (doc.data()?['wallet_balance'] ?? 0).toDouble();
            });
          }
        });
  }

 Future<Address?> getDefaultAddress() async {
  if (customerId == null) return null;
  
  final res = await http.get(
    Uri.parse("$url/customer/addresses/active/$customerId"),
  );
  
  if (res.statusCode != 200) return null;
  
  final data = jsonDecode(res.body);
  if (data["data"] == null) return null;
  
  return Address.fromJson(data["data"]);
}

  Future<List<Store>> fetchStores({String search = ""}) async {
  final fullUrl = "$url/customer/getstores?search=$search";

  final response = await http.get(Uri.parse(fullUrl));

  final json = jsonDecode(response.body);

  List<Store> stores = [];

  for (var item in json["data"]) {
    stores.add(Store.fromJson(item));
  }
  return stores;
}


  @override
  Widget build(BuildContext context) {
    if (_futureStores == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF0593FF),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  _buildStoreListHeader(),
                  Expanded(child: _buildStoreList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildIconButton(Icons.menu),
                  const Spacer(),
                  _buildIconButton(Icons.notifications_none_rounded),
                ],
              ),
              const SizedBox(height: 12),
              _buildLocationCard(),
              const SizedBox(height: 12),
              _buildWalletCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildLocationCard() {
    final address = defaultAddress?.addressText ?? 'ยังไม่มีที่อยู่หลัก';
    return InkWell(
      onTap: () {
        Get.to(() =>  CustomerAddressScreen(customerId: customerId.toString()));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ตำแหน่งของคุณ',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  const Color(0xFF0593FF).withOpacity(0.95),
                  const Color(0xFF0593FF).withOpacity(0.25),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/icons/wallet_white.png',
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ยอดเงินคงเหลือ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${walletBalance.toStringAsFixed(2)} บาท',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Get.to(() => TopupCustomer());
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'เติมเงิน',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: "ค้นหาร้าน...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
        onChanged: (value) {
          searchText = value;
          setState(() {
            _futureStores = fetchStores(search: value);
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['ทั้งหมด', 'ใกล้ฉัน', 'คะแนนสูง'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(filters.length, (i) {
          final active = selectedFilterIndex == i;
          return Padding(
            padding: EdgeInsets.only(right: i < filters.length - 1 ? 8 : 0),
            child: InkWell(
              onTap: () => setState(() => selectedFilterIndex = i),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
                        )
                      : null,
                  color: active ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? Colors.transparent : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey[700],
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStoreListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ร้านยอดนิยมใกล้คุณ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'ดูทั้งหมด',
              style: TextStyle(fontSize: 14, color: Color(0xFF0593FF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreList() {
    return FutureBuilder<List<Store>>(
      future: _futureStores,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "ไม่พบร้าน",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, i) => _buildStoreCard(snapshot.data![i]),
        );
      },
    );
  }

  Widget _buildStoreCard(Store store) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                store.image,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.blue[100],
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      color: Color(0xFF0593FF),
                      size: 32,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.rating.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.blue[700],
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        "${store.distance} km",
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.opening,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
