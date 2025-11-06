import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/student_management/add_student_modal.dart';
import 'package:android_app/screens/admin/dashboard/student_management/edit_student_modal.dart';
import 'package:android_app/screens/admin/dashboard/student_management/import_excel_modal.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/models/student.dart' as student_model;

class StudentsManagementView extends StatefulWidget {
  const StudentsManagementView({super.key});

  @override
  State<StudentsManagementView> createState() => _StudentsManagementViewState();
}

class _StudentsManagementViewState extends State<StudentsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API data for students
  List<student_model.StudentModel> _students = [];
  bool _isLoading = false;
  int _totalStudents = 0;
  int _totalPages = 0;
  String? _errorMessage;

  // Cache for major and cohort names
  final Map<int, String> _majorCache = {};
  final Map<int, String> _cohortCache = {};

  // Track loading status to prevent infinite loops
  final Set<int> _loadingMajors = {};
  final Set<int> _loadingCohorts = {};

  final Set<int> _selectedStudents = <int>{};

  // Filter data
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _majors = [];
  List<Map<String, dynamic>> _cohorts = [];
  Map<String, dynamic>? _selectedFaculty;
  Map<String, dynamic>? _selectedMajor;
  Map<String, dynamic>? _selectedCohort;
  bool _isLoadingFilters = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadFaculties();
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
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getStudentsPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
        facultyId: _selectedFaculty?['id'],
        majorId: _selectedMajor?['id'],
        cohortId: _selectedCohort?['id'],
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
      );

      if (result.success && result.data != null) {
        setState(() {
          _students = result.data!.items
              .map((item) => student_model.StudentModel.fromJson(item))
              .toList();
          _totalStudents = result.data!.total;
          _totalPages = result.data!.totalPages;
          _isLoading = false;
          // Clear selections when loading new data (search/pagination)
          _selectedStudents.clear();
        });

        // Load major and cohort names after state is updated
        await _loadMajorAndCohortNames(_students);
        // Force UI update after names are loaded
        if (mounted) setState(() {});
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
          _selectedStudents.clear();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi tải dữ liệu sinh viên: ${e.toString()}';
        _selectedStudents.clear();
      });
    }
  }

  Future<void> _loadMajorAndCohortNames(
    List<student_model.StudentModel> students,
  ) async {
    // Get unique major and cohort IDs that we haven't cached yet
    final majorIds = students
        .where((s) => s.majorId != null)
        .map((s) => s.majorId!)
        .where((id) => !_majorCache.containsKey(id))
        .toSet();

    final cohortIds = students
        .where((s) => s.cohortId != null)
        .map((s) => s.cohortId!)
        .where((id) => !_cohortCache.containsKey(id))
        .toSet();

    // Load major names concurrently
    final majorFutures = majorIds.map((id) async {
      try {
        final result = await _apiService.getMajor(id);
        if (result.success && result.data != null) {
          if (mounted) {
            setState(() {
              _majorCache[id] = result.data!['name'] ?? 'Không xác định';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _majorCache[id] = 'Lỗi tải thông tin';
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _majorCache[id] = 'Lỗi kết nối';
          });
        }
      }
    });

    // Load cohort names concurrently
    final cohortFutures = cohortIds.map((id) async {
      try {
        final result = await _apiService.getCohort(id);
        if (result.success && result.data != null) {
          if (mounted) {
            setState(() {
              _cohortCache[id] =
                  result.data!['name'] ??
                  result.data!['year']?.toString() ??
                  'Không xác định';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _cohortCache[id] = 'Lỗi tải thông tin';
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _cohortCache[id] = 'Lỗi kết nối';
          });
        }
      }
    });

    await Future.wait([...majorFutures, ...cohortFutures]);
  }

  Future<void> _loadFaculties() async {
    setState(() {
      _isLoadingFilters = true;
    });

    try {
      final result = await _apiService.getFacultiesPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _faculties = result.data!.items;
        });
        // Load majors and cohorts after faculties are loaded
        await _loadMajors();
        await _loadCohorts();
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isLoadingFilters = false;
      });
    }
  }

  Future<void> _loadMajors({int? facultyId}) async {
    try {
      final result = await _apiService.getMajorsPaginated(
        limit: 100,
        facultyId: facultyId,
      );
      if (result.success && result.data != null) {
        setState(() {
          _majors = result.data!.items;
          // Reset selected major when faculty changes
          if (facultyId != null) {
            _selectedMajor = null;
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadCohorts() async {
    try {
      final result = await _apiService.getCohortsPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _cohorts = result.data!.items;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String _getMajorName(int? majorId) {
    if (majorId == null) return 'Chưa phân ngành';
    final cachedName = _majorCache[majorId];
    if (cachedName != null) return cachedName;

    // If not cached and not already loading, start loading in background
    if (!_loadingMajors.contains(majorId)) {
      _loadSingleMajor(majorId);
    }
    return 'Đang tải...';
  }

  String _getCohortName(int? cohortId) {
    if (cohortId == null) return 'Chưa phân khóa';
    final cachedName = _cohortCache[cohortId];
    if (cachedName != null) return cachedName;

    // If not cached and not already loading, start loading in background
    if (!_loadingCohorts.contains(cohortId)) {
      _loadSingleCohort(cohortId);
    }
    return 'Đang tải...';
  }

  Future<void> _loadSingleMajor(int majorId) async {
    if (_majorCache.containsKey(majorId) || _loadingMajors.contains(majorId)) {
      return;
    }

    _loadingMajors.add(majorId);

    try {
      final result = await _apiService.getMajor(majorId);
      if (result.success && result.data != null) {
        setState(() {
          _majorCache[majorId] = result.data!['name'] ?? 'Không xác định';
        });
      } else {
        setState(() {
          _majorCache[majorId] = 'Lỗi tải thông tin';
        });
      }
    } catch (e) {
      setState(() {
        _majorCache[majorId] = 'Lỗi kết nối';
      });
    } finally {
      _loadingMajors.remove(majorId);
    }
  }

  Future<void> _loadSingleCohort(int cohortId) async {
    if (_cohortCache.containsKey(cohortId) ||
        _loadingCohorts.contains(cohortId)) {
      return;
    }

    _loadingCohorts.add(cohortId);

    try {
      final result = await _apiService.getCohort(cohortId);
      if (result.success && result.data != null) {
        setState(() {
          _cohortCache[cohortId] =
              result.data!['name'] ??
              result.data!['year']?.toString() ??
              'Không xác định';
        });
      } else {
        setState(() {
          _cohortCache[cohortId] = 'Lỗi tải thông tin';
        });
      }
    } catch (e) {
      setState(() {
        _cohortCache[cohortId] = 'Lỗi kết nối';
      });
    } finally {
      _loadingCohorts.remove(cohortId);
    }
  }

  // Column configuration for students table
  static const List<TableColumn> _studentColumns = [
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
      type: TableColumnType.major,
      flex: 2,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.phone,
      flex: 2,
      textAlign: TextAlign.right,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.email,
      flex: 2,
      textAlign: TextAlign.right,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.birthDate,
      flex: 2,
      textAlign: TextAlign.right,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.course,
      flex: 2,
      textAlign: TextAlign.right,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.actions,
      flex: 2,
      textAlign: TextAlign.right,
    ),
  ];

  // Pagination getters and methods
  int get totalPages => _totalPages;

  // Since we're getting paginated data from API, just return current page data
  List<student_model.StudentModel> get currentPageStudents => _students;

  // Get current page as StudentData objects with sequential IDs
  List<StudentData> get currentPageStudentData {
    return _students.asMap().entries.map((entry) {
      final index = entry.key;
      final student = entry.value;
      final sequentialNumber = (_currentPage - 1) * _itemsPerPage + (index + 1);
      // Use global unique ID based on page and index (starting from 1000 to avoid conflicts)
      final uniqueApiId = 1000 + (_currentPage - 1) * _itemsPerPage + index;
      return _studentToStudentDataWithUniqueId(
        student,
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
      _loadStudents();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadStudents();
    }
  }

  // Convert StudentModel to StudentData with unique ID for UI
  StudentData _studentToStudentDataWithUniqueId(
    student_model.StudentModel student,
    int sequentialId,
    int uniqueId,
  ) {
    return StudentData(
      id: sequentialId, // Use sequential number for display
      code: student.studentCode,
      name: student.fullName,
      major: _getMajorName(student.majorId),
      phone: student.phone ?? '',
      email: student.email ?? '',
      birthDate: student.birthDate != null
          ? _formatDateForDisplay(student.birthDate!)
          : '',
      course: _getCohortName(student.cohortId),
      apiId: student.apiId ?? 0, // Store real API ID for operations
      // Additional fields for editing
      hometown: student.hometown,
      facultyId: student.facultyId,
      majorId: student.majorId,
      cohortId: student.cohortId,
      className: student.className,
    );
  }

  String _formatDateForDisplay(String apiDate) {
    try {
      // API returns date in YYYY-MM-DD format, convert to DD/MM/YYYY
      final parts = apiDate.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return apiDate;
    } catch (e) {
      return apiDate;
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
            'Bạn có chắc chắn muốn xóa ${_selectedStudents.length} sinh viên đã chọn? Hành động này không thể hoàn tác.',
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleDeleteSelectedStudents();
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

  Future<void> _handleDeleteSelectedStudents() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Convert selected API IDs to strings for deletion
      final selectedApiIds = _selectedStudents
          .map((apiId) => apiId.toString())
          .toList();

      // Delete students concurrently
      final futures = selectedApiIds.map((id) => _apiService.deleteStudent(id));
      final results = await Future.wait(futures);

      // Check if all deletions were successful
      final failedDeletions = results
          .where((result) => !result.success)
          .toList();

      if (failedDeletions.isEmpty) {
        // All deletions successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xóa ${selectedApiIds.length} sinh viên thành công!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear selections and reload data
        setState(() {
          _selectedStudents.clear();
        });

        // Reload current page
        await _loadStudents();

        // If current page is empty, go to previous page
        if (_students.isEmpty && _currentPage > 1) {
          setState(() {
            _currentPage--;
          });
          await _loadStudents();
        }
      } else {
        // Some deletions failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Xóa thành công ${selectedApiIds.length - failedDeletions.length}/${selectedApiIds.length} sinh viên. '
              'Một số sinh viên không thể xóa được.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        // Reload data to reflect changes
        await _loadStudents();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa sinh viên: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            'Quản lý sinh viên',
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
                    child: _selectedStudents.isEmpty
                        ? Row(
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
                              // Faculty filter dropdown
                              _buildFacultyDropdown(),
                              const SizedBox(width: 16),
                              // Major filter dropdown
                              _buildMajorDropdown(),
                              const SizedBox(width: 16),
                              // Cohort filter dropdown
                              _buildCohortDropdown(),
                              const Spacer(),

                              // Import Excel button
                              SizedBox(
                                height: 38,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) =>
                                          const ImportExcelModal(),
                                    );

                                    // Reload data if import was successful
                                    if (result == true) {
                                      _loadStudents();
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: const Text(
                                    'Nhập excel',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.28,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF46E522),
                                    foregroundColor: Colors.black,
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
                              const SizedBox(width: 12),
                              // Add student button
                              SizedBox(
                                height: 38,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) =>
                                          const AddStudentModal(),
                                    );

                                    // Reload data if student was added successfully
                                    if (result == true) {
                                      _loadStudents();
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text(
                                    'Thêm sinh viên',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.28,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2264E5),
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
                          )
                        : Row(
                            children: [
                              // Selected items count
                              Text(
                                '${_selectedStudents.length} sinh viên đã chọn',
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
                    child: Column(
                      children: [
                        // Fixed Table header
                        Container(
                          color: const Color(0xFFF9FAFC),
                          child: _buildTableHeader(),
                        ),

                        // Table rows - using Flexible to prevent overflow
                        Flexible(
                          child: _isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _errorMessage != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: Colors.red[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Lỗi: $_errorMessage',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.red,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadStudents,
                                          child: const Text('Thử lại'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // Table rows
                                      ...List.generate(_itemsPerPage, (index) {
                                        if (index <
                                            currentPageStudentData.length) {
                                          final student =
                                              currentPageStudentData[index];
                                          final isEven = index % 2 == 0;
                                          return _buildTableRow(
                                            student,
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
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageStudents.length} of $_totalStudents',
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
                                          ),
                                          const BoxShadow(
                                            color: Color(0xFF000000),
                                            blurRadius: 1,
                                            offset: Offset(0, 1),
                                            spreadRadius: 0.1,
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

  Widget _buildFacultyDropdown() {
    return Container(
      height: 38,
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
            'Lọc theo khoa',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA1A9B8),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF717680),
          ),
          onChanged: _isLoadingFilters
              ? null
              : (Map<String, dynamic>? newValue) {
                  setState(() {
                    _selectedFaculty = newValue;
                    _selectedMajor = null; // Reset major when faculty changes
                    _currentPage = 1; // Reset to first page when filtering
                  });
                  if (newValue != null) {
                    _loadMajors(facultyId: newValue['id']);
                  } else {
                    _loadMajors();
                  }
                  _loadStudents(); // Reload students with new filter
                },
          items: [
            const DropdownMenuItem<Map<String, dynamic>>(
              value: null,
              child: Text(
                'Tất cả khoa',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1D29),
                ),
              ),
            ),
            ..._faculties.map((faculty) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: faculty,
                child: Text(
                  faculty['name'] ?? 'Không xác định',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1A1D29),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMajorDropdown() {
    return Container(
      height: 38,
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
          value: _selectedMajor,
          hint: const Text(
            'Lọc theo ngành',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA1A9B8),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF717680),
          ),
          onChanged: _isLoadingFilters
              ? null
              : (Map<String, dynamic>? newValue) {
                  setState(() {
                    _selectedMajor = newValue;
                    _currentPage = 1; // Reset to first page when filtering
                  });
                  _loadStudents(); // Reload students with new filter
                },
          items: [
            const DropdownMenuItem<Map<String, dynamic>>(
              value: null,
              child: Text(
                'Tất cả ngành',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1D29),
                ),
              ),
            ),
            ..._majors.map((major) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: major,
                child: Text(
                  major['name'] ?? 'Không xác định',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1A1D29),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCohortDropdown() {
    return Container(
      height: 38,
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
            'Lọc theo khóa',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA1A9B8),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF717680),
          ),
          onChanged: _isLoadingFilters
              ? null
              : (Map<String, dynamic>? newValue) {
                  setState(() {
                    _selectedCohort = newValue;
                    _currentPage = 1; // Reset to first page when filtering
                  });
                  _loadStudents(); // Reload students with new filter
                },
          items: [
            const DropdownMenuItem<Map<String, dynamic>>(
              value: null,
              child: Text(
                'Tất cả khóa',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1D29),
                ),
              ),
            ),
            ..._cohorts.map((cohort) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: cohort,
                child: Text(
                  cohort['name'] ??
                      cohort['year']?.toString() ??
                      'Không xác định',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1A1D29),
                  ),
                ),
              );
            }),
          ],
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
                  value: currentPageStudentData.every(
                    (student) => _selectedStudents.contains(student.apiId),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedStudents.addAll(
                          currentPageStudentData.map((t) => t.apiId),
                        );
                      } else {
                        for (final student in currentPageStudentData) {
                          _selectedStudents.remove(student.apiId);
                        }
                      }
                    });
                  },
                ),
              ),

              // # chiếm 1 phần
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

              // Mã SV chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'MÃ SV',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Tên chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'TÊN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Ngành chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'NGÀNH',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Số điện thoại chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'SỐ ĐIỆN THOẠI',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Email chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'EMAIL',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Ngày sinh chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'NGÀY SINH',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Khóa chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'KHÓA',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Hành động chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'HÀNH ĐỘNG',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableRow(StudentData student, bool isEven) {
    final isSelected = _selectedStudents.contains(student.apiId);

    return DataTableRow<StudentData>(
      data: student,
      isEven: isEven,
      isSelected: isSelected,
      columns: _studentColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedStudents.remove(student.apiId);
          } else {
            _selectedStudents.add(student.apiId);
          }
        });
      },
      onEdit: () {
        showDialog(
          context: context,
          builder: (context) => EditStudentModal(student: student),
        );
      },
      onDelete: () async {
        // Delete individual student - use API ID for actual deletion
        try {
          final result = await _apiService.deleteStudentById(student.apiId);
          if (result.success) {
            _loadStudents(); // Reload data
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa sinh viên thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('API Error: ${result.message}');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi xóa: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}

class StudentData implements StudentTableRowData {
  @override
  final int id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String major;
  @override
  final String phone;
  @override
  final String email;
  @override
  final String birthDate;
  @override
  final String course;

  final int apiId; // Store original API ID for operations

  // Additional fields for editing
  final String? hometown;
  final int? facultyId;
  final int? majorId;
  final int? cohortId;
  final String className;

  StudentData({
    required this.id,
    required this.code,
    required this.name,
    required this.major,
    required this.phone,
    required this.email,
    required this.birthDate,
    required this.course,
    required this.apiId,
    this.hometown,
    this.facultyId,
    this.majorId,
    this.cohortId,
    required this.className,
  });
}
