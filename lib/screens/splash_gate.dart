import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wash_and_dry/service/session_service.dart';

import 'package:wash_and_dry/screens/login_screen.dart';

import 'package:wash_and_dry/widgets/main_shell_customer.dart';
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

    
    final loggedInCustomer =
        role == "customer" && (customerId != null && customerId.isNotEmpty);

    final loggedInStore =
        role == "store" && (storeId != null && storeId.isNotEmpty);

    if (!mounted) return;


    if (loggedInCustomer) {
      Get.offAll(() => MainShellCustomer());
      return;
    }
     if (loggedInStore) {
      Get.offAll(() => MainShellStore());
      return;
    }

    Get.offAll(() => const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
