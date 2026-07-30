import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

Future<({double lat, double lng})> geocodeFromAddress(String addressText) async {
  final address = addressText.trim();
  if (address.isEmpty) {
    throw Exception("กรุณากรอกที่อยู่ก่อน");
  }

  log(" [GEOCODE] input='$address'");

  try {
    final locations = await locationFromAddress(address);

    log("[GEOCODE] locations=${locations.length}");
    if (locations.isNotEmpty) {
      log(" [GEOCODE] first=${locations.first.latitude}, ${locations.first.longitude}");
    }

    if (locations.isEmpty) {
      throw Exception("ไม่พบพิกัดจากที่อยู่ที่กรอก กรุณาเพิ่มรายละเอียดให้ชัดเจน");
    }

    final loc = locations.first;
    return (lat: loc.latitude, lng: loc.longitude);
  } on MissingPluginException catch (_) {

    throw Exception(
    
    );
  } catch (e) {
    throw Exception("แปลงที่อยู่เป็นพิกัดไม่สำเร็จ: $e");
  }
}
Future<String> addressFromLatLngThai(double lat, double lng) async {
  log("[REVERSE] lat=$lat lng=$lng");

  try {
    final placemarks = await placemarkFromCoordinates(
      lat,
      lng,
    );

    if (placemarks.isEmpty) {
      throw Exception("ไม่พบข้อมูลที่อยู่");
    }

    final p = placemarks.first;

    final address =
        "${p.name ?? ''} "
        "${p.street ?? ''} "
        "ต.${p.subLocality ?? ''} "
        "อ.${p.locality ?? ''} "
        "จ.${p.administrativeArea ?? ''} "
        "${p.postalCode ?? ''}";

    log("address=$address");

    return address.trim();

  } on MissingPluginException {
    throw Exception("ฟีเจอร์นี้ไม่รองรับบนแพลตฟอร์มนี้");
  } catch (e) {
    throw Exception("แปลงพิกัดเป็นที่อยู่ไม่สำเร็จ: $e");
  }
  
}
Future<Position?> getCurrentLocationData() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return position;
  } catch (e) {
    log("getCurrentLocationData error: $e");
    return null;
  }
}