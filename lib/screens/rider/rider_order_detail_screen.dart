import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/res/customer/rider/res_order_detail_rider.dart';
import 'package:wash_and_dry/service/address_service.dart';


class RiderOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const RiderOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<RiderOrderDetailScreen> createState() => _RiderOrderDetailScreenState();
}

class _RiderOrderDetailScreenState extends State<RiderOrderDetailScreen> {
  String url = '';
  bool isLoading = true;
  String? error;
GoogleMapController? _mapController;
  OrderDetailResponse? orderDetailResponse;
  OrderDetailData? order;
Position? currentRiderPosition;
  @override
  void initState() {
    super.initState();
    loadConfigAndFetch();
  }
Future<void> getCurrentLocation() async {
  final position = await getCurrentLocationData();

  if (!mounted) return;

  setState(() {
    currentRiderPosition = position;
  });
}
  Future<void> loadConfigAndFetch() async {
    try {
      final config = await Configuration.getConfig();
      url = config['apiEndpoint']?.toString() ?? '';

      if (url.isEmpty) {
        setState(() {
          error = 'ไม่พบ apiEndpoint';
          isLoading = false;
        });
        return;
      }

      await fetchOrderDetail();
    } catch (e) {
      setState(() {
        error = 'โหลด config ไม่สำเร็จ: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchOrderDetail() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final uri = Uri.parse('$url/order/rider/detail/${widget.orderId}');
      final response = await http.get(uri);

      final parsed = orderDetailResponseFromJson(response.body);

      if (response.statusCode != 200 || parsed.ok != true) {
        setState(() {
          error = parsed.message ?? 'เกิดข้อผิดพลาด';
          isLoading = false;
        });
        return;
      }

      setState(() {
        orderDetailResponse = parsed;
        order = parsed.data;
        isLoading = false;
      });
      await getCurrentLocation();
    } catch (e) {
      setState(() {
        error = 'ดึงข้อมูลไม่สำเร็จ: $e';
        isLoading = false;
      });
    }
  }

  String formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('d MMM yyyy เวลา HH:mm น.', 'th').format(dt);
  }

  Widget buildCard(IconData icon, String title, Widget child) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF29ABE2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF29ABE2)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPersonCard(
    IconData icon,
    String role,
    String? fullname,
    String? phone,
    String? profileImage, {
    String? licensePlate,
    String? vehicleType,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFE3F4FC),
          backgroundImage:
              profileImage != null && profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
          child: profileImage == null || profileImage.isEmpty
              ? Icon(icon, color: const Color(0xFF29ABE2), size: 22)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF29ABE2),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                fullname ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.phone_rounded,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    phone ?? '-',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              if (vehicleType != null && vehicleType.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'ประเภทรถ: $vehicleType',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              if (licensePlate != null && licensePlate.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'ทะเบียน: $licensePlate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget buildImageBox(String? url, String label) {
    final hasImage = url != null && url.isNotEmpty;

    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: hasImage
                ? () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url, fit: BoxFit.contain),
                        ),
                      ),
                    );
                  }
                : null,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: Colors.grey.shade400, size: 30),
                          const SizedBox(height: 4),
                          Text(
                            'ยังไม่มีรูป',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

Widget buildMapCard() {
  final customerLat = order?.address?.latitude;
  final customerLng = order?.address?.longitude;
  final riderLat = currentRiderPosition?.latitude;
  final riderLng = currentRiderPosition?.longitude;

  if (customerLat == null || customerLng == null) {
    return buildCard(
      Icons.map_rounded,
      'ตำแหน่งลูกค้าและไรเดอร์',
      const Text(
        'ไม่มีพิกัดลูกค้า',
        style: TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }

  final customerPosition = LatLng(customerLat, customerLng);
  final riderPosition = (riderLat != null && riderLng != null)
      ? LatLng(riderLat, riderLng)
      : null;

  final initialTarget = riderPosition != null
      ? LatLng(
          (customerPosition.latitude + riderPosition.latitude) / 2,
          (customerPosition.longitude + riderPosition.longitude) / 2,
        )
      : customerPosition;

  final markers = <Marker>{
    Marker(
      markerId: const MarkerId('customer_location'),
      position: customerPosition,
      infoWindow: const InfoWindow(
        title: 'ลูกค้า',
        snippet: 'ตำแหน่งลูกค้า',
      ),
    ),
    if (riderPosition != null)
      Marker(
        markerId: const MarkerId('rider_current_location'),
        position: riderPosition,
        infoWindow: const InfoWindow(
          title: 'ไรเดอร์',
          snippet: 'ตำแหน่งปัจจุบันของไรเดอร์',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
  };

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _fitMapToBounds(customerPosition, riderPosition);
  });

  return buildCard(
    Icons.map_rounded,
    'ตำแหน่งลูกค้าและไรเดอร์',
    SizedBox(
      height: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 13,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            _fitMapToBounds(customerPosition, riderPosition);
          },
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapToolbarEnabled: false,
          liteModeEnabled: true,
          compassEnabled: false,
          buildingsEnabled: false,
          trafficEnabled: false,
          indoorViewEnabled: false,
          myLocationEnabled: false,
        ),
      ),
    ),
  );
}

