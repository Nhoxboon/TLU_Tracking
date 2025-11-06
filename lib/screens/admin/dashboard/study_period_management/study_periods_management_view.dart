import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/common/custom_search_bar.dart';
import 'package:android_app/widgets/common/data_table_row.dart';
import 'package:android_app/screens/admin/dashboard/study_period_management/add_study_period_modal.dart';
import 'package:android_app/screens/admin/dashboard/study_period_management/edit_study_period_modal.dart';
import 'package:android_app/services/api_service.dart';

class StudyPeriodsManagementView extends StatefulWidget {
  const StudyPeriodsManagementView({super.key});

  @override
  State<StudyPeriodsManagementView> createState() =>
      _StudyPeriodsManagementViewState();
}

class _StudyPeriodsManagementViewState
    extends State<StudyPeriodsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Academic years data from API
  List<Map<String, dynamic>> _academicYears = [];
  // Semesters data from API
  List<Map<String, dynamic>> _semesters = [];
  // Cache for academic year and semester names
  final Map<int, String> _academicYearCache = {};
  final Map<int, String> _semesterCache = {};

  // API-backed data for study periods
  List<StudyPeriodData> _studyPeriods = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalItems = 0;
  int _totalPages = 0;
  // Map UI row id -> API id
  final Map<int, int> _studyPeriodIdMapping = {};

  final Set<int> _selectedStudyPeriods = <int>{};

  // Column configuration for study periods table
  static const List<TableColumn> _studyPeriodColumns = [
    TableColumn(
      type: TableColumnType.id,
      flex: 1,
      styleType: TableColumnStyleType.primary,
    ),
    TableColumn(
      type: TableColumnType.semester,
      flex: 1,
      styleType: TableColumnStyleType.secondary,
    ),
    TableColumn(
      type: TableColumnType.period,
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
      type: TableColumnType.academicYearName,
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
      ? (_studyPeriods.length / _itemsPerPage).ceil()
      : _totalPages;

  List<StudyPeriodData> get currentPageStudyPeriods {
    return _studyPeriods;
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadStudyPhases();
    }
  }

  void _goToNextPage() {
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadStudyPhases();
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
            'Bạn có chắc chắn muốn xóa ${_selectedStudyPeriods.length} đợt học đã chọn? Hành động này không thể hoàn tác.',
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
              onPressed: _handleBulkDelete,
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
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load academic years and semesters first, then study phases
    await Future.wait([_loadAcademicYears(), _loadSemesters()]);
    // Load study phases after caches are populated
    await _loadStudyPhases();
  }

  Future<void> _loadStudyPhases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiService.getStudyPhasesPaginated(
      page: _currentPage,
      limit: _itemsPerPage,
    );

    if (mounted) {
      if (result.success && result.data != null) {
        final items = result.data!.items;
        final List<StudyPeriodData> rows = [];
        _studyPeriodIdMapping.clear();
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final apiId = (item['id'] as num).toInt();
          final start = DateTime.tryParse(item['start_date'] as String? ?? '');
          final end = DateTime.tryParse(item['end_date'] as String? ?? '');
          final semesterId = item['semester_id'] as int?;
          // Use 'name' field as period since API doesn't have 'period' field
          final period = item['name'] as String? ?? '';

          // Get academic_year_id from semester data
          int? academicYearId;
          if (semesterId != null) {
            // Find semester in _semesters list to get academic_year_id
            final semester = _semesters.firstWhere(
              (s) => s['id'] == semesterId,
              orElse: () => <String, dynamic>{},
            );
            academicYearId = semester['academic_year_id'] as int?;
          }

          // Map API to UI row
          final uiId = ((_currentPage - 1) * _itemsPerPage) + i + 1;
          _studyPeriodIdMapping[uiId] = apiId;

          rows.add(
            StudyPeriodData(
              id: uiId,
              academicYear: _getAcademicYearName(academicYearId),
              semester: _getSemesterName(semesterId),
              period: period,
              startDate: start ?? DateTime.now(),
              endDate: end ?? DateTime.now(),
              apiId: apiId,
              semesterId: semesterId,
              academicYearId: academicYearId,
            ),
          );
        }

        setState(() {
          _studyPeriods = rows;
          _totalItems = result.data!.total;
          _totalPages = result.data!.totalPages;
          _isLoading = false;
          _selectedStudyPeriods.clear();
        });
      } else {
        setState(() {
          _studyPeriods = [];
          _totalItems = 0;
          _totalPages = 0;
          _isLoading = false;
          _errorMessage = result.message;
          _selectedStudyPeriods.clear();
        });
      }
    }
  }

  Future<void> _handleBulkDelete() async {
    try {
      final ids = _selectedStudyPeriods
          .map((uiId) => _studyPeriodIdMapping[uiId])
          .where((e) => e != null)
          .cast<int>()
          .toList();
      for (final id in ids) {
        await _apiService.deleteStudyPhase(id);
      }
      if (mounted) {
        Navigator.of(context).pop();
        _loadStudyPhases();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa đợt học đã chọn'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAcademicYears() async {
    try {
      final result = await _apiService.getAcademicYearsPaginated(limit: 100);
      if (result.success && result.data != null) {
        setState(() {
          _academicYears = result.data!.items;
        });
        // Cache academic year names
        for (final academicYear in _academicYears) {
          final id = (academicYear['id'] as num).toInt();
          final name = academicYear['name'] as String? ?? 'Unknown';
          _academicYearCache[id] = name;
        }
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _loadSemesters() async {
    try {
      final result = await _apiService.getSemestersPaginated(limit: 100);

      if (result.success && result.data != null) {
        setState(() {
          _semesters = result.data!.items;
        });
        // Cache semester names
        for (final semester in _semesters) {
          final id = (semester['id'] as num).toInt();
          final name = semester['name'] as String? ?? 'Unknown';
          _semesterCache[id] = name;
        }
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  String _getAcademicYearName(int? academicYearId) {
    if (academicYearId == null) return 'Chưa xác định';
    return _academicYearCache[academicYearId] ?? 'Đang tải...';
  }

  String _getSemesterName(int? semesterId) {
    if (semesterId == null) return 'Chưa xác định';
    return _semesterCache[semesterId] ?? 'Đang tải...';
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
            'Quản lý đợt học',
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
                        style: const TextStyle(color: Color(0xFFB91C1C)),
                      ),
                    ),
                  // Action bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: _selectedStudyPeriods.isEmpty
                        ? Row(
                            children: [
                              // Search field
                              CustomSearchBar(
                                controller: _searchController,
                                hintText: 'Tìm kiếm...',
                                onChanged: (value) {
                                  // TODO: Implement search
                                },
                                onClear: () {
                                  _searchController.clear();
                                },
                              ),
                              const Spacer(),

                              // Add study period button
                              SizedBox(
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await showDialog(
                                      context: context,
                                      builder: (context) => AddStudyPeriodModal(
                                        academicYears: _academicYears,
                                      ),
                                    );
                                    if (result == true) {
                                      _currentPage = 1;
                                      _loadStudyPhases();
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text(
                                    'Thêm đợt học',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              // Selected items count
                              Text(
                                '${_selectedStudyPeriods.length} đợt học đã chọn',
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
                                  onPressed: _showDeleteConfirmationDialog,
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text(
                                    'Xóa',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
                                      for (
                                        int i = 0;
                                        i < currentPageStudyPeriods.length;
                                        i++
                                      )
                                        _buildTableRow(
                                          currentPageStudyPeriods[i],
                                          i % 2 == 0,
                                        ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentPage > 1
                                      ? const Color(0xFFF7F9FC)
                                      : const Color(
                                          0xFFF7F9FC,
                                        ).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _currentPage > 1
                                        ? const Color(
                                            0xFF464F60,
                                          ).withValues(alpha: 0.24)
                                        : const Color(
                                            0xFF464F60,
                                          ).withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 16,
                                  color: _currentPage > 1
                                      ? const Color(0xFF868FA0)
                                      : const Color(
                                          0xFF868FA0,
                                        ).withValues(alpha: 0.5),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentPage < totalPages
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _currentPage < totalPages
                                        ? const Color(
                                            0xFF464F60,
                                          ).withValues(alpha: 0.24)
                                        : const Color(
                                            0xFF464F60,
                                          ).withValues(alpha: 0.12),
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
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 1,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: _currentPage < totalPages
                                      ? const Color(0xFF868FA0)
                                      : const Color(
                                          0xFF868FA0,
                                        ).withValues(alpha: 0.5),
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
                  value: currentPageStudyPeriods.every(
                    (period) => _selectedStudyPeriods.contains(period.id),
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedStudyPeriods.addAll(
                          currentPageStudyPeriods.map((p) => p.id),
                        );
                      } else {
                        _selectedStudyPeriods.removeAll(
                          currentPageStudyPeriods.map((p) => p.id),
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
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(1),
                              topRight: Radius.circular(1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_drop_up,
                            size: 5,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 7,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFBCC2CE),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(1),
                              bottomRight: Radius.circular(1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_drop_down,
                            size: 5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
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

              // Đợt học chiếm 1 phần
              const Expanded(
                flex: 1,
                child: Text(
                  'ĐỢT HỌC',
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

  Widget _buildTableRow(StudyPeriodData period, bool isEven) {
    final isSelected = _selectedStudyPeriods.contains(period.id);

    return DataTableRow<StudyPeriodData>(
      data: period,
      isEven: isEven,
      isSelected: isSelected,
      columns: _studyPeriodColumns,
      onSelectionChanged: () {
        setState(() {
          if (isSelected) {
            _selectedStudyPeriods.remove(period.id);
          } else {
            _selectedStudyPeriods.add(period.id);
          }
        });
      },
      onEdit: () async {
        final result = await showDialog(
          context: context,
          builder: (context) => EditStudyPeriodModal(
            studyPeriod: period,
            academicYears: _academicYears,
          ),
        );

        // Refresh data if study period was updated
        if (result == true) {
          _loadStudyPhases();

          // Show success message with note about position
          if (mounted) {}
        }
      },
      onDelete: () async {
        try {
          final apiId = period.apiId ?? _studyPeriodIdMapping[period.id];
          if (apiId == null) {
            throw Exception('Không tìm thấy ID đợt học');
          }
          final res = await _apiService.deleteStudyPhase(apiId);
          if (res.success) {
            _loadStudyPhases();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa đợt học thành công!'),
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

class StudyPeriodData implements StudyPeriodTableRowData {
  @override
  final int id;
  @override
  final String academicYear;
  @override
  final String semester;
  @override
  final String period;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  // Keep track of API ID for operations
  final int? apiId;
  // Additional fields for API operations
  final int? semesterId;
  final int? academicYearId;

  // Required fields from TableRowData interface (not used for study periods)
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

  StudyPeriodData({
    required this.id,
    required this.academicYear,
    required this.semester,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.apiId,
    this.semesterId,
    this.academicYearId,
  });
}
