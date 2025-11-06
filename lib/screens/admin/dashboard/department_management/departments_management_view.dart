import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/department_management/add_department_modal.dart';
import 'package:android_app/screens/admin/dashboard/department_management/edit_department_modal.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/models/department.dart';

class DepartmentsManagementView extends StatefulWidget {
  const DepartmentsManagementView({super.key});

  @override
  State<DepartmentsManagementView> createState() =>
      _DepartmentsManagementViewState();
}

class _DepartmentsManagementViewState extends State<DepartmentsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API data for departments
  List<Department> _departments = [];
  bool _isLoading = false;
  int _totalDepartments = 0;
  int _totalPages = 0;
  String? _errorMessage;

  // Cache for faculty names
  final Map<int, String> _facultyCache = {};

  final Set<int> _selectedDepartments = <int>{};

  // Filter data
  List<Map<String, dynamic>> _faculties = [];
  Map<String, dynamic>? _selectedFaculty;

  // Column configuration for departments table
  static const List<TableColumn> _departmentColumns = [
    TableColumn(
      type: TableColumnType.id,
      flex: 1,
      styleType: TableColumnStyleType.primary,
    ),
    TableColumn(
      type: TableColumnType.code,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.name,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.faculty,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.actions,
      flex: 1,
      textAlign: TextAlign.right,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
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
      _loadDepartments();
    }
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getDepartmentsPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        facultyId: _selectedFaculty?['id'],
      );

      if (result.success && result.data != null) {
        // Load faculty names for departments
        await _loadFacultyNames(result.data!.items);

        setState(() {
          _departments = result.data!.items
              .map((item) => Department.fromJson(item))
              .toList();
          _totalDepartments = result.data!.total;
          _totalPages = result.data!.totalPages;
          _isLoading = false;
          _selectedDepartments.clear();
        });
      } else {
        setState(() {
          _departments = [];
          _totalDepartments = 0;
          _totalPages = 0;
          _isLoading = false;
          _errorMessage = result.message;
          _selectedDepartments.clear();
        });
      }
    } catch (e) {
      setState(() {
        _departments = [];
        _totalDepartments = 0;
        _totalPages = 0;
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi khi tải dữ liệu: $e';
        _selectedDepartments.clear();
      });
    }
  }

  Future<void> _loadFacultyNames(List<Map<String, dynamic>> departments) async {
    // Get unique faculty IDs that we haven't cached yet
    final facultyIds = departments
        .map((department) => department['faculty_id'] as int?)
        .where((id) => id != null && !_facultyCache.containsKey(id))
        .cast<int>()
        .toSet();

    // Load faculty names concurrently
    final futures = facultyIds.map((id) async {
      try {
        final result = await _apiService.getFaculty(id);
        if (result.success && result.data != null) {
          setState(() {
            _facultyCache[id] = result.data!['name'] ?? 'Không rõ';
          });
        }
      } catch (e) {
        setState(() {
          _facultyCache[id] = 'Không rõ';
        });
      }
    });

    await Future.wait(futures);
  }

  Future<void> _loadFaculties() async {
    try {
      final result = await _apiService.getFacultiesPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _faculties = result.data!.items.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          _faculties = [];
        });
      }
    } catch (e) {
      setState(() {
        _faculties = [];
      });
    }
  }

  String _getFacultyName(int? facultyId) {
    if (facultyId == null) return 'Chưa phân khoa';
    final cachedName = _facultyCache[facultyId];
    if (cachedName != null) return cachedName;

    // If not cached, start loading in background
    _loadSingleFaculty(facultyId);
    return 'Đang tải...';
  }

  Future<void> _loadSingleFaculty(int facultyId) async {
    if (_facultyCache.containsKey(facultyId)) return;

    try {
      final result = await _apiService.getFaculty(facultyId);
      if (result.success && result.data != null) {
        setState(() {
          _facultyCache[facultyId] = result.data!['name'] ?? 'Không rõ';
        });
      }
    } catch (e) {
      setState(() {
        _facultyCache[facultyId] = 'Không rõ';
      });
    }
  }

  // Pagination getters and methods
  int get totalPages => _totalPages;

  // Since we're getting paginated data from API, just return current page data
  List<Department> get currentPageDepartments => _departments;

  // Get current page as DepartmentData objects with sequential IDs
  List<DepartmentData> get currentPageDepartmentData {
    return _departments.asMap().entries.map((entry) {
      final index = entry.key;
      final department = entry.value;
      return _departmentToDepartmentDataWithUniqueId(
        department,
        index + 1,
        department.id,
      );
    }).toList();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadDepartments();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadDepartments();
    }
  }

  // Convert Department model to DepartmentData with unique ID for UI
  DepartmentData _departmentToDepartmentDataWithUniqueId(
    Department department,
    int sequentialId,
    int uniqueId,
  ) {
    return DepartmentData(
      id: sequentialId,
      code: department.code,
      name: department.name,
      faculty: _getFacultyName(department.facultyId),
      apiId: uniqueId,
      facultyId: department.facultyId,
    );
  }

  Future<void> _handleDeleteSelectedDepartments() async {
    try {
      // Get API IDs from selected department data
      final selectedApiIds = currentPageDepartmentData
          .where((dept) => _selectedDepartments.contains(dept.id))
          .map((dept) => dept.apiId)
          .toList();

      // Delete each selected department
      for (final apiId in selectedApiIds) {
        await _apiService.deleteDepartment(apiId);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa bộ môn thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload the data
      await _loadDepartments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi xóa: $e'),
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
            'Bạn có chắc chắn muốn xóa ${_selectedDepartments.length} bộ môn đã chọn? Hành động này không thể hoàn tác.',
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
                _handleDeleteSelectedDepartments();
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
            'Quản lý bộ môn',
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
                    child: _selectedDepartments.isEmpty
                        ? Row(
                            children: [
                              // Search bar
                              CustomSearchBar(
                                controller: _searchController,
                                hintText: 'Tìm kiếm...',
                                width: 320,
                              ),
                              const SizedBox(width: 16),
                              // Filter by faculty
                              _buildFacultyDropdown(),
                              const Spacer(),
                              // Add button
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context) =>
                                        const AddDepartmentModal(),
                                  );
                                  if (result == true) {
                                    _loadDepartments();
                                  }
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  'Thêm bộ môn',
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              // Selected count
                              Text(
                                '${_selectedDepartments.length} bộ môn đã chọn',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF414651),
                                ),
                              ),
                              const Spacer(),
                              // Delete button
                              ElevatedButton(
                                onPressed: _showDeleteConfirmationDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
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
                                    letterSpacing: 0.28,
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
                        _buildTableHeader(),
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(50.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _errorMessage != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(50.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadDepartments,
                                          child: const Text('Thử lại'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: currentPageDepartmentData.length,
                                  itemBuilder: (context, index) {
                                    return _buildTableRow(
                                      currentPageDepartmentData[index],
                                      index % 2 == 0,
                                    );
                                  },
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
                        // Page info
                        Text(
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageDepartments.length} của $_totalDepartments',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.36,
                            color: Color(0xFF687182),
                          ),
                        ),

                        // Pagination controls
                        Row(
                          children: [
                            // Previous button
                            Container(
                              decoration: BoxDecoration(
                                color: _currentPage > 1
                                    ? Colors.white
                                    : const Color(0xFFF7F9FC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(
                                    0xFF464F60,
                                  ).withValues(alpha: 0.24),
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.chevron_left),
                                iconSize: 16,
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                color: _currentPage > 1
                                    ? const Color(0xFF464F60)
                                    : const Color(0xFF868FA0),
                                onPressed: _currentPage > 1
                                    ? _goToPreviousPage
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Page indicator
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
                            Container(
                              decoration: BoxDecoration(
                                color: _currentPage < totalPages
                                    ? Colors.white
                                    : const Color(0xFFF7F9FC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(
                                    0xFF464F60,
                                  ).withValues(alpha: 0.24),
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.chevron_right),
                                iconSize: 16,
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                color: _currentPage < totalPages
                                    ? const Color(0xFF464F60)
                                    : const Color(0xFF868FA0),
                                onPressed: _currentPage < totalPages
                                    ? _goToNextPage
                                    : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
            'Tất cả khoa',
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
          items: [
            const DropdownMenuItem<Map<String, dynamic>>(
              value: null,
              child: Text(
                'Tất cả khoa',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFA1A9B8),
                ),
              ),
            ),
            ..._faculties.map((Map<String, dynamic> faculty) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: faculty,
                child: Text(
                  faculty['name'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF181D27),
                  ),
                ),
              );
            }).toList(),
          ],
          onChanged: (Map<String, dynamic>? newValue) {
            setState(() {
              _selectedFaculty = newValue;
              _currentPage = 1; // Reset to first page when filtering
            });
            _loadDepartments();
          },
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
              // Checkbox
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: currentPageDepartments.every(
                    (department) =>
                        _selectedDepartments.contains(department.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        for (var department in currentPageDepartments) {
                          _selectedDepartments.add(department.id);
                        }
                      } else {
                        for (var department in currentPageDepartments) {
                          _selectedDepartments.remove(department.id);
                        }
                      }
                    });
                  },
                ),
              ),

              // # column
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
                        color: Color(0xFF464F60),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Sort icons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_drop_up,
                          size: 14,
                          color: const Color(0xFF171C26),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: const Color(0xFFBCC2CE),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Mã bộ môn column
              const Expanded(
                flex: 2,
                child: Text(
                  'MÃ BỘ MÔN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Tên bộ môn column
              const Expanded(
                flex: 2,
                child: Text(
                  'TÊN BỘ MÔN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Khoa trực thuộc column
              const Expanded(
                flex: 2,
                child: Text(
                  'KHOA TRỰC THUỘC',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Hành động column
              const Expanded(
                flex: 1,
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

  Widget _buildTableRow(DepartmentData department, bool isEven) {
    final isSelected = _selectedDepartments.contains(department.id);

    return DataTableRow<DepartmentData>(
      data: department,
      isEven: isEven,
      isSelected: isSelected,
      columns: _departmentColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedDepartments.remove(department.id);
          } else {
            _selectedDepartments.add(department.id);
          }
        });
      },
      onEdit: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => EditDepartmentModal(
            departmentId: department.apiId,
            onUpdate: _loadDepartments,
          ),
        );
        if (result == true) {
          _loadDepartments();
        }
      },
      onDelete: () async {
        try {
          await _apiService.deleteDepartment(department.apiId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xóa bộ môn thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _loadDepartments();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Có lỗi xảy ra khi xóa: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}

class DepartmentData implements DepartmentTableRowData {
  @override
  final int id;
  @override
  final String code;
  @override
  final String name;
  final String faculty;

  final int apiId; // Store original API ID for operations
  final int? facultyId;

  // Required fields from TableRowData interface (not used for departments)
  @override
  String get phone => '';
  @override
  String get email => '';
  @override
  String get birthDate => '';

  DepartmentData({
    required this.id,
    required this.code,
    required this.name,
    required this.faculty,
    required this.apiId,
    this.facultyId,
  });

  @override
  String get facultyName => faculty;
}
