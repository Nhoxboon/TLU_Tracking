// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/course_management/add_course_modal.dart';
import 'package:android_app/screens/admin/dashboard/course_management/edit_course_modal.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/models/cohort.dart';

class CoursesManagementView extends StatefulWidget {
  const CoursesManagementView({super.key});

  @override
  State<CoursesManagementView> createState() => _CoursesManagementViewState();
}

class _CoursesManagementViewState extends State<CoursesManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API data for cohorts
  List<Cohort> _cohorts = [];
  bool _isLoading = false;
  int _totalPages = 0;
  String? _errorMessage;

  // Mapping from uniqueId to original cohort ID for API operations
  final Map<int, int> _cohortIdMapping = {};

  final Set<int> _selectedCohorts = <int>{};

  @override
  void initState() {
    super.initState();
    _loadCohorts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Since we don't have search functionality in the API yet, we'll implement basic filtering
    if (_searchController.text.length >= 3 || _searchController.text.isEmpty) {
      setState(() {
        _currentPage = 1; // Reset to first page when searching
      });
      _loadCohorts();
    }
  }

  Future<void> _loadCohorts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getCohortsPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      if (result.success && result.data != null) {
        final List<Cohort> cohorts = (result.data!.items)
            .map((item) => Cohort.fromJson(item))
            .toList();

        setState(() {
          _cohorts = cohorts;
          _totalPages = (result.data!.total / _itemsPerPage).ceil();
          _isLoading = false;
          _cohortIdMapping.clear();
          // Build mapping for UI IDs to API IDs
          for (int i = 0; i < cohorts.length; i++) {
            final sequentialId = (_currentPage - 1) * _itemsPerPage + i + 1;
            if (cohorts[i].id != null) {
              _cohortIdMapping[sequentialId] = cohorts[i].id!;
            }
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
          _cohorts = [];
          _totalPages = 0;
          _cohortIdMapping.clear();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối mạng: $e';
        _cohorts = [];
        _totalPages = 0;
        _cohortIdMapping.clear();
      });
    }
  }

  // Convert Cohort model to CourseData for UI
  CourseData _cohortToCourseData(
    Cohort cohort,
    int sequentialId,
    int uniqueId,
  ) {
    // Store mapping from uniqueId to real API cohort ID for API operations
    if (cohort.id != null) {
      _cohortIdMapping[uniqueId] = cohort.id!;
    }
    return CourseData(
      id: uniqueId, // Use sequential ID for UI
      name: cohort.name,
      admissionYear: cohort.startYear.toString(),
      endYear: cohort.endYear.toString(),
      apiId: cohort.id ?? 0, // Store original API ID for operations
    );
  }

  Future<void> _handleDeleteSelectedCohorts() async {
    try {
      // Convert UI IDs to API IDs
      final List<int> apiIds = _selectedCohorts
          .map((uiId) => _cohortIdMapping[uiId])
          .where((apiId) => apiId != null)
          .cast<int>()
          .toList();

      if (apiIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No cohorts selected for deletion'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await _apiService.deleteCohorts(apiIds);

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa thành công ${_selectedCohorts.length} khóa học'),
            backgroundColor: Colors.green,
          ),
        );
        _selectedCohorts.clear();
        _loadCohorts(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting cohorts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Column configuration for courses table
  static const List<TableColumn> _courseColumns = [
    TableColumn(
      type: TableColumnType.id,
      flex: 1,
      styleType: TableColumnStyleType.primary,
    ),
    TableColumn(
      type: TableColumnType.name,
      flex: 3,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.custom,
      flex: 3,
      textAlign: TextAlign.right,
      styleType: TableColumnStyleType.normal,
      customValue: 'admissionYear',
    ),
    TableColumn(
      type: TableColumnType.custom,
      flex: 3,
      textAlign: TextAlign.right,
      styleType: TableColumnStyleType.normal,
      customValue: 'endYear',
    ),
    TableColumn(
      type: TableColumnType.actions,
      flex: 3,
      textAlign: TextAlign.right,
    ),
  ];

  // Pagination getters and methods
  int get totalPages => _totalPages;

  // Since we're getting paginated data from API, just return current page data
  List<Cohort> get currentPageCohorts => _cohorts;

  // Get current page as CourseData objects with sequential IDs
  List<CourseData> get currentPageCourses {
    return _cohorts.asMap().entries.map((entry) {
      final index = entry.key;
      final cohort = entry.value;
      final sequentialId = (_currentPage - 1) * _itemsPerPage + index + 1;
      final uniqueId = sequentialId; // Use sequential ID as unique ID for UI
      return _cohortToCourseData(cohort, sequentialId, uniqueId);
    }).toList();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadCohorts();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadCohorts();
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
            'Bạn có chắc chắn muốn xóa ${_selectedCohorts.length} khóa học đã chọn? Hành động này không thể hoàn tác.',
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
                // Handle delete action
                Navigator.of(context).pop();
                _handleDeleteSelectedCohorts();
                Navigator.of(context).pop();
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
            'Quản lý khóa học',
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCohorts,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Action bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: _selectedCohorts.isEmpty
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
                                    const Spacer(),
                                    // Add course button
                                    SizedBox(
                                      height: 38,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await showDialog<bool>(
                                            context: context,
                                            builder: (context) =>
                                                const AddCourseModal(),
                                          );
                                          if (result == true) {
                                            _loadCohorts(); // Refresh the list
                                          }
                                        },
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text(
                                          'Thêm khóa học',
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
                                )
                              : Row(
                                  children: [
                                    // Selected items count
                                    Text(
                                      '${_selectedCohorts.length} khóa học đã chọn',
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
                                          backgroundColor: const Color(
                                            0xFFEF4444,
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
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // Table rows
                                      ...List.generate(_itemsPerPage, (index) {
                                        if (index < currentPageCourses.length) {
                                          final course =
                                              currentPageCourses[index];
                                          final isEven = index % 2 == 0;
                                          return _buildTableRow(course, isEven);
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
                            color: const Color(
                              0xFFF4F7FC,
                            ).withValues(alpha: .75),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left side: Items count
                              Text(
                                '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageCourses.length} of ${_cohorts.length}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  letterSpacing: 0.36,
                                  color: Color(0xFF687182),
                                ),
                              ),

                              // Right side: Navigation controls
                              Row(
                                children: [
                                  // Previous button
                                  GestureDetector(
                                    onTap: () {
                                      if (_currentPage > 1) {
                                        _goToPreviousPage();
                                      }
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _currentPage > 1
                                            ? Colors.white
                                            : const Color(0xFFF7F9FC),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: _currentPage > 1
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
                                                  blurRadius: 0,
                                                  offset: const Offset(0, 0),
                                                  spreadRadius: 1,
                                                ),
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: .1),
                                                  blurRadius: 1,
                                                  offset: const Offset(0, 1),
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
                                  const SizedBox(width: 16),

                                  // Page info
                                  Text(
                                    '$_currentPage/$totalPages',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      letterSpacing: 0.36,
                                      color: Color(0xFF687182),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Next button
                                  GestureDetector(
                                    onTap: () {
                                      if (_currentPage < totalPages) {
                                        _goToNextPage();
                                      }
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _currentPage < totalPages
                                            ? Colors.white
                                            : const Color(0xFFF7F9FC),
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
                                                  blurRadius: 0,
                                                  offset: const Offset(0, 0),
                                                  spreadRadius: 1,
                                                ),
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: .1),
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
                  value: currentPageCourses.every(
                    (course) => _selectedCohorts.contains(course.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedCohorts.addAll(
                          currentPageCourses.map((c) => c.id),
                        );
                      } else {
                        for (final course in currentPageCourses) {
                          _selectedCohorts.remove(course.id);
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

              // Tên khóa chiếm 3 phần
              const Expanded(
                flex: 3,
                child: Text(
                  'TÊN KHÓA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Năm nhập học chiếm 3 phần
              const Expanded(
                flex: 3,
                child: Text(
                  'NĂM NHẬP HỌC',
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

              // Năm kết thúc chiếm 3 phần
              const Expanded(
                flex: 3,
                child: Text(
                  'NĂM KẾT THÚC',
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

              // Hành động chiếm 3 phần
              const Expanded(
                flex: 3,
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

  Widget _buildTableRow(CourseData course, bool isEven) {
    final isSelected = _selectedCohorts.contains(course.id);

    return DataTableRow<CourseData>(
      data: course,
      isEven: isEven,
      isSelected: isSelected,
      columns: _courseColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedCohorts.remove(course.id);
          } else {
            _selectedCohorts.add(course.id);
          }
        });
      },
      onEdit: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => EditCourseModal(course: course),
        );
        if (result == true) {
          _loadCohorts(); // Refresh the list
        }
      },
      onDelete: () async {
        try {
          final result = await _apiService.deleteCohort(course.apiId);
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xóa khóa học thành công'),
                backgroundColor: Colors.green,
              ),
            );
            _loadCohorts(); // Refresh the list
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi kết nối: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}

// Course data class
class CourseData implements CourseTableRowData {
  @override
  final int id;
  @override
  final String name;
  @override
  final String admissionYear;
  @override
  final String endYear;

  final int apiId; // Store original API ID for operations

  // Required fields from TableRowData interface (courses don't have these)
  @override
  String get code => '';
  @override
  String get phone => '';
  @override
  String get email => '';
  @override
  String get birthDate => '';

  CourseData({
    required this.id,
    required this.name,
    required this.admissionYear,
    required this.endYear,
    required this.apiId,
  });
}
