import 'package:flutter/material.dart';
import 'package:android_app/services/api_service.dart';

class AddStudentToClassModal extends StatefulWidget {
  final int classId;
  final String classCode;
  final String className;

  const AddStudentToClassModal({
    super.key,
    required this.classId,
    required this.classCode,
    required this.className,
  });

  @override
  State<AddStudentToClassModal> createState() => _AddStudentToClassModalState();
}

class _AddStudentToClassModalState extends State<AddStudentToClassModal> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  int? _selectedStudentId;
  String? _selectedStudentCode;
  String _studentName = '';

  // Available students that are not yet in the class
  List<Map<String, dynamic>> _availableStudents = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableStudents();
  }

  Future<void> _loadAvailableStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First get students already in this class
      final classStudentsResult = await _apiService.getClassStudents(
        widget.classId,
      );

      Set<int> enrolledStudentIds = {};
      if (classStudentsResult.success && classStudentsResult.data != null) {
        try {
          enrolledStudentIds = classStudentsResult.data!
              .map((student) => student['student_id'] as int)
              .toSet();
        } catch (e) {
          print('Error parsing enrolled students: $e');
          // Continue with empty set if parsing fails
        }
      }

      // Load all students with pagination (respecting API limit of 100)
      final allStudents = <Map<String, dynamic>>[];
      int currentPage = 1;
      bool hasMorePages = true;
      const int pageLimit = 100; // Maximum allowed by API

      while (hasMorePages) {
        final studentsResult = await _apiService.getStudentsPaginated(
          page: currentPage,
          limit: pageLimit,
        );

        if (studentsResult.success && studentsResult.data != null) {
          // Debug: print structure of students data (only for first page)
          if (currentPage == 1) {
            print(
              'Students data structure: ${studentsResult.data!.items.length} items in page 1',
            );
            if (studentsResult.data!.items.isNotEmpty) {
              print(
                'First student structure: ${studentsResult.data!.items.first}',
              );
            }
          }

          // Process students from current page
          for (final student in studentsResult.data!.items) {
            try {
              final studentId = student['id'];
              if (studentId != null &&
                  !enrolledStudentIds.contains(studentId)) {
                // Safely extract string values, handling possible List types
                String getStringValue(dynamic value) {
                  if (value == null) return '';
                  if (value is String) return value;
                  if (value is List && value.isNotEmpty)
                    return value.first.toString();
                  return value.toString();
                }

                final studentCode = getStringValue(
                  student['student_code'] ?? student['code'],
                );
                final studentName = getStringValue(
                  student['full_name'] ?? student['name'],
                );
                final studentEmail = getStringValue(student['email']);

                final studentData = {
                  'id': studentId,
                  'code': studentCode,
                  'name': studentName.isNotEmpty
                      ? studentName
                      : 'Không xác định',
                  'email': studentEmail,
                };

                if (studentData['code']!.isNotEmpty) {
                  allStudents.add(studentData);
                }
              }
            } catch (e) {
              print('Error processing student: $student, error: $e');
              // Continue with next student if this one fails
            }
          }

          // Check if we have more pages
          hasMorePages = currentPage < studentsResult.data!.totalPages;
          currentPage++;
        } else {
          // If API call fails, break the loop
          if (currentPage == 1) {
            // If first page fails, show error
            setState(() {
              _errorMessage = studentsResult.message;
              _isLoading = false;
            });
            return;
          } else {
            // If subsequent page fails, just stop loading more
            hasMorePages = false;
          }
        }
      }

      setState(() {
        _availableStudents = allStudents;
        _isLoading = false;
      });

      print('Loaded ${allStudents.length} available students total');
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onStudentCodeChanged(String? studentCode) {
    setState(() {
      _selectedStudentCode = studentCode;
      if (studentCode != null) {
        // Find the student by code
        final student = _availableStudents.firstWhere(
          (s) => s['code'] == studentCode,
          orElse: () => {},
        );
        _selectedStudentId = student['id'];
        _studentName = student['name'] ?? '';
      } else {
        _selectedStudentId = null;
        _studentName = '';
      }
    });
  }

  Future<void> _handleConfirm() async {
    if (_formKey.currentState!.validate() && _selectedStudentId != null) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final result = await _apiService.addStudentToClass(
          widget.classId,
          _selectedStudentId!,
        );

        if (result.success) {
          // Close modal and pass success result
          if (mounted) {
            Navigator.of(context).pop(true);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã thêm sinh viên $_studentName ($_selectedStudentCode) vào lớp ${widget.className} thành công',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = result.message;
            _isSubmitting = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Lỗi kết nối: ${e.toString()}';
          _isSubmitting = false;
        });
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
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : _errorMessage != null
          ? SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi: $_errorMessage',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAvailableStudents,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : _availableStudents.isEmpty
          ? const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Không có sinh viên nào có thể thêm vào lớp này',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Show error if any during submission
                  if (_errorMessage != null && !_isLoading)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Student Code Dropdown
                  _buildStudentCodeDropdown(),
                  const SizedBox(height: 16),

                  // Student Name Field (Read-only)
                  _buildStudentNameField(),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentCodeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mã sinh viên*',
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
          initialValue: _selectedStudentCode,
          onChanged: _onStudentCodeChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn sinh viên';
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
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF717680),
          ),
          hint: const Text(
            'Chọn mã sinh viên',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA1A9B8),
            ),
          ),
          items: _availableStudents.map<DropdownMenuItem<String>>((student) {
            final code = student['code'] as String;
            // final name = student['name'] as String;
            return DropdownMenuItem<String>(
              value: code,
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF181D27),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudentNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tên sinh viên',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF414651),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(
              0xFF999999,
            ).withValues(alpha: 0.4), // Grayed out background
            border: Border.all(color: const Color(0xFF999999)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A0D12).withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _studentName.isEmpty
                  ? 'Tên sinh viên sẽ hiển thị khi chọn mã'
                  : _studentName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _studentName.isEmpty
                    ? const Color(0xFFA1A9B8)
                    : const Color(0xFF181D27),
              ),
            ),
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
              onTap: _isSubmitting || _isLoading || _availableStudents.isEmpty
                  ? null
                  : _handleConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      _isSubmitting || _isLoading || _availableStudents.isEmpty
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF2264E5),
                  border: Border.all(
                    color:
                        _isSubmitting ||
                            _isLoading ||
                            _availableStudents.isEmpty
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF7F56D9),
                  ),
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
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
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
