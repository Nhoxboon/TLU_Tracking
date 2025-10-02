import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/widgets/common/custom_action_button.dart';

class CoursesManagementView extends StatefulWidget {
  const CoursesManagementView({super.key});

  @override
  State<CoursesManagementView> createState() => _CoursesManagementViewState();
}

class _CoursesManagementViewState extends State<CoursesManagementView> {
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Sample data for courses
  final List<CourseData> _courses = [
    CourseData(id: 1, name: 'K65', admissionYear: '2019'),
    CourseData(id: 2, name: 'K66', admissionYear: '2020'),
    CourseData(id: 3, name: 'K67', admissionYear: '2021'),
    CourseData(id: 4, name: 'K68', admissionYear: '2022'),
    CourseData(id: 5, name: 'K69', admissionYear: '2023'),
    CourseData(id: 6, name: 'K70', admissionYear: '2024'),
    CourseData(id: 7, name: 'K71', admissionYear: '2025'),
    CourseData(id: 8, name: 'K72', admissionYear: '2026'),
    CourseData(id: 9, name: 'K73', admissionYear: '2027'),
    CourseData(id: 10, name: 'K74', admissionYear: '2028'),
    CourseData(id: 11, name: 'K75', admissionYear: '2029'),
    CourseData(id: 12, name: 'K76', admissionYear: '2030'),
  ];

  final Set<int> _selectedCourses = <int>{};

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
      type: TableColumnType.actions,
      flex: 3,
      textAlign: TextAlign.right,
    ),
  ];

  // Pagination getters and methods
  int get totalPages => (_courses.length / _itemsPerPage).ceil();

  List<CourseData> get currentPageCourses {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _courses.sublist(
      startIndex,
      endIndex > _courses.length ? _courses.length : endIndex,
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
            'Bạn có chắc chắn muốn xóa ${_selectedCourses.length} khóa học đã chọn? Hành động này không thể hoàn tác.',
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
                  _courses.removeWhere(
                    (course) => _selectedCourses.contains(course.id),
                  );
                  _selectedCourses.clear();
                  // Reset to first page if current page is empty
                  if (currentPageCourses.isEmpty && _currentPage > 1) {
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
              child: Column(
                children: [
                  // Action bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: _selectedCourses.isEmpty
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
                                  onPressed: () {
                                    // TODO: implement add course functionality
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Thêm khóa học'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
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
                                '${_selectedCourses.length} khóa học đã chọn',
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
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Table rows
                                ...List.generate(_itemsPerPage, (index) {
                                  if (index < currentPageCourses.length) {
                                    final course = currentPageCourses[index];
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
                      color: const Color(0xFFF4F7FC).withValues(alpha: .75),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side: Items count
                        Text(
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageCourses.length} of ${_courses.length}',
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
                  value: currentPageCourses.every(
                    (course) => _selectedCourses.contains(course.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedCourses.addAll(
                          currentPageCourses.map((c) => c.id),
                        );
                      } else {
                        for (final course in currentPageCourses) {
                          _selectedCourses.remove(course.id);
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
    final isSelected = _selectedCourses.contains(course.id);

    return CustomDataTableRow<CourseData>(
      data: course,
      isEven: isEven,
      isSelected: isSelected,
      columns: _courseColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedCourses.remove(course.id);
          } else {
            _selectedCourses.add(course.id);
          }
        });
      },
      onEdit: () {
        // TODO: handle edit
      },
      onDelete: () {
        // TODO: handle delete
      },
    );
  }
}

// Custom data table row for courses since we need to handle the custom admission year field
class CustomDataTableRow<T extends CourseTableRowData> extends StatelessWidget {
  final T data;
  final bool isEven;
  final bool isSelected;
  final List<TableColumn> columns;
  final VoidCallback? onSelectionChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CustomDataTableRow({
    super.key,
    required this.data,
    required this.isEven,
    required this.isSelected,
    required this.columns,
    this.onSelectionChanged,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected
          ? const Color(0xFFCFDDFA) // màu highlight khi select
          : (isEven ? Colors.white : const Color(0xFFF9FAFC)), // màu thường
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 32,
            child: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                onSelectionChanged?.call();
              },
            ),
          ),

          // Dynamic columns
          ...columns.map((column) => _buildColumn(column)),
        ],
      ),
    );
  }

  Widget _buildColumn(TableColumn column) {
    switch (column.type) {
      case TableColumnType.id:
        return Expanded(
          flex: column.flex,
          child: Text(
            data.id.toString(),
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.name:
        return Expanded(
          flex: column.flex,
          child: Text(
            data.name,
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.custom:
        // Handle custom admission year field
        if (column.customValue == 'admissionYear') {
          return Expanded(
            flex: column.flex,
            child: Padding(
              padding: const EdgeInsets.only(right: 50.0),
              child: Text(
                data.admissionYear,
                textAlign: column.textAlign,
                style: _getTextStyle(column.styleType),
              ),
            ),
          );
        }
        return Expanded(
          flex: column.flex,
          child: Text(
            column.customValue ?? '',
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.actions:
        return Expanded(
          flex: column.flex,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onEdit != null) ...[
                CustomActionButton(
                  icon: Icons.edit_outlined,
                  iconColor: const Color(0xFF000000).withValues(alpha: 0.6),
                  onTap: onEdit!,
                  tooltip: "Chỉnh sửa",
                ),
                const SizedBox(width: 8),
              ],
              if (onDelete != null)
                CustomActionButton(
                  icon: Icons.delete_outline,
                  iconColor: const Color(0xFFEF3826),
                  onTap: onDelete!,
                  tooltip: "Xóa",
                  requiresConfirmation: true,
                  confirmationTitle: 'Xác nhận xóa',
                  confirmationMessage:
                      'Bạn có chắc chắn muốn xóa? Hành động này không thể hoàn tác.',
                ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  TextStyle _getTextStyle(TableColumnStyleType styleType) {
    switch (styleType) {
      case TableColumnStyleType.primary:
        return const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.28,
          color: Color(0xFF171C26),
        );
      case TableColumnStyleType.secondary:
        return const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.28,
          color: Color(0xFF464F60),
        );
      case TableColumnStyleType.normal:
        return const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF464F60),
        );
    }
  }
}

// Course data interface
abstract class CourseTableRowData extends TableRowData {
  String get admissionYear;
}

// Course data class
class CourseData implements CourseTableRowData {
  @override
  final int id;
  @override
  final String name;
  @override
  final String admissionYear;

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
  });
}
