import 'package:flutter/material.dart';

import 'package:android_app/services/api_service.dart';

class EditDepartmentModal extends StatefulWidget {
  final int departmentId;
  final VoidCallback onUpdate;

  const EditDepartmentModal({
    super.key,
    required this.departmentId,
    required this.onUpdate,
  });

  @override
  State<EditDepartmentModal> createState() => _EditDepartmentModalState();
}

class _EditDepartmentModalState extends State<EditDepartmentModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _selectedFaculty;
  bool _isLoading = false;
  bool _isLoadingData = false;

  // API data
  List<Map<String, dynamic>> _faculties = [];
  Map<String, dynamic>? _departmentData;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _codeController = TextEditingController();
    _nameController = TextEditingController();

    // Load department data and faculties
    _loadDepartmentData();
    _loadFaculties();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartmentData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final result = await _apiService.getDepartment(widget.departmentId);
      if (result.success && result.data != null) {
        setState(() {
          _departmentData = result.data!;
          _codeController.text = result.data!['code'] ?? '';
          _nameController.text = result.data!['name'] ?? '';
          _isLoadingData = false;
        });

        // Set selected faculty after faculties are loaded
        if (_faculties.isNotEmpty) {
          _setSelectedFaculty();
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

  Future<void> _loadFaculties() async {
    try {
      final result = await _apiService.getFacultiesPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _faculties = result.data!.items.cast<Map<String, dynamic>>();
        });

        // Set selected faculty if department data is already loaded
        if (_departmentData != null) {
          _setSelectedFaculty();
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  void _setSelectedFaculty() {
    if (_departmentData != null && _faculties.isNotEmpty) {
      final facultyId = _departmentData!['faculty_id'];
      _selectedFaculty = _faculties.firstWhere(
        (faculty) => faculty['id'] == facultyId,
        orElse: () => <String, dynamic>{},
      );
      if (_selectedFaculty!.isEmpty) {
        _selectedFaculty = null;
      }
    }
  }

  Future<void> _handleConfirm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare department data for API update
        final departmentData = {
          'code': _codeController.text.trim(),
          'name': _nameController.text.trim(),
          'faculty_id': _selectedFaculty?['id'] ?? 0,
        };

        final result = await _apiService.updateDepartmentData(
          widget.departmentId,
          departmentData,
        );

        if (!mounted) return;

        if (result.success) {
          Navigator.of(context).pop(true); // Return true to indicate success

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật bộ môn thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Có lỗi xảy ra khi cập nhật bộ môn'),
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
            content: Text('Đã xảy ra lỗi: ${e.toString()}'),
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
      child: SizedBox(
        width: 640,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sửa bộ môn',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFF181D27),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(),
                      color: const Color(0xFF717680),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _isLoadingData
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Department Code field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mã bộ môn',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF414651),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _codeController,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5D7DA),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5D7DA),
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Department Name field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tên bộ môn',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF414651),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5D7DA),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5D7DA),
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập tên bộ môn';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Faculty dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Khoa trực thuộc',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF414651),
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedFaculty,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5D7DA),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5D7DA),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: _faculties.map((
                                  Map<String, dynamic> faculty,
                                ) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: faculty,
                                    child: Text(
                                      faculty['name'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        color: Color(0xFF181D27),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (Map<String, dynamic>? newValue) {
                                  setState(() {
                                    _selectedFaculty = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Vui lòng chọn khoa';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          side: const BorderSide(color: Color(0xFFD5D7DA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2264E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFF7F56D9)),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Cập nhật',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
