import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/major_management/add_major_modal.dart';
import 'package:android_app/screens/admin/dashboard/major_management/edit_major_modal.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/models/major.dart';

class MajorsManagementView extends StatefulWidget {
  const MajorsManagementView({super.key});

  @override
  State<MajorsManagementView> createState() => _MajorsManagementViewState();
}

class _MajorsManagementViewState extends State<MajorsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API data for majors
  List<Major> _majors = [];
  bool _isLoading = false;
  int _totalMajors = 0;
  int _totalPages = 0;
  String? _errorMessage;

  // Cache for faculty names
  final Map<int, String> _facultyCache = {};

  final Set<int> _selectedMajors = <int>{};

  // Filter data
  List<Map<String, dynamic>> _faculties = [];
  Map<String, dynamic>? _selectedFaculty;
  bool _isLoadingFilters = false;

  // Column configuration for majors table - simplified structure
  static const List<TableColumn> _majorColumns = [
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
      type: TableColumnType.majorName,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.departmentName,
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
    _loadMajors();
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
      _loadMajors();
    }
  }

  Future<void> _loadMajors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getMajorsPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
        facultyId: _selectedFaculty?['id'],
      );

      if (result.success && result.data != null) {
        // Parse majors first
        final majors = result.data!.items.map((item) {
          return Major.fromJson(item);
        }).toList();

        // Load faculty names for majors
        await _loadFacultyNames(
          result.data!.items.cast<Map<String, dynamic>>(),
        );

        setState(() {
          _majors = majors;
          _totalMajors = result.data!.total;
          _totalPages = result.data!.totalPages;
          _isLoading = false;
          _selectedMajors.clear();
        });
      } else {
        setState(() {
          _majors = [];
          _totalMajors = 0;
          _totalPages = 0;
          _isLoading = false;
          _errorMessage = result.message;
          _selectedMajors.clear();
        });
      }
    } catch (e) {
      setState(() {
        _majors = [];
        _totalMajors = 0;
        _totalPages = 0;
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi khi tải dữ liệu: ${e.toString()}';
        _selectedMajors.clear();
      });
    }
  }

  Future<void> _loadFacultyNames(List<Map<String, dynamic>> majors) async {
    // Get unique faculty IDs that we haven't cached yet
    final facultyIds = majors
        .map((major) => major['faculty_id'] as int?)
        .where((id) => id != null && !_facultyCache.containsKey(id))
        .cast<int>()
        .toSet();

    // Load faculty names concurrently
    final futures = facultyIds.map((id) async {
      try {
        final result = await _apiService.getFaculty(id);
        if (result.success && result.data != null) {
          _facultyCache[id] =
              result.data!['name'] ??
              'Không rõ'; // API trả về 'name' không phải 'faculty_name'
        }
      } catch (e) {
        _facultyCache[id] = 'Không rõ';
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
          _faculties = result.data!.items.cast<Map<String, dynamic>>();
          _isLoadingFilters = false;
        });
      } else {
        setState(() {
          _faculties = [];
          _isLoadingFilters = false;
        });
      }
    } catch (e) {
      setState(() {
        _faculties = [];
        _isLoadingFilters = false;
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
          _facultyCache[facultyId] =
              result.data!['name'] ??
              'Không rõ'; // API trả về 'name' không phải 'faculty_name'
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
  List<Major> get currentPageMajors => _majors;

  // Get current page as MajorData objects with sequential IDs
  List<MajorData> get currentPageMajorData {
    return _majors.asMap().entries.map((entry) {
      final index = entry.key;
      final major = entry.value;
      return _majorToMajorDataWithUniqueId(
        major,
        index + 1, // Sequential ID for display (1, 2, 3...)
        major.id, // Keep original API ID for operations
      );
    }).toList();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadMajors();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadMajors();
    }
  }

  // Convert Major model to MajorData with unique ID for UI
  MajorData _majorToMajorDataWithUniqueId(
    Major major,
    int sequentialId,
    int uniqueId,
  ) {
    return MajorData(
      id: sequentialId,
      code: major.majorCode,
      name: major.majorName,
      department: _getFacultyName(major.facultyId),
      apiId: uniqueId,
      facultyId: major.facultyId,
    );
  }

  Future<void> _handleDeleteSelectedMajors() async {
    try {
      // Get API IDs from selected major data
      final selectedApiIds = currentPageMajorData
          .where((major) => _selectedMajors.contains(major.id))
          .map((major) => major.apiId)
          .toList();

      // Delete each selected major
      for (final apiId in selectedApiIds) {
        await _apiService.deleteMajorById(apiId);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa ${selectedApiIds.length} ngành thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload the data
      await _loadMajors();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa ngành: ${e.toString()}'),
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
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: Color(0xFF1F2937),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa ${_selectedMajors.length} ngành đã chọn? Hành động này không thể hoàn tác.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.43,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeleteSelectedMajors();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
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
                ),
              ),
            ),
          ],
        );
      },
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
            color: const Color(0xFF687182).withValues(alpha: 0.08),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>?>(
          value: _selectedFaculty,
          hint: const Text(
            'Tất cả khoa',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.43,
              color: Color(0xFF717680),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF717680),
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF717680),
          ),
          items: [
            const DropdownMenuItem<Map<String, dynamic>?>(
              value: null,
              child: Text('Tất cả khoa'),
            ),
            ..._faculties.map((faculty) {
              return DropdownMenuItem<Map<String, dynamic>?>(
                value: faculty,
                child: Text(
                  faculty['name'] ?? 'Không rõ',
                ), // API trả về 'name' không phải 'faculty_name'
              );
            }),
          ],
          onChanged: _isLoadingFilters
              ? null
              : (Map<String, dynamic>? newValue) {
                  setState(() {
                    _selectedFaculty = newValue;
                    _currentPage = 1; // Reset to first page when filtering
                  });
                  _loadMajors();
                },
        ),
      ),
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
            'Quản lý ngành',
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
                    child: _selectedMajors.isEmpty
                        ? Row(
                            children: [
                              // Search field
                              CustomSearchBar(
                                controller: _searchController,
                                hintText: 'Tìm kiếm...',
                                onChanged: (value) {
                                  // Handle search logic here
                                  setState(() {
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
                              const Spacer(),

                              // Add major button
                              SizedBox(
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) =>
                                          const AddMajorModal(),
                                    );
                                    if (result == true) {
                                      _loadMajors(); // Refresh list on success
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 12),
                                  label: const Text(
                                    'Thêm ngành',
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
                                '${_selectedMajors.length} ngành đã chọn',
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
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showDeleteConfirmationDialog();
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 12,
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
                              ? const Center(child: CircularProgressIndicator())
                              : _errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _loadMajors,
                                        child: const Text('Thử lại'),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // Table rows
                                      ...List.generate(_itemsPerPage, (index) {
                                        if (index <
                                            currentPageMajorData.length) {
                                          final major =
                                              currentPageMajorData[index];
                                          final isEven = index % 2 == 0;
                                          return _buildTableRow(major, isEven);
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
                        // Show results info
                        Text(
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _totalMajors ? _totalMajors : _currentPage * _itemsPerPage} of $_totalMajors',
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
                            GestureDetector(
                              onTap: _currentPage > 1
                                  ? _goToPreviousPage
                                  : null,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: _currentPage > 1
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF464F60,
                                            ).withValues(alpha: 0.24),
                                            offset: const Offset(0, 0),
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
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

                            // Page info
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
                            GestureDetector(
                              onTap: _currentPage < totalPages
                                  ? _goToNextPage
                                  : null,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: _currentPage < totalPages
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF595E78,
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
                  value: currentPageMajorData.every(
                    (major) => _selectedMajors.contains(major.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedMajors.addAll(
                          currentPageMajorData.map((m) => m.id),
                        );
                      } else {
                        _selectedMajors.removeAll(
                          currentPageMajorData.map((m) => m.id),
                        );
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

              // Mã ngành chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'MÃ NGÀNH',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Tên ngành chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'TÊN NGÀNH',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Khoa chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'KHOA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Hành động chiếm 1 phần
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

  Widget _buildTableRow(MajorData major, bool isEven) {
    final isSelected = _selectedMajors.contains(major.id);

    return DataTableRow<MajorData>(
      data: major,
      isEven: isEven,
      isSelected: isSelected,
      columns: _majorColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedMajors.remove(major.id);
          } else {
            _selectedMajors.add(major.id);
          }
        });
      },
      onEdit: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => EditMajorModal(
            majorId: major.apiId,
            onUpdate: () => _loadMajors(),
          ),
        );
        if (result == true) {
          _loadMajors(); // Refresh list on success
        }
      },
      onDelete: () async {
        try {
          await _apiService.deleteMajorById(major.apiId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xóa ngành thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _loadMajors();
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

class MajorData implements MajorTableRowData {
  @override
  final int id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String department;

  final int apiId; // Store original API ID for operations
  final int? facultyId;

  // Required fields from TableRowData interface (not used for majors)
  @override
  String get phone => '';
  @override
  String get email => '';
  @override
  String get birthDate => '';
  @override
  String get departmentName => department;

  MajorData({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.apiId,
    this.facultyId,
  });
}
