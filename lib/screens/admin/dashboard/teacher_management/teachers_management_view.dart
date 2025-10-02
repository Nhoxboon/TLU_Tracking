import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/teacher_management/add_teacher_modal.dart';
import 'package:android_app/screens/admin/dashboard/teacher_management/edit_teacher_modal.dart';

class TeachersManagementView extends StatefulWidget {
  const TeachersManagementView({super.key});

  @override
  State<TeachersManagementView> createState() => _TeachersManagementViewState();
}

class _TeachersManagementViewState extends State<TeachersManagementView> {
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Sample data for teachers
  final List<TeacherData> _teachers = [
    TeacherData(
      id: 1,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 2,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 3,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 4,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 5,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 6,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 7,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 8,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 9,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 10,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 11,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
    TeacherData(
      id: 12,
      code: '0000',
      name: 'Ann Culhane',
      phone: '11111111111',
      email: 'Lorem ipsum',
      birthDate: '12/05/2004',
    ),
  ];

  final Set<int> _selectedTeachers = <int>{};

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
      type: TableColumnType.actions,
      flex: 2,
      textAlign: TextAlign.right,
    ),
  ];

  // Pagination getters and methods
  int get totalPages => (_teachers.length / _itemsPerPage).ceil();

  List<TeacherData> get currentPageTeachers {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _teachers.sublist(
      startIndex,
      endIndex > _teachers.length ? _teachers.length : endIndex,
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
              onPressed: () {
                // Handle delete action
                setState(() {
                  _teachers.removeWhere(
                    (teacher) => _selectedTeachers.contains(teacher.id),
                  );
                  _selectedTeachers.clear();
                  // Reset to first page if current page is empty
                  if (currentPageTeachers.isEmpty && _currentPage > 1) {
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
                              const Spacer(),
                              // Add teacher button
                              SizedBox(
                                height: 38,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const AddTeacherModal();
                                      },
                                    );
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
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Table rows
                                ...List.generate(_itemsPerPage, (index) {
                                  if (index < currentPageTeachers.length) {
                                    final teacher = currentPageTeachers[index];
                                    final isEven = index % 2 == 0;
                                    return _buildTableRow(teacher, isEven);
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
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageTeachers.length} of ${_teachers.length}',
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
                  value: currentPageTeachers.every(
                    (teacher) => _selectedTeachers.contains(teacher.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedTeachers.addAll(
                          currentPageTeachers.map((t) => t.id),
                        );
                      } else {
                        for (final teacher in currentPageTeachers) {
                          _selectedTeachers.remove(teacher.id);
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
    final isSelected = _selectedTeachers.contains(teacher.id);

    return DataTableRow<TeacherData>(
      data: teacher,
      isEven: isEven,
      isSelected: isSelected,
      columns: _teacherColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedTeachers.remove(teacher.id);
          } else {
            _selectedTeachers.add(teacher.id);
          }
        });
      },
      onEdit: () {
        showDialog(
          context: context,
          builder: (context) => EditTeacherModal(teacher: teacher),
        );
      },
      onDelete: () {
        // TODO: handle delete
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

  TeacherData({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    required this.email,
    required this.birthDate,
  });
}
