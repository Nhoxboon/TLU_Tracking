import 'package:flutter/material.dart';
import 'package:android_app/services/api_service.dart';

class AddStudentModal extends StatefulWidget {
  const AddStudentModal({super.key});

  @override
  State<AddStudentModal> createState() => _AddStudentModalState();
}

class _AddStudentModalState extends State<AddStudentModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _classNameController = TextEditingController();
  final _hometownController = TextEditingController();
  final ApiService _apiService = ApiService();

  DateTime? _selectedBirthDate;
  Map<String, dynamic>? _selectedFaculty;
  Map<String, dynamic>? _selectedMajor;
  Map<String, dynamic>? _selectedCohort;
  bool _isLoading = false;

  // API data
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _majors = [];
  List<Map<String, dynamic>> _cohorts = [];

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentCodeController.dispose();
    _classNameController.dispose();
    _hometownController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
    try {
      final result = await _apiService.getFacultiesPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _faculties = result.data!.items;
        });
        // Load majors and cohorts
        _loadMajors();
        _loadCohorts();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadMajors({int? facultyId}) async {
    try {
      final result = await _apiService.getMajorsPaginated(
        limit: 100,
        facultyId: facultyId,
      );
      if (result.success && result.data != null) {
        setState(() {
          _majors = result.data!.items;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadCohorts() async {
    try {
      final result = await _apiService.getCohortsPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _cohorts = result.data!.items;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2264E5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  String _formatBirthDate() {
    if (_selectedBirthDate == null) return '15/06/2004';
    return '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}';
  }

  Future<void> _handleConfirm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare student data for API (matching the API schema)
        final studentData = {
          'faculty_id': _selectedFaculty?['id'],
          'major_id': _selectedMajor?['id'],
          'cohort_id': _selectedCohort?['id'],
          'class_name': _classNameController.text,
          'student_code': _studentCodeController.text,
          'full_name': _nameController.text,
          'phone': _phoneController.text.isNotEmpty
              ? _phoneController.text
              : null,
          'birth_date': _selectedBirthDate != null
              ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
              : null,
          'hometown': _hometownController.text.isNotEmpty
              ? _hometownController.text
              : null,
          'email': _emailController.text,
          'password': _passwordController.text,
        };

        final result = await _apiService.createStudentData(studentData);

        if (result.success) {
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate success
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.message.isNotEmpty
                      ? result.message
                      : 'Thêm sinh viên thành công!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.message.isNotEmpty
                      ? result.message
                      : 'Thêm sinh viên thất bại',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi thêm sinh viên: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 640,
        ),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A0D12).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF0A0D12).withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                _buildModalHeader(),

                // Modal Content
                _buildModalContent(),

                // Modal Actions
                _buildModalActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Stack(
        children: [
          // Title
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Thêm sinh viên',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.56,
                color: Color(0xFF181D27),
              ),
            ),
          ),

          // Close Button
          Positioned(
            right: 0,
            top: -8,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF717680),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Student Name Field
              _buildInputField(
                label: 'Tên sinh viên*',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên sinh viên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Student Code and Class Name Row
              Row(
                children: [
                  // Student Code Field
                  Expanded(
                    child: _buildInputField(
                      label: 'Mã sinh viên*',
                      controller: _studentCodeController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mã sinh viên';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Class Name Field
                  Expanded(
                    child: _buildInputField(
                      label: 'Lớp*',
                      controller: _classNameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên lớp';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone and Birth Date Row
              Row(
                children: [
                  // Phone Field
                  Expanded(
                    child: _buildInputField(
                      label: 'Số điện thoại',
                      controller: _phoneController,
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            value.length < 10) {
                          return 'Số điện thoại không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Birth Date Field
                  SizedBox(width: 152, child: _buildDateField()),
                ],
              ),
              const SizedBox(height: 16),

              // Faculty Dropdown
              _buildFacultyField(),
              const SizedBox(height: 16),

              // Major Dropdown
              _buildMajorField(),
              const SizedBox(height: 16),

              // Cohort Dropdown
              _buildCohortField(),
              const SizedBox(height: 16),

              // Hometown Field
              _buildInputField(
                label: 'Quê quán',
                controller: _hometownController,
              ),
              const SizedBox(height: 16),

              // Email Field
              _buildInputField(
                label: 'Email*',
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildPasswordField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF414651),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2264E5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181D27),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngày sinh*',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF414651),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectBirthDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD5D7DA)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A0D12).withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatBirthDate(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF181D27),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Color(0xFF717680),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mật khẩu*',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF414651),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            if (value.length < 6) {
              return 'Mật khẩu phải có ít nhất 6 ký tự';
            }
            return null;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2264E5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181D27),
          ),
        ),
      ],
    );
  }

  Widget _buildFacultyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khoa*',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF414651),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _selectedFaculty,
          validator: (value) {
            if (value == null) {
              return 'Vui lòng chọn khoa';
            }
            return null;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2264E5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          items: _faculties.map((faculty) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: faculty,
              child: Text(faculty['name'] ?? ''),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFaculty = value;
              _selectedMajor = null; // Reset major when faculty changes
            });
            // Load majors for selected faculty
            if (value != null) {
              _loadMajors(facultyId: value['id']);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMajorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngành*',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF414651),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _selectedMajor,
          validator: (value) {
            if (value == null) {
              return 'Vui lòng chọn ngành';
            }
            return null;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2264E5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          items: _majors.map((major) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: major,
              child: Text(major['name'] ?? ''),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMajor = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCohortField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khóa*',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF414651),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _selectedCohort,
          validator: (value) {
            if (value == null) {
              return 'Vui lòng chọn khóa';
            }
            return null;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2264E5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          items: _cohorts.map((cohort) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: cohort,
              child: Text(cohort['name'] ?? ''),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCohort = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildModalActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD5D7DA)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A0D12).withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF414651),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Confirm Button
          Expanded(
            child: InkWell(
              onTap: _isLoading ? null : _handleConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2264E5),
                  border: Border.all(color: const Color(0xFF7F56D9)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A0D12).withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
