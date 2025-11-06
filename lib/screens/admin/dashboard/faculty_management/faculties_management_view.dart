// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/faculty_management/add_faculty_modal.dart';
import 'package:android_app/screens/admin/dashboard/faculty_management/edit_faculty_modal.dart';
import 'package:android_app/services/api_service.dart';

class FacultiesManagementView extends StatefulWidget {
  const FacultiesManagementView({super.key});

  @override
  State<FacultiesManagementView> createState() =>
      _FacultiesManagementViewState();
}

class _FacultiesManagementViewState extends State<FacultiesManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API data for faculties
  List<FacultyData> _faculties = [];
  bool _isLoading = false;
  int _totalFaculties = 0;
  int _totalPages = 0;
  String? _errorMessage;

  final Set<int> _selectedFaculties = <int>{};

  // Column configuration for faculties table
  static const List<TableColumn> _facultyColumns = [
    TableColumn(
      type: TableColumnType.id,
      flex: 1,
      styleType: TableColumnStyleType.primary,
    ),
    TableColumn(
      type: TableColumnType.facultyCode,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.facultyName,
      flex: 3,
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
      _currentPage = 1; // Reset to first page when searching
      _loadFaculties();
    }
  }

  Future<void> _loadFaculties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getFacultiesPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      if (result.success && result.data != null) {
        final facultiesData = result.data!.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final sequentialNumber =
              (_currentPage - 1) * _itemsPerPage + (index + 1);
          return FacultyData(
            id: sequentialNumber, // Use sequential number for display
            code: item['code'] ?? '',
            name: item['name'] ?? '',
            apiId: item['id'], // Store API ID for operations
          );
        }).toList();

        setState(() {
          _faculties = facultiesData;
          _totalFaculties = result.data!.total;
          _totalPages = result.data!.totalPages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Có lỗi xảy ra: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Pagination getters and methods
  int get totalPages => _totalPages;

  // Since we're getting paginated data from API, just return current page data
  List<FacultyData> get currentPageFaculties => _faculties;

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadFaculties();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadFaculties();
    }
  }

  Future<void> _handleDeleteSelectedFaculties() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Delete each selected faculty
      final futures = _selectedFaculties.map((facultyId) async {
        return await _apiService.deleteFacultyById(facultyId);
      });

      final results = await Future.wait(futures);

      // Check if all deletions were successful
      final failed = results.where((result) => !result.success).toList();

      if (failed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xóa thành công ${_selectedFaculties.length} khoa',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _selectedFaculties.clear();
        _loadFaculties(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra khi xóa: ${failed.first.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            'Bạn có chắc chắn muốn xóa ${_selectedFaculties.length} khoa đã chọn? Hành động này không thể hoàn tác.',
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
                _handleDeleteSelectedFaculties();
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
            'Quản lý khoa',
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
                    child: _selectedFaculties.isEmpty
                        ? Row(
                            children: [
                              // Search bar
                              CustomSearchBar(
                                controller: _searchController,
                                hintText: 'Tìm kiếm...',
                              ),
                              const Spacer(),
                              // Add button
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const AddFacultyModal(),
                                  ).then((_) {
                                    // Refresh data when modal is closed
                                    _loadFaculties();
                                  });
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Thêm khoa'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2264E5),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
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
                                '${_selectedFaculties.length} mục đã chọn',
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
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text('Xóa'),
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
                              ? const Center(child: CircularProgressIndicator())
                              : _errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                        onPressed: _loadFaculties,
                                        child: const Text('Thử lại'),
                                      ),
                                    ],
                                  ),
                                )
                              : currentPageFaculties.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Không có dữ liệu',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: currentPageFaculties.length,
                                  itemBuilder: (context, index) {
                                    final faculty = currentPageFaculties[index];
                                    return _buildTableRow(
                                      faculty,
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
                        // Items per page info
                        Text(
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage) > _totalFaculties ? _totalFaculties : (_currentPage * _itemsPerPage)} of $_totalFaculties',
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
                            // Previous page button
                            IconButton(
                              onPressed: _currentPage > 1
                                  ? _goToPreviousPage
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                              color: _currentPage > 1
                                  ? const Color(0xFF464F60)
                                  : const Color(0xFFD5D7DA),
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
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
                            const SizedBox(width: 8),
                            // Next page button
                            IconButton(
                              onPressed: _currentPage < totalPages
                                  ? _goToNextPage
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                              color: _currentPage < totalPages
                                  ? const Color(0xFF464F60)
                                  : const Color(0xFFD5D7DA),
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
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
              // Checkbox
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: currentPageFaculties.every(
                    (faculty) => _selectedFaculties.contains(faculty.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        for (var faculty in currentPageFaculties) {
                          _selectedFaculties.add(faculty.id);
                        }
                      } else {
                        for (var faculty in currentPageFaculties) {
                          _selectedFaculties.remove(faculty.id);
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
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 0),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Mã khoa column
              const Expanded(
                flex: 2,
                child: Text(
                  'MÃ KHOA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Tên khoa column
              const Expanded(
                flex: 3,
                child: Text(
                  'TÊN KHOA',
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

  Widget _buildTableRow(FacultyData faculty, bool isEven) {
    final isSelected = _selectedFaculties.contains(faculty.apiId);

    return DataTableRow<FacultyData>(
      data: faculty,
      isEven: isEven,
      isSelected: isSelected,
      columns: _facultyColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedFaculties.remove(faculty.apiId);
          } else {
            _selectedFaculties.add(faculty.apiId);
          }
        });
      },
      onEdit: () {
        showDialog(
          context: context,
          builder: (context) => EditFacultyModal(faculty: faculty),
        ).then((_) {
          // Refresh data when modal is closed
          _loadFaculties();
        });
      },
      onDelete: () async {
        try {
          final result = await _apiService.deleteFacultyById(faculty.apiId);
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xóa khoa thành công'),
                backgroundColor: Colors.green,
              ),
            );
            _loadFaculties(); // Refresh the list
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Có lỗi xảy ra: ${result.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Có lỗi xảy ra: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}

class FacultyData implements FacultyTableRowData {
  @override
  final int id;
  @override
  final String code;
  @override
  final String name;
  final int apiId; // Store original API ID for operations

  // Required fields from TableRowData interface (not used for faculties)
  @override
  String get phone => '';
  @override
  String get email => '';
  @override
  String get birthDate => '';

  FacultyData({
    required this.id,
    required this.code,
    required this.name,
    required this.apiId,
  });
}
