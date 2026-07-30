import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wash_and_dry/screens/login_screen.dart';
import 'package:wash_and_dry/screens/regiser_employee_store.dart';
import 'package:wash_and_dry/service/session_service.dart';
import 'package:wash_and_dry/widgets/main_shell_customer.dart';
import 'package:wash_and_dry/widgets/main_shell_rider.dart';
import 'package:wash_and_dry/widgets/main_shell_staff.dart';
import 'package:wash_and_dry/widgets/main_shell_store.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final ss = Session();

    final role = await ss.getRole();
    final customerId = await ss.getCustomerId();
    final storeId = await ss.getStoreId();
    final riderId = await ss.getRiderId();
    final staffId = await ss.getStaffId();
    final status = await ss.getStatus();
debugPrint("role = $role");
debugPrint("riderId = $riderId");
debugPrint("storeId = $storeId");
debugPrint("status,$status");
    if (!mounted) return;

    // Customer
    if (role == "customer" &&
        customerId != null &&
        customerId.isNotEmpty) {
      Get.offAll(() => MainShellCustomer());
      return;
    }

    // Store
    if (role == "store" &&
        storeId != null &&
        storeId.isNotEmpty) {
      Get.offAll(() => MainShellStore());
      return;
    }

   if (role == "rider" &&
    riderId != null &&
    riderId.isNotEmpty) {
  final approved = status == 'ONLINE' || status == 'TEMP_CLOSED';
  if (storeId == null || storeId.isEmpty || !approved) {
    Get.offAll(() => const RegiserEmployeeStore());
  } else {
    Get.offAll(() => MainShellRider());
  }
  return;
}

// Laundry Staff
if (role == "laundry_staff" &&
    staffId != null &&
    staffId.isNotEmpty) {
  final approved = status == 'ONLINE' || status == 'TEMP_CLOSED';
  if (storeId == null || storeId.isEmpty || !approved) {
    Get.offAll(() => const RegiserEmployeeStore());
  } else {
    Get.offAll(() => MainShellStaff());
  }
  return;
}

    // ยังไม่ได้ Login
    Get.offAll(() => const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}