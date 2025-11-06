import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/class_management/add_student_to_class_modal.dart';
import 'package:android_app/services/api_service.dart';

class ClassStudentsView extends StatefulWidget {
  final int classId;
  final String classCode;
  final String className;

  const ClassStudentsView({
    super.key,
    required this.classId,
    required this.classCode,
    required this.className,
  });

  @override
  State<ClassStudentsView> createState() => _ClassStudentsViewState();
}

class _ClassStudentsViewState extends State<ClassStudentsView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 12;

  // API data for students
  List<StudentData> _students = [];
  List<StudentData> _filteredStudents = [];
  bool _isLoading = false;
  String? _errorMessage;

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

  @override
  void initState() {
    super.initState();
    _loadStudents();
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
    _filterStudents();
  }

  void _filterStudents() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredStudents = _students;
      } else {
        final searchQuery = _searchController.text.toLowerCase();
        _filteredStudents = _students.where((student) {
          return student.name.toLowerCase().contains(searchQuery) ||
              student.code.toLowerCase().contains(searchQuery) ||
              student.email.toLowerCase().contains(searchQuery) ||
              student.phone.contains(searchQuery);
        }).toList();
      }
      _currentPage = 1; // Reset to first page when filtering
    });
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getClassStudents(widget.classId);

      if (result.success && result.data != null) {
        setState(() {
          _students = result.data!.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final student = entry.value;
            return StudentData(
              id: student['student_id'] ?? index,
              studentCode: student['student_code'] ?? '',
              name: student['student_name'] ?? 'Không xác định',
              major: 'Chưa cập nhật', // API doesn't return major info
              phone: student['student_phone'] ?? '',
              email: student['student_email'] ?? '',
              birthDate: _formatDate(student['enrolled_at']),
              course: 'Chưa cập nhật', // API doesn't return course info
              enrollmentId: student['id'], // Store enrollment ID for deletion
            );
          }).toList();
          _filteredStudents = _students;
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
        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return 'Không xác định';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Không xác định';
    }
  }

  Future<void> _removeSelectedStudentsFromClass() async {
    if (_selectedStudents.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedStudentData = _students
          .where((student) => _selectedStudents.contains(student.id))
          .toList();

      // Remove students from class using API
      for (final student in selectedStudentData) {
        await _apiService.removeStudentFromClass(widget.classId, student.id);
      }

      // Reload the students list after successful removal
      await _loadStudents();

      setState(() {
        _selectedStudents.clear();
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xóa ${selectedStudentData.length} sinh viên khỏi lớp thành công',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa sinh viên: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeIndividualStudent(StudentData student) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.removeStudentFromClass(widget.classId, student.id);

      // Reload the students list after successful removal
      await _loadStudents();

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xóa sinh viên ${student.name} khỏi lớp thành công',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa sinh viên: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Pagination getters and methods
  int get totalPages => (_filteredStudents.length / _itemsPerPage).ceil();

  List<StudentData> get currentPageStudents {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredStudents.sublist(
      startIndex,
      endIndex > _filteredStudents.length ? _filteredStudents.length : endIndex,
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
                Navigator.of(context).pop();
                _removeSelectedStudentsFromClass();
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
                                    onPressed: () async {
                                      final result = await showDialog<bool>(
                                        context: context,
                                        builder: (context) =>
                                            AddStudentToClassModal(
                                              classId: widget.classId,
                                              classCode: widget.classCode,
                                              className: widget.className,
                                            ),
                                      );

                                      // If student was added successfully, reload the list
                                      if (result == true) {
                                        _loadStudents();
                                      }
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
                                const SizedBox(width: 12),

                                // Refresh button
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: _loadStudents,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text(
                                      'Làm mới',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.28,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B7280),
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

                          // Table content
                          Flexible(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _errorMessage != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: Colors.red[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Lỗi: $_errorMessage',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.red,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadStudents,
                                          child: const Text('Thử lại'),
                                        ),
                                      ],
                                    ),
                                  )
                                : currentPageStudents.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Không có sinh viên nào trong lớp',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        // Table rows
                                        ...List.generate(_itemsPerPage, (
                                          index,
                                        ) {
                                          if (index <
                                              currentPageStudents.length) {
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
                            '${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage - 1) * _itemsPerPage + currentPageStudents.length} of ${_filteredStudents.length}',
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
                        borderRadius: BorderRadius.all(Radius.circular(0.5)),
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
                        borderRadius: BorderRadius.all(Radius.circular(0.5)),
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
        _removeIndividualStudent(studentData);
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

  // Additional fields for API operations
  final int? enrollmentId;

  StudentData({
    required this.id,
    required String studentCode,
    required this.name,
    required this.major,
    required this.phone,
    required this.email,
    required this.birthDate,
    required this.course,
    this.enrollmentId,
  }) : code = studentCode;
}
