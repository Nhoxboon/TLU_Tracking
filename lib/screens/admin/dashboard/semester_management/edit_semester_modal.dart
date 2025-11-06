import 'package:flutter/material.dart';
import 'package:android_app/screens/admin/dashboard/semester_management/semesters_management_view.dart';
import 'package:intl/intl.dart';
import 'package:android_app/services/api_service.dart';

class EditSemesterModal extends StatefulWidget {
  final SemesterData semester;

  const EditSemesterModal({super.key, required this.semester});

  @override
  State<EditSemesterModal> createState() => _EditSemesterModalState();
}

class _EditSemesterModalState extends State<EditSemesterModal> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAcademicYear;
  String? _selectedSemester;
  DateTime? _startDate;
  DateTime? _endDate;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  final List<String> _semesters = ['1', '2'];
  final ApiService _apiService = ApiService();

  // API data
  List<Map<String, dynamic>> _academicYears = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _selectedAcademicYear = widget.semester.academicYear;
    _selectedSemester = widget.semester.semester;
    _startDate = widget.semester.startDate;
    _endDate = widget.semester.endDate;
    _startDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.semester.startDate),
    );
    _endDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.semester.endDate),
    );

    // Ensure dropdown contains current values
    if (_selectedSemester != null &&
        _selectedSemester!.isNotEmpty &&
        !_semesters.contains(_selectedSemester)) {
      _semesters.add(_selectedSemester!);
    }

    // Load academic years from API
    _loadAcademicYears();
  }

  Future<void> _loadAcademicYears() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final result = await _apiService.getAcademicYearsPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _academicYears = result.data!.items;
          _isLoadingData = false;
        });
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

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _buildAcademicYearItems() {
    final Set<String> allYears = <String>{};

    // Always include the current academic year first (from the existing data)
    if (_selectedAcademicYear != null && _selectedAcademicYear!.isNotEmpty) {
      allYears.add(_selectedAcademicYear!);
    }

    // Add years from API if loaded
    if (!_isLoadingData) {
      for (final year in _academicYears) {
        final yearName = year['name'] as String?;
        if (yearName != null && yearName.isNotEmpty) {
          allYears.add(yearName);
        }
      }
    }

    // If still loading and no current value, show loading item
    if (_isLoadingData && allYears.isEmpty) {
      return [
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Đang tải...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFF717680),
            ),
          ),
        ),
      ];
    }

    // Convert to dropdown items, sorted
    final sortedYears = allYears.toList()
      ..sort((a, b) => b.compareTo(a)); // Desc order
    return sortedYears.map((year) {
      return DropdownMenuItem<String>(
        value: year,
        child: Text(
          year,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
        ),
      );
    }).toList();
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
                      'Sửa học kì',
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
                    // Academic Year dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Năm học',
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
                          items: _buildAcademicYearItems(),
                          onChanged: _isLoadingData
                              ? null
                              : (String? newValue) {
                                  setState(() {
                                    _selectedAcademicYear = newValue;
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
                    const SizedBox(height: 20),

                    // Semester dropdown (label "Đợt học" in Edit modal)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đợt học',
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
                          items: _semesters.map((String semester) {
                            return DropdownMenuItem<String>(
                              value: semester,
                              child: Text(
                                semester,
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
                    const SizedBox(height: 20),

                    // Start Date field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày bắt đầu',
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
                          'Ngày kết thúc',
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
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Store context before async operations
                            final navigator = Navigator.of(context);
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );

                            try {
                              // Find the academic year ID from the selected name
                              final selectedAcademicYear = _academicYears
                                  .firstWhere(
                                    (year) =>
                                        year['name'] == _selectedAcademicYear,
                                    orElse: () => <String, dynamic>{},
                                  );

                              final payload = <String, dynamic>{};
                              if (_selectedSemester != null) {
                                payload['name'] = _selectedSemester!;
                              }
                              if (selectedAcademicYear.isNotEmpty) {
                                payload['academic_year_id'] =
                                    selectedAcademicYear['id'];
                              }
                              if (_startDate != null) {
                                payload['start_date'] = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(_startDate!);
                              }
                              if (_endDate != null) {
                                payload['end_date'] = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(_endDate!);
                              }

                              final apiId = widget.semester.apiId;
                              if (apiId == null) {
                                throw Exception('Thiếu ID học kì để cập nhật');
                              }

                              final res = await _apiService.updateSemester(
                                apiId,
                                payload,
                              );
                              if (res.success) {
                                if (mounted) {
                                  navigator.pop(true);
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cập nhật học kì thành công',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                throw Exception(res.message);
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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
                        child: const Text(
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
