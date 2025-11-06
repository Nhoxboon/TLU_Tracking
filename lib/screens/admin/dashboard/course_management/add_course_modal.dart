import 'package:flutter/material.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/models/cohort.dart';

class AddCourseModal extends StatefulWidget {
  const AddCourseModal({super.key});

  @override
  State<AddCourseModal> createState() => _AddCourseModalState();
}

class _AddCourseModalState extends State<AddCourseModal> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Generate years dynamically from current year backwards
  late final List<String> _availableYears;

  List<String> _generateAdmissionYears() {
    final currentYear = DateTime.now().year;
    final years = <String>[];

    // Generate years from current year
    for (int i = 0; i <= 15; i++) {
      years.add((currentYear - i).toString());
    }

    return years;
  }

  String? _selectedAdmissionYear;
  String? _selectedEndYear;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize available years and set default to current year
    _availableYears = _generateAdmissionYears();
    _selectedAdmissionYear = _availableYears.first; // Current year
    _selectedEndYear = _availableYears.first; // Current year
  }

  @override
  void dispose() {
    _courseNameController.dispose();
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
          name: _courseNameController.text.trim(),
          startYear: int.parse(_selectedAdmissionYear!),
          endYear: int.parse(_selectedEndYear!),
        ).toCreateJson();

        final result = await _apiService.createCohort(cohortData);

        if (!mounted) return;

        if (result.success) {
          Navigator.of(context).pop(true); // Pass true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm khóa học thành công'),
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
              'Thêm khóa học',
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
              controller: _courseNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên khóa';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Admission Year Field
            _buildYearDropdownField(),
            const SizedBox(height: 16),

            // End Year Field
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

  Widget _buildYearDropdownField() {
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
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF717680),
          ),
          items: _availableYears.map((String year) {
            return DropdownMenuItem<String>(value: year, child: Text(year));
          }).toList(),
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
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF717680),
          ),
          items: _availableYears.map((String year) {
            return DropdownMenuItem<String>(value: year, child: Text(year));
          }).toList(),
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
