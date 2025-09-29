import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';

class ClassesManagementView extends StatefulWidget {
  const ClassesManagementView({super.key});

  @override
  State<ClassesManagementView> createState() => _ClassesManagementViewState();
}

class _ClassesManagementViewState extends State<ClassesManagementView> {
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Sample data for classes
  final List<ClassData> _classes = [
    ClassData(
      id: 1,
      code: 'CSE101',
      name: 'Lập trình cơ bản',
      teacher: 'Nguyễn Văn A',
      subject: 'Lập trình',
      creationDate: '12/04/2025',
    ),
    ClassData(
      id: 2,
      code: 'CSE102',
      name: 'Cấu trúc dữ liệu',
      teacher: 'Trần Thị B',
      subject: 'Khoa học máy tính',
      creationDate: '15/04/2025',
    ),
    ClassData(
      id: 3,
      code: 'CSE103',
      name: 'Cơ sở dữ liệu',
      teacher: 'Lê Văn C',
      subject: 'Cơ sở dữ liệu',
      creationDate: '18/04/2025',
    ),
    ClassData(
      id: 4,
      code: 'CSE104',
      name: 'Mạng máy tính',
      teacher: 'Phạm Thị D',
      subject: 'Mạng',
      creationDate: '20/04/2025',
    ),
    ClassData(
      id: 5,
      code: 'CSE105',
      name: 'Hệ điều hành',
      teacher: 'Hoàng Văn E',
      subject: 'Hệ thống',
      creationDate: '22/04/2025',
    ),
    ClassData(
      id: 6,
      code: 'CSE106',
      name: 'Phát triển web',
      teacher: 'Nguyễn Thị F',
      subject: 'Web',
      creationDate: '25/04/2025',
    ),
    ClassData(
      id: 7,
      code: 'CSE107',
      name: 'Thuật toán',
      teacher: 'Trần Văn G',
      subject: 'Thuật toán',
      creationDate: '28/04/2025',
    ),
    ClassData(
      id: 8,
      code: 'CSE108',
      name: 'Trí tuệ nhân tạo',
      teacher: 'Lê Thị H',
      subject: 'AI',
      creationDate: '30/04/2025',
    ),
    ClassData(
      id: 9,
      code: 'CSE109',
      name: 'Bảo mật thông tin',
      teacher: 'Phạm Văn I',
      subject: 'Bảo mật',
      creationDate: '02/05/2025',
    ),
    ClassData(
      id: 10,
      code: 'CSE110',
      name: 'Kỹ thuật phần mềm',
      teacher: 'Hoàng Thị J',
      subject: 'Phần mềm',
      creationDate: '05/05/2025',
    ),
    ClassData(
      id: 11,
      code: 'CSE111',
      name: 'Học máy',
      teacher: 'Nguyễn Văn K',
      subject: 'Machine Learning',
      creationDate: '08/05/2025',
    ),
    ClassData(
      id: 12,
      code: 'CSE112',
      name: 'Phân tích dữ liệu',
      teacher: 'Trần Thị L',
      subject: 'Data Science',
      creationDate: '10/05/2025',
    ),
  ];

  final Set<int> _selectedClasses = <int>{};

  // Column configuration for classes table
  static const List<TableColumn> _classColumns = [
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
      type: TableColumnType.teacher,
      flex: 2,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.subject,
      flex: 2,
      styleType: TableColumnStyleType.normal,
    ),
    TableColumn(
      type: TableColumnType.creationDate,
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
  int get totalPages => (_classes.length / _itemsPerPage).ceil();

  List<ClassData> get currentPageClasses {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _classes.sublist(
      startIndex,
      endIndex > _classes.length ? _classes.length : endIndex,
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
            'Quản lý lớp học',
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
                    child: Row(
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

                        // Filter buttons
                        _buildFilterButton('Lọc theo mã lớp'),
                        const SizedBox(width: 16),
                        _buildFilterButton('Lọc theo giảng viên'),
                        const SizedBox(width: 16),
                        _buildFilterButton('Lọc theo môn học'),

                        const Spacer(),

                        // Add class button
                        SizedBox(
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Handle add class
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Thêm lớp học',
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
                                  if (index < currentPageClasses.length) {
                                    final classData = currentPageClasses[index];
                                    final isEven = index % 2 == 0;
                                    return _buildTableRow(classData, isEven);
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
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageClasses.length} of ${_classes.length}',
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
              // Checkbox (fix nhỏ)
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: currentPageClasses.every(
                    (classData) => _selectedClasses.contains(classData.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedClasses.addAll(
                          currentPageClasses.map((c) => c.id),
                        );
                      } else {
                        for (final classData in currentPageClasses) {
                          _selectedClasses.remove(classData.id);
                        }
                      }
                    });
                  },
                ),
              ),

              // ID (#) chiếm 1 phần
              Expanded(
                flex: 1,
                child: Text(
                  '#',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Mã lớp chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'MÃ LỚP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Tên lớp chiếm 3 phần
              Expanded(
                flex: 3,
                child: Text(
                  'TÊN LỚP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Giảng viên chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'GIẢNG VIÊN',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Môn học chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'MÔN HỌC',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // Ngày tạo chiếm 2 phần
              Expanded(
                flex: 2,
                child: Text(
                  'NGÀY TẠO',
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

  Widget _buildTableRow(ClassData classData, bool isEven) {
    final isSelected = _selectedClasses.contains(classData.id);

    return GestureDetector(
      onDoubleTap: () {
        // Navigate to class students view
        Navigator.pushNamed(
          context,
          '/class-students',
          arguments: {'classCode': classData.code, 'className': classData.name},
        );
      },
      child: DataTableRow<ClassData>(
        data: classData,
        isEven: isEven,
        isSelected: isSelected,
        columns: _classColumns,
        onSelectionChanged: () {
          setState(() {
            if (isSelected) {
              _selectedClasses.remove(classData.id);
            } else {
              _selectedClasses.add(classData.id);
            }
          });
        },
        onEdit: () {
          // TODO: handle edit
        },
        onDelete: () {
          // TODO: handle delete
        },
      ),
    );
  }
}

class ClassData implements ClassTableRowData {
  @override
  final int id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String teacher;
  @override
  final String subject;
  @override
  final String creationDate;

  // Required fields from TableRowData interface
  @override
  String get phone => '';
  @override
  String get email => '';
  @override
  String get birthDate => creationDate;

  ClassData({
    required this.id,
    required this.code,
    required this.name,
    required this.teacher,
    required this.subject,
    required this.creationDate,
  });
}
