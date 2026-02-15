import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPicker extends StatefulWidget {
  final LatLng? initialPosition;

  const MapPicker({super.key, this.initialPosition});

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? mapController;

  LatLng? selected;
  String address = "";

  bool isLoadingAddress = false;
  bool isLoadingLocation = false;
  bool isSearching = false;

  final searchController = TextEditingController();

  Timer? _debounce;

  /// 🔑 ใส่ API KEY ตรงนี้
  static const apiKey = "AIzaSyCCUAtzXWXOy0CLq6pw0iDBuUdy17RAzFg";

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // ================== LOCATION INIT ==================

  Future<void> _initializeLocation() async {
    if (widget.initialPosition != null) {
      selected = widget.initialPosition;
      await _updateAddress(selected!);
      setState(() {});
      return;
    }

    setState(() => isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      selected = LatLng(pos.latitude, pos.longitude);

      await _updateAddress(selected!);
    } catch (e) {
      _setDefaultLocation();
    }

    setState(() => isLoadingLocation = false);
  }

  void _setDefaultLocation() async {
    selected = const LatLng(13.736717, 100.523186); // BKK
    await _updateAddress(selected!);
    setState(() => isLoadingLocation = false);
  }

  // ================== REVERSE GEOCODE ==================

  Future<void> _updateAddress(LatLng pos) async {
    setState(() => isLoadingAddress = true);

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json"
        "?latlng=${pos.latitude},${pos.longitude}"
        "&language=th"
        "&key=$apiKey",
      );

      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['status'] == "OK") {
        address = data['results'][0]['formatted_address'];
      } else {
        address = "ไม่พบที่อยู่";
      }
    } catch (e) {
      address = "ผิดพลาด";
    }

    if (mounted) {
      setState(() => isLoadingAddress = false);
    }
  }

  // ================== SEARCH ==================

  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => isSearching = true);
    FocusScope.of(context).unfocus();

    try {
      final endpoint = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(query)}'
        '&location=${selected?.latitude},${selected?.longitude}'
        '&radius=50000'
        '&language=th'
        '&region=th'
        '&key=$apiKey',
      );

      final res = await http.get(endpoint);
      final json = jsonDecode(res.body);

      if (json['status'] != "OK") {
        _showError("ไม่พบสถานที่");
        return;
      }

      final first = json['results'][0];
      final loc = first['geometry']['location'];

      final target = LatLng(loc['lat'], loc['lng']);

      selected = target;
      setState(() {});

      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 16),
      );

      await _updateAddress(target);
    } catch (e) {
      _showError("ค้นหาไม่สำเร็จ");
    }

    setState(() => isSearching = false);
  }

  // ================== HELPERS ==================

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    if (selected == null || isLoadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("เลือกตำแหน่ง", style: TextStyle(color: Colors.white)),
      flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: selected!, zoom: 16),
            onMapCreated: (c) => mapController = c,

            onTap: (pos) {
              selected = pos;
              setState(() {});
              _updateAddress(pos);
            },

            onCameraMove: (pos) => selected = pos.target,

            
            onCameraIdle: () {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 200),
                () => _updateAddress(selected!),
              );
            },

            markers: {
              Marker(
                markerId: const MarkerId("pin"),
                position: selected!,
              ),
            },

            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),

          _buildSearchBar(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  // ================== SEARCH BAR ==================

  Widget _buildSearchBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: TextField(
          controller: searchController,
          onSubmitted: searchLocation,
          decoration: InputDecoration(
            hintText: "ค้นหาสถานที่",
            prefixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ),
    );
  }

  // ================== BOTTOM SHEET ==================

  Widget _buildBottomSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: isLoadingAddress
                      ? const Text("กำลังโหลด...")
                      : Text(address),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  "lat": selected!.latitude,
                  "lng": selected!.longitude,
                  "address": address,
                });
              },
              child: const Text("เลือกที่อยู่นี้"),
            ),
          ],
        ),
      ),
    );
  }
}
