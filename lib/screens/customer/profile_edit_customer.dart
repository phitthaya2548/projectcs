// lib/pages/profile_edit_customer.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/models/req/customer/req_editprofile_customer.dart';
import 'package:wash_and_dry/service/session_service.dart';

class ProfileEditCustomer extends StatefulWidget {
  final String customerId;
  const ProfileEditCustomer({super.key, required this.customerId});

  @override
  State<ProfileEditCustomer> createState() => _ProfileEditCustomerState();
}

class _ProfileEditCustomerState extends State<ProfileEditCustomer> {
  String url = '';
  bool isLoading = true;
  bool isSaving = false;

  Customer? customer;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedBirthday;
  File? _newProfileImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() => url = config['apiEndpoint']?.toString() ?? '');

      if (url.isNotEmpty) {
        await fetchCustomerProfile();
      }
    } catch (e) {
      log('Config error: $e');
      setState(() {
        url = '';
        isLoading = false;
      });
      _showError('ไม่สามารถโหลด Config ได้');
    }
  }

  Future<void> fetchCustomerProfile() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$url/customer/profile/${widget.customerId}'),
        headers: {'Content-Type': 'application/json'},
      );

      log('GET Profile - Status: ${response.statusCode}');
      log('GET Profile - Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['ok'] == true) {
          setState(() {
            customer = Customer.fromJson(jsonData['data']);
            
            _fullnameController.text = customer!.fullname;
            _emailController.text = customer!.email;
            _phoneController.text = customer!.phone;
            _selectedGender = customer!.gender.isNotEmpty ? customer!.gender : null;

            if (customer!.birthday != null && customer!.birthday!.isNotEmpty) {
              try {
                _selectedBirthday = DateTime.parse(customer!.birthday!);
              } catch (e) {
                log('Birthday parse error: $e');
              }
            }

            isLoading = false;
          });
        } else {
          _showError(jsonData['message'] ?? 'ไม่สามารถดึงข้อมูลได้');
          setState(() => isLoading = false);
        }
      } else {
        _showError('เกิดข้อผิดพลาดในการดึงข้อมูล');
        setState(() => isLoading = false);
      }
    } catch (e) {
      log('Fetch error: $e');
      _showError('เกิดข้อผิดพลาด: ${e.toString()}');
      setState(() => isLoading = false);
    }
  }

 
 void _showImageSourceDialog() {
  Get.bottomSheet(
    Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'เลือกรูปโปรไฟล์',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.blue,
                ),
              ),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Get.back();
                _pickImageFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Colors.green,
                ),
              ),
              title: const Text('เลือกจากแกลเลอรี่'),
              onTap: () {
                Get.back();
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
           
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
  );
}


  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          _showError('ไฟล์รูปภาพต้องมีขนาดไม่เกิน 5MB');
          return;
        }

        setState(() {
          _newProfileImage = file;
        });
      }
    } catch (e) {
      log('Pick image error: $e');
      _showError('เกิดข้อผิดพลาดในการเลือกรูปภาพ');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isSaving = true);

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$url/customer/profile/${widget.customerId}'),
      );

      request.fields['fullname'] = _fullnameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();

      if (_selectedGender != null && _selectedGender!.isNotEmpty) {
        request.fields['gender'] = _selectedGender!;
      }

      if (_selectedBirthday != null) {
        request.fields['birthday'] = _selectedBirthday!.toIso8601String().split('T')[0];
      }

      if (_newProfileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _newProfileImage!.path,
          ),
        );
      }

      log('Update Profile - Fields: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      log('Update Profile - Status: ${response.statusCode}');
      log('Update Profile - Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['ok'] == true) {
          setState(() {
            customer = Customer.fromJson(jsonData['data']);
            _newProfileImage = null;
          });

          try {
            await Session().saveLogin(
              role: 'customer',
              customerId: customer!.customerId,
              fullname: customer!.fullname,
              profileImage: customer!.profileImage,
              phone: customer!.phone,
            );
            log('Session updated successfully');
          } catch (sessionError) {
            log('Session update error: $sessionError');
          }

          Get.snackbar(
            'สำเร็จ',
            'บันทึกข้อมูลเรียบร้อยแล้ว',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, customer);
          }
        } else {
          _showError(jsonData['message'] ?? 'ไม่สามารถบันทึกข้อมูลได้');
        }
      } else {
        final jsonData = json.decode(response.body);
        _showError(jsonData['message'] ?? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล');
      }
    } catch (e) {
      log('Save error: $e');
      _showError('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'ข้อผิดพลาด',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _formatBirthday(DateTime? date) {
    if (date == null) return 'เลือกวันเกิด';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
      
        title: const Text("แก้ไขโปรไฟล์", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
          ),
        ),
      ),
        actions: [
          if (isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customer == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('ไม่พบข้อมูลลูกค้า'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchCustomerProfile,
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: _newProfileImage != null
                                  ? FileImage(_newProfileImage!)
                                  : (customer!.profileImage.isNotEmpty
                                      ? NetworkImage(customer!.profileImage)
                                      : null) as ImageProvider?,
                              child: _newProfileImage == null &&
                                      customer!.profileImage.isEmpty
                                  ? const Icon(Icons.person, size: 60)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                radius: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                                  onPressed: _showImageSourceDialog, 
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Center(
                        child: Column(
                          children: [
                            Text(
                              '@${customer!.username}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ยอดเงินในกระเป๋า: ฿${customer!.walletBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _fullnameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อ-นามสกุล',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณากรอกชื่อ-นามสกุล';
                          }
                          if (value.trim().length < 2) {
                            return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'อีเมล',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณากรอกอีเมล';
                          }
                          final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'รูปแบบอีเมลไม่ถูกต้อง';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'เบอร์โทรศัพท์',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณากรอกเบอร์โทรศัพท์';
                          }
                          final phoneRegex = RegExp(r'^[0-9]{9,10}$');
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return 'เบอร์โทรศัพท์ต้องเป็นตัวเลข 9-10 หลัก';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'เพศ',
                          prefixIcon: Icon(Icons.wc),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('ชาย')),
                          DropdownMenuItem(value: 'female', child: Text('หญิง')),
                          DropdownMenuItem(value: 'other', child: Text('อื่นๆ')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาเลือกเพศ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'วันเกิด',
                            prefixIcon: Icon(Icons.cake),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _formatBirthday(_selectedBirthday),
                            style: TextStyle(
                              color: _selectedBirthday != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'บันทึกข้อมูล',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}