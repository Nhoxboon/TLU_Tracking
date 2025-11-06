import 'package:flutter/material.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/screens/admin/dashboard/class_management/classes_management_view.dart';

class EditClassModal extends StatefulWidget {
  final ClassTableRowData classData;

  const EditClassModal({super.key, required this.classData});

  @override
  State<EditClassModal> createState() => _EditClassModalState();
}

class _EditClassModalState extends State<EditClassModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _selectedTeacher;
  Map<String, dynamic>? _selectedFaculty;
  Map<String, dynamic>? _selectedDepartment;
  Map<String, dynamic>? _selectedSubject;
  Map<String, dynamic>? _selectedMajor;
  Map<String, dynamic>? _selectedCohort;
  Map<String, dynamic>? _selectedAcademicYear;
  Map<String, dynamic>? _selectedSemester;
  Map<String, dynamic>? _selectedStudyPhase;
  bool _isLoading = false;

  // API data
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _majors = [];
  List<Map<String, dynamic>> _cohorts = [];
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _semesters = [];
  List<Map<String, dynamic>> _studyPhases = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate form with existing data
    _nameController.text = widget.classData.name;

    // Load initial data from API
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load all required data concurrently
      final futures = [
        _apiService.getFacultiesPaginated(limit: 100),
        _apiService.getDepartmentsPaginated(limit: 100),
        _apiService.getTeachersPaginated(limit: 100),
        _apiService.getSubjectsPaginated(limit: 100),
        _apiService.getMajorsPaginated(limit: 100),
        _apiService.getCohortsPaginated(limit: 100),
        _apiService.getAcademicYearsPaginated(limit: 100),
        _apiService.getSemestersPaginated(limit: 100),
        _apiService.getStudyPhasesPaginated(limit: 100),
      ];

      final results = await Future.wait(futures);

      setState(() {
        if (results[0].success && results[0].data != null) {
          _faculties = results[0].data!.items;
          // Try to find and set the current faculty based on widget data
          if (widget.classData is ClassData) {
            final classData = widget.classData as ClassData;
            _selectedFaculty = _faculties
                .cast<Map<String, dynamic>?>()
                .firstWhere(
                  (f) => f?['id'] == classData.facultyId,
                  orElse: () => null,
                );
          }
        }
        if (results[1].success && results[1].data != null) {
          _departments = results[1].data!.items;
          // Try to find and set the current department based on widget data
          if (widget.classData is ClassData) {
            final classData = widget.classData as ClassData;
            _selectedDepartment = _departments
                .cast<Map<String, dynamic>?>()
                .firstWhere(
                  (d) => d?['id'] == classData.departmentId,
                  orElse: () => null,
                );
          }
        }
        if (results[2].success && results[2].data != null) {
          _teachers = results[2].data!.items;
          // Try to find and set the current teacher based on widget data
          if (widget.classData is ClassData) {
            final classData = widget.classData as ClassData;
            _selectedTeacher = _teachers
                .cast<Map<String, dynamic>?>()
                .firstWhere(
                  (t) => t?['id'] == classData.teacherId,
                  orElse: () => null,
                );
          }
        }
        if (results[3].success && results[3].data != null) {
          _subjects = results[3].data!.items;
          // Try to find and set the current subject based on widget data
          if (widget.classData is ClassData) {
            final classData = widget.classData as ClassData;
            _selectedSubject = _subjects
                .cast<Map<String, dynamic>?>()
                .firstWhere(
                  (s) => s?['id'] == classData.subjectId,
                  orElse: () => null,
                );
          }
        }
        if (results[4].success && results[4].data != null) {
          _majors = results[4].data!.items;
          // Try to find and set the current major based on widget data
          if (widget.classData is ClassData) {
            final classData = widget.classData as ClassData;
            _selectedMajor = _majors.cast<Map<String, dynamic>?>().firstWhere(
              (m) => m?['id'] == classData.majorId,
              orElse: () => null,
            );
          }
        }
        if (results[5].success && results[5].data != null) {
          _cohorts = results[5].data!.items;
          // Try to find and set the current cohort based on widget data
          if (widget.classData is ClassData) {
            final classData = widget.classData as ClassData;
            _selectedCohort = _cohorts.cast<Map<String, dynamic>?>().firstWhere(
              (c) => c?['id'] == classData.cohortId,
              orElse: () => null,
            );
          }
        }
        if (results[6].success && results[6].data != null) {
          _academicYears = results[6].data!.items;
          // Try to find and set the current academic year based on widget data
          if (widget.classData is ClassData) {
            final classData = widget.classData as ClassData;
            _selectedAcademicYear = _academicYears
                .cast<Map<String, dynamic>?>()
                .firstWhere(
                  (ay) => ay?['id'] == classData.academicYearId,
                  orElse: () => null,
                );
          }
        }
        if (results[7].success && results[7].data != null) {
          _semesters = results[7].data!.items;
          // Try to find and set the current semester based on widget data
          if (widget.classData is ClassData) {
            final classData = widget.classData as ClassData;
            _selectedSemester = _semesters
                .cast<Map<String, dynamic>?>()
                .firstWhere(
                  (s) => s?['id'] == classData.semesterId,
                  orElse: () => null,
                );
          }
        }
        if (results[8].success && results[8].data != null) {
          _studyPhases = results[8].data!.items;
          // Try to find and set the current study phase based on widget data
          if (widget.classData is ClassData) {
            final classData = widget.classData as ClassData;
            _selectedStudyPhase = _studyPhases
                .cast<Map<String, dynamic>?>()
                .firstWhere(
                  (sp) => sp?['id'] == classData.studyPhaseId,
                  orElse: () => null,
                );
          }
        }
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // Cascade loading methods (similar to add_class_modal)
  Future<void> _loadDepartments({int? facultyId}) async {
    try {
      final result = await _apiService.getDepartmentsPaginated(
        limit: 100,
        facultyId: facultyId,
      );
      if (result.success && result.data != null) {
        setState(() {
          _departments = result.data!.items;
          // Reset selected department when faculty changes
          if (facultyId != null) {
            _selectedDepartment = null;
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadSemesters({int? academicYearId}) async {
    try {
      final result = await _apiService.getSemestersPaginated(
        limit: 100,
        academicYearId: academicYearId,
      );
      if (result.success && result.data != null) {
        setState(() {
          _semesters = result.data!.items;
          // Reset selected semester when academic year changes
          if (academicYearId != null) {
            _selectedSemester = null;
            _selectedStudyPhase = null;
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadStudyPhases({int? semesterId}) async {
    try {
      final result = await _apiService.getStudyPhasesPaginated(
        limit: 100,
        semesterId: semesterId,
      );
      if (result.success && result.data != null) {
        setState(() {
          _studyPhases = result.data!.items;
          // Reset selected study phase when semester changes
          if (semesterId != null) {
            _selectedStudyPhase = null;
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _handleConfirm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the class API ID
        int classApiId;
        if (widget.classData is ClassData) {
          final classData = widget.classData as ClassData;
          classApiId = classData.apiId;
        } else {
          // Fallback if not ClassData type - try to get apiId from dynamic data
          classApiId = widget.classData.id;
        }

        // Prepare class data for API update
        final classData = <String, dynamic>{
          'name': _nameController.text.trim(),
          'subject_id': _selectedSubject?['id'],
          'teacher_id': _selectedTeacher?['id'],
          'faculty_id': _selectedFaculty?['id'],
          'department_id': _selectedDepartment?['id'],
          'major_id': _selectedMajor?['id'],
          'cohort_id': _selectedCohort?['id'],
          'academic_year_id': _selectedAcademicYear?['id'],
          'semester_id': _selectedSemester?['id'],
          'study_phase_id': _selectedStudyPhase?['id'],
          'status': 'active', // Default status
        };

        final result = await _apiService.updateClassData(classApiId, classData);

        if (!mounted) return;

        if (result.success) {
          Navigator.of(context).pop(true); // Return true to indicate success

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật lớp học thành công!'),
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
                'Có lỗi xảy ra khi cập nhật lớp học: ${result.message}',
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
              'Sửa lớp',
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
    if (_isLoadingData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Class Name Field
            _buildInputField(
              label: 'Tên lớp*',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên lớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Teacher Dropdown Field
            _buildApiDropdownField(
              label: 'Giảng viên phụ trách*',
              value: _selectedTeacher,
              items: _teachers,
              hintText: 'Chọn giảng viên',
              displayField: 'full_name', // Specify field for teacher name
              onChanged: (value) {
                setState(() {
                  _selectedTeacher = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Vui lòng chọn giảng viên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Faculty and Department Row
            Row(
              children: [
                // Faculty Dropdown Field
                Expanded(
                  child: _buildApiDropdownField(
                    label: 'Khoa*',
                    value: _selectedFaculty,
                    items: _faculties,
                    hintText: 'Chọn khoa',
                    displayField: 'name',
                    onChanged: (value) {
                      setState(() {
                        _selectedFaculty = value;
                        _selectedDepartment = null; // Reset department
                      });
                      // Load departments for selected faculty
                      if (value != null) {
                        _loadDepartments(facultyId: value['id']);
                      } else {
                        _loadDepartments();
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Vui lòng chọn khoa';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Department Dropdown Field
                Expanded(
                  child: _buildApiDropdownField(
                    label: 'Bộ môn*',
                    value: _selectedDepartment,
                    items: _departments,
                    hintText: 'Chọn bộ môn',
                    displayField: 'name',
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Vui lòng chọn bộ môn';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject Dropdown Field
            _buildApiDropdownField(
              label: 'Môn học*',
              value: _selectedSubject,
              items: _subjects,
              hintText: 'Chọn môn học',
              displayField: 'name',
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Vui lòng chọn môn học';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Cohort Dropdown Field
            _buildApiDropdownField(
              label: 'Khóa',
              value: _selectedCohort,
              items: _cohorts,
              hintText: 'Chọn khóa',
              displayField: 'name',
              onChanged: (value) {
                setState(() {
                  _selectedCohort = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Academic Year Dropdown Field
            _buildApiDropdownField(
              label: 'Năm học*',
              value: _selectedAcademicYear,
              items: _academicYears,
              hintText: 'Chọn năm học',
              displayField: 'name',
              onChanged: (value) {
                setState(() {
                  _selectedAcademicYear = value;
                  _selectedSemester = null;
                  _selectedStudyPhase = null;
                });
                // Load semesters for selected academic year
                if (value != null) {
                  _loadSemesters(academicYearId: value['id']);
                } else {
                  _loadSemesters();
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Vui lòng chọn năm học';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Semester and Study Phase Row
            Row(
              children: [
                // Semester Dropdown Field
                Expanded(
                  child: _buildApiDropdownField(
                    label: 'Học kì*',
                    value: _selectedSemester,
                    items: _semesters,
                    hintText: 'Chọn học kì',
                    displayField: 'name',
                    onChanged: (value) {
                      setState(() {
                        _selectedSemester = value;
                        _selectedStudyPhase = null;
                      });
                      // Load study phases for selected semester
                      if (value != null) {
                        _loadStudyPhases(semesterId: value['id']);
                      } else {
                        _loadStudyPhases();
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Vui lòng chọn học kì';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Study Phase Dropdown Field
                Expanded(
                  child: _buildApiDropdownField(
                    label: 'Đợt học*',
                    value: _selectedStudyPhase,
                    items: _studyPhases,
                    hintText: 'Chọn đợt học',
                    displayField: 'name',
                    onChanged: (value) {
                      setState(() {
                        _selectedStudyPhase = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Vui lòng chọn đợt học';
                      }
                      return null;
                    },
                  ),
                ),
              ],
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

  String _getDisplayName(Map<String, dynamic> item, String? displayField) {
    if (displayField != null) {
      return item[displayField] ?? 'Không tên';
    }

    // Auto-detect field based on common patterns
    if (item.containsKey('full_name')) {
      return item['full_name'] ?? 'Không tên';
    } else if (item.containsKey('name')) {
      return item['name'] ?? 'Không tên';
    } else if (item.containsKey('title')) {
      return item['title'] ?? 'Không tên';
    }

    return 'Không tên';
  }

  Widget _buildApiDropdownField({
    required String label,
    required Map<String, dynamic>? value,
    required List<Map<String, dynamic>> items,
    required void Function(Map<String, dynamic>?) onChanged,
    String? Function(Map<String, dynamic>?)? validator,
    String hintText = 'Chọn...',
    String? displayField, // Field để hiển thị tên
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
        DropdownButtonFormField<Map<String, dynamic>>(
          value: value,
          onChanged: _isLoadingData ? null : onChanged,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF2264E5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
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
          hint: Text(hintText),
          items: _isLoadingData
              ? []
              : items.map<DropdownMenuItem<Map<String, dynamic>>>((
                  Map<String, dynamic> item,
                ) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: item,
                    child: Tooltip(
                      message: _getDisplayName(item, displayField),
                      child: Text(
                        _getDisplayName(item, displayField),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  );
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
                  color: _isLoading
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFF2264E5),
                  border: Border.all(
                    color: _isLoading
                        ? const Color(0xFFE5E7EB)
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
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6B7280),
                            ),
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
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
