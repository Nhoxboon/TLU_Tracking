// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:android_app/services/api_service.dart';

class AddStudyPeriodModal extends StatefulWidget {
  final List<Map<String, dynamic>>? academicYears;

  const AddStudyPeriodModal({super.key, this.academicYears});

  @override
  State<AddStudyPeriodModal> createState() => _AddStudyPeriodModalState();
}

class _AddStudyPeriodModalState extends State<AddStudyPeriodModal> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAcademicYear;
  String? _selectedSemester;
  String? _selectedPeriod;
  DateTime? _startDate;
  DateTime? _endDate;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  List<Map<String, dynamic>> _semesters = [];
  List<Map<String, dynamic>> _filteredSemesters = [];
  final List<String> _periods = ['1', '2'];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadSemesters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.getSemestersPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _semesters = result.data!.items;
          _filteredSemesters = _semesters; // Initially show all semesters
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSemesters() {
    if (_selectedAcademicYear == null || widget.academicYears == null) {
      _filteredSemesters = _semesters;
      return;
    }

    // Find selected academic year ID
    final academicYear = widget.academicYears!.firstWhere(
      (ay) => ay['name'] == _selectedAcademicYear,
      orElse: () => <String, dynamic>{},
    );
    final academicYearId = academicYear['id'] as int?;

    if (academicYearId == null) {
      _filteredSemesters = _semesters;
      return;
    }

    // Filter semesters by academic year ID
    _filteredSemesters = _semesters
        .where((semester) => semester['academic_year_id'] == academicYearId)
        .toList();

    // Reset semester selection if current selection is not in filtered list
    if (_selectedSemester != null) {
      final currentSemesterExists = _filteredSemesters.any(
        (semester) => semester['id'].toString() == _selectedSemester,
      );
      if (!currentSemesterExists) {
        _selectedSemester = null;
      }
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
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
                      'Thêm đợt học',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row with Semester and Academic Year
                    Row(
                      children: [
                        // Semester dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Học kì*',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF414651),
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSemester,
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
                                hint: const Text(
                                  'Chọn học kì',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    color: Color(0xFF717680),
                                  ),
                                ),
                                items: _filteredSemesters.map((
                                  Map<String, dynamic> semester,
                                ) {
                                  final id = semester['id'].toString();
                                  final name =
                                      semester['name'] as String? ??
                                      'Học kì $id';
                                  return DropdownMenuItem<String>(
                                    value: id,
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedSemester = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Vui lòng chọn học kì';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Academic Year dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Năm học*',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF414651),
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedAcademicYear,
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
                                hint: const Text(
                                  'Chọn năm học',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    color: Color(0xFF717680),
                                  ),
                                ),
                                items: (widget.academicYears ?? []).map((
                                  Map<String, dynamic> academicYear,
                                ) {
                                  final name =
                                      academicYear['name'] as String? ?? '';
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedAcademicYear = newValue;
                                    _filterSemesters();
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Vui lòng chọn năm học';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Period dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đợt học*',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF414651),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPeriod,
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
                          hint: const Text(
                            'Chọn đợt học',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: Color(0xFF717680),
                            ),
                          ),
                          items: _periods.map((String period) {
                            return DropdownMenuItem<String>(
                              value: period,
                              child: Text(
                                period,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPeriod = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Vui lòng chọn đợt học';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Start Date field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày bắt đầu*',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF414651),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _startDateController,
                          decoration: InputDecoration(
                            hintText: 'DD/MM/YYYY',
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
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                          ),
                          readOnly: true,
                          onTap: () => _selectStartDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng chọn ngày bắt đầu';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // End Date field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày kết thúc*',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF414651),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _endDateController,
                          decoration: InputDecoration(
                            hintText: 'DD/MM/YYYY',
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
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                          ),
                          readOnly: true,
                          onTap: () => _selectEndDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng chọn ngày kết thúc';
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
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    final payload = {
                                      // API expects: name, start_date, end_date, semester_id
                                      'name': _selectedPeriod ?? '1',
                                      'start_date': _startDate != null
                                          ? DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(_startDate!)
                                          : null,
                                      'end_date': _endDate != null
                                          ? DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(_endDate!)
                                          : null,
                                      'semester_id': _selectedSemester != null
                                          ? int.tryParse(_selectedSemester!)
                                          : null,
                                    }..removeWhere((key, value) => value == null);

                                    final res = await _apiService
                                        .createStudyPhase(payload);

                                    if (!mounted) return;

                                    if (res.success) {
                                      Navigator.of(context).pop(true);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Thêm đợt học thành công',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: ${res.message}'),
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
                                        content: Text(
                                          'Lỗi kết nối: ${e.toString()}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
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
