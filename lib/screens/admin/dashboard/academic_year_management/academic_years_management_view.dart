import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/academic_year_management/add_academic_year_modal.dart';
import 'package:android_app/screens/admin/dashboard/academic_year_management/edit_academic_year_modal.dart';
import 'package:android_app/services/api_service.dart';
import 'package:android_app/models/academic_year.dart';

class AcademicYearsManagementView extends StatefulWidget {
  const AcademicYearsManagementView({super.key});

  @override
  State<AcademicYearsManagementView> createState() =>
      _AcademicYearsManagementViewState();
}

class _AcademicYearsManagementViewState
    extends State<AcademicYearsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API data for academic years
  List<AcademicYear> _academicYears = [];
  bool _isLoading = false;
  int _totalPages = 0;
  String? _errorMessage;

  // Mapping from uniqueId to original academic year ID for API operations
  final Map<int, int> _academicYearIdMapping = {};

  final Set<int> _selectedAcademicYears = <int>{};

  @override
  void initState() {
    super.initState();
    _loadAcademicYears();
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
      _loadAcademicYears();
    }
  }

  Future<void> _loadAcademicYears() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getAcademicYearsPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      if (result.success && result.data != null) {
        final List<AcademicYear> academicYears = (result.data!.items)
            .map((item) => AcademicYear.fromJson(item))
            .toList();

        setState(() {
          _academicYears = academicYears;
          _totalPages = result.data!.totalPages;
          _isLoading = false;

          // Update ID mapping for API operations
          _academicYearIdMapping.clear();
          for (int i = 0; i < academicYears.length; i++) {
            final academicYear = academicYears[i];
            final uniqueId = (_currentPage - 1) * _itemsPerPage + i + 1;
            if (academicYear.id != null) {
              _academicYearIdMapping[uniqueId] = academicYear.id!;
            }
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
          _academicYears = [];
          _totalPages = 0;
          _academicYearIdMapping.clear();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối mạng: $e';
        _academicYears = [];
        _totalPages = 0;
        _academicYearIdMapping.clear();
      });
    }
  }

  // Convert AcademicYear model to AcademicYearData for UI
  AcademicYearData _academicYearToAcademicYearData(
    AcademicYear academicYear,
    int sequentialId,
    int uniqueId,
  ) {
    // Store mapping from uniqueId to real API academic year ID for API operations
    if (academicYear.id != null) {
      _academicYearIdMapping[uniqueId] = academicYear.id!;
    }
    return AcademicYearData(
      id: uniqueId, // Use sequential ID for UI
      name: academicYear.name,
      startDate: academicYear.startDate,
      endDate: academicYear.endDate,
      apiId: academicYear.id ?? 0, // Store original API ID for operations
    );
  }

  Future<void> _handleDeleteSelectedAcademicYears() async {
    try {
      // Convert UI IDs to API IDs
      final List<int> apiIds = _selectedAcademicYears
          .map((uiId) => _academicYearIdMapping[uiId])
          .where((apiId) => apiId != null)
          .cast<int>()
          .toList();

      if (apiIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid academic years selected for deletion'),
          ),
        );
        return;
      }

      final result = await _apiService.deleteAcademicYears(apiIds);

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa thành công ${apiIds.length} năm học'),
            backgroundColor: Colors.green,
          ),
        );
        _selectedAcademicYears.clear();
        _loadAcademicYears(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting academic years: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Column configuration for academic years table
  static const List<TableColumn> _academicYearColumns = [
    TableColumn(
      type: TableColumnType.id,
      flex: 1,
      styleType: TableColumnStyleType.primary,
    ),
    TableColumn(
      type: TableColumnType.academicYearName,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.startDate,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.endDate,
      flex: 2,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.actions,
      flex: 1,
      textAlign: TextAlign.right,
    ),
  ];

  // Pagination getters and methods
  int get totalPages => _totalPages;

  // Since we're getting paginated data from API, just return current page data
  List<AcademicYear> get currentPageAcademicYears => _academicYears;

  // Get current page as AcademicYearData objects with sequential IDs
  List<AcademicYearData> get currentPageAcademicYearData {
    return _academicYears.asMap().entries.map((entry) {
      final index = entry.key;
      final academicYear = entry.value;
      final sequentialId = (_currentPage - 1) * _itemsPerPage + index + 1;
      final uniqueId = sequentialId; // Use sequential ID as unique ID for UI
      return _academicYearToAcademicYearData(
        academicYear,
        sequentialId,
        uniqueId,
      );
    }).toList();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadAcademicYears();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadAcademicYears();
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
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF1F2937),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa ${_selectedAcademicYears.length} năm học đã chọn? Hành động này không thể hoàn tác.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDeleteSelectedAcademicYears();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Xóa',
                style: TextStyle(fontWeight: FontWeight.w500),
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
            'Quản lý năm học',
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
                    child: _selectedAcademicYears.isEmpty
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

                              // Add academic year button
                              SizedBox(
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) =>
                                          const AddAcademicYearModal(),
                                    );
                                    if (result == true) {
                                      _loadAcademicYears(); // Reload data after successful add
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 12),
                                  label: const Text(
                                    'Thêm năm học',
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
                                '${_selectedAcademicYears.length} năm học đã chọn',
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
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2264E5),
                                  ),
                                )
                              : _errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _loadAcademicYears,
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
                                            currentPageAcademicYearData
                                                .length) {
                                          final academicYear =
                                              currentPageAcademicYearData[index];
                                          final isEven = index % 2 == 0;
                                          return _buildTableRow(
                                            academicYear,
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
                        // Show results info
                        Text(
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _academicYears.length ? _academicYears.length : _currentPage * _itemsPerPage} of ${_academicYears.length}',
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
                  value: currentPageAcademicYears.every(
                    (academicYear) =>
                        _selectedAcademicYears.contains(academicYear.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedAcademicYears.addAll(
                          currentPageAcademicYearData.map((ay) => ay.id),
                        );
                      } else {
                        _selectedAcademicYears.removeAll(
                          currentPageAcademicYearData.map((ay) => ay.id),
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

              // Năm học chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'NĂM HỌC',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Ngày bắt đầu chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'NGÀY BẮT ĐẦU',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.44,
                    color: Color(0xFF464F60),
                  ),
                ),
              ),

              // Ngày kết thúc chiếm 2 phần
              const Expanded(
                flex: 2,
                child: Text(
                  'NGÀY KẾT THÚC',
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

  Widget _buildTableRow(AcademicYearData academicYear, bool isEven) {
    final isSelected = _selectedAcademicYears.contains(academicYear.id);

    return DataTableRow<AcademicYearData>(
      data: academicYear,
      isEven: isEven,
      isSelected: isSelected,
      columns: _academicYearColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedAcademicYears.remove(academicYear.id);
          } else {
            _selectedAcademicYears.add(academicYear.id);
          }
        });
      },
      onEdit: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) =>
              EditAcademicYearModal(academicYear: academicYear),
        );
        if (result == true) {
          _loadAcademicYears(); // Reload data after successful edit
        }
      },
      onDelete: () async {
        try {
          final result = await _apiService.deleteAcademicYear(
            academicYear.apiId,
          );
          if (!mounted) return;

          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xóa năm học thành công'),
                backgroundColor: Colors.green,
              ),
            );
            _loadAcademicYears(); // Reload data after successful delete
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
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

class AcademicYearData implements AcademicYearTableRowData {
  @override
  final int id;
  @override
  final String name;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;

  final int apiId; // Store original API ID for operations

  // Required fields from TableRowData interface (not used for academic years)
  @override
  String get code => '';
  @override
  String get phone => '';
  @override
  String get email => '';
  @override
  String get birthDate => '';

  AcademicYearData({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.apiId,
  });
}
