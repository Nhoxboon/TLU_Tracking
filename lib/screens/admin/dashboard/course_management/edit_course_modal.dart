import 'package:flutter/material.dart';
import 'package:android_app/screens/admin/dashboard/course_management/courses_management_view.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/models/cohort.dart';

class EditCourseModal extends StatefulWidget {
  final CourseData course;

  const EditCourseModal({super.key, required this.course});

  @override
  State<EditCourseModal> createState() => _EditCourseModalState();
}

class _EditCourseModalState extends State<EditCourseModal> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late final TextEditingController _nameController;

  String? _selectedAdmissionYear;
  String? _selectedEndYear;
  bool _isLoading = false;

  // Generate years dynamically from current year backwards
  late final List<String> _admissionYears;

  List<String> _generateAdmissionYears() {
    final currentYear = DateTime.now().year;
    final years = <String>[];

    // Generate years from current year
    for (int i = 0; i <= 15; i++) {
      years.add((currentYear - i).toString());
    }

    return years;
  }

  @override
  void initState() {
    super.initState();
    // Initialize available years
    _admissionYears = _generateAdmissionYears();
    // Initialize controllers with existing course data
    _nameController = TextEditingController(text: widget.course.name);

    // Check if existing admission year is in our list, if not add it
    if (!_admissionYears.contains(widget.course.admissionYear)) {
      _admissionYears.add(widget.course.admissionYear);
      _admissionYears.sort((a, b) => b.compareTo(a)); // Sort descending
    }
    _selectedAdmissionYear = widget.course.admissionYear;

    // Check if existing end year is in our list, if not add it
    if (!_admissionYears.contains(widget.course.endYear)) {
      _admissionYears.add(widget.course.endYear);
      _admissionYears.sort((a, b) => b.compareTo(a)); // Sort descending
    }
    _selectedEndYear = widget.course.endYear;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAdmissionYear == null || _selectedEndYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn năm nhập học và năm kết thúc'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare cohort data for API
        final cohortData = Cohort(
          name: _nameController.text.trim(),
          startYear: int.parse(_selectedAdmissionYear!),
          endYear: int.parse(_selectedEndYear!),
        ).toUpdateJson();

        final result = await _apiService.updateCohort(
          widget.course.apiId, // Use the API ID from the course object
          cohortData,
        );

        if (!mounted) return;

        if (result.success) {
          Navigator.of(context).pop(true); // Pass true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật khóa học thành công'),
              backgroundColor: Colors.green,
            ),
          );
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
            content: Text('Lỗi kết nối: $e'),
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
              'Sửa khóa học',
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
            // Course Name Field
            _buildInputField(
              label: 'Tên khóa*',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên khóa học';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Admission Year Dropdown Field
            _buildDropdownField(),
            const SizedBox(height: 16),

            // End Year Dropdown Field
            _buildEndYearDropdownField(),
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

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Năm nhập học*',
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
          initialValue: _selectedAdmissionYear,
          onChanged: (String? newValue) {
            setState(() {
              _selectedAdmissionYear = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn năm nhập học';
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
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF717680)),
          items: _admissionYears.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEndYearDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Năm kết thúc*',
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
          initialValue: _selectedEndYear,
          onChanged: (String? newValue) {
            setState(() {
              _selectedEndYear = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn năm kết thúc';
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
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF717680)),
          items: _admissionYears.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
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
