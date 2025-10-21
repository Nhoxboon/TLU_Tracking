import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/department_management/add_department_modal.dart';
import 'package:android_app/screens/admin/dashboard/department_management/edit_department_modal.dart';

class DepartmentsManagementView extends StatefulWidget {
  const DepartmentsManagementView({super.key});

  @override
  State<DepartmentsManagementView> createState() =>
      _DepartmentsManagementViewState();
}

class _DepartmentsManagementViewState extends State<DepartmentsManagementView> {
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Faculties list (should come from a service in production)
  final List<String> _faculties = [
    'Công nghệ thông tin',
    'Kinh tế',
    'Ngoại ngữ',
    'Luật',
    'Toán - Tin',
    'Văn học',
  ];

  // Sample data for departments
  final List<DepartmentData> _departments = [
    DepartmentData(
      id: 1,
      code: 'BM001',
      name: 'Bộ môn Lập trình',
      faculty: 'Công nghệ thông tin',
    ),
    DepartmentData(
      id: 2,
      code: 'BM002',
      name: 'Bộ môn Mạng máy tính',
      faculty: 'Công nghệ thông tin',
    ),
    DepartmentData(
      id: 3,
      code: 'BM003',
      name: 'Bộ môn Trí tuệ nhân tạo',
      faculty: 'Công nghệ thông tin',
    ),
    DepartmentData(
      id: 4,
      code: 'BM004',
      name: 'Bộ môn Kinh tế vi mô',
      faculty: 'Kinh tế',
    ),
    DepartmentData(
      id: 5,
      code: 'BM005',
      name: 'Bộ môn Kinh tế vĩ mô',
      faculty: 'Kinh tế',
    ),
    DepartmentData(
      id: 6,
      code: 'BM006',
      name: 'Bộ môn Tiếng Anh',
      faculty: 'Ngoại ngữ',
    ),
    DepartmentData(
      id: 7,
      code: 'BM007',
      name: 'Bộ môn Tiếng Trung',
      faculty: 'Ngoại ngữ',
    ),
    DepartmentData(
      id: 8,
      code: 'BM008',
      name: 'Bộ môn Luật Dân sự',
      faculty: 'Luật',
    ),
    DepartmentData(
      id: 9,
      code: 'BM009',
      name: 'Bộ môn Toán học',
      faculty: 'Toán - Tin',
    ),
    DepartmentData(
      id: 10,
      code: 'BM010',
      name: 'Bộ môn Tin học ứng dụng',
      faculty: 'Toán - Tin',
    ),
    DepartmentData(
      id: 11,
      code: 'BM011',
      name: 'Bộ môn Văn học Việt Nam',
      faculty: 'Văn học',
    ),
    DepartmentData(
      id: 12,
      code: 'BM012',
      name: 'Bộ môn Văn học nước ngoài',
      faculty: 'Văn học',
    ),
  ];

  final Set<int> _selectedDepartments = <int>{};

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

  // Pagination getters and methods
  int get totalPages => (_departments.length / _itemsPerPage).ceil();

  List<DepartmentData> get currentPageDepartments {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _departments.sublist(
      startIndex,
      endIndex > _departments.length ? _departments.length : endIndex,
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
                // Handle delete action
                setState(() {
                  _departments.removeWhere(
                    (department) =>
                        _selectedDepartments.contains(department.id),
                  );
                  _selectedDepartments.clear();
                  // Reset to first page if current page is empty
                  if (currentPageDepartments.isEmpty && _currentPage > 1) {
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
                              _buildFilterButton('Lọc theo khoa'),
                              const Spacer(),
                              // Add button
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AddDepartmentModal(
                                      faculties: _faculties,
                                    ),
                                  );
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
                          child: ListView.builder(
                            itemCount: currentPageDepartments.length,
                            itemBuilder: (context, index) {
                              return _buildTableRow(
                                currentPageDepartments[index],
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
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageDepartments.length} of ${_departments.length}',
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

  Widget _buildFilterButton(String text) {
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA1A9B8),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF717680),
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
      onEdit: () {
        showDialog(
          context: context,
          builder: (context) => EditDepartmentModal(
            department: department,
            faculties: _faculties,
          ),
        );
      },
      onDelete: () {
        // TODO: handle delete
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
  });

  @override
  String get facultyName => faculty;
}
