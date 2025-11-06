import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/models/subject.dart';
import 'package:android_app/screens/admin/dashboard/subject_management/add_subject_modal.dart';
import 'package:android_app/screens/admin/dashboard/subject_management/edit_subject_modal.dart';
import 'package:android_app/services/api_service.dart';

class SubjectsManagementView extends StatefulWidget {
  const SubjectsManagementView({super.key});

  @override
  State<SubjectsManagementView> createState() => _SubjectsManagementViewState();
}

class _SubjectsManagementViewState extends State<SubjectsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API data for subjects
  List<SubjectData> _subjects = [];
  bool _isLoading = false;
  int _totalSubjects = 0;
  int _totalPages = 0;
  String? _errorMessage;

  // Cache for department names
  final Map<int, String> _departmentCache = {};

  // Mapping from uniqueId to original subject ID for API operations
  final Map<int, String> _subjectIdMapping = {};

  // Filter data
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _departments = [];
  Map<String, dynamic>? _selectedFaculty;
  Map<String, dynamic>? _selectedDepartment;
  bool _isLoadingFilters = false;

  // Sample data for subjects (commented out - now using API)
  // final List<SubjectData> _sampleSubjects = [ ... ];

  final Set<int> _selectedSubjects = <int>{};

  // Column configuration for subjects table
  static const List<TableColumn> _subjectColumns = [
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
      flex: 3,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.department,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.credits,
      flex: 2,
      styleType: TableColumnStyleType.primary,
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
    _loadSubjects();
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
      _loadSubjects();
    }
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getSubjectsPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
        departmentId: _selectedDepartment?['id'],
        facultyId: _selectedFaculty?['id'],
      );

      if (result.success && result.data != null) {
        // Load department names first from API data before creating subjects
        await _preloadDepartmentNames(result.data!.items);

        final subjects = <SubjectData>[];
        _subjectIdMapping.clear();

        // Now create subjects after departments are loaded
        for (int i = 0; i < result.data!.items.length; i++) {
          final item = result.data!.items[i];
          final uniqueId = i + 1; // Sequential ID for UI
          final subjectData = _subjectToSubjectDataWithUniqueId(item, uniqueId);
          subjects.add(subjectData);
        }

        setState(() {
          _subjects = subjects;
          _totalSubjects = result.data!.total;
          _totalPages = result.data!.totalPages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _subjects = [];
          _totalSubjects = 0;
          _totalPages = 0;
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _subjects = [];
        _totalSubjects = 0;
        _totalPages = 0;
        _errorMessage = 'Lỗi kết nối mạng: ${e.toString()}';
        _isLoading = false;
        _subjectIdMapping.clear();
      });
    }
  }

  Future<void> _preloadDepartmentNames(
    List<Map<String, dynamic>> apiSubjects,
  ) async {
    // Get unique department IDs that we haven't cached yet
    final departmentIds = apiSubjects
        .where((subject) => subject['department_id'] != null)
        .map((subject) => subject['department_id'] as int)
        .where((id) => !_departmentCache.containsKey(id))
        .toSet();

    if (departmentIds.isEmpty) return;

    // Load department names concurrently
    final futures = departmentIds.map((id) async {
      try {
        final result = await _apiService.getDepartment(id);
        if (result.success && result.data != null) {
          _departmentCache[id] = result.data!['name'] ?? 'Unknown Department';
        }
      } catch (e) {
        _departmentCache[id] = 'Lỗi tải dữ liệu';
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
        // Load all departments initially
        _loadDepartments();
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
              result.data!['name'] ?? 'Unknown Department';
        });
      }
    } catch (e) {
      setState(() {
        _departmentCache[departmentId] = 'Lỗi tải dữ liệu';
      });
    }
  }

  // Pagination getters and methods
  int get totalPages => _totalPages;

  // Since we're getting paginated data from API, just return current page data
  List<SubjectData> get currentPageSubjects => _subjects;

  // Get current page as SubjectData objects with sequential IDs
  List<SubjectData> get currentPageSubjectData {
    return _subjects.asMap().entries.map((entry) {
      final subject = entry.value;
      return subject;
    }).toList();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadSubjects();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadSubjects();
    }
  }

  // Convert API data to SubjectData with unique ID for UI
  SubjectData _subjectToSubjectDataWithUniqueId(
    Map<String, dynamic> apiSubject,
    int uniqueId,
  ) {
    // Store mapping from uniqueId to real API subject ID for API operations
    final apiId = apiSubject['id'];
    if (apiId != null) {
      _subjectIdMapping[uniqueId] = apiId.toString();
    }

    return SubjectData(
      id: uniqueId,
      code: apiSubject['code'] ?? '',
      name: apiSubject['name'] ?? '',
      department: _getDepartmentName(apiSubject['department_id']),
      credits: apiSubject['credits'] ?? 0,
      // Add additional fields for API operations
      departmentId: apiSubject['department_id'],
      apiId: apiId is int ? apiId.toString() : (apiId?.toString() ?? ''),
    );
  }

  Future<void> _handleDeleteSelectedSubjects() async {
    try {
      // Convert selected UI IDs to API IDs and delete
      for (final uiId in _selectedSubjects) {
        final apiId = _subjectIdMapping[uiId];
        if (apiId != null) {
          await _apiService.deleteSubject(apiId);
        }
      }

      // Reload subjects and show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa thành công ${_selectedSubjects.length} môn học'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedSubjects.clear();
      });

      // Reload current page
      _loadSubjects();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa môn học: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
            'Bạn có chắc chắn muốn xóa ${_selectedSubjects.length} môn học đã chọn? Hành động này không thể hoàn tác.',
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
                _handleDeleteSelectedSubjects();
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
            'Quản lý môn học',
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
                    child: _selectedSubjects.isEmpty
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

                              // Filter dropdowns
                              _buildDepartmentDropdown(),
                              const SizedBox(width: 16),
                              _buildFacultyDropdown(),
                              const Spacer(),

                              // Add subject button
                              SizedBox(
                                height: 38,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AddSubjectModal(
                                        onSubjectAdded: _loadSubjects,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text(
                                    'Thêm môn học',
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
                                '${_selectedSubjects.length} môn học đã chọn',
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
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadSubjects,
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
                                            currentPageSubjects.length) {
                                          final subject =
                                              currentPageSubjects[index];
                                          final isEven = index % 2 == 0;
                                          return _buildTableRow(
                                            subject,
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
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageSubjects.length} of $_totalSubjects',
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
          items: _isLoadingFilters
              ? []
              : [
                  const DropdownMenuItem<Map<String, dynamic>>(
                    value: null,
                    child: Text('Tất cả khoa'),
                  ),
                  ..._faculties.map((faculty) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: faculty,
                      child: Text(faculty['name'] ?? ''),
                    );
                  }).toList(),
                ],
          onChanged: (value) {
            setState(() {
              _selectedFaculty = value;
              _currentPage = 1;
            });
            if (value != null) {
              _loadDepartments(facultyId: value['id']);
            } else {
              _loadDepartments();
            }
            _loadSubjects();
          },
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
          items: _isLoadingFilters
              ? []
              : [
                  const DropdownMenuItem<Map<String, dynamic>>(
                    value: null,
                    child: Text('Tất cả bộ môn'),
                  ),
                  ..._departments.map((department) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: department,
                      child: Text(department['name'] ?? ''),
                    );
                  }).toList(),
                ],
          onChanged: (value) {
            setState(() {
              _selectedDepartment = value;
              _currentPage = 1;
            });
            _loadSubjects();
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
              // Checkbox (fix nhỏ)
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: currentPageSubjects.every(
                    (subject) => _selectedSubjects.contains(subject.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedSubjects.addAll(
                          currentPageSubjects.map((t) => t.id),
                        );
                      } else {
                        for (final subject in currentPageSubjects) {
                          _selectedSubjects.remove(subject.id);
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

              // Mã môn học chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'MÃ MÔN HỌC',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Tên môn học chiếm 3 phần
              const Expanded(
                flex: 3,
                child: Text(
                  'TÊN MÔN HỌC',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Bộ môn chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'BỘ MÔN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Số tín chỉ chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'SỐ TÍN CHỈ',
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

  Widget _buildTableRow(SubjectData subject, bool isEven) {
    final isSelected = _selectedSubjects.contains(subject.id);

    return DataTableRow<SubjectData>(
      data: subject,
      isEven: isEven,
      isSelected: isSelected,
      columns: _subjectColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedSubjects.remove(subject.id);
          } else {
            _selectedSubjects.add(subject.id);
          }
        });
      },
      onEdit: () {
        showDialog(
          context: context,
          builder: (context) => EditSubjectModal(
            subject: subject,
            onSubjectUpdated: _loadSubjects,
          ),
        );
      },
      onDelete: () async {
        try {
          await _apiService.deleteSubject(subject.apiId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa môn học thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSubjects(); // Reload subjects
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa môn học: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}
