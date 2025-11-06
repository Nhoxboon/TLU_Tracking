import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/teacher_management/add_teacher_modal.dart';
import 'package:android_app/screens/admin/dashboard/teacher_management/edit_teacher_modal.dart';
import 'package:android_app/screens/admin/dashboard/teacher_management/import_excel_modal.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/models/teacher.dart' as teacher_model;

class TeachersManagementView extends StatefulWidget {
  const TeachersManagementView({super.key});

  @override
  State<TeachersManagementView> createState() => _TeachersManagementViewState();
}

class _TeachersManagementViewState extends State<TeachersManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API data for teachers
  List<teacher_model.Teacher> _teachers = [];
  bool _isLoading = false;
  int _totalTeachers = 0;
  int _totalPages = 0;
  String? _errorMessage;

  // Cache for department names
  final Map<int, String> _departmentCache = {};

  final Set<int> _selectedTeachers = <int>{};

  // Filter data
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _departments = [];
  Map<String, dynamic>? _selectedFaculty;
  Map<String, dynamic>? _selectedDepartment;
  bool _isLoadingFilters = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
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
      _loadTeachers();
    }
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getTeachersPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
        facultyId: _selectedFaculty?['id'],
        departmentId: _selectedDepartment?['id'],
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
      );

      if (result.success && result.data != null) {
        // Convert Map<String, dynamic> to Teacher objects
        final teachers = result.data!.items
            .map((item) => teacher_model.Teacher.fromJson(item))
            .toList();

        // Load department names for teachers that have department_id
        await _loadDepartmentNames(teachers);

        setState(() {
          _teachers = teachers;
          _totalTeachers = result.data!.total;
          _totalPages = result.data!.totalPages;
          _isLoading = false;
          // Clear selections when loading new data (search/pagination)
          _selectedTeachers.clear();
        });
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
          _teachers = [];
          _selectedTeachers.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
        _isLoading = false;
        _teachers = [];
        _selectedTeachers.clear();
      });
    }
  }

  Future<void> _loadDepartmentNames(
    List<teacher_model.Teacher> teachers,
  ) async {
    // Get unique department IDs that we haven't cached yet
    final departmentIds = teachers
        .where((teacher) => teacher.departmentId != null)
        .map((teacher) => teacher.departmentId!)
        .where((id) => !_departmentCache.containsKey(id))
        .toSet();

    // Load department names concurrently
    final futures = departmentIds.map((id) async {
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
    });

    await Future.wait(futures);
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
          _isLoadingFilters = false;
        });
        // Load departments for the first faculty if exists
        if (_faculties.isNotEmpty) {
          _loadDepartments();
        }
      } else {
        setState(() {
          _isLoadingFilters = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFilters = false;
      });
    }
  }

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
      // Handle error
    }
  }

  String _getDepartmentName(int? departmentId) {
    if (departmentId == null) return 'Chưa phân bộ môn';
    final cachedName = _departmentCache[departmentId];
    if (cachedName != null) return cachedName;

    // If not cached, start loading in background
    _loadSingleDepartment(departmentId);
    return 'Đang tải...';
  }

  Future<void> _loadSingleDepartment(int departmentId) async {
    if (_departmentCache.containsKey(departmentId)) return;

    try {
      final result = await _apiService.getDepartment(departmentId);
      if (result.success && result.data != null) {
        setState(() {
          _departmentCache[departmentId] =
              result.data!['name'] ?? 'Không xác định';
        });
      } else {
        setState(() {
          _departmentCache[departmentId] = 'Lỗi tải thông tin';
        });
      }
    } catch (e) {
      setState(() {
        _departmentCache[departmentId] = 'Lỗi kết nối';
      });
    }
  }

  // Column configuration for teachers table
  static const List<TableColumn> _teacherColumns = [
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
      type: TableColumnType.phone,
      flex: 2,
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
      type: TableColumnType.department,
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
  List<teacher_model.Teacher> get currentPageTeachers => _teachers;

  // Get current page as TeacherData objects with sequential IDs
  List<TeacherData> get currentPageTeacherData {
    return _teachers.asMap().entries.map((entry) {
      final index = entry.key;
      final teacher = entry.value;
      final sequentialNumber = (_currentPage - 1) * _itemsPerPage + (index + 1);
      // Use global unique ID based on page and index (starting from 1000 to avoid conflicts)
      final uniqueApiId = 1000 + (_currentPage - 1) * _itemsPerPage + index;
      return _teacherToTeacherDataWithUniqueId(
        teacher,
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
      _loadTeachers();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadTeachers();
    }
  }

  // Convert Teacher model to TeacherData for UI

  // Convert Teacher model to TeacherData with unique ID for UI
  TeacherData _teacherToTeacherDataWithUniqueId(
    teacher_model.Teacher teacher,
    int sequentialId,
    int uniqueId,
  ) {
    return TeacherData(
      id: sequentialId, // Use sequential number for display
      code: teacher.teacherId,
      name: teacher.fullName,
      phone: teacher.phoneNumber,
      email: teacher.email,
      birthDate:
          '${teacher.dateOfBirth.day.toString().padLeft(2, '0')}/${teacher.dateOfBirth.month.toString().padLeft(2, '0')}/${teacher.dateOfBirth.year}', // Format as DD/MM/YYYY
      department: _getDepartmentName(teacher.departmentId),
      apiId: teacher.apiId ?? 0, // Store real API ID for operations
      hometown: teacher.hometown,
      facultyId: teacher.facultyId,
      departmentId: teacher.departmentId,
    );
  }

  Future<void> _handleDeleteSelectedTeachers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Convert selected API IDs to list for deletion
      final selectedApiIds = _selectedTeachers.toList();

      // Delete teachers concurrently
      final futures = selectedApiIds.map((teacherId) {
        return _apiService.deleteTeacherById(teacherId);
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
                'Đã xóa ${selectedApiIds.length} giảng viên thành công!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear selections and reload data
        setState(() {
          _selectedTeachers.clear();
        });

        // Reload current page
        await _loadTeachers();

        // If current page is empty, go to previous page
        if (_teachers.isEmpty && _currentPage > 1) {
          setState(() {
            _currentPage--;
          });
          await _loadTeachers();
        }
      } else {
        // Some deletions failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Xóa thành công ${selectedApiIds.length - failedDeletions.length}/${selectedApiIds.length} giảng viên. '
                'Một số giảng viên không thể xóa được.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Reload data to reflect changes
        await _loadTeachers();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi xóa giảng viên: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: ${e.toString()}'),
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
            'Bạn có chắc chắn muốn xóa ${_selectedTeachers.length} giảng viên đã chọn? Hành động này không thể hoàn tác.',
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
                // Handle delete action using API
                Navigator.of(context).pop();
                await _handleDeleteSelectedTeachers();
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
            'Quản lý giảng viên',
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
                    child: _selectedTeachers.isEmpty
                        ? Column(
                            children: [
                              // First row: Search and filters
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

                                  // Filter dropdowns
                                  _buildFacultyDropdown(),
                                  const SizedBox(width: 16),
                                  _buildDepartmentDropdown(),
                                  const Spacer(),

                                  // Import excel button
                                  SizedBox(
                                    height: 38,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await showDialog(
                                          context: context,
                                          builder: (context) =>
                                              const ImportExcelModal(),
                                        );

                                        // Refresh data if import was successful
                                        if (result == true) {
                                          _loadTeachers();
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.upload_file,
                                        size: 16,
                                      ),
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
                                        backgroundColor: const Color(
                                          0xFF46E522,
                                        ),
                                        foregroundColor: Colors.black,
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
                                  const SizedBox(width: 16),

                                  // Add teacher button
                                  SizedBox(
                                    height: 38,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return const AddTeacherModal();
                                          },
                                        );

                                        // Refresh data if teacher was added
                                        if (result == true) {
                                          _loadTeachers();
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text(
                                        'Thêm giảng viên',
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
                            ],
                          )
                        : Row(
                            children: [
                              // Selected items count
                              Text(
                                '${_selectedTeachers.length} giảng viên đã chọn',
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
                                          color: Colors.red.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadTeachers,
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
                                            currentPageTeachers.length) {
                                          final teacher =
                                              currentPageTeachers[index];
                                          // Calculate sequential number: (currentPage - 1) * itemsPerPage + (index + 1)
                                          final sequentialNumber =
                                              (_currentPage - 1) *
                                                  _itemsPerPage +
                                              (index + 1);
                                          // Use global unique ID based on page and index (starting from 1000 to avoid conflicts)
                                          final uniqueApiId =
                                              1000 +
                                              (_currentPage - 1) *
                                                  _itemsPerPage +
                                              index;
                                          final teacherData =
                                              _teacherToTeacherDataWithUniqueId(
                                                teacher,
                                                sequentialNumber,
                                                uniqueApiId,
                                              );
                                          final isEven = index % 2 == 0;
                                          return _buildTableRow(
                                            teacherData,
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
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageTeachers.length} of $_totalTeachers',
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
                                            ).withValues(alpha: .1),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                          BoxShadow(
                                            color: const Color(
                                              0xFF464F60,
                                            ).withValues(alpha: .16),
                                            offset: const Offset(0, 0),
                                            spreadRadius: 1,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: .1,
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
                    _currentPage = 1; // Reset to first page when filtering
                  });
                  if (newValue != null) {
                    _loadDepartments(facultyId: newValue['id']);
                  } else {
                    _loadDepartments();
                  }
                  _loadTeachers(); // Reload teachers with new filter
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

  Widget _buildDepartmentDropdown() {
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
          value: _selectedDepartment,
          hint: const Text(
            'Lọc theo bộ môn',
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
                    _selectedDepartment = newValue;
                    _currentPage = 1; // Reset to first page when filtering
                  });
                  _loadTeachers(); // Reload teachers with new filter
                },
          items: [
            const DropdownMenuItem<Map<String, dynamic>>(
              value: null,
              child: Text(
                'Tất cả bộ môn',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1D29),
                ),
              ),
            ),
            ..._departments.map((department) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: department,
                child: Text(
                  department['name'] ?? 'Không xác định',
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
                  value: currentPageTeacherData.every(
                    (teacher) => _selectedTeachers.contains(teacher.apiId),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        // Select all current page items
                        final apiIds = currentPageTeacherData
                            .map((t) => t.apiId)
                            .toList();
                        _selectedTeachers.addAll(apiIds);
                      } else {
                        // Deselect all current page items
                        final apiIds = currentPageTeacherData
                            .map((t) => t.apiId)
                            .toList();
                        for (final apiId in apiIds) {
                          _selectedTeachers.remove(apiId);
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

              // Mã GV chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'MÃ GV',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Tên chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'TÊN',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Số điện thoại chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'SỐ ĐIỆN THOẠI',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Email chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'EMAIL',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Ngày sinh chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'NGÀY SINH',
                  textAlign: TextAlign.right,
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

  Widget _buildTableRow(TeacherData teacher, bool isEven) {
    final isSelected = _selectedTeachers.contains(teacher.apiId);

    return DataTableRow<TeacherData>(
      data: teacher,
      isEven: isEven,
      isSelected: isSelected,
      columns: _teacherColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedTeachers.remove(teacher.apiId);
          } else {
            _selectedTeachers.add(teacher.apiId);
          }
        });
      },
      onEdit: () async {
        final result = await showDialog(
          context: context,
          builder: (context) => EditTeacherModal(teacher: teacher),
        );

        // Refresh data if teacher was updated
        if (result == true) {
          _loadTeachers();
        }
      },
      onDelete: () async {
        // Delete individual teacher - use API ID for actual deletion
        try {
          final result = await _apiService.deleteTeacherById(teacher.apiId);
          if (result.success) {
            _loadTeachers(); // Reload data
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa giảng viên thành công!'),
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

class TeacherData implements TableRowData {
  @override
  final int id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String phone;
  @override
  final String email;
  @override
  final String birthDate;

  final String department;
  final int apiId; // Store original API ID for operations

  // Additional fields for editing
  final String hometown;
  final int? facultyId;
  final int? departmentId;

  TeacherData({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    required this.email,
    required this.birthDate,
    required this.department,
    required this.apiId,
    required this.hometown,
    this.facultyId,
    this.departmentId,
  });
}
