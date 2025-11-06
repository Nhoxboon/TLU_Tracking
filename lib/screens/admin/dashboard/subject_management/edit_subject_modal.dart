import 'package:flutter/material.dart';
import 'package:android_app/models/subject.dart';
import 'package:android_app/services/api_service.dart';

class EditSubjectModal extends StatefulWidget {
  final SubjectData subject;
  final VoidCallback? onSubjectUpdated;

  const EditSubjectModal({
    super.key,
    required this.subject,
    this.onSubjectUpdated,
  });

  @override
  State<EditSubjectModal> createState() => _EditSubjectModalState();
}

class _EditSubjectModalState extends State<EditSubjectModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _creditsController;
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _selectedFaculty;
  Map<String, dynamic>? _selectedDepartment;
  bool _isLoading = false;

  // API data
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _departments = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing subject data
    _codeController = TextEditingController(text: widget.subject.code);
    _nameController = TextEditingController(text: widget.subject.name);
    _creditsController = TextEditingController(
      text: widget.subject.credits.toString(),
    );

    // Load faculties and departments from API
    _loadFaculties();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final result = await _apiService.getFacultiesPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _faculties = result.data!.items;
          _isLoadingData = false;
        });
        // Load departments for the current subject
        await _loadDepartments(facultyId: widget.subject.departmentId);

        // Set the current department if available
        if (widget.subject.departmentId != null) {
          final currentDept = _departments.firstWhere(
            (dept) => dept['id'] == widget.subject.departmentId,
            orElse: () => <String, dynamic>{},
          );
          if (currentDept.isNotEmpty) {
            setState(() {
              _selectedDepartment = currentDept;
              // Find and set the faculty for this department
              final facultyId = currentDept['faculty_id'];
              if (facultyId != null) {
                _selectedFaculty = _faculties.firstWhere(
                  (faculty) => faculty['id'] == facultyId,
                  orElse: () => <String, dynamic>{},
                );
                if (_selectedFaculty!.isEmpty) {
                  _selectedFaculty = null;
                }
              }
            });
          }
        }
      } else {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadDepartments({int? facultyId}) async {
    try {
      final result = await _apiService.getDepartmentsPaginated(
        limit: 100,
        facultyId: facultyId,
      );
      if (result.success && result.data != null) {
        setState(() {
          _departments = result.data!.items;
          // Reset selected department when faculty changes (except during initialization)
          if (facultyId != null && facultyId != widget.subject.departmentId) {
            _selectedDepartment = null;
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _handleConfirm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare subject data for API update
        final subjectData = {
          'code': _codeController.text.trim(),
          'name': _nameController.text.trim(),
          'credits': int.tryParse(_creditsController.text.trim()) ?? 0,
          'department_id': _selectedDepartment?['id'] ?? 0,
        };

        final result = await _apiService.updateSubjectData(
          widget.subject.apiId,
          subjectData,
        );

        if (!mounted) return;

        if (result.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật môn học thành công'),
              backgroundColor: Colors.green,
            ),
          );
          // Call the callback to refresh the parent view
          if (widget.onSubjectUpdated != null) {
            widget.onSubjectUpdated!();
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
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
            content: Text('Lỗi: ${e.toString()}'),
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
      child: Container(
        width: 640,
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
              'Sửa môn học',
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
            // Subject Code Field
            _buildInputField(
              label: 'Mã môn học*',
              controller: _codeController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mã môn học';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subject Name Field
            _buildInputField(
              label: 'Tên môn học*',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên môn học';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Faculty Dropdown Field
            _buildFacultyField(),
            const SizedBox(height: 16),

            // Department Dropdown Field
            _buildDepartmentField(),
            const SizedBox(height: 16),

            // Credits Field
            _buildInputField(
              label: 'Số tín chỉ*',
              controller: _creditsController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số tín chỉ';
                }
                final credits = int.tryParse(value);
                if (credits == null || credits <= 0) {
                  return 'Số tín chỉ phải là số nguyên dương';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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
          initialValue: _selectedFaculty,
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
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181D27),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _isLoadingData
              ? []
              : _faculties.map((faculty) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: faculty,
                    child: Text(faculty['name'] ?? ''),
                  );
                }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFaculty = value;
              _selectedDepartment =
                  null; // Reset department when faculty changes
            });
            if (value != null) {
              _loadDepartments(facultyId: value['id']);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDepartmentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bộ môn*',
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
          initialValue: _selectedDepartment,
          validator: (value) {
            if (value == null) {
              return 'Vui lòng chọn bộ môn';
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
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181D27),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _isLoadingData
              ? []
              : _departments.map((department) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: department,
                    child: Text(department['name'] ?? ''),
                  );
                }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDepartment = value;
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
                  color: _isLoading ? Colors.grey : const Color(0xFF2264E5),
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
}
