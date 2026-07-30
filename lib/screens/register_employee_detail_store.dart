import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/res/customer/store/res_list_register_employee_store.dart';
import 'package:wash_and_dry/service/session_service.dart';

class StoreDetailEmployeeScreen extends StatefulWidget {
  final StoreListItem store;

  const StoreDetailEmployeeScreen({super.key, required this.store});

  @override
  State<StoreDetailEmployeeScreen> createState() =>
      _StoreDetailEmployeeScreenState();
}

class _StoreDetailEmployeeScreenState extends State<StoreDetailEmployeeScreen>
    with SingleTickerProviderStateMixin {
 

  static const Color _primaryColor = Color(0xFF0593FF);
  static const Color _primaryDarkColor = Color(0xFF0476D9);
  static const Color _bgColor = Color(0xFFF5F7FA);
  static const Color _successColor = Color(0xFF22C55E);
  static const Color _dangerColor = Color(0xFFEF4444);
  static const Color _starColor = Color(0xFFFFB800);
  static const Color _mutedTextColor = Color(0xFF6B7280);
  static const Color _chipBgColor = Color(0xFFF1F5F9);
  static const Color _titleTextColor = Color(0xFF1A1A2E);
  static const Color _lineColor = Color(0xFF06C755);
  static const Color _facebookColor = Color(0xFF1877F2);

  late final TabController _tabController;
  final PageController _imageController = PageController();
  final Session _session = Session();

  int _currentImage = 0;
  bool _isApplying = false;

  String url = '';

  List<StoreImageItem> _images = [];
  bool _loadingImages = true;

  List<StoreReviewItem> _reviews = [];
  bool _loadingReviews = true;

  StoreListItem get store => widget.store;

  bool get _isOpen => store.status.toLowerCase() == 'เปิดร้าน';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExtras();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imageController.dispose();
    super.dispose();
  }


  /// โหลดรูปและรีวิวแบบขนาน ไม่บล็อกกัน
  Future<void> _loadExtras() async {
    try {
      final cfg = await Configuration.getConfig();
      url = cfg['apiEndpoint']?.toString() ?? '';
    } catch (_) {
    }

    _fetchImages();
    _fetchReviews();
  }

  Future<void> _fetchImages() async {
    if (url.isEmpty) {
      if (mounted) setState(() => _loadingImages = false);
      return;
    }

    try {
      final uri = Uri.parse(
        '$url/store/images/${store.storeId}',
      );
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;

        if (json['ok'] == true) {
          final list = json['images'] as List<dynamic>? ?? [];
          final images = list
              .map((e) => StoreImageItem.fromJson(e as Map<String, dynamic>))
              .toList();

          if (mounted) setState(() => _images = images);
        }
      }
    } catch (_) {

    }

    if (mounted) setState(() => _loadingImages = false);
  }

  Future<void> _fetchReviews() async {
    if (url.isEmpty) {
      if (mounted) setState(() => _loadingReviews = false);
      return;
    }

    try {
      final uri = Uri.parse('$url/order/store/${store.storeId}/reviews');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? {};
        final list = data['reviews'] as List<dynamic>? ?? [];
        final reviews = list
            .map((e) => StoreReviewItem.fromJson(e as Map<String, dynamic>))
            .toList();

        if (mounted) setState(() => _reviews = reviews);
      }
    } catch (_) {

    }

    if (mounted) setState(() => _loadingReviews = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildImageCarousel(),
                _buildHeaderCard(),
                _buildTabBar(),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInfoTab(),
                      _buildReviewsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _primaryDarkColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'รายละเอียดร้านค้า',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }



  Widget _buildImageCarousel() {
    // ระหว่างรอโหลดรูป โชว์ profileImage ไปก่อน (ถ้ามี) ไม่ต้องรอจอว่าง
    if (_loadingImages) {
      return SizedBox(
        height: 240,
        child: _buildNetworkOrFallback(store.profileImage),
      );
    }

    final hasImages = _images.isNotEmpty;
    final itemCount = hasImages ? _images.length : 1;

    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imageController,
            itemCount: itemCount,
            onPageChanged: (i) => setState(() => _currentImage = i),
            itemBuilder: (context, i) {
              final url = hasImages ? _images[i].imagePath : store.profileImage;
              return _buildNetworkOrFallback(url);
            },
          ),
          if (itemCount > 1) _buildImageCounter(itemCount),
          if (itemCount > 1) _buildImageDots(itemCount),
        ],
      ),
    );
  }

  Widget _buildNetworkOrFallback(String url) {
    if (url.isEmpty) return _imageFallback();
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageFallback(),
    );
  }

  Widget _buildImageCounter(int itemCount) {
    return Positioned(
      top: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentImage + 1} / $itemCount',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildImageDots(int itemCount) {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (i) {
          final active = i == _currentImage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white54,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: Colors.blue[50],
      alignment: Alignment.center,
      child: Icon(Icons.store_rounded, size: 64, color: Colors.blue[200]),
    );
  }

  // ---------------- Header card ----------------

  Widget _buildHeaderCard() {
    final rating = store.avgRating.clamp(0, 5).toDouble();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  store.storeName.isNotEmpty ? store.storeName : '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.star_rounded, size: 18, color: _starColor),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                icon: Icons.circle,
                iconSize: 8,
                iconColor: _isOpen ? _successColor : _dangerColor,
                label: _isOpen ? 'เปิดร้าน' : 'ปิดชั่วคราว',
              ),
              _chip(
                icon: Icons.access_time_rounded,
                label: store.openingHours.isNotEmpty
                    ? '${store.openingHours} - ${store.closedHours}'
                    : '-',
              ),
              _chip(
                icon: Icons.local_shipping_outlined,
                label: '${store.serviceRadius.toStringAsFixed(1)} กม.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    double iconSize = 14,
    Color iconColor = _mutedTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------- Tabs ----------------

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey[500],
        indicatorColor: _primaryColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: const [
          Tab(text: 'ข้อมูลร้าน'),
          Tab(text: 'รีวิว'),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _sectionTitle('ตำแหน่งร้าน'),
        const SizedBox(height: 8),
        _buildMap(),
        const SizedBox(height: 18),
        _sectionTitle('ข้อมูลติดต่อ'),
        const SizedBox(height: 8),
        _contactRow(Icons.location_on_outlined, store.address),
        _contactRow(Icons.phone_outlined, store.phone),
        _contactRow(Icons.email_outlined, store.email, isLink: true),
        _contactRow(Icons.facebook, store.facebook, iconColor: _facebookColor),
        _contactRow(
          Icons.chat_bubble_outline,
          store.lineId,
          customIcon: const FaIcon(
            FontAwesomeIcons.line,
            size: 18,
            color: _lineColor,
          ),
        ),
        const SizedBox(height: 18),
        _sectionTitle('เกี่ยวกับร้าน'),
        const SizedBox(height: 8),
        _contactRow(
          Icons.social_distance_outlined,
          'รับส่งสูงสุด ${store.serviceRadius.toStringAsFixed(1)} กม.',
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }

  Widget _contactRow(
    IconData icon,
    String text, {
    bool isLink = false,
    Widget? customIcon,
    Color iconColor = _primaryColor,
  }) {
    final display = text.isNotEmpty ? text : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: customIcon ?? Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              display,
              style: TextStyle(
                fontSize: 13,
                color: isLink ? _primaryColor : Colors.black87,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (store.latitude == 0 && store.longitude == 0) {
      return const _MapPlaceholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 160,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(store.latitude, store.longitude),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId(store.storeId),
              position: LatLng(store.latitude, store.longitude),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          liteModeEnabled: true,
        ),
      ),
    );
  }

  // ---------------- Reviews tab ----------------

  Widget _buildReviewsTab() {
    if (_loadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'ยังไม่มีรีวิว',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _buildReviewSummaryCard(),
        const SizedBox(height: 12),
        ..._reviews.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildReviewCard(r),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSummaryCard() {
    final rating = store.avgRating.clamp(0, 5).toDouble();
    final total = store.totalReviews > 0 ? store.totalReviews : _reviews.length;

    final counts = List<int>.filled(5, 0);
    for (final r in _reviews) {
      final star = r.rating.round().clamp(1, 5);
      counts[star - 1]++;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _titleTextColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: _starColor,
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                '$total รีวิว',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = counts[star - 1];
                final ratio = total > 0 ? count / total : 0.0;
                return _buildRatingBar(star, count, ratio);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, int count, double ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 11, color: _starColor),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: _chipBgColor,
                valueColor: const AlwaysStoppedAnimation<Color>(_starColor),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 18,
            child: Text(
              '$count',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(StoreReviewItem r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFE6F4FF),
                backgroundImage: r.reviewerImage.isNotEmpty
                    ? NetworkImage(r.reviewerImage)
                    : null,
                child: r.reviewerImage.isEmpty
                    ? const Icon(Icons.person_rounded,
                        size: 18, color: _primaryColor)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reviewerName.isNotEmpty
                          ? r.reviewerName
                          : 'ผู้ใช้ไม่ระบุชื่อ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _titleTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (j) {
                        return Icon(
                          j < r.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 13,
                          color: _starColor,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (r.reviewedAt != null)
                Text(
                  '${r.reviewedAt!.day}/${r.reviewedAt!.month}/${r.reviewedAt!.year}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.comment,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- Bottom actions ----------------

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    _isApplying ? null : () => _applyAsEmployee(role: 'rider'),
                icon: const Icon(Icons.two_wheeler_rounded, color: _primaryColor),
                label: _isApplying
                    ? _buttonSpinner(_primaryColor)
                    : const Text(
                        'สมัครพนักงานไรเดอร์',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isApplying
                    ? null
                    : () => _applyAsEmployee(role: 'laundry'),
                icon: const Icon(Icons.local_laundry_service_rounded,
                    color: Colors.white),
                label: _isApplying
                    ? _buttonSpinner(Colors.white)
                    : const Text(
                        'สมัครพนักงานซักอบ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buttonSpinner(Color color) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  // ---------------- Apply as employee ----------------

  Future<void> _applyAsEmployee({required String role}) async {
    final sessionRole = await _session.getRole();
    final expectedSessionRole = role == 'rider' ? 'rider' : 'laundry_staff';

    if (sessionRole == null ||
        sessionRole.isEmpty ||
        sessionRole != expectedSessionRole) {
      _showSnack(
        title: 'แจ้งเตือน',
        message: (sessionRole == null || sessionRole.isEmpty)
            ? 'กรุณาเข้าสู่ระบบก่อนสมัคร'
            : 'บัญชีนี้ไม่สามารถสมัครเป็น${role == 'rider' ? 'ไรเดอร์' : 'พนักงานซักอบ'}ได้',
        type: _SnackType.warning,
      );
      return;
    }

    final userId = role == 'rider'
        ? await _session.getRiderId()
        : await _session.getStaffId();

    if (userId == null || userId.isEmpty) {
      _showSnack(
        title: 'แจ้งเตือน',
        message: 'ไม่พบข้อมูลบัญชี กรุณาเข้าสู่ระบบใหม่อีกครั้ง',
        type: _SnackType.warning,
      );
      return;
    }

    String apiUrl = url;
    if (apiUrl.isEmpty) {
      try {
        final config = await Configuration.getConfig();
        apiUrl = config['apiEndpoint']?.toString() ?? '';
      } catch (_) {
        // เดี๋ยว apiUrl.isEmpty ด้านล่างจะจัดการต่อ
      }
    }

    if (apiUrl.isEmpty) {
      _showSnack(
        title: 'แจ้งเตือน',
        message: 'ไม่สามารถโหลดการตั้งค่าได้',
        type: _SnackType.error,
      );
      return;
    }

    final endpoint = role == 'rider'
        ? '$apiUrl/employee_regis_store/rider/store/$userId'
        : '$apiUrl/employee_regis_store/staff/store/$userId';

    setState(() => _isApplying = true);

    try {
      final res = await GetConnect().put(endpoint, {'store_id': store.storeId});

      if (res.statusCode == 200 && res.body['ok'] == true) {
        _showSnack(
          title: 'สำเร็จ',
          message: res.body['message']?.toString() ??
              'ส่งคำขอสำเร็จ กรุณารอร้านค้ายืนยัน',
          type: _SnackType.success,
        );
      } else {
        _showSnack(
          title: 'ไม่สำเร็จ',
          message: res.body['message']?.toString() ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่',
          type: _SnackType.error,
        );
      }
    } catch (_) {
      _showSnack(
        title: 'ไม่สำเร็จ',
        message: 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
        type: _SnackType.error,
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  void _showSnack({
    required String title,
    required String message,
    required _SnackType type,
  }) {
    final colors = switch (type) {
      _SnackType.success => (bg: const Color(0xFFE8FFF0), text: const Color(0xFF1DB954)),
      _SnackType.warning => (bg: const Color(0xFFFFF7E6), text: const Color(0xFF92400E)),
      _SnackType.error => (bg: const Color(0xFFFFEBEB), text: const Color(0xFFE53935)),
    };

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: colors.bg,
      colorText: colors.text,
    );
  }
}

enum _SnackType { success, warning, error }

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        width: double.infinity,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: Icon(Icons.map_outlined, size: 40, color: Colors.grey[400]),
      ),
    );
  }
}