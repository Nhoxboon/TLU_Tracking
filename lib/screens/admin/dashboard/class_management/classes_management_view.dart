import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/class_management/add_class_modal.dart';
import 'package:android_app/screens/admin/dashboard/class_management/edit_class_modal.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/models/api_models.dart';

class ClassesManagementView extends StatefulWidget {
  const ClassesManagementView({super.key});

  @override
  State<ClassesManagementView> createState() => _ClassesManagementViewState();
}

class _ClassesManagementViewState extends State<ClassesManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API data for classes
  List<ClassItem> _classes = [];
  bool _isLoading = false;
  int _totalClasses = 0;
  int _totalPages = 0;
  String? _errorMessage;

  // Cache for related data
  final Map<int, String> _teacherCache = {};
  final Map<int, String> _departmentCache = {};
  final Map<int, String> _subjectCache = {};
  final Map<int, String> _cohortCache = {};

  // Mapping from uniqueId to original class ID for API operations
  final Map<int, int> _classIdMapping = {};

  final Set<int> _selectedClasses = <int>{};

  // Filter data
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _cohorts = [];
  List<Map<String, dynamic>> _studyPhases = [];
  List<Map<String, dynamic>> _semesters = [];
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _classCodes = [];

  // Selected filters
  Map<String, dynamic>? _selectedTeacher;
  Map<String, dynamic>? _selectedSubject;
  Map<String, dynamic>? _selectedDepartment;
  Map<String, dynamic>? _selectedFaculty;
  Map<String, dynamic>? _selectedCohort;
  Map<String, dynamic>? _selectedStudyPhase;
  Map<String, dynamic>? _selectedSemester;
  Map<String, dynamic>? _selectedAcademicYear;
  Map<String, dynamic>? _selectedClassCode;

  // Column configuration for classes table
  static const List<TableColumn> _classColumns = [
    TableColumn(
      type: TableColumnType.id,
      flex: 1,
      styleType: TableColumnStyleType.primary,
    ),
    TableColumn(
      type: TableColumnType.code,
      flex: 2,
      styleType: TableColumnStyleType.primary,
    ),
    TableColumn(
      type: TableColumnType.name,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.creationDate,
      flex: 2,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.teacher,
      flex: 2,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.department,
      flex: 2,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.subject,
      flex: 2,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.course,
      flex: 1,
      textAlign: TextAlign.right,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.actions,
      flex: 2,
      textAlign: TextAlign.right,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadFilters();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search
    if (_searchController.text.length >= 3 || _searchController.text.isEmpty) {
      setState(() {
        _currentPage = 1; // Reset to first page when searching
      });
      _loadClasses();
    }
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getClassesPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
        teacherId: _selectedTeacher?['id'],
        subjectId: _selectedSubject?['id'],
        facultyId: _selectedFaculty?['id'],
        departmentId: _selectedDepartment?['id'],
        cohortId: _selectedCohort?['id'],
        academicYearId: _selectedAcademicYear?['id'],
        semesterId: _selectedSemester?['id'],
        studyPhaseId: _selectedStudyPhase?['id'],
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
      );

      if (result.success && result.data != null) {
        // Convert Map<String, dynamic> to ClassItem objects
        var classes = result.data!.items
            .map((item) => ClassItem.fromJson(item))
            .toList();

        // Apply client-side class code filter if selected
        if (_selectedClassCode != null) {
          final selectedCode = _selectedClassCode!['code'] as String;
          classes = classes
              .where((classItem) => classItem.code == selectedCode)
              .toList();
        }

        // Load related data for classes
        await _loadRelatedData(classes);

        setState(() {
          _classes = classes;
          // Adjust total counts when class code filter is applied
          if (_selectedClassCode != null) {
            _totalClasses = classes.length;
            _totalPages = (_totalClasses / _itemsPerPage).ceil();
          } else {
            _totalClasses = result.data!.total;
            _totalPages = result.data!.totalPages;
          }
          _isLoading = false;
          // Clear selections and mappings when loading new data
          _selectedClasses.clear();
          _classIdMapping.clear();
        });

        // Extract class codes from loaded classes
        _extractClassCodesFromExistingClasses();
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
          _classes = [];
          _selectedClasses.clear();
          _classIdMapping.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
        _isLoading = false;
        _classes = [];
        _selectedClasses.clear();
        _classIdMapping.clear();
      });
    }
  }

  Future<void> _loadRelatedData(List<ClassItem> classes) async {
    // Get unique IDs that we haven't cached yet
    final teacherIds = classes
        .where((cls) => cls.teacherId != null)
        .map((cls) => cls.teacherId!)
        .where((id) => !_teacherCache.containsKey(id))
        .toSet();

    final departmentIds = classes
        .where((cls) => cls.departmentId != null)
        .map((cls) => cls.departmentId!)
        .where((id) => !_departmentCache.containsKey(id))
        .toSet();

    final subjectIds = classes
        .where((cls) => cls.subjectId != null)
        .map((cls) => cls.subjectId!)
        .where((id) => !_subjectCache.containsKey(id))
        .toSet();

    final cohortIds = classes
        .where((cls) => cls.cohortId != null)
        .map((cls) => cls.cohortId!)
        .where((id) => !_cohortCache.containsKey(id))
        .toSet();

    // Load data concurrently
    final futures = <Future>[];

    // Load teachers
    futures.addAll(
      teacherIds.map((id) async {
        try {
          final result = await _apiService.getTeacherById(id);
          if (result.success && result.data != null) {
            _teacherCache[id] = result.data!['full_name'] ?? 'Không xác định';
          } else {
            _teacherCache[id] = 'Lỗi tải thông tin';
          }
        } catch (e) {
          _teacherCache[id] = 'Lỗi kết nối';
        }
      }),
    );

    // Load departments
    futures.addAll(
      departmentIds.map((id) async {
        try {
          final result = await _apiService.getDepartment(id);
          if (result.success && result.data != null) {
            _departmentCache[id] = result.data!['name'] ?? 'Không xác định';
          } else {
            _departmentCache[id] = 'Lỗi tải thông tin';
          }
        } catch (e) {
          _departmentCache[id] = 'Lỗi kết nối';
        }
      }),
    );

    // Load subjects
    futures.addAll(
      subjectIds.map((id) async {
        try {
          final result = await _apiService.getSubjectById(id);
          if (result.success && result.data != null) {
            _subjectCache[id] = result.data!['name'] ?? 'Không xác định';
          } else {
            _subjectCache[id] = 'Lỗi tải thông tin';
          }
        } catch (e) {
          _subjectCache[id] = 'Lỗi kết nối';
        }
      }),
    );

    // Load cohorts
    futures.addAll(
      cohortIds.map((id) async {
        try {
          final result = await _apiService.getCohort(id);
          if (result.success && result.data != null) {
            _cohortCache[id] = result.data!['name'] ?? 'Không xác định';
          } else {
            _cohortCache[id] = 'Lỗi tải thông tin';
          }
        } catch (e) {
          _cohortCache[id] = 'Lỗi kết nối';
        }
      }),
    );

    await Future.wait(futures);
  }

  String _getTeacherName(int? teacherId) {
    if (teacherId == null) return 'Chưa phân giảng viên';
    final cachedName = _teacherCache[teacherId];
    if (cachedName != null) return cachedName;
    return 'Đang tải...';
  }

  String _getDepartmentName(int? departmentId) {
    if (departmentId == null) return 'Chưa phân bộ môn';
    final cachedName = _departmentCache[departmentId];
    if (cachedName != null) return cachedName;
    return 'Đang tải...';
  }

  String _getSubjectName(int? subjectId) {
    if (subjectId == null) return 'Chưa phân môn học';
    final cachedName = _subjectCache[subjectId];
    if (cachedName != null) return cachedName;
    return 'Đang tải...';
  }

  String _getCohortName(int? cohortId) {
    if (cohortId == null) return 'Chưa phân khóa';
    final cachedName = _cohortCache[cohortId];
    if (cachedName != null) return cachedName;
    return 'Đang tải...';
  }

  Future<void> _loadFilters() async {
    setState(() {});

    try {
      // Load all filter data concurrently
      final futures = [
        _apiService.getFacultiesPaginated(limit: 100),
        _apiService.getDepartmentsPaginated(limit: 100),
        _apiService.getTeachersPaginated(limit: 100),
        _apiService.getSubjectsPaginated(limit: 100),
        _apiService.getCohortsPaginated(limit: 100),
        _apiService.getAcademicYearsPaginated(limit: 100),
        _apiService.getSemestersPaginated(limit: 100),
        _apiService.getStudyPhasesPaginated(limit: 100),
      ];

      final results = await Future.wait(futures);

      setState(() {
        if (results[0].success && results[0].data != null) {
          _faculties = results[0].data!.items;
        }
        if (results[1].success && results[1].data != null) {
          _departments = results[1].data!.items;
        }
        if (results[2].success && results[2].data != null) {
          _teachers = results[2].data!.items;
        }
        if (results[3].success && results[3].data != null) {
          _subjects = results[3].data!.items;
        }
        if (results[4].success && results[4].data != null) {
          _cohorts = results[4].data!.items;
        }
        if (results[5].success && results[5].data != null) {
          _academicYears = results[5].data!.items;
        }
        if (results[6].success && results[6].data != null) {
          _semesters = results[6].data!.items;
        }
        if (results[7].success && results[7].data != null) {
          _studyPhases = results[7].data!.items;
        }
      });

      // Load additional cascaded data after main data is loaded
      if (_faculties.isNotEmpty) {
        _loadDepartments(); // Load all departments initially
      }
      if (_academicYears.isNotEmpty) {
        _loadSemesters(); // Load all semesters initially
      }

      // Class codes will be loaded when classes are loaded
    } catch (e) {
      setState(() {});
    }
  }

  void _onFilterChanged() {
    setState(() {
      _currentPage = 1; // Reset to first page when filter changes
    });
    _loadClasses();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTeacher = null;
      _selectedSubject = null;
      _selectedDepartment = null;
      _selectedFaculty = null;
      _selectedCohort = null;
      _selectedStudyPhase = null;
      _selectedSemester = null;
      _selectedAcademicYear = null;
      _selectedClassCode = null;
      _currentPage = 1;
    });
    // Reload cascaded data when clearing filters
    _loadDepartments(); // Load all departments
    _loadSemesters(); // Load all semesters
    _loadClasses();
  }

  // Cascade loading methods (similar to teachers_management_view)
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

  void _extractClassCodesFromExistingClasses() {
    final uniqueCodes = <String, Map<String, dynamic>>{};
    for (final classItem in _classes) {
      final code = classItem.code.trim();
      if (code.isNotEmpty) {
        uniqueCodes[code] = {'id': code, 'name': code, 'code': code};
      }
    }
    setState(() {
      _classCodes = uniqueCodes.values.toList();
      _classCodes.sort(
        (a, b) => (a['code'] as String).compareTo(b['code'] as String),
      );
    });
  }

  // Pagination getters and methods
  int get totalPages => _totalPages;

  // Since we're getting paginated data from API, just return current page data
  List<ClassItem> get currentPageClasses => _classes;

  // Get current page as ClassData objects with sequential IDs
  List<ClassData> get currentPageClassData {
    return _classes.asMap().entries.map((entry) {
      final index = entry.key;
      final classItem = entry.value;
      final sequentialNumber = (_currentPage - 1) * _itemsPerPage + (index + 1);
      // Use global unique ID based on page and index (starting from 1000 to avoid conflicts)
      final uniqueApiId = 1000 + (_currentPage - 1) * _itemsPerPage + index;
      return _classToClassDataWithUniqueId(
        classItem,
        sequentialNumber,
        uniqueApiId,
      );
    }).toList();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadClasses();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadClasses();
    }
  }

  // Convert ClassItem model to ClassData with unique ID for UI
  ClassData _classToClassDataWithUniqueId(
    ClassItem classItem,
    int sequentialId,
    int uniqueId,
  ) {
    // Store mapping from uniqueId to real API class ID for API operations
    _classIdMapping[uniqueId] = classItem.id;

    return ClassData(
      id: sequentialId, // Use sequential number for display
      code: classItem.code,
      name: classItem.name,
      teacher: _getTeacherName(classItem.teacherId),
      department: _getDepartmentName(classItem.departmentId),
      subject: _getSubjectName(classItem.subjectId),
      course: _getCohortName(classItem.cohortId),
      creationDate: classItem.createdAt != null
          ? _formatDate(classItem.createdAt!)
          : 'Không xác định',
      apiId: uniqueId, // Use unique ID for selection
      teacherId: classItem.teacherId,
      departmentId: classItem.departmentId,
      subjectId: classItem.subjectId,
      cohortId: classItem.cohortId,
      facultyId: classItem.facultyId,
      majorId: classItem.majorId,
      academicYearId: classItem.academicYearId,
      semesterId: classItem.semesterId,
      studyPhaseId: classItem.studyPhaseId,
      status: classItem.status,
    );
  }

  String _formatDate(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Không xác định';
    }
  }

  Future<void> _handleDeleteSelectedClasses() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the real API IDs for selected classes
      final selectedApiIds = _selectedClasses
          .map((uniqueId) => _classIdMapping[uniqueId])
          .where((id) => id != null)
          .cast<int>()
          .toList();

      // Delete classes concurrently
      final futures = selectedApiIds.map((id) {
        return _apiService.deleteClass(id);
      });
      final results = await Future.wait(futures);

      // Check if all deletions were successful
      final failedDeletions = results
          .where((result) => !result.success)
          .toList();

      setState(() {
        _isLoading = false;
      });

      if (failedDeletions.isEmpty) {
        // All deletions successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã xóa thành công ${selectedApiIds.length} lớp học',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear selections and reload data
        setState(() {
          _selectedClasses.clear();
        });

        // Reload current page
        await _loadClasses();

        // If current page is empty, go to previous page
        if (_classes.isEmpty && _currentPage > 1) {
          setState(() {
            _currentPage--;
          });
          await _loadClasses();
        }
      } else {
        // Some deletions failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã xóa thành công ${selectedApiIds.length - failedDeletions.length}/${selectedApiIds.length} lớp học. ${failedDeletions.length} lớp học không thể xóa.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Reload data to reflect changes
        await _loadClasses();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi xóa lớp học: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa lớp học: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'Xác nhận xóa',
            style: TextStyle(
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1F2937),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa ${_selectedClasses.length} lớp học đã chọn? Hành động này không thể hoàn tác.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeleteSelectedClasses();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Xóa',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6FA),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Quản lý lớp học',
            style: TextStyle(
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
              fontSize: 32,
              letterSpacing: -0.11,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 27),

          // Data table container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                  BoxShadow(
                    color: const Color(0xFF454B57).withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: const Color(0xFF98A1B2).withValues(alpha: 0.1),
                    offset: const Offset(0, 0),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Action bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: _selectedClasses.isEmpty
                        ? Column(
                            children: [
                              // First row: Search and primary filters
                              Row(
                                children: [
                                  // Search field
                                  CustomSearchBar(
                                    controller: _searchController,
                                    hintText: 'Tìm kiếm...',
                                    onChanged: (value) {
                                      // Handle search logic here
                                      setState(() {
                                        // Reset to first page when searching
                                        _currentPage = 1;
                                      });
                                    },
                                    onClear: () {
                                      setState(() {
                                        _currentPage = 1;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 16),

                                  // Filter dropdowns - Row 1
                                  _buildClassCodeDropdown(),
                                  const SizedBox(width: 16),
                                  _buildFacultyDropdown(),
                                  const SizedBox(width: 16),
                                  _buildDepartmentDropdown(),
                                  const SizedBox(width: 16),
                                  _buildTeacherDropdown(),
                                  const SizedBox(width: 16),
                                  _buildSubjectDropdown(),
                                  const Spacer(),

                                  // Add class button
                                  SizedBox(
                                    height: 38,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AddClassModal(
                                            onSuccess: () {
                                              // Refresh danh sách classes khi tạo thành công
                                              _loadClasses();
                                            },
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text(
                                        'Thêm lớp học',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.28,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2264E5,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Second row: Additional filters
                              Row(
                                children: [
                                  _buildCohortDropdown(),
                                  const SizedBox(width: 16),
                                  _buildAcademicYearDropdown(),
                                  const SizedBox(width: 16),
                                  _buildSemesterDropdown(),
                                  const SizedBox(width: 16),
                                  _buildStudyPhaseDropdown(),
                                  const SizedBox(width: 16),
                                  // Clear filters button
                                  SizedBox(
                                    height: 38,
                                    child: OutlinedButton.icon(
                                      onPressed: _clearAllFilters,
                                      icon: const Icon(Icons.clear, size: 16),
                                      label: const Text('Xóa bộ lọc'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF6B7280,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFE5E7EB),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              // Selected items count
                              Text(
                                '${_selectedClasses.length} lớp học đã chọn',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const Spacer(),
                              // Delete button
                              SizedBox(
                                height: 38,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showDeleteConfirmationDialog();
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Xóa',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.28,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Divider
                  Container(height: 1, color: const Color(0xFFE9EDF5)),

                  // Table
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadClasses,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Fixed Table header
                              Container(
                                color: const Color(0xFFF9FAFC),
                                child: _buildTableHeader(),
                              ),

                              // Table rows - using Flexible to prevent overflow
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // Table rows
                                      ...List.generate(_itemsPerPage, (index) {
                                        if (index <
                                            currentPageClassData.length) {
                                          final classData =
                                              currentPageClassData[index];
                                          final isEven = index % 2 == 0;
                                          return _buildTableRow(
                                            classData,
                                            isEven,
                                          );
                                        } else {
                                          // Empty row to maintain consistent height
                                          return Container(
                                            height: 64,
                                            color: index % 2 == 0
                                                ? Colors.white
                                                : const Color(0xFFF9FAFC),
                                          );
                                        }
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Pagination
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FC).withValues(alpha: .75),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side: Items count
                        Text(
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageClassData.length} of $_totalClasses',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.36,
                            color: Color(0xFF687182),
                          ),
                        ),

                        // Right side: Navigation controls
                        Row(
                          children: [
                            // Previous button
                            InkWell(
                              onTap: _currentPage > 1
                                  ? _goToPreviousPage
                                  : null,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 24,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _currentPage > 1
                                      ? const Color(0xFFF7F9FC)
                                      : const Color(
                                          0xFFF7F9FC,
                                        ).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF464F60,
                                    ).withValues(alpha: .24),
                                  ),
                                ),
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 16,
                                  color: _currentPage > 1
                                      ? const Color(0xFF464F60)
                                      : const Color(0xFF868FA0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$_currentPage/$totalPages',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.36,
                                color: Color(0xFF687182),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Next button
                            InkWell(
                              onTap: _currentPage < totalPages
                                  ? _goToNextPage
                                  : null,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 24,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _currentPage < totalPages
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: _currentPage < totalPages
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF596078,
                                            ).withValues(alpha: 0.1),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                          BoxShadow(
                                            color: const Color(
                                              0xFF464F60,
                                            ).withValues(alpha: 0.16),
                                            offset: const Offset(0, 0),
                                            spreadRadius: 1,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 1,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: _currentPage < totalPages
                                      ? const Color(0xFF464F60)
                                      : const Color(0xFF868FA0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCodeDropdown() {
    return SizedBox(
      width: 200,
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF687182).withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _selectedClassCode,
            hint: const Text(
              'Mã lớp',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA1A9B8),
              ),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF717680),
            ),
            items: [
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text(
                  'Tất cả mã lớp',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ..._classCodes.map(
                (classCode) => DropdownMenuItem<Map<String, dynamic>>(
                  value: classCode,
                  child: Text(
                    classCode['code'] ?? 'Không có mã',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (Map<String, dynamic>? value) {
              setState(() {
                _selectedClassCode = value;
              });
              _onFilterChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFacultyDropdown() {
    return SizedBox(
      width: 200,
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF687182).withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _selectedFaculty,
            hint: const Text(
              'Chọn khoa',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA1A9B8),
              ),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF717680),
            ),
            items: [
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text(
                  'Tất cả khoa',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ..._faculties.map(
                (faculty) => DropdownMenuItem<Map<String, dynamic>>(
                  value: faculty,
                  child: Text(
                    faculty['name'] ?? 'Không tên',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (Map<String, dynamic>? value) {
              setState(() {
                _selectedFaculty = value;
                // Clear dependent selections
                _selectedDepartment = null;
              });
              // Load departments for selected faculty
              if (value != null) {
                _loadDepartments(facultyId: value['id']);
              } else {
                _loadDepartments();
              }
              _onFilterChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return SizedBox(
      width: 200,
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF687182).withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _selectedDepartment,
            hint: const Text(
              'Chọn bộ môn',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA1A9B8),
              ),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF717680),
            ),
            items: [
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text(
                  'Tất cả bộ môn',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ..._departments
                  .where(
                    (dept) =>
                        _selectedFaculty == null ||
                        dept['faculty_id'] == _selectedFaculty?['id'],
                  )
                  .map(
                    (department) => DropdownMenuItem<Map<String, dynamic>>(
                      value: department,
                      child: Text(
                        department['name'] ?? 'Không tên',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
            ],
            onChanged: (Map<String, dynamic>? value) {
              setState(() {
                _selectedDepartment = value;
              });
              _onFilterChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherDropdown() {
    return SizedBox(
      width: 200,
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF687182).withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _selectedTeacher,
            hint: const Text(
              'Chọn giảng viên',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA1A9B8),
              ),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF717680),
            ),
            items: [
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text(
                  'Tất cả giảng viên',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ..._teachers.map(
                (teacher) => DropdownMenuItem<Map<String, dynamic>>(
                  value: teacher,
                  child: Text(
                    teacher['full_name'] ?? 'Không tên',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (Map<String, dynamic>? value) {
              setState(() {
                _selectedTeacher = value;
              });
              _onFilterChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return SizedBox(
      width: 200,
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF687182).withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _selectedSubject,
            hint: const Text(
              'Chọn môn học',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA1A9B8),
              ),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF717680),
            ),
            items: [
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text(
                  'Tất cả môn học',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ..._subjects.map(
                (subject) => DropdownMenuItem<Map<String, dynamic>>(
                  value: subject,
                  child: Text(
                    subject['name'] ?? 'Không tên',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (Map<String, dynamic>? value) {
              setState(() {
                _selectedSubject = value;
              });
              _onFilterChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCohortDropdown() {
    return SizedBox(
      width: 150,
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF687182).withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _selectedCohort,
            hint: const Text(
              'Chọn khóa',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA1A9B8),
              ),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF717680),
            ),
            items: [
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text(
                  'Tất cả khóa',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ..._cohorts.map(
                (cohort) => DropdownMenuItem<Map<String, dynamic>>(
                  value: cohort,
                  child: Text(
                    cohort['name'] ?? 'Không tên',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (Map<String, dynamic>? value) {
              setState(() {
                _selectedCohort = value;
              });
              _onFilterChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicYearDropdown() {
    return SizedBox(
      width: 150,
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF687182).withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _selectedAcademicYear,
            hint: const Text(
              'Năm học',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA1A9B8),
              ),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF717680),
            ),
            items: [
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text(
                  'Tất cả năm học',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ..._academicYears.map(
                (year) => DropdownMenuItem<Map<String, dynamic>>(
                  value: year,
                  child: Text(
                    year['name'] ?? 'Không tên',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (Map<String, dynamic>? value) {
              setState(() {
                _selectedAcademicYear = value;
                // Clear dependent selections
                _selectedSemester = null;
                _selectedStudyPhase = null;
              });
              // Load semesters for selected academic year
              if (value != null) {
                _loadSemesters(academicYearId: value['id']);
              } else {
                _loadSemesters();
              }
              _onFilterChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterDropdown() {
    return SizedBox(
      width: 150,
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF687182).withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _selectedSemester,
            hint: const Text(
              'Học kì',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA1A9B8),
              ),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF717680),
            ),
            items: [
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text(
                  'Tất cả học kì',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ..._semesters
                  .where(
                    (semester) =>
                        _selectedAcademicYear == null ||
                        semester['academic_year_id'] ==
                            _selectedAcademicYear?['id'],
                  )
                  .map(
                    (semester) => DropdownMenuItem<Map<String, dynamic>>(
                      value: semester,
                      child: Text(
                        semester['name'] ?? 'Không tên',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
            ],
            onChanged: (Map<String, dynamic>? value) {
              setState(() {
                _selectedSemester = value;
                // Clear dependent selections
                _selectedStudyPhase = null;
              });
              // Load study phases for selected semester
              if (value != null) {
                _loadStudyPhases(semesterId: value['id']);
              } else {
                _loadStudyPhases();
              }
              _onFilterChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStudyPhaseDropdown() {
    return SizedBox(
      width: 150,
      height: 38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF687182).withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _selectedStudyPhase,
            hint: const Text(
              'Đợt học',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA1A9B8),
              ),
            ),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF717680),
            ),
            items: [
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text(
                  'Tất cả đợt học',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              ..._studyPhases
                  .where(
                    (phase) =>
                        _selectedSemester == null ||
                        phase['semester_id'] == _selectedSemester?['id'],
                  )
                  .map(
                    (phase) => DropdownMenuItem<Map<String, dynamic>>(
                      value: phase,
                      child: Text(
                        phase['name'] ?? 'Không tên',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
            ],
            onChanged: (Map<String, dynamic>? value) {
              setState(() {
                _selectedStudyPhase = value;
              });
              _onFilterChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFFF9FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Checkbox (fix nhỏ)
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: currentPageClassData.every(
                    (classData) => _selectedClasses.contains(classData.apiId),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedClasses.addAll(
                          currentPageClassData.map((c) => c.apiId),
                        );
                      } else {
                        for (final classData in currentPageClassData) {
                          _selectedClasses.remove(classData.apiId);
                        }
                      }
                    });
                  },
                ),
              ),

              // ID (#) chiếm 1 phần
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    const Text(
                      '#',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.44,
                        color: Color(0xFF171C26),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Sort icons
                    Column(
                      children: [
                        Container(
                          width: 7,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF171C26),
                            borderRadius: BorderRadius.all(
                              Radius.circular(0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_up,
                            size: 4,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 7,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFBCC2CE),
                            borderRadius: BorderRadius.all(
                              Radius.circular(0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Mã lớp chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'MÃ LỚP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Tên lớp chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'TÊN LỚP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Ngày tạo chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'NGÀY TẠO',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Giảng viên chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'GIẢNG VIÊN',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Bộ môn chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'BỘ MÔN',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Môn học chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'MÔN HỌC',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Khóa chiếm 1 phần
              Expanded(
                flex: 1,
                child: Text(
                  'KHÓA',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Hành động chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'HÀNH ĐỘNG',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableRow(ClassData classData, bool isEven) {
    final isSelected = _selectedClasses.contains(classData.apiId);

    return GestureDetector(
      onDoubleTap: () {
        // Navigate to class students view
        Navigator.pushNamed(
          context,
          '/class-students',
          arguments: {
            'classId': _classIdMapping[classData.apiId] ?? classData.apiId,
            'classCode': classData.code,
            'className': classData.name,
          },
        );
      },
      child: DataTableRow<ClassData>(
        data: classData,
        isEven: isEven,
        isSelected: isSelected,
        columns: _classColumns,
        onSelectionChanged: () {
          setState(() {
            if (isSelected) {
              _selectedClasses.remove(classData.apiId);
            } else {
              _selectedClasses.add(classData.apiId);
            }
          });
        },
        onEdit: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => EditClassModal(classData: classData),
          );

          // Refresh data if class was updated
          if (result == true) {
            _loadClasses();
          }
        },
        onDelete: () async {
          // Delete individual class - use original class ID for actual deletion
          try {
            final realClassId = _classIdMapping[classData.apiId];
            if (realClassId != null) {
              final result = await _apiService.deleteClass(realClassId);
              if (result.success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa lớp học thành công')),
                  );
                }
                _loadClasses(); // Refresh the list
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi xóa lớp học: ${result.message}'),
                    ),
                  );
                }
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi xóa lớp học: ${e.toString()}')),
              );
            }
          }
        },
      ),
    );
  }
}

class ClassData implements ClassTableRowData {
  @override
  final int id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String teacher;
  @override
  final String department;
  @override
  final String subject;
  @override
  final String course;
  @override
  final String creationDate;

  // Required fields from TableRowData interface
  @override
  String get phone => '';
  @override
  String get email => '';
  @override
  String get birthDate => creationDate;

  // Additional fields for API operations
  final int apiId; // Store unique ID for selection
  final int? teacherId;
  final int? departmentId;
  final int? subjectId;
  final int? cohortId;
  final int? facultyId;
  final int? majorId;
  final int? academicYearId;
  final int? semesterId;
  final int? studyPhaseId;
  final String? status;

  ClassData({
    required this.id,
    required this.code,
    required this.name,
    required this.teacher,
    required this.department,
    required this.subject,
    required this.course,
    required this.creationDate,
    required this.apiId,
    this.teacherId,
    this.departmentId,
    this.subjectId,
    this.cohortId,
    this.facultyId,
    this.majorId,
    this.academicYearId,
    this.semesterId,
    this.studyPhaseId,
    this.status,
  });
}
