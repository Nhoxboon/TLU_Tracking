import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';

class ClassStudentsView extends StatefulWidget {
  final String classCode;
  final String className;

  const ClassStudentsView({
    super.key,
    required this.classCode,
    required this.className,
  });

  @override
  State<ClassStudentsView> createState() => _ClassStudentsViewState();
}

class _ClassStudentsViewState extends State<ClassStudentsView> {
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 12;

  // Sample data for students
  final List<StudentData> _students = [
    StudentData(
      id: 1,
      studentCode: '20210001',
      name: 'Ann Culhane',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'ann.culhane@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 2,
      studentCode: '20210002',
      name: 'Tatiana Mango',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'tatiana.mango@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 3,
      studentCode: '20210003',
      name: 'Ahmad Rosser',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'ahmad.rosser@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 4,
      studentCode: '20210004',
      name: 'Phillip Stanton',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'phillip.stanton@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 5,
      studentCode: '20210005',
      name: 'Zain Calzoni',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'zain.calzoni@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 6,
      studentCode: '20210006',
      name: 'Leo Stanton',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'leo.stanton@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 7,
      studentCode: '20210007',
      name: 'Kaiya Vetrovs',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'kaiya.vetrovs@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 8,
      studentCode: '20210008',
      name: 'Ryan Westervelt',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'ryan.westervelt@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 9,
      studentCode: '20210009',
      name: 'Corey Stanton',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'corey.stanton@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 10,
      studentCode: '20210010',
      name: 'Adison Aminoff',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'adison.aminoff@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 11,
      studentCode: '20210011',
      name: 'Alfredo Aminoff',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'alfredo.aminoff@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 12,
      studentCode: '20210012',
      name: 'Allison Botosh',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'allison.botosh@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 13,
      studentCode: '20210013',
      name: 'Allison Botosh',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'allison.botosh@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
    StudentData(
      id: 14,
      studentCode: '20210014',
      name: 'Allison Botosh',
      major: 'Công nghệ thông tin',
      phone: '11111111111',
      email: 'allison.botosh@example.com',
      birthDate: '12/05/2004',
      course: 'K65',
    ),
  ];

  final Set<int> _selectedStudents = <int>{};

  // Column configuration for students table
  static const List<TableColumn> _studentColumns = [
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
      type: TableColumnType.major,
      flex: 2,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.phone,
      flex: 2,
      textAlign: TextAlign.right,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.email,
      flex: 3,
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
      type: TableColumnType.course,
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
  int get totalPages => (_students.length / _itemsPerPage).ceil();

  List<StudentData> get currentPageStudents {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _students.sublist(
      startIndex,
      endIndex > _students.length ? _students.length : endIndex,
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

  void _showRemoveFromClassDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'Xác nhận xóa khỏi lớp',
            style: TextStyle(
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1F2937),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa ${_selectedStudents.length} sinh viên đã chọn khỏi lớp ${widget.className}? Hành động này không thể hoàn tác.',
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
                // Handle remove from class action
                setState(() {
                  _students.removeWhere(
                    (student) => _selectedStudents.contains(student.id),
                  );
                  _selectedStudents.clear();
                  // Reset to first page if current page is empty
                  if (currentPageStudents.isEmpty && _currentPage > 1) {
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
                'Xóa khỏi lớp',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and title
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Danh sách sinh viên của lớp ${widget.className}',
                  style: const TextStyle(
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    letterSpacing: -0.11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
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
                      child: _selectedStudents.isEmpty
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
                                const SizedBox(width: 20),
                                // Major filter dropdown
                                Container(
                                  height: 38,
                                  width: 226,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF687182,
                                      ).withValues(alpha: 0.16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Lọc theo ngành',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            color: Color(0xFFA1A9B8),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: const Color(0xFF717680),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Course filter dropdown
                                Container(
                                  height: 38,
                                  width: 226,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF687182,
                                      ).withValues(alpha: 0.16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Lọc theo khóa',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            color: Color(0xFFA1A9B8),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: const Color(0xFF717680),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // Import excel button
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Handle import excel
                                    },
                                    icon: const Icon(
                                      Icons.upload_file,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Nhập excel',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.28,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF46E522),
                                      foregroundColor: Colors.black,
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
                                const SizedBox(width: 16),

                                // Add student button
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Handle add student
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text(
                                      'Thêm sinh viên vào lớp',
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
                                  '${_selectedStudents.length} sinh viên đã chọn',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const Spacer(),
                                // Remove from class button
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showRemoveFromClassDialog();
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Xóa khỏi lớp',
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
                                    if (index < currentPageStudents.length) {
                                      final studentData =
                                          currentPageStudents[index];
                                      final isEven = index % 2 == 0;
                                      return _buildTableRow(
                                        studentData,
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
                            '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageStudents.length} of ${_students.length}',
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
                                              spreadRadius: 1,
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
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
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF9FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Checkbox (fix nhỏ)
          SizedBox(
            width: 32,
            child: Checkbox(
              value: currentPageStudents.every(
                (studentData) => _selectedStudents.contains(studentData.id),
              ),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedStudents.addAll(
                      currentPageStudents.map((s) => s.id),
                    );
                  } else {
                    for (final studentData in currentPageStudents) {
                      _selectedStudents.remove(studentData.id);
                    }
                  }
                });
              },
            ),
          ),

          // # chiếm 1 phần
          Expanded(
            flex: 1,
            child: Text(
              '#',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Mã sinh viên chiếm 2 phần
          Expanded(
            flex: 2,
            child: Text(
              'MÃ SV',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Tên chiếm 3 phần
          Expanded(
            flex: 3,
            child: Text(
              'TÊN',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Ngành chiếm 2 phần
          Expanded(
            flex: 2,
            child: Text(
              'NGÀNH',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Số điện thoại chiếm 2 phần
          Expanded(
            flex: 2,
            child: Text(
              'SỐ ĐIỆN THOẠI',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Email chiếm 3 phần
          Expanded(
            flex: 3,
            child: Text(
              'EMAIL',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Ngày sinh chiếm 2 phần
          Expanded(
            flex: 2,
            child: Text(
              'NGÀY SINH',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Khóa chiếm 2 phần
          Expanded(
            flex: 2,
            child: Text(
              'KHÓA',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // Hành động chiếm 2 phần
          Expanded(
            flex: 2,
            child: Text(
              'HÀNH ĐỘNG',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(StudentData studentData, bool isEven) {
    final isSelected = _selectedStudents.contains(studentData.id);

    return DataTableRow<StudentData>(
      data: studentData,
      isEven: isEven,
      isSelected: isSelected,
      columns: _studentColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedStudents.remove(studentData.id);
          } else {
            _selectedStudents.add(studentData.id);
          }
        });
      },
      onDelete: () {
        // TODO: handle delete student
      },
    );
  }
}

class StudentData implements StudentTableRowData {
  @override
  final int id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String major;
  @override
  final String phone;
  @override
  final String email;
  @override
  final String birthDate;
  @override
  final String course;

  StudentData({
    required this.id,
    required String studentCode,
    required this.name,
    required this.major,
    required this.phone,
    required this.email,
    required this.birthDate,
    required this.course,
  }) : code = studentCode;
}
