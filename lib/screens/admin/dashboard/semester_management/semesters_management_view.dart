import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/widgets/common/confirmation_dialog.dart';
import 'package:android_app/screens/admin/dashboard/semester_management/add_semester_modal.dart';
import 'package:android_app/screens/admin/dashboard/semester_management/edit_semester_modal.dart';
import 'package:android_app/services/api_service.dart';

class SemestersManagementView extends StatefulWidget {
  const SemestersManagementView({super.key});

  @override
  State<SemestersManagementView> createState() =>
      _SemestersManagementViewState();
}

class _SemestersManagementViewState extends State<SemestersManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // API-backed data for semesters
  List<SemesterData> _semesters = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalItems = 0;
  int _totalPages = 0;
  final Map<int, int> _semesterIdMapping = {};
  final Map<int, String> _academicYearCache = {};

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
  int get totalPages => _totalPages == 0
      ? (_semesters.length / _itemsPerPage).ceil()
      : _totalPages;

  List<SemesterData> get currentPageSemesters {
    return _semesters;
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadSemesters();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadSemesters();
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final result = await ConfirmationDialog.show(
      context,
      title: 'Xác nhận xóa',
      message:
          'Bạn có chắc chắn muốn xóa ${_selectedSemesters.length} học kì đã chọn? Hành động này không thể hoàn tác.',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    );

    if (result == true) {
      await _handleBulkDelete();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSemesters();
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
      setState(() {
        _currentPage = 1; // Reset to first page when searching
      });
      _loadSemesters();
    }
  }

  Future<void> _loadSemesters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiService.getSemestersPaginated(
      page: _currentPage,
      limit: _itemsPerPage,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );

    if (!mounted) return;

    if (result.success && result.data != null) {
      final items = result.data!.items;
      final List<SemesterData> rows = [];
      _semesterIdMapping.clear();
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final apiId = (item['id'] as num).toInt();
        final name = (item['name'] as String?) ?? '';
        final academicYearId = (item['academic_year_id'] as num?)?.toInt();
        final start = DateTime.tryParse(item['start_date'] as String? ?? '');
        final end = DateTime.tryParse(item['end_date'] as String? ?? '');
        final uiId = ((_currentPage - 1) * _itemsPerPage) + i + 1;
        _semesterIdMapping[uiId] = apiId;
        rows.add(
          SemesterData(
            id: uiId,
            academicYear: _getAcademicYearName(academicYearId),
            semester: name,
            startDate: start ?? DateTime.now(),
            endDate: end ?? DateTime.now(),
            apiId: apiId,
            academicYearId: academicYearId,
          ),
        );
      }

      setState(() {
        _semesters = rows;
        _totalItems = result.data!.total;
        _totalPages = result.data!.totalPages;
        _isLoading = false;
        _selectedSemesters.clear();
      });

      // Lazy load academic year names
      await _preloadAcademicYearNames(rows);
    } else {
      setState(() {
        _semesters = [];
        _totalItems = 0;
        _totalPages = 0;
        _isLoading = false;
        _errorMessage = result.message;
        _selectedSemesters.clear();
      });
    }
  }

  String _getAcademicYearName(int? academicYearId) {
    if (academicYearId == null) return '';
    final cached = _academicYearCache[academicYearId];
    if (cached != null) return cached;
    // background fetch
    _loadSingleAcademicYear(academicYearId);
    return '';
  }

  Future<void> _preloadAcademicYearNames(List<SemesterData> rows) async {
    final ids = rows
        .map((r) => r.academicYearId)
        .where((id) => id != null && !_academicYearCache.containsKey(id))
        .cast<int>()
        .toSet();
    if (ids.isEmpty) return;
    final futures = ids.map((id) async {
      final res = await _apiService.getAcademicYear(id);
      if (res.success && res.data != null) {
        _academicYearCache[id] = res.data!['name'] ?? '';
      }
    });
    await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      _semesters = _semesters
          .map(
            (s) => SemesterData(
              id: s.id,
              academicYear: s.academicYearId != null
                  ? (_academicYearCache[s.academicYearId!] ?? s.academicYear)
                  : s.academicYear,
              semester: s.semester,
              startDate: s.startDate,
              endDate: s.endDate,
              apiId: s.apiId,
              academicYearId: s.academicYearId,
            ),
          )
          .toList();
    });
  }

  Future<void> _loadSingleAcademicYear(int id) async {
    if (_academicYearCache.containsKey(id)) return;
    final res = await _apiService.getAcademicYear(id);
    if (res.success && res.data != null) {
      setState(() {
        _academicYearCache[id] = res.data!['name'] ?? '';
        _semesters = _semesters
            .map(
              (s) => s.academicYearId == id
                  ? SemesterData(
                      id: s.id,
                      academicYear: _academicYearCache[id] ?? s.academicYear,
                      semester: s.semester,
                      startDate: s.startDate,
                      endDate: s.endDate,
                      apiId: s.apiId,
                      academicYearId: s.academicYearId,
                    )
                  : s,
            )
            .toList();
      });
    }
  }

  Future<void> _handleBulkDelete() async {
    try {
      final ids = _selectedSemesters
          .map((uiId) => _semesterIdMapping[uiId])
          .where((e) => e != null)
          .cast<int>()
          .toList();
      for (final id in ids) {
        await _apiService.deleteSemester(id);
      }
      if (mounted) {
        _loadSemesters();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa học kì được chọn'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                                  onPressed: () async {
                                    final result = await showDialog(
                                      context: context,
                                      builder: (context) =>
                                          const AddSemesterModal(),
                                    );
                                    if (result == true) {
                                      _currentPage = 1;
                                      _loadSemesters();
                                    }
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              if (_errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  color: const Color(0xFFFFE2E2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
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
                                      ...currentPageSemesters
                                          .asMap()
                                          .entries
                                          .map((entry) {
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
                          '${(_currentPage - 1) * _itemsPerPage + 1}-${_currentPage * _itemsPerPage > _totalItems ? _totalItems : _currentPage * _itemsPerPage} of ${_totalItems}',
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
      onEdit: () async {
        final result = await showDialog(
          context: context,
          builder: (context) => EditSemesterModal(semester: semester),
        );
        if (result == true) {
          _loadSemesters();
        }
      },
      onDelete: () async {
        try {
          final apiId = semester.apiId ?? _semesterIdMapping[semester.id];
          if (apiId == null) {
            throw Exception('Không tìm thấy ID học kì');
          }
          final res = await _apiService.deleteSemester(apiId);
          if (res.success) {
            _loadSemesters();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa học kì thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception(res.message);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi xóa: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
  // Extra fields for API operations
  final int? apiId;
  final int? academicYearId;

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
    this.apiId,
    this.academicYearId,
  });
}
