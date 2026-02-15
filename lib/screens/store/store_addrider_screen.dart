import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/service/session_service.dart';

class AddRiderScreen extends StatefulWidget {
  const AddRiderScreen({Key? key}) : super(key: key);

  @override
  State<AddRiderScreen> createState() => _AddRiderScreenState();
}

class _AddRiderScreenState extends State<AddRiderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _controllers = {
    'email': TextEditingController(),
    'username': TextEditingController(),
    'password': TextEditingController(),
    'confirmPassword': TextEditingController(),
    'fullName': TextEditingController(),
    'phone': TextEditingController(),
    'licensePlate': TextEditingController(),
  };

  File? _profileImage;
  String _vehicleType = 'มอเตอร์ไซค์';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String url = '';

  final _vehicleTypes = const ['มอเตอร์ไซค์', 'รถยนต์', 'จักรยานยนต์'];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() => url = config['apiEndpoint']?.toString() ?? '');
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) setState(() => _profileImage = File(image.path));
    } catch (e) {
      _showSnackbar('ข้อผิดพลาด', 'ไม่สามารถเลือกรูปภาพได้', false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_controllers['password']!.text !=
        _controllers['confirmPassword']!.text) {
      _showSnackbar('ข้อผิดพลาด', 'รหัสผ่านไม่ตรงกัน', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = Session();
      final storeId = await session.getStoreId();

      if (storeId == null) {
        _showSnackbar('ข้อผิดพลาด', 'ไม่พบข้อมูล Store ID', false);
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/rider/register'),
      );

      request.fields.addAll({
        'store_id': storeId.toString(),
        'email': _controllers['email']!.text.trim(),
        'username': _controllers['username']!.text.trim(),
        'password': _controllers['password']!.text,
        'full_name': _controllers['fullName']!.text.trim(),
        'phone': _controllers['phone']!.text.trim(),
        'vehicle_type': _vehicleType,
        'license_plate': _controllers['licensePlate']!.text.trim(),
      });

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _profileImage!.path,
          ),
        );
      }

      final response = await http.Response.fromStream(await request.send());
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        Get.back();
        _showSnackbar('สำเร็จ', data['message'] ?? 'เพิ่ม Rider สำเร็จ', true);
      } else {
        _showSnackbar('ข้อผิดพลาด', data['message'] ?? 'เกิดข้อผิดพลาด', false);
      }
    } catch (e) {
      _showSnackbar('ข้อผิดพลาด', 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String title, String message, bool isSuccess) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isSuccess
          ? const Color(0xFF34C759)
          : const Color(0xFFFF3B30),
      colorText: Colors.white,
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
         flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
          ),
        ),
      ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เพิ่มพนักงานจัดส่ง',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildField(
              'ชื่อผู้ใช้',
              _controllers['username']!,
              'กรอกชื่อผู้ใช้',
              Icons.person_outline,
              validator: (v) => v!.trim().isEmpty
                  ? 'กรุณากรอกชื่อผู้ใช้'
                  : v.length < 3
                  ? 'ต้องมีอย่างน้อย 3 ตัวอักษร'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              'ชื่อ-นามสกุล',
              _controllers['fullName']!,
              'กรอกชื่อ-นามสกุล',
              Icons.badge_outlined,
              validator: (v) =>
                  v!.trim().isEmpty ? 'กรุณากรอกชื่อ-นามสกุล' : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              'อีเมล',
              _controllers['email']!,
              'กรอกอีเมล',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.trim().isEmpty
                  ? 'กรุณากรอกอีเมล'
                  : !GetUtils.isEmail(v.trim())
                  ? 'รูปแบบอีเมลไม่ถูกต้อง'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              'เบอร์โทรศัพท์',
              _controllers['phone']!,
              'กรอกเบอร์โทรศัพท์',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => v!.trim().isEmpty
                  ? 'กรุณากรอกเบอร์โทรศัพท์'
                  : v.length < 9
                  ? 'เบอร์โทรศัพท์ไม่ถูกต้อง'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              'รหัสผ่าน',
              _controllers['password']!,
              _obscurePassword,
              () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              'ยืนยันรหัสผ่าน',
              _controllers['confirmPassword']!,
              _obscureConfirmPassword,
              () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              validator: (v) => v != _controllers['password']!.text
                  ? 'รหัสผ่านไม่ตรงกัน'
                  : null,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('ข้อมูลยานพาหนะ'),
            const SizedBox(height: 16),
            _buildVehicleDropdown(),
            const SizedBox(height: 16),
            _buildField(
              'ทะเบียนรถ',
              _controllers['licensePlate']!,
              'กรอกทะเบียนรถ',
              Icons.credit_card_outlined,
              validator: (v) => v!.trim().isEmpty ? 'กรุณากรอกทะเบียนรถ' : null,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('รูปถ่ายพนักงาน'),
            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/personst.png',
              width: 40,
              height: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'สร้างบัญชีพนักงานจัดส่ง',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กรอกข้อมูลพนักงานเพื่อเพิ่มเข้าสู่ระบบ',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9), size: 22),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0EA5E9),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF3B30),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF3B30),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback onToggle, {
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            validator:
                validator ??
                (v) => v!.isEmpty
                    ? 'กรุณากรอกรหัสผ่าน'
                    : v.length < 6
                    ? 'ต้องมีอย่างน้อย 6 ตัวอักษร'
                    : null,
            decoration: InputDecoration(
              hintText: 'กรอกรหัสผ่าน',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF0EA5E9),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: 22,
                ),
                onPressed: onToggle,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0EA5E9),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF3B30),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF3B30),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'ประเภทรถ',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButtonFormField<String>(
            value: _vehicleType,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.directions_bike_outlined,
                color: Color(0xFF0EA5E9),
                size: 22,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0EA5E9),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade600,
              size: 24,
            ),
            items: _vehicleTypes.map((type) {
              IconData vehicleIcon =
                  (type == 'มอเตอร์ไซค์' || type == 'จักรยานยนต์')
                  ? Icons.two_wheeler
                  : Icons.directions_car;
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(vehicleIcon, size: 20, color: const Color(0xFF64748B)),
                    const SizedBox(width: 12),
                    Text(
                      type,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _vehicleType = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _profileImage != null
                ? const Color(0xFF0EA5E9)
                : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _profileImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _profileImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      size: 40,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'เพิ่มรูปถ่ายพนักงาน',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'แตะเพื่อเลือกรูปภาพ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'สร้างบัญชี',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
