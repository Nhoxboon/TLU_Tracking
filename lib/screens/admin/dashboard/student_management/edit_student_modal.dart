import 'package:flutter/material.dart';
import 'package:android_app/screens/admin/dashboard/student_management/students_management_view.dart';
import 'package:android_app/services/api_service.dart';

class EditStudentModal extends StatefulWidget {
  final StudentData student;

  const EditStudentModal({super.key, required this.student});

  @override
  State<EditStudentModal> createState() => _EditStudentModalState();
}

class _EditStudentModalState extends State<EditStudentModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _studentCodeController;
  late final TextEditingController _classNameController;
  late final TextEditingController _hometownController;

  DateTime? _selectedBirthDate;
  String _selectedMajor = '';
  String _selectedCourse = '';

  // API service and data for dropdowns
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _majors = [];
  List<Map<String, dynamic>> _cohorts = [];
  List<Map<String, dynamic>> _faculties = [];
  bool _isLoadingData = false;
  bool _isLoading = false;

  // Dropdown selections
  Map<String, dynamic>? _selectedFaculty;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing student data
    _nameController = TextEditingController(text: widget.student.name);
    _phoneController = TextEditingController(text: widget.student.phone);
    _emailController = TextEditingController(text: widget.student.email);
    _passwordController = TextEditingController();
    _studentCodeController = TextEditingController(text: widget.student.code);
    _classNameController = TextEditingController(
      text: widget.student.className,
    );
    _hometownController = TextEditingController(
      text: widget.student.hometown ?? '',
    );

    // Set initial values
    _selectedMajor = widget.student.major;
    _selectedCourse = widget.student.course;

    // Load API data for dropdowns
    _loadDropdownData();

    // Parse birth date from string format (DD/MM/YYYY)
    try {
      final parts = widget.student.birthDate.split('/');
      if (parts.length == 3) {
        _selectedBirthDate = DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      // If parsing fails, use a default date
      _selectedBirthDate = DateTime(2004, 6, 15);
    }
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load faculties, majors and cohorts concurrently
      final results = await Future.wait([
        _apiService.getFacultiesPaginated(limit: 100),
        _apiService.getMajorsPaginated(limit: 100),
        _apiService.getCohortsPaginated(limit: 100),
      ]);

      final facultyResult = results[0];
      final majorResult = results[1];
      final cohortResult = results[2];

      // Load faculties
      if (facultyResult.success && facultyResult.data != null) {
        setState(() {
          _faculties = facultyResult.data!.items;
          // Find and set current faculty based on student's facultyId
          if (widget.student.facultyId != null) {
            _selectedFaculty = _faculties.firstWhere(
              (faculty) => faculty['id'] == widget.student.facultyId,
              orElse: () => <String, dynamic>{},
            );
            if (_selectedFaculty!.isEmpty) _selectedFaculty = null;
          }
        });
      }

      if (majorResult.success && majorResult.data != null) {
        final majors = majorResult.data!.items;
        // Check if current student major exists in API data
        final currentMajorExists = majors.any(
          (major) => major['name'] == _selectedMajor,
        );
        if (!currentMajorExists && _selectedMajor.isNotEmpty) {
          // Add current major as temporary entry if not found in API
          majors.insert(0, {'id': -1, 'name': _selectedMajor});
        }
        setState(() {
          _majors = majors;
        });
      }

      if (cohortResult.success && cohortResult.data != null) {
        final cohorts = cohortResult.data!.items;
        // Check if current student cohort exists in API data
        final currentCohortExists = cohorts.any(
          (cohort) =>
              (cohort['name'] ?? cohort['year']?.toString() ?? '') ==
              _selectedCourse,
        );
        if (!currentCohortExists && _selectedCourse.isNotEmpty) {
          // Add current cohort as temporary entry if not found in API
          cohorts.insert(0, {'id': -1, 'name': _selectedCourse});
        }
        setState(() {
          _cohorts = cohorts;
        });
      }
    } catch (e) {
      // Handle error silently or show snackbar
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
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
        // Get major_id - handle temporary entries (-1) by using original student's majorId
        final majorId = _majors.firstWhere(
          (major) => major['name'] == _selectedMajor,
          orElse: () => <String, dynamic>{'id': -1},
        )['id'];
        final finalMajorId = (majorId == -1) ? widget.student.majorId : majorId;

        // Get cohort_id - handle temporary entries (-1) by using original student's cohortId
        final cohortId = _cohorts.firstWhere(
          (cohort) =>
              (cohort['name'] ?? cohort['year']?.toString() ?? '') ==
              _selectedCourse,
          orElse: () => <String, dynamic>{'id': -1},
        )['id'];
        final finalCohortId = (cohortId == -1)
            ? widget.student.cohortId
            : cohortId;

        // Prepare student data for API update (matching the API schema exactly)
        final studentData = <String, dynamic>{
          'faculty_id':
              _selectedFaculty?['id'] ?? widget.student.facultyId ?? 0,
          'major_id': finalMajorId ?? 0,
          'cohort_id': finalCohortId ?? 0,
          'class_name': _classNameController.text.trim(),
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'birth_date':
              _selectedBirthDate?.toIso8601String().split('T')[0] ??
              DateTime.now().toIso8601String().split(
                'T',
              )[0], // Format as YYYY-MM-DD
          'hometown': _hometownController.text.trim(),
          'email': _emailController.text.trim(),
        };

        // Only include password if it's not empty
        if (_passwordController.text.isNotEmpty) {
          studentData['password'] = _passwordController.text;
        }

        final result = await _apiService.updateStudentData(
          widget.student.apiId, // Use the API ID
          studentData,
        );

        if (!mounted) return;

        if (result.success) {
          Navigator.of(context).pop(true); // Return true to indicate success

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật sinh viên thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.message.isNotEmpty
                    ? result.message
                    : 'Cập nhật sinh viên thất bại',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
              'Sửa sinh viên',
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
                    label: 'Số điện thoại*',
                    controller: _phoneController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (value.length < 10) {
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
            _buildFacultyDropdown(),
            const SizedBox(height: 16),

            // Major Field (Dropdown)
            _buildMajorDropdown(),
            const SizedBox(height: 16),

            // Course Field (Dropdown)
            Row(
              children: [
                SizedBox(width: 189, child: _buildCourseDropdown()),
                const Spacer(),
              ],
            ),
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

            // Password Field (optional for editing)
            _buildPasswordField(),
          ],
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

  Widget _buildMajorDropdown() {
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
        DropdownButtonFormField<String>(
          initialValue: _selectedMajor.isNotEmpty ? _selectedMajor : null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn ngành';
            }
            return null;
          },
          onChanged: _isLoadingData
              ? null
              : (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMajor = newValue;
                    });
                  }
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
          items: _isLoadingData
              ? []
              : _majors.map<DropdownMenuItem<String>>((
                  Map<String, dynamic> major,
                ) {
                  final majorName = major['name'] ?? 'Không xác định';
                  return DropdownMenuItem<String>(
                    value: majorName,
                    child: Text(
                      majorName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF000000),
                      ),
                    ),
                  );
                }).toList(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF717680),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseDropdown() {
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
        DropdownButtonFormField<String>(
          initialValue: _selectedCourse.isNotEmpty ? _selectedCourse : null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn khóa';
            }
            return null;
          },
          onChanged: _isLoadingData
              ? null
              : (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCourse = newValue;
                    });
                  }
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
          items: _isLoadingData
              ? []
              : _cohorts.map<DropdownMenuItem<String>>((
                  Map<String, dynamic> cohort,
                ) {
                  final cohortName =
                      cohort['name'] ??
                      cohort['year']?.toString() ??
                      'Không xác định';
                  return DropdownMenuItem<String>(
                    value: cohortName,
                    child: Text(
                      cohortName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF000000),
                      ),
                    ),
                  );
                }).toList(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF717680),
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
            width: 152,
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
          'Mật khẩu',
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
            // Password is optional when editing - only validate if user enters something
            if (value != null && value.isNotEmpty && value.length < 6) {
              return 'Mật khẩu phải có ít nhất 6 ký tự';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Để trống nếu không muốn thay đổi',
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9CA3AF),
            ),
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
                  color: _isLoading
                      ? const Color(0xFF2264E5).withValues(alpha: 0.6)
                      : const Color(0xFF2264E5),
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
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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

  Widget _buildFacultyDropdown() {
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
          items: _isLoadingData
              ? []
              : _faculties.map<DropdownMenuItem<Map<String, dynamic>>>((
                  Map<String, dynamic> faculty,
                ) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: faculty,
                    child: Text(
                      faculty['name'] ?? 'Không xác định',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF000000),
                      ),
                    ),
                  );
                }).toList(),
          onChanged: _isLoadingData
              ? null
              : (Map<String, dynamic>? newValue) {
                  setState(() {
                    _selectedFaculty = newValue;
                    // Reset major when faculty changes - will be handled by existing major dropdown logic
                  });
                },
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF717680),
          ),
        ),
      ],
    );
  }
}
