import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/screens/customer/pickmap.dart';
import 'package:wash_and_dry/service/address_screen.dart';
import 'package:wash_and_dry/widgets/main_shell_customer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CustomerOnboardingScreen extends StatefulWidget {
  final String customerId;
  final List<String> missingFields;
  final bool needProfile;
  final bool needAddress;
  final String? initialFullname;
  final String? initialEmail;
  final String? initialPhotoUrl;
  final String? initialPhone;
  
  const CustomerOnboardingScreen({
    super.key,
    required this.customerId,
    this.missingFields = const [],
    required this.needProfile,
    required this.needAddress,
    this.initialFullname,
    this.initialEmail,
    this.initialPhotoUrl,
    this.initialPhone,
  });

  @override
  State<CustomerOnboardingScreen> createState() =>
      _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends State<CustomerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  static const primaryBlue = Color(0xFF1279E6);
  static const lightBlue = Color(0xFFE3F2FD);

  // Controllers
  final fullnameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final emailCtl = TextEditingController();
  final birthdayCtl = TextEditingController();
  final addressNameCtl = TextEditingController(text: "บ้าน");
  final addressTextCtl = TextEditingController();

  String? selectedGender;
  File? profileImage;
  String? _networkImageUrl;
  final _picker = ImagePicker();

  bool loading = false;
  bool _configLoaded = false;
  String? error;
  String? url;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _initializeFields();
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

  void _initializeFields() {
    if (widget.initialFullname?.isNotEmpty ?? false) {
      fullnameCtl.text = widget.initialFullname!;
    }
    if (widget.initialEmail?.isNotEmpty ?? false) {
      emailCtl.text = widget.initialEmail!;
    }
    if (widget.initialPhone?.isNotEmpty ?? false) {
      phoneCtl.text = widget.initialPhone!;
    }
    if (widget.initialPhotoUrl?.isNotEmpty ?? false) {
      _networkImageUrl = widget.initialPhotoUrl!;
    }
  }

  String? _required(String? v) => (v?.trim().isEmpty ?? true) ? "จำเป็นต้องกรอก" : null;

  Future<File> _persistImage(XFile x) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(x.path).isNotEmpty ? p.extension(x.path) : ".jpg";
    final newPath = p.join(dir.path, "profile_${DateTime.now().millisecondsSinceEpoch}$ext");
    return File(x.path).copy(newPath);
  }

  Future<void> _pickImage(ImageSource source) async {
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
            const Text('เลือกรูปโปรไฟล์',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryBlue),
              title: const Text('เลือกจากแกลเลอรี่'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryBlue),
              title: const Text('ถ่ายรูปใหม่'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_configLoaded || url == null) {
      setState(() => error = "กำลังโหลดการตั้งค่า กรุณารอสักครู่");
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (widget.needProfile) await _updateCustomerProfile();
      if (widget.needAddress) await _createCustomerAddress();
      
      if (!mounted) return;
      
      _showSuccess("บันทึกข้อมูลเรียบร้อย");
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAll(() => MainShellCustomer());
    } catch (e) {
      log("Submit error: $e");
      setState(() => error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _updateCustomerProfile() async {
    if (profileImage != null) {
      await _updateProfileWithImage();
    } else {
      await _updateProfileWithoutImage();
    }
  }

  Future<void> _updateProfileWithImage() async {
    final uri = Uri.parse("$url/customer/profile/${widget.customerId}");
    final request = http.MultipartRequest('PUT', uri);

    request.fields.addAll({
      'fullname': fullnameCtl.text.trim(),
      'phone': phoneCtl.text.trim(),
      'email': emailCtl.text.trim(),
    });

    if (birthdayCtl.text.trim().isNotEmpty) {
      request.fields['birthday'] = birthdayCtl.text.trim();
    }
    if (selectedGender?.isNotEmpty ?? false) {
      request.fields['gender'] = selectedGender!;
    }

    if (!await profileImage!.exists()) {
      throw Exception("ไฟล์รูปหายไป กรุณาเลือกรูปใหม่");
    }

    request.files.add(
      await http.MultipartFile.fromPath('profile_image', profileImage!.path),
    );

    final resp = await http.Response.fromStream(await request.send());
    _handleProfileResponse(resp);
  }

  Future<void> _updateProfileWithoutImage() async {
    final body = {
      "fullname": fullnameCtl.text.trim(),
      "phone": phoneCtl.text.trim(),
      "email": emailCtl.text.trim(),
      if (birthdayCtl.text.trim().isNotEmpty) "birthday": birthdayCtl.text.trim(),
      if (selectedGender?.isNotEmpty ?? false) "gender": selectedGender,
    };

    final resp = await http.put(
      Uri.parse("$url/customer/profile/${widget.customerId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    
    _handleProfileResponse(resp);
  }

  void _handleProfileResponse(http.Response resp) {
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200 || data["ok"] != true) {
      throw Exception(data["message"] ?? "อัปเดตข้อมูลลูกค้าไม่สำเร็จ");
    }
  }

  Future<void> _createCustomerAddress() async {
    final geo = await geocodeFromAddress(addressTextCtl.text);
    
    final body = {
      "address_name": addressNameCtl.text.trim(),
      "address_text": addressTextCtl.text.trim(),
      "latitude": geo.lat.toDouble(),
      "longitude": geo.lng.toDouble(),
      "status": true,
    };

    final resp = await http.post(
      Uri.parse("$url/customer/addresses/${widget.customerId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(resp.body);
    final okStatus = resp.statusCode == 200 || resp.statusCode == 201;
    
    if (!okStatus || data["ok"] != true) {
      throw Exception(data["message"] ?? "บันทึกที่อยู่ไม่สำเร็จ");
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
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void dispose() {
    fullnameCtl.dispose();
    phoneCtl.dispose();
    emailCtl.dispose();
    birthdayCtl.dispose();
    addressNameCtl.dispose();
    addressTextCtl.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
        ],
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
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
              ? Icon(Icons.person, size: 60, color: Colors.grey[400])
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        automaticallyImplyLeading: false,
        title: const Text("กรอกข้อมูลก่อนใช้งาน"),
        centerTitle: true,
      ),
      body: !_configLoaded
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.edit_document, size: 48, color: primaryBlue),
                      const SizedBox(height: 12),
                      const Text("ยินดีต้อนรับ!",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("กรุณากรอกข้อมูลเพื่อเริ่มใช้งานระบบ",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(child: Text(error!, 
                          style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (widget.needProfile) ...[
                  _buildSectionHeader("ข้อมูลส่วนตัว", Icons.person),
                  const SizedBox(height: 20),
                  
                  _buildProfileImage(),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      profileImage == null && _networkImageUrl == null
                        ? 'แตะเพื่อเพิ่มรูปโปรไฟล์'
                        : 'แตะเพื่อเปลี่ยนรูปโปรไฟล์',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildTextField(
                    controller: fullnameCtl,
                    label: "ชื่อ-นามสกุล",
                    icon: Icons.person_outline,
                    validator: _required),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: phoneCtl,
                    label: "เบอร์โทรศัพท์",
                    icon: Icons.phone_outlined,
                    validator: _required,
                    keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: emailCtl,
                    label: "อีเมล",
                    icon: Icons.email_outlined,
                    validator: _required,
                    keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now());
                      if (picked != null) {
                        setState(() {
                          birthdayCtl.text =
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: birthdayCtl,
                        label: "วันเกิด (ไม่บังคับ)",
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.none)),
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: InputDecoration(
                      labelText: "เพศ (ไม่บังคับ)",
                      prefixIcon: const Icon(Icons.person_outline, color: primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: const [
                      DropdownMenuItem(value: "ชาย", child: Text("ชาย")),
                      DropdownMenuItem(value: "หญิง", child: Text("หญิง")),
                      DropdownMenuItem(value: "อื่นๆ", child: Text("อื่นๆ")),
                    ],
                    onChanged: (value) => setState(() => selectedGender = value),
                  ),
                  const SizedBox(height: 32),
                ],

                if (widget.needAddress) ...[
                  _buildSectionHeader("ที่อยู่สำหรับรับ-ส่ง", Icons.location_on),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: addressNameCtl,
                    label: "ชื่อที่อยู่ (เช่น บ้าน, ที่ทำงาน)",
                    icon: Icons.label_outline,
                    validator: _required),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: addressTextCtl,
                    label: "รายละเอียดที่อยู่",
                    icon: Icons.home_outlined,
                    validator: _required,
                    maxLines: 3),
                  const SizedBox(height: 32),
                ],
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
      addressTextCtl.text = result["address"];
    }
  },
),
const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white))),
                          SizedBox(width: 12),
                          Text("กำลังบันทึก...",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ])
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text("บันทึกและเริ่มใช้งาน",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}