void _fitMapToBounds(LatLng customerPosition, LatLng? riderPosition) {
  if (_mapController == null) return;

  if (riderPosition == null) {
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: customerPosition,
          zoom: 15,
        ),
      ),
    );
    return;
  }

  double southLat = customerPosition.latitude < riderPosition.latitude
      ? customerPosition.latitude
      : riderPosition.latitude;

  double northLat = customerPosition.latitude > riderPosition.latitude
      ? customerPosition.latitude
      : riderPosition.latitude;

  double westLng = customerPosition.longitude < riderPosition.longitude
      ? customerPosition.longitude
      : riderPosition.longitude;

  double eastLng = customerPosition.longitude > riderPosition.longitude
      ? customerPosition.longitude
      : riderPosition.longitude;

  double latDiff = northLat - southLat;
  double lngDiff = eastLng - westLng;

  if (latDiff < 0.002) {
    southLat -= 0.001;
    northLat += 0.001;
  } else {
    southLat -= latDiff * 0.25;
    northLat += latDiff * 0.25;
  }

  if (lngDiff < 0.002) {
    westLng -= 0.001;
    eastLng += 0.001;
  } else {
    westLng -= lngDiff * 0.25;
    eastLng += lngDiff * 0.25;
  }

  final bounds = LatLngBounds(
    southwest: LatLng(southLat, westLng),
    northeast: LatLng(northLat, eastLng),
  );

  Future.delayed(const Duration(milliseconds: 300), () {
    if (!mounted || _mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  });
}
  @override
  Widget build(BuildContext context) {
    final o = order;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'รายละเอียดออเดอร์',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF29ABE2)),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: fetchOrderDetail,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : o == null
                  ? const Center(child: Text('ไม่พบข้อมูลออเดอร์'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
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
                                  color: const Color(0xFF29ABE2).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'หมายเลขออเดอร์',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '#${(o.orderId ?? widget.orderId).toUpperCase().substring(0, (o.orderId ?? widget.orderId).length.clamp(0, 8))}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatDate(o.orderDatetime),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (o.customer != null || o.address != null)
                            buildCard(
                              Icons.person_rounded,
                              'ข้อมูลลูกค้า',
                              Column(
                                children: [
                                  if (o.customer != null) ...[
                                    buildRow('ชื่อ', o.customer?.fullname ?? '-'),
                                    buildRow('เบอร์โทร', o.customer?.phone ?? '-'),
                                  ],
                                  if (o.address != null)
                                    buildRow(
                                      'ที่อยู่',
                                      o.address?.addressText ?? '-',
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),

                          buildMapCard(),
                          const SizedBox(height: 12),

                          buildCard(
                            Icons.local_laundry_service_rounded,
                            'รายละเอียดบริการ',
                            Column(
                              children: [
                                buildRow(
                                  'รูปแบบบริการ',
                                  o.serviceType == 'wash_dry'
                                      ? 'ซักและอบ'
                                      : o.serviceType == 'wash'
                                          ? 'ซักอย่างเดียว'
                                          : o.serviceType == 'dry'
                                              ? 'อบอย่างเดียว'
                                              : '-',
                                ),
                                buildRow(
                                  'น้ำหนักผ้า',
                                  o.washDryWeight != null
                                      ? '${o.washDryWeight} กิโลกรัม'
                                      : '-',
                                  valueColor: const Color(0xFF29ABE2),
                                ),
                                buildRow(
                                  'น้ำยาซัก',
                                  o.detergentOption == 'detergent'
                                      ? 'ใช้น้ำยาซักผ้าของร้าน'
                                      : o.detergentOption == 'no_detergent'
                                          ? 'ไม่ใช้น้ำยาซัก'
                                          : '-',
                                ),
                                buildRow('หมายเหตุ', o.note ?? '-'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          buildCard(
                            Icons.receipt_long_rounded,
                            'รายละเอียดราคา',
                            Column(
                              children: [
                                buildRow(
                                  'ค่าซัก',
                                  '${(o.servicePrice ?? 0).toString()} ฿',
                                ),
                                buildRow(
                                  'ค่าจัดส่ง',
                                  '${(o.deliveryPrice ?? 0).toString()} ฿',
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(
                                    height: 1,
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ราคารวมทั้งหมด',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${(o.servicePrice ?? 0) + (o.deliveryPrice ?? 0)} ฿',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF29ABE2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (o.riderPickup != null ||
                              o.staff != null ||
                              o.riderDelivery != null)
                            buildCard(
                              Icons.people_rounded,
                              'ผู้รับผิดชอบ',
                              Column(
                                children: [
                                  if (o.riderPickup != null)
                                    buildPersonCard(
                                      Icons.directions_bike_rounded,
                                      'ไรเดอร์รับผ้า',
                                      o.riderPickup?.fullname,
                                      o.riderPickup?.phone,
                                      o.riderPickup?.profileImage,
                                      licensePlate: o.riderPickup?.licensePlate,
                                      vehicleType: o.riderPickup?.vehicleType,
                                    ),
                                  if (o.staff != null) ...[
                                    if (o.riderPickup != null)
                                      const Divider(
                                        height: 20,
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    buildPersonCard(
                                      Icons.local_laundry_service_rounded,
                                      'พนักงานซัก',
                                      o.staff?.fullname,
                                      o.staff?.phone,
                                      o.staff?.profileImage,
                                    ),
                                  ],
                                  if (o.riderDelivery != null) ...[
                                    const Divider(
                                      height: 20,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    buildPersonCard(
                                      Icons.delivery_dining_rounded,
                                      'ไรเดอร์ส่งผ้า',
                                      o.riderDelivery?.fullname,
                                      o.riderDelivery?.phone,
                                      o.riderDelivery?.profileImage,
                                      licensePlate:
                                          o.riderDelivery?.licensePlate,
                                      vehicleType: o.riderDelivery?.vehicleType,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),

                          buildCard(
                            Icons.photo_library_rounded,
                            'รูปภาพจากร้านค้า',
                            Row(
                              children: [
                                buildImageBox(o.beforeWashImage, 'ก่อนซัก'),
                                const SizedBox(width: 12),
                                buildImageBox(o.afterWashImage, 'หลังซัก'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}