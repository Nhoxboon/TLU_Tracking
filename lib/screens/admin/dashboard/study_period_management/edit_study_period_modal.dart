import 'package:flutter/material.dart';
import 'package:android_app/screens/admin/dashboard/study_period_management/study_periods_management_view.dart';
import 'package:intl/intl.dart';

class EditStudyPeriodModal extends StatefulWidget {
  final StudyPeriodData studyPeriod;
  final List<String>? academicYears;

  const EditStudyPeriodModal({
    super.key,
    required this.studyPeriod,
    this.academicYears,
  });

  @override
  State<EditStudyPeriodModal> createState() => _EditStudyPeriodModalState();
}

class _EditStudyPeriodModalState extends State<EditStudyPeriodModal> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAcademicYear;
  String? _selectedSemester;
  String? _selectedPeriod;
  DateTime? _startDate;
  DateTime? _endDate;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  final List<String> _semesters = ['1', '2'];
  final List<String> _periods = ['1', '2'];

  @override
  void initState() {
    super.initState();
    _selectedAcademicYear = widget.studyPeriod.academicYear;
    _selectedSemester = widget.studyPeriod.semester;
    _selectedPeriod = widget.studyPeriod.period;
    _startDate = widget.studyPeriod.startDate;
    _endDate = widget.studyPeriod.endDate;
    _startDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.studyPeriod.startDate),
    );
    _endDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.studyPeriod.endDate),
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
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
                      'Sửa đợt học',
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
                        ),
                        const SizedBox(width: 16),

                        // Academic Year dropdown
                        Expanded(
                          child: Column(
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
                                items: (widget.academicYears ?? []).map((
                                  String year,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: year,
                                    child: Text(
                                      year,
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // TODO: Handle update action
                            Navigator.of(context).pop();
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
