import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/user_session.dart';
import '../../services/api_service.dart';

class StudentEditProfileScreen extends StatefulWidget {
  const StudentEditProfileScreen({Key? key}) : super(key: key);

  @override
  State<StudentEditProfileScreen> createState() => _StudentEditProfileScreenState();
}

class _StudentEditProfileScreenState extends State<StudentEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _hometownController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _studentCodeController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = UserSession().accessToken;
      if (token == null) throw Exception('Chưa đăng nhập');

      final url = Uri.parse('${ApiService.baseUrl}/auth/me');
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        final user = data['data'] ?? data;
        final profile = user['profile'] as Map<String, dynamic>?;
        setState(() {
          _emailController.text = user['email'] ?? '';
          if (profile != null) {
            _nameController.text = profile['full_name'] ?? '';
            _phoneController.text = profile['phone'] ?? '';
            _studentCodeController.text = profile['student_code'] ?? '';
            _hometownController.text = profile['hometown'] ?? '';
            final birth = profile['birth_date']?.toString();
            if (birth != null && birth.isNotEmpty) {
              try {
                final parts = birth.split('-');
                if (parts.length == 3) {
                  _birthdayController.text = '${parts[2]}/${parts[1]}/${parts[0]}';
                } else {
                  _birthdayController.text = birth;
                }
              } catch (_) {
                _birthdayController.text = birth;
              }
            }
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Lỗi server: ${res.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _hometownController.dispose();
    _phoneController.dispose();
    _studentCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchUserProfile, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                if (_studentCodeController.text.isNotEmpty)
                                  _buildTextField(controller: _studentCodeController, label: 'Mã sinh viên', enabled: false),
                                if (_studentCodeController.text.isNotEmpty) const SizedBox(height: 25),
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Tên',
                                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tên' : null,
                                ),
                                const SizedBox(height: 25),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                                    if (!v.contains('@')) return 'Email không hợp lệ';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 25),
                                _buildDatePickerField(controller: _birthdayController, label: 'Ngày sinh', context: context),
                                const SizedBox(height: 25),
                                _buildTextField(controller: _hometownController, label: 'Quê quán'),
                                const SizedBox(height: 25),
                                _buildTextField(
                                  controller: _phoneController,
                                  label: 'Số điện thoại',
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập số điện thoại' : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.all(24.0), child: _buildSaveButton(context)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 16, right: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 24,
              height: 24,
              child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF1E1E1E)),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Sửa thông tin', style: TextStyle(fontFamily: 'Sen', fontSize: 17, fontWeight: FontWeight.w400, color: Color(0xFF181C2E))),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF32343E))),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? const Color(0xFFF0F5FA) : const Color(0xFFE8E8E8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1),
            ),
          ),
          style: const TextStyle(fontFamily: 'Sen', fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF6B6E82)),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Sen', fontSize: 13, letterSpacing: 0.26, fontWeight: FontWeight.w400, color: Color(0xFF32343E))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2196F3))),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
            }
          },
          child: Container(
            width: 148,
            height: 66,
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  child: Container(
                    width: 148,
                    height: 42,
                    decoration: BoxDecoration(color: const Color(0xFFF0F5FA), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                Positioned(
                  top: 37,
                  left: 13,
                  child: Text(controller.text, style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, letterSpacing: -0.32, fontWeight: FontWeight.w400, color: Color(0xB3000000))),
                ),
                Positioned(
                  right: 10,
                  top: 37,
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (!_formKey.currentState!.validate()) return;
        final token = UserSession().accessToken;
        if (token == null || token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa đăng nhập'), backgroundColor: Colors.red));
          return;
        }
        final profileId = UserSession().userData?['profile_id'];
        final studentId = profileId is int ? profileId : (profileId is String ? int.tryParse(profileId) : null);
        if (studentId == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy mã sinh viên'), backgroundColor: Colors.red));
          return;
        }
        String? birthIso;
        final birthText = _birthdayController.text.trim();
        if (birthText.isNotEmpty) {
          try {
            final parts = birthText.split('/');
            if (parts.length == 3) {
              birthIso = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
            }
          } catch (_) {}
        }
        final body = <String, dynamic>{
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          if (birthIso != null && birthIso.isNotEmpty) 'birth_date': birthIso,
          if (_hometownController.text.trim().isNotEmpty) 'hometown': _hometownController.text.trim(),
        };
        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
        try {
          final url = Uri.parse('${ApiService.baseUrl}/users/students/$studentId');
          final resp = await http.put(url, headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          }, body: jsonEncode(body));
          Navigator.of(context).pop();
          if (resp.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thông tin thành công'), backgroundColor: Color(0xFF2196F3)));
            await Future.delayed(const Duration(milliseconds: 800));
            if (context.mounted) Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật thất bại (${resp.statusCode})'), backgroundColor: Colors.red));
          }
        } catch (e) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red));
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2196F3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(16),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: const Text('LƯU', style: TextStyle(fontFamily: 'Sen', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}


