import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wash_and_dry/screens/pickaddress_frommap.dart';
import 'package:wash_and_dry/service/address_service.dart';
import 'package:wash_and_dry/widgets/main_shell_store.dart';

class StoreOnboardingScreen extends StatefulWidget {
  final String storeId;
  
  const StoreOnboardingScreen({
    super.key,
    required this.storeId,
  });

  @override
  State<StoreOnboardingScreen> createState() => _StoreOnboardingScreenState();
}

class _StoreOnboardingScreenState extends State<StoreOnboardingScreen> {
  static const primaryBlue = Color(0xFF1279E6);
  static const lightBlue = Color(0xFFE3F2FD);
  static const darkBlue = Color(0xFF0D47A1);
  static const successGreen = Color(0xFF4CAF50);

  int _currentStep = 0;
  final _pageController = PageController();
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());

  // Controllers
  final storeNameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final emailCtl = TextEditingController();
  final addressCtl = TextEditingController();
  final serviceRadiusCtl = TextEditingController(text: "5");
  final openingHoursCtl = TextEditingController(text: "08:00");
  final closedHoursCtl = TextEditingController(text: "18:00");
  final facebookCtl = TextEditingController();
  final lineIdCtl = TextEditingController();

  // Images
  File? profileImage;
  String? _networkImageUrl;
  List<File> storeImages = [];
  final _picker = ImagePicker();

  bool loading = false;
  bool _configLoaded = false;
  String? error;
  String? url;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() {
        url = config['apiEndpoint'];
        _configLoaded = true;
      });
    } catch (e) {
      log("Config error: $e");
      setState(() {
        error = "ไม่สามารถโหลดการตั้งค่าได้";
        _configLoaded = false;
      });
    }
  }

  // Validators
  String? _required(String? v) => (v?.trim().isEmpty ?? true) ? "จำเป็นต้องกรอก" : null;
  
  String? _emailValidator(String? v) {
    if (v?.trim().isEmpty ?? true) return "จำเป็นต้องกรอกอีเมล";
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!)) {
      return "รูปแบบอีเมลไม่ถูกต้อง";
    }
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v?.trim().isEmpty ?? true) return "จำเป็นต้องกรอกเบอร์โทร";
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(v!)) {
      return "เบอร์โทรไม่ถูกต้อง (0XXXXXXXXX)";
    }
    return null;
  }

  String? _numberValidator(String? v) {
    if (v?.trim().isEmpty ?? true) return "จำเป็นต้องกรอก";
    if (double.tryParse(v!) == null) return "กรุณากรอกตัวเลข";
    return null;
  }

  Future<File> _persistImage(XFile x) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(x.path).isNotEmpty ? p.extension(x.path) : ".jpg";
    final newPath = p.join(dir.path, "img_${DateTime.now().millisecondsSinceEpoch}$ext");
    return File(x.path).copy(newPath);
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (picked == null) return;
      
      final saved = await _persistImage(picked);
      setState(() {
        profileImage = saved;
        _networkImageUrl = null;
      });
    } catch (e) {
      _showError("ไม่สามารถเลือกรูปภาพได้");
    }
  }

  Future<void> _pickStoreImages() async {
    try {
      final remainingSlots = 5 - storeImages.length;
      if (remainingSlots <= 0) {
        _showError("คุณมีรูปครบ 5 รูปแล้ว");
        return;
      }

      final picked = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (picked.isEmpty) return;

      if (picked.length > remainingSlots) {
        _showError("คุณสามารถเพิ่มได้อีก $remainingSlots รูปเท่านั้น");
        return;
      }

      final savedFiles = <File>[];
      for (final xFile in picked) {
        savedFiles.add(await _persistImage(xFile));
      }

      setState(() => storeImages.addAll(savedFiles));
      _showSuccess("เพิ่มรูป ${picked.length} รูปแล้ว");
    } catch (e) {
      _showError("ไม่สามารถเลือกรูปภาพได้");
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เลือกรูปโปรไฟล์ร้าน', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryBlue),
              title: const Text('เลือกจากแกลเลอรี่'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryBlue),
              title: const Text('ถ่ายรูปใหม่'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            if (profileImage != null || _networkImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('ลบรูปภาพ', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    profileImage = null;
                    _networkImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (!(_formKeys[_currentStep].currentState?.validate() ?? false)) return;

    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
    } else {
      _submitAllData();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
    }
  }

  Future<void> _submitAllData() async {
    if (!_configLoaded || url == null) {
      setState(() => error = "กำลังโหลดการตั้งค่า กรุณารอสักครู่");
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await _updateStoreProfile();
      
      if (storeImages.isNotEmpty) {
        await _uploadStoreImages();
      }
      
      if (!mounted) return;
      _showSuccess("บันทึกข้อมูลร้านค้าเรียบร้อย");
      
 
      Get.offAll(() => MainShellStore());
    } catch (e) {
      log("Submit error: $e");
      setState(() => error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _uploadStoreImages() async {
    final uri = Uri.parse("$url/store/images/${widget.storeId}");
    final request = http.MultipartRequest('POST', uri);

    for (final file in storeImages) {
      if (await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('store_images', file.path));
      }
    }

    if (request.files.isEmpty) return;

    final resp = await http.Response.fromStream(await request.send());
    final data = jsonDecode(resp.body);

    if (resp.statusCode != 200 || data["ok"] != true) {
      throw Exception(data["message"] ?? "อัปโหลดรูปโฆษณาไม่สำเร็จ");
    }
  }

  Future<void> _updateStoreProfile() async {
    if (profileImage != null) {
      await _updateProfileWithImage();
    } else {
      await _updateProfileWithoutImage();
    }
  }

  Future<void> _updateProfileWithImage() async {
    final uri = Uri.parse("$url/store/profile/${widget.storeId}");
    final request = http.MultipartRequest('PUT', uri);
    final geo = await geocodeFromAddress(addressCtl.text.trim());
    
    request.fields.addAll({
      'store_name': storeNameCtl.text.trim(),
      'phone': phoneCtl.text.trim(),
      'email': emailCtl.text.trim(),
      'address': addressCtl.text.trim(),
      'latitude': geo.lat.toString(),
      'longitude': geo.lng.toString(),
      'service_radius': serviceRadiusCtl.text.trim(),
      'opening_hours': openingHoursCtl.text.trim(),
      'closed_hours': closedHoursCtl.text.trim(),
    });

    if (facebookCtl.text.trim().isNotEmpty) {
      request.fields['facebook'] = facebookCtl.text.trim();
    }
    if (lineIdCtl.text.trim().isNotEmpty) {
      request.fields['line_id'] = lineIdCtl.text.trim();
    }

    if (!await profileImage!.exists()) {
      throw Exception("ไฟล์รูปหายไป กรุณาเลือกรูปใหม่");
    }

    request.files.add(await http.MultipartFile.fromPath('profile_image', profileImage!.path));

    final resp = await http.Response.fromStream(await request.send());
    _handleProfileResponse(resp);
  }

  Future<void> _updateProfileWithoutImage() async {
    final geo = await geocodeFromAddress(addressCtl.text.trim());
    
    final body = {
      "store_name": storeNameCtl.text.trim(),
      "phone": phoneCtl.text.trim(),
      "email": emailCtl.text.trim(),
      "address": addressCtl.text.trim(),
      "latitude": geo.lat,
      "longitude": geo.lng,
      "service_radius": double.parse(serviceRadiusCtl.text.trim()),
      "opening_hours": openingHoursCtl.text.trim(),
      "closed_hours": closedHoursCtl.text.trim(),
      if (facebookCtl.text.trim().isNotEmpty) "facebook": facebookCtl.text.trim(),
      if (lineIdCtl.text.trim().isNotEmpty) "line_id": lineIdCtl.text.trim(),
    };

    final resp = await http.put(
      Uri.parse("$url/store/profile/${widget.storeId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    
    _handleProfileResponse(resp);
  }

  void _handleProfileResponse(http.Response resp) {
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200 || data["ok"] != true) {
      throw Exception(data["message"] ?? "อัปเดตข้อมูลร้านค้าไม่สำเร็จ");
    }
  }

  void _showError(String message) {
    Get.snackbar("ข้อผิดพลาด", message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String message) {
    Get.snackbar("สำเร็จ", message,
      backgroundColor: successGreen,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void dispose() {
    _pageController.dispose();
    storeNameCtl.dispose();
    phoneCtl.dispose();
    emailCtl.dispose();
    addressCtl.dispose();
    serviceRadiusCtl.dispose();
    openingHoursCtl.dispose();
    closedHoursCtl.dispose();
    facebookCtl.dispose();
    lineIdCtl.dispose();
    super.dispose();
  }

  String _getStepTitle(int index) {
    const titles = ["ข้อมูลร้าน", "ที่อยู่", "เวลาทำการ", "ติดต่อ", "รูปโฆษณา"];
    return titles[index];
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: List.generate(5, (i) {
          final active = i == _currentStep;
          final completed = i < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: completed ? successGreen : 
                          (active ? primaryBlue : Colors.grey[300]),
                        child: completed 
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text("${i + 1}", 
                              style: TextStyle(
                                color: active ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Text(_getStepTitle(i),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: active ? primaryBlue : Colors.grey[600],
                          fontWeight: active ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
                if (i < 4)
                  Container(
                    height: 2,
                    width: 20,
                    color: completed ? successGreen : Colors.grey[300],
                    margin: const EdgeInsets.only(bottom: 30)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: profileImage != null ? FileImage(profileImage!)
              : (_networkImageUrl != null ? CachedNetworkImageProvider(_networkImageUrl!) : null),
            child: profileImage == null && _networkImageUrl == null
              ? Icon(Icons.store, size: 60, color: Colors.grey[400])
              : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: primaryBlue,
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeys[0],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("ข้อมูลพื้นฐานของร้าน",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildProfileImage(),
          const SizedBox(height: 8),
          const Center(child: Text('แตะเพื่อเพิ่มโลโก้ร้าน', 
            style: TextStyle(fontSize: 12, color: Colors.grey))),
          const SizedBox(height: 32),
          _buildTextField(
            controller: storeNameCtl,
            label: "ชื่อร้านค้า *",
            icon: Icons.store,
            hint: "เช่น ร้านซักรีดดีไซน์",
            validator: _required),
          const SizedBox(height: 16),
          _buildTextField(
            controller: phoneCtl,
            label: "เบอร์โทรศัพท์ *",
            icon: Icons.phone,
            hint: "0812345678",
            validator: _phoneValidator,
            keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(
            controller: emailCtl,
            label: "อีเมล *",
            icon: Icons.email,
            hint: "store@example.com",
            validator: _emailValidator,
            keyboardType: TextInputType.emailAddress),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeys[1],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("ที่อยู่และพื้นที่บริการ",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildTextField(
            controller: addressCtl,
            label: "ที่อยู่ร้าน *",
            icon: Icons.location_on,
            hint: "ที่อยู่ร้าน",
            validator: _required,
            maxLines: 3),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
TextButton.icon(
  icon: Icon(Icons.map),
  label: Text("เลือกจากแผนที่"),
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPicker()),
    );

    if (result != null) {
      addressCtl.text = result["address"];
    }
  },
),
const SizedBox(height: 8),
          _buildTextField(
            controller: serviceRadiusCtl,
            label: "รัศมีให้บริการ (กม.) *",
            icon: Icons.delivery_dining,


            hint: "5",
            validator: _numberValidator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _formKeys[2],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("เวลาทำการของร้าน",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now());
              if (picked != null) {
                setState(() {
                  openingHoursCtl.text = 
                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                });
              }
            },
            child: AbsorbPointer(
              child: _buildTextField(
                controller: openingHoursCtl,
                label: "เวลาเปิดร้าน *",
                icon: Icons.access_time,
                validator: _required)),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now());
              if (picked != null) {
                setState(() {
                  closedHoursCtl.text = 
                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                });
              }
            },
            child: AbsorbPointer(
              child: _buildTextField(
                controller: closedHoursCtl,
                label: "เวลาปิดร้าน *",
                icon: Icons.access_time_filled,
                validator: _required)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return Form(
      key: _formKeys[3],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("ช่องทางติดต่ออื่นๆ",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text("ไม่บังคับ", style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildTextField(
            controller: facebookCtl,
            label: "Facebook",
            icon: Icons.facebook,
            hint: "facebook.com/yourpage",
            keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          _buildTextField(
            controller: lineIdCtl,
            label: "Line ID",
            icon: Icons.chat,
            hint: "@yourlineid"),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    final totalImages = storeImages.length;
    final canAdd = totalImages < 5;

    return Form(
      key: _formKeys[4],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("รูปโฆษณาร้าน",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text("สูงสุด 5 รูป (ไม่บังคับ)", 
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(8)),
            child: Text("$totalImages / 5 รูป",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryBlue)),
          ),
          const SizedBox(height: 24),
          if (canAdd)
            ElevatedButton.icon(
              onPressed: _pickStoreImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text("เลือกรูปโฆษณา"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16))),
          if (storeImages.isNotEmpty) ...[
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
              itemCount: storeImages.length,
              itemBuilder: (context, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(storeImages[i], fit: BoxFit.cover,
                      width: double.infinity, height: double.infinity)),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => storeImages.removeAt(i)),
                      child: const CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, color: Colors.white, size: 16)))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        title: const Text("ตั้งค่าร้านค้า"),
        centerTitle: true),
      body: !_configLoaded
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildStepIndicator(),
              if (error != null)
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(error!, style: const TextStyle(color: Colors.red))),
                    ])),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                    _buildStep5(),
                  ])),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5))]),
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading ? null : _previousStep,
                          child: const Text("ย้อนกลับ"))),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: loading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : Text(_currentStep < 4 ? "ถัดไป" : "บันทึก"))),
                  ])),
            ]),
    );
  }
}