import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wash_and_dry/config/config.dart';
import 'package:wash_and_dry/screens/customer/pickmap.dart';

class CustomerAddressScreen extends StatefulWidget {
  final String customerId;

  const CustomerAddressScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerAddressScreen> createState() => _CustomerAddressScreenState();
}

class _CustomerAddressScreenState extends State<CustomerAddressScreen> {
  List<dynamic> addresses = [];
  String? url;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await Configuration.getConfig();
    url = config['apiEndpoint'];
    await loadAddresses();
  }

  // ================= LOAD =================
  Future<void> loadAddresses() async {
    final res = await http.get(
      Uri.parse("$url/customer/addresses/${widget.customerId}"),
    );

    final data = jsonDecode(res.body);

    setState(() {
      addresses = data["data"] ?? [];
      loading = false;
    });
  }

  // ================= ADD =================
  Future<void> addAddress({
    required String name,
    required String address,
    required bool isDefault,
    double lat = 0,
    double lng = 0,
  }) async {
    await http.post(
      Uri.parse("$url/customer/addresses/${widget.customerId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "address_name": name,
        "address_text": address,
        "latitude": lat,
        "longitude": lng,
        "status": isDefault,
      }),
    );

    await loadAddresses();
  }

  // ================= UPDATE =================
  Future<void> updateAddress({
    required String id,
    required String name,
    required String address,
    required bool isDefault,
    double lat = 0,
    double lng = 0,
  }) async {
    await http.put(
      Uri.parse("$url/customer/addresses/update/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "address_name": name,
        "address_text": address,
        "latitude": lat,
        "longitude": lng,
        "status": isDefault,
      }),
    );

    await loadAddresses();
  }

  // ================= DELETE =================
  Future<void> deleteAddress(String id) async {
    await http.delete(
      Uri.parse("$url/customer/addresses/delete/$id"),
    );

    await loadAddresses();
  }

  // ================= DEFAULT =================
  Future<void> setDefault(String id) async {
    await http.put(
      Uri.parse("$url/customer/addresses/status/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": true}),
    );

    await loadAddresses();
  }

  // ================= ADD DIALOG =================
  void showAddDialog() {
    final nameCtrl = TextEditingController();
    final addressDetailCtrl = TextEditingController();

    bool isDefault = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (c, setS) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      "เพิ่มที่อยู่ใหม่",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ชื่อที่อยู่
                    _buildTextField(
                      controller: nameCtrl,
                      label: "ชื่อที่อยู่",
                      hint: "เช่น บ้าน, ออฟฟิศ",
                      icon: Icons.label_outline,
                    ),

              

                    // ตำบล อำเภอ จังหวัด รหัสไปรษณีย์ (รวมกัน)
                    _buildTextField(
                      controller: addressDetailCtrl,
                      label: "รายละเอียดที่อยู่",
                      hint: "ที่อยู่, ตำบล, อำเภอ, จังหวัด, รหัสไปรษณีย์",
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),

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
      addressDetailCtrl.text = result["address"];
    }
  },
),
const SizedBox(height: 8),
                    // Switch ที่อยู่หลัก
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "ตั้งเป็นที่อยู่หลัก",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: isDefault,
                            onChanged: (v) => setS(() => isDefault = v),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ปุ่มบันทึก
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          

                        

                          await addAddress(
                            name: nameCtrl.text,
                            address: addressDetailCtrl.text,
                            isDefault: isDefault,
                          );

                          Navigator.pop(context);
                        },
                        child: const Text(
                          "บันทึกที่อยู่",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= TEXT FIELD BUILDER =================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int? maxLength,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines ?? 1,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
          counterText: "",
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
    );
  }

  // ================= EDIT DIALOG =================
  void showEditDialog(Map a) {
    final nameCtrl = TextEditingController(text: a["address_name"]);
    final addressDetailCtrl = TextEditingController(text: a["address_text"]);
    bool isDefault = a["status"] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (c, setS) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "แก้ไขที่อยู่",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    controller: nameCtrl,
                    label: "ชื่อที่อยู่",
                    icon: Icons.label_outline,
                  ),

                  _buildTextField(
                    controller: addressDetailCtrl,
                    label: "ที่อยู่",
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                  ),

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
      addressDetailCtrl.text = result["address"];
    }
  },
),
const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "ตั้งเป็นที่อยู่หลัก",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: isDefault,
                          onChanged: (v) => setS(() => isDefault = v),
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        await updateAddress(
                          id: a["address_id"],
                          name: nameCtrl.text,
                          address: addressDetailCtrl.text,
                          isDefault: isDefault,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "บันทึก",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "ที่อยู่ของฉัน",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
              ? const Center(child: Text("ไม่มีที่อยู่"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: addresses.length,
                  itemBuilder: (c, i) {
                    final a = addresses[i];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            Text(
                              a["address_name"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (a["status"] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "หลัก",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            a["address_text"],
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: PopupMenuButton(
                          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: "edit",
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text("แก้ไข"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: "default",
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text("ตั้งเป็นที่อยู่หลัก"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: "delete",
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text("ลบ",
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (v) {
                            if (v == "edit") {
                              showEditDialog(a);
                            } else if (v == "default") {
                              setDefault(a["address_id"]);
                            } else if (v == "delete") {
                              deleteAddress(a["address_id"]);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "เพิ่มที่อยู่",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}