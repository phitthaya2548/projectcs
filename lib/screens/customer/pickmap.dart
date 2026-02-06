import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPicker extends StatefulWidget {
  const MapPicker({super.key});

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? mapController;
  LatLng selected = const LatLng(13.736717, 100.523186); // กรุงเทพ default
  String address = "";

  Future<void> _updateAddress(LatLng pos) async {
    final placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);

    final p = placemarks.first;

    setState(() {
      address =
        "${p.name ?? ''} "
        "${p.street ?? ''} "
        "ต.${p.subLocality ?? ''} "
        "อ.${p.locality ?? ''} "
        "จ.${p.administrativeArea ?? ''} "
        "${p.postalCode ?? ''}";
    });
  }

  @override
  void initState() {
    super.initState();
    _updateAddress(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เลือกตำแหน่ง"),
      ),
      body: Stack(
        children: [
          GoogleMap(
  initialCameraPosition: CameraPosition(
    target: selected,
    zoom: 16,
  ),
  onMapCreated: (c) => mapController = c,
 onTap: (LatLng pos) {
    setState(() {
      selected = pos;
    });
    _updateAddress(pos);
  },
  onCameraMove: (pos) {
    selected = pos.target;
  },
  onCameraIdle: () {
    _updateAddress(selected);
  },
markers: {
    Marker(
      markerId: const MarkerId("selected"),
      position: selected,
    ),
  },

  /// 👇 เพิ่มส่วนนี้
  zoomGesturesEnabled: true,
  scrollGesturesEnabled: true,
  tiltGesturesEnabled: true,
  rotateGesturesEnabled: true,
  zoomControlsEnabled: true, // ปุ่ม + -
compassEnabled: true,
mapToolbarEnabled: false,

  myLocationEnabled: true,
  myLocationButtonEnabled: true,
   

),

          /// หมุดกลางจอแบบ Grab
         
          /// กล่องที่อยู่
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(address),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        "lat": selected.latitude,
                        "lng": selected.longitude,
                        "address": address
                      });
                    },
                    child: const Text("เลือกที่อยู่นี้"),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
