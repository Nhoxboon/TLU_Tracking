import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/semester_management/add_semester_modal.dart';
import 'package:android_app/screens/admin/dashboard/semester_management/edit_semester_modal.dart';

class SemestersManagementView extends StatefulWidget {
  const SemestersManagementView({super.key});

  @override
  State<SemestersManagementView> createState() =>
      _SemestersManagementViewState();
}

class _SemestersManagementViewState extends State<SemestersManagementView> {
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Academic years list (should come from a service in production)
  final List<String> _academicYears = [
    '2024-2025',
    '2023-2024',
    '2022-2023',
    '2021-2022',
    '2020-2021',
    '2019-2020',
    '2018-2019',
    '2017-2018',
  ];

  // Sample data for semesters
  final List<SemesterData> _semesters = [
    SemesterData(
      id: 1,
      academicYear: '2024-2025',
      semester: '1',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2025, 1, 1),
    ),
    SemesterData(
      id: 2,
      academicYear: '2024-2025',
      semester: '2',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 6, 1),
    ),
    SemesterData(
      id: 3,
      academicYear: '2023-2024',
      semester: '1',
      startDate: DateTime(2023, 1, 1),
      endDate: DateTime(2024, 1, 1),
    ),
    SemesterData(
      id: 4,
      academicYear: '2023-2024',
      semester: '2',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 6, 1),
    ),
    SemesterData(
      id: 5,
      academicYear: '2022-2023',
      semester: '1',
      startDate: DateTime(2022, 1, 1),
      endDate: DateTime(2023, 1, 1),
    ),
    SemesterData(
      id: 6,
      academicYear: '2022-2023',
      semester: '2',
      startDate: DateTime(2023, 1, 1),
      endDate: DateTime(2023, 6, 1),
    ),
    SemesterData(
      id: 7,
      academicYear: '2021-2022',
      semester: '1',
      startDate: DateTime(2021, 1, 1),
      endDate: DateTime(2022, 1, 1),
    ),
    SemesterData(
      id: 8,
      academicYear: '2021-2022',
      semester: '2',
      startDate: DateTime(2022, 1, 1),
      endDate: DateTime(2022, 6, 1),
    ),
    SemesterData(
      id: 9,
      academicYear: '2020-2021',
      semester: '1',
      startDate: DateTime(2020, 1, 1),
      endDate: DateTime(2021, 1, 1),
    ),
    SemesterData(
      id: 10,
      academicYear: '2020-2021',
      semester: '2',
      startDate: DateTime(2021, 1, 1),
      endDate: DateTime(2021, 6, 1),
    ),
    SemesterData(
      id: 11,
      academicYear: '2019-2020',
      semester: '1',
      startDate: DateTime(2019, 1, 1),
      endDate: DateTime(2020, 1, 1),
    ),
    SemesterData(
      id: 12,
      academicYear: '2019-2020',
      semester: '2',
      startDate: DateTime(2020, 1, 1),
      endDate: DateTime(2020, 6, 1),
    ),
  ];

  final Set<int> _selectedSemesters = <int>{};

  // Column configuration for semesters table
  static const List<TableColumn> _semesterColumns = [
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
      type: TableColumnType.semester,
      flex: 1,
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
  int get totalPages => (_semesters.length / _itemsPerPage).ceil();

  List<SemesterData> get currentPageSemesters {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _semesters.sublist(
      startIndex,
      endIndex > _semesters.length ? _semesters.length : endIndex,
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
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
            'Bạn có chắc chắn muốn xóa ${_selectedSemesters.length} học kì đã chọn? Hành động này không thể hoàn tác.',
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
                setState(() {
                  _semesters.removeWhere(
                    (semester) => _selectedSemesters.contains(semester.id),
                  );
                  _selectedSemesters.clear();
                  // Reset to first page if current page is empty
                  if (currentPageSemesters.isEmpty && _currentPage > 1) {
                    _currentPage = 1;
                  }
                });
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
            'Quản lý học kì',
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
                    child: _selectedSemesters.isEmpty
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

                              // Add semester button
                              SizedBox(
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AddSemesterModal(
                                        academicYears: _academicYears,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 12),
                                  label: const Text(
                                    'Thêm học kì',
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
                                '${_selectedSemesters.length} học kì đã chọn',
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
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                ...currentPageSemesters.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final semester = entry.value;
                                  return _buildTableRow(
                                    semester,
                                    index % 2 == 0,
                                  );
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
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _semesters.length ? _semesters.length : _currentPage * _itemsPerPage} of ${_semesters.length}',
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
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _currentPage > 1
                                      ? const Color(0xFFF7F9FC)
                                      : const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _currentPage > 1
                                        ? const Color(
                                            0xFF464F60,
                                          ).withValues(alpha: 0.24)
                                        : const Color(
                                            0xFF464F60,
                                          ).withValues(alpha: 0.12),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 16,
                                  color: _currentPage > 1
                                      ? const Color(0xFF868FA0)
                                      : const Color(
                                          0xFF868FA0,
                                        ).withValues(alpha: 0.4),
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
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _currentPage < totalPages
                                      ? Colors.white
                                      : const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _currentPage < totalPages
                                        ? const Color(
                                            0xFF464F60,
                                          ).withValues(alpha: 0.24)
                                        : const Color(
                                            0xFF464F60,
                                          ).withValues(alpha: 0.12),
                                    width: 1,
                                  ),
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
                                          const BoxShadow(
                                            color: Color(0x1A000000),
                                            blurRadius: 1,
                                            offset: Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: _currentPage < totalPages
                                      ? const Color(0xFF171C26)
                                      : const Color(
                                          0xFF868FA0,
                                        ).withValues(alpha: 0.4),
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
                  value: currentPageSemesters.every(
                    (semester) => _selectedSemesters.contains(semester.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedSemesters.addAll(
                          currentPageSemesters.map((s) => s.id),
                        );
                      } else {
                        _selectedSemesters.removeAll(
                          currentPageSemesters.map((s) => s.id),
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

              // Học kì chiếm 1 phần
              const Expanded(
                flex: 1,
                child: Text(
                  'HỌC KÌ',
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

  Widget _buildTableRow(SemesterData semester, bool isEven) {
    final isSelected = _selectedSemesters.contains(semester.id);

    return DataTableRow<SemesterData>(
      data: semester,
      isEven: isEven,
      isSelected: isSelected,
      columns: _semesterColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedSemesters.remove(semester.id);
          } else {
            _selectedSemesters.add(semester.id);
          }
        });
      },
      onEdit: () {
        showDialog(
          context: context,
          builder: (context) => EditSemesterModal(
            semester: semester,
            academicYears: _academicYears,
          ),
        );
      },
      onDelete: () {
        // TODO: handle delete
      },
    );
  }
}

class SemesterData implements SemesterTableRowData {
  @override
  final int id;
  @override
  final String academicYear;
  @override
  final String semester;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;

  // Required fields from TableRowData interface (not used for semesters)
  @override
  String get name => '';
  @override
  String get code => '';
  @override
  String get phone => '';
  @override
  String get email => '';
  @override
  String get birthDate => '';

  SemesterData({
    required this.id,
    required this.academicYear,
    required this.semester,
    required this.startDate,
    required this.endDate,
  });
}
