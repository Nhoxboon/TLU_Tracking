import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import 'student_class_detail_screen.dart';

class ClassSearchScreen extends StatefulWidget {
  const ClassSearchScreen({Key? key}) : super(key: key);

  @override
  State<ClassSearchScreen> createState() => _ClassSearchScreenState();
}

class _ClassSearchScreenState extends State<ClassSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedClassCode;
  String? _selectedTeacher;
  String? _selectedSubject;
  String? _selectedFaculty;
  String? _selectedCohort;

  List<_ClassItem> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  // Cache for dropdown data
  List<Map<String, dynamic>> _classCodes = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _cohorts = [];

  // Dropdown expansion states
  String? _expandedFilter; // 'classCode', 'teacher', 'subject', 'faculty', 'cohort'
  
  // Pagination for dropdowns
  final Map<String, int> _displayedCounts = {
    'classCode': 5,
    'teacher': 5,
    'subject': 5,
    'faculty': 5,
    'cohort': 5,
  };
  
  bool _isLoadingDropdown = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final studentId = UserSession().profileId;
    if (studentId == null) {
      setState(() {
        _error = 'Không xác định được student_id. Vui lòng đăng nhập lại.';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final baseUrl = ApiService.baseUrl;
      // Build query params
      final params = <String, String>{'active_only': 'true'};
      
      // Add filters if selected
      // Note: Backend might not support all these filters on student endpoint
      // This is a placeholder - adjust based on actual API capabilities
      
      final url = Uri.parse('$baseUrl/classes/student/$studentId').replace(queryParameters: params);

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      debugPrint('DEBUG - Search URL: $url');
      final resp = await http.get(url, headers: headers);
      debugPrint('DEBUG - Search Status: ${resp.statusCode}');
      debugPrint('DEBUG - Search Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        
        // Client-side filtering based on selections
        final allResults = data.map((e) {
          final m = e as Map<String, dynamic>;
          return _ClassItem(
            id: (m['id'] ?? 0) is int ? m['id'] as int : int.tryParse('${m['id']}') ?? 0,
            title: (m['name'] ?? m['class_name'] ?? 'Chưa rõ').toString(),
            code: (m['code'] ?? m['class_code'] ?? '—').toString(),
            students: (m['student_count'] ?? m['students_count'] ?? 0) as int,
            teacherName: (m['teacher_name'] ?? '').toString(),
            subjectName: (m['subject_name'] ?? '').toString(),
            facultyName: (m['faculty_name'] ?? '').toString(),
            cohortName: (m['cohort_name'] ?? '').toString(),
          );
        }).toList();

        // Apply client-side filters
        final filtered = allResults.where((item) {
          if (_searchController.text.isNotEmpty) {
            final q = _searchController.text.toLowerCase();
            if (!item.title.toLowerCase().contains(q) &&
                !item.code.toLowerCase().contains(q)) {
              return false;
            }
          }
          if (_selectedClassCode != null && item.code != _selectedClassCode) return false;
          if (_selectedTeacher != null && item.teacherName != _selectedTeacher) return false;
          if (_selectedSubject != null && item.subjectName != _selectedSubject) return false;
          if (_selectedFaculty != null && item.facultyName != _selectedFaculty) return false;
          if (_selectedCohort != null && item.cohortName != _selectedCohort) return false;
          return true;
        }).toList();

        setState(() {
          _searchResults = filtered;
        });
      } else {
        setState(() {
          _error = 'Lỗi tìm kiếm (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: GestureDetector(
                onTap: () {
                  // Focus the text field when tapping the container
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0x142196F3), // #2196F3 @ 8%
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x4D333333)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, size: 24, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm lớp',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: 16,
                              height: 1.235,
                              letterSpacing: -0.32,
                              color: Color(0xB3333333), // 70%
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Filter chips with inline dropdowns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChip(
                    filterKey: 'classCode',
                    label: 'Lọc theo mã lớp',
                    value: _selectedClassCode,
                    onTap: () => _toggleDropdown('classCode'),
                  ),
                  if (_expandedFilter == 'classCode')
                    _buildDropdownList(
                      items: _classCodes,
                      filterKey: 'classCode',
                      displayField: 'code',
                      onSelect: (value) {
                        setState(() {
                          _selectedClassCode = value;
                          _expandedFilter = null;
                        });
                      },
                    ),
                  const SizedBox(height: 8),
                  
                  _buildFilterChip(
                    filterKey: 'teacher',
                    label: 'Lọc theo giảng viên',
                    value: _selectedTeacher,
                    onTap: () => _toggleDropdown('teacher'),
                  ),
                  if (_expandedFilter == 'teacher')
                    _buildDropdownList(
                      items: _teachers,
                      filterKey: 'teacher',
                      displayField: 'full_name',
                      secondaryField: 'teacher_code',
                      onSelect: (value) {
                        setState(() {
                          _selectedTeacher = value;
                          _expandedFilter = null;
                        });
                      },
                    ),
                  const SizedBox(height: 8),
                  
                  _buildFilterChip(
                    filterKey: 'subject',
                    label: 'Lọc theo môn học',
                    value: _selectedSubject,
                    onTap: () => _toggleDropdown('subject'),
                  ),
                  if (_expandedFilter == 'subject')
                    _buildDropdownList(
                      items: _subjects,
                      filterKey: 'subject',
                      displayField: 'name',
                      secondaryField: 'code',
                      onSelect: (value) {
                        setState(() {
                          _selectedSubject = value;
                          _expandedFilter = null;
                        });
                      },
                    ),
                  const SizedBox(height: 8),
                  
                  _buildFilterChip(
                    filterKey: 'faculty',
                    label: 'Lọc theo khoa',
                    value: _selectedFaculty,
                    onTap: () => _toggleDropdown('faculty'),
                  ),
                  if (_expandedFilter == 'faculty')
                    _buildDropdownList(
                      items: _faculties,
                      filterKey: 'faculty',
                      displayField: 'name',
                      secondaryField: 'code',
                      onSelect: (value) {
                        setState(() {
                          _selectedFaculty = value;
                          _expandedFilter = null;
                        });
                      },
                    ),
                  const SizedBox(height: 8),
                  
                  _buildFilterChip(
                    filterKey: 'cohort',
                    label: 'Lọc theo khóa',
                    value: _selectedCohort,
                    onTap: () => _toggleDropdown('cohort'),
                  ),
                  if (_expandedFilter == 'cohort')
                    _buildDropdownList(
                      items: _cohorts,
                      filterKey: 'cohort',
                      displayField: 'name',
                      onSelect: (value) {
                        setState(() {
                          _selectedCohort = value;
                          _expandedFilter = null;
                        });
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _performSearch,
                                  child: const Text('Thử lại'),
                                )
                              ],
                            ),
                          ),
                        )
                      : _searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                'Nhấn nút tìm kiếm để xem kết quả',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];
                                return _ClassCard(
                                  item: item,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentClassDetailScreen(
                                          classCode: item.code,
                                          className: item.title,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),

      // Floating search button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _performSearch,
        backgroundColor: const Color(0xFF2196F3),
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text(
          'Tìm kiếm',
          style: TextStyle(
            fontFamily: 'Sen',
            fontSize: 13.67,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // Bottom nav
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 100,
              offset: const Offset(0, -10),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Color(0xFF2196F3)),
              onPressed: () => Navigator.pop(context),
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: Colors.black.withOpacity(0.7)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDropdown(String filterKey) async {
    if (_expandedFilter == filterKey) {
      setState(() => _expandedFilter = null);
      return;
    }

    setState(() {
      _expandedFilter = filterKey;
      _isLoadingDropdown = true;
      _displayedCounts[filterKey] = 5; // Reset to 5 items
    });

    // Fetch data if not cached
    switch (filterKey) {
      case 'classCode':
        if (_classCodes.isEmpty) await _fetchClassCodes();
        break;
      case 'teacher':
        if (_teachers.isEmpty) await _fetchTeachers();
        break;
      case 'subject':
        if (_subjects.isEmpty) await _fetchSubjects();
        break;
      case 'faculty':
        if (_faculties.isEmpty) await _fetchFaculties();
        break;
      case 'cohort':
        if (_cohorts.isEmpty) await _fetchCohorts();
        break;
    }

    if (mounted) {
      setState(() => _isLoadingDropdown = false);
    }
  }

  void _loadMoreItems(String filterKey) {
    setState(() {
      _displayedCounts[filterKey] = (_displayedCounts[filterKey] ?? 5) + 5;
    });
  }

  Widget _buildDropdownList({
    required List<Map<String, dynamic>> items,
    required String filterKey,
    required String displayField,
    String? secondaryField,
    required Function(String) onSelect,
  }) {
    final displayCount = _displayedCounts[filterKey] ?? 5;
    final visibleItems = items.take(displayCount).toList();
    final hasMore = items.length > displayCount;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoadingDropdown)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // Clear filter button
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFEAECF0)),
                ),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.clear, size: 20, color: Colors.red),
                title: const Text(
                  'Xóa bộ lọc',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  setState(() {
                    switch (filterKey) {
                      case 'classCode':
                        _selectedClassCode = null;
                        break;
                      case 'teacher':
                        _selectedTeacher = null;
                        break;
                      case 'subject':
                        _selectedSubject = null;
                        break;
                      case 'faculty':
                        _selectedFaculty = null;
                        break;
                      case 'cohort':
                        _selectedCohort = null;
                        break;
                    }
                    _expandedFilter = null;
                  });
                },
              ),
            ),
            
            // Items list
            if (visibleItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ...visibleItems.map((item) {
                final displayValue = item[displayField]?.toString() ?? '';
                final secondaryValue = secondaryField != null 
                    ? item[secondaryField]?.toString() 
                    : null;
                final fullText = secondaryValue != null 
                    ? '$displayValue ($secondaryValue)' 
                    : displayValue;
                
                String? selectedValue;
                switch (filterKey) {
                  case 'classCode':
                    selectedValue = _selectedClassCode;
                    break;
                  case 'teacher':
                    selectedValue = _selectedTeacher;
                    break;
                  case 'subject':
                    selectedValue = _selectedSubject;
                    break;
                  case 'faculty':
                    selectedValue = _selectedFaculty;
                    break;
                  case 'cohort':
                    selectedValue = _selectedCohort;
                    break;
                }
                
                final isSelected = selectedValue == displayValue;
                
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFEAECF0).withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      fullText,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF2196F3), size: 20)
                        : null,
                    onTap: () => onSelect(displayValue),
                  ),
                );
              }).toList(),
            
            // Load more button
            if (hasMore)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: const Color(0xFFEAECF0)),
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.expand_more, size: 20, color: Color(0xFF2196F3)),
                  title: const Text(
                    'Xem thêm',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Text(
                    'Còn ${items.length - displayCount} mục',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  onTap: () => _loadMoreItems(filterKey),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String filterKey,
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    final isExpanded = _expandedFilter == filterKey;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF7FE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF687182).withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                value ?? label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  void _showClassCodePicker() async {
    if (_classCodes.isEmpty) {
      // Fetch all classes to get unique codes
      await _fetchClassCodes();
    }
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn mã lớp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedClassCode = null);
                    Navigator.pop(context);
                  },
                  child: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _classCodes.isEmpty
                  ? const Center(child: Text('Không có dữ liệu'))
                  : ListView.builder(
                      itemCount: _classCodes.length,
                      itemBuilder: (context, index) {
                        final code = _classCodes[index]['code'] as String;
                        return ListTile(
                          title: Text(code),
                          onTap: () {
                            setState(() => _selectedClassCode = code);
                            Navigator.pop(context);
                          },
                          trailing: _selectedClassCode == code
                              ? const Icon(Icons.check, color: Color(0xFF2196F3))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchClassCodes() async {
    try {
      final baseUrl = ApiService.baseUrl;
      final url = Uri.parse('$baseUrl/classes?limit=100');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final items = data['items'] as List? ?? [];
        
        // Extract unique class codes
        final codes = <String>{};
        for (var item in items) {
          final code = item['code'] ?? item['class_code'];
          if (code != null) codes.add(code.toString());
        }
        
        setState(() {
          _classCodes = codes.map((c) => {'code': c}).toList()..sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));
        });
      }
    } catch (e) {
      debugPrint('Error fetching class codes: $e');
    }
  }

  void _showTeacherPicker() async {
    if (_teachers.isEmpty) {
      await _fetchTeachers();
    }
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn giảng viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedTeacher = null);
                    Navigator.pop(context);
                  },
                  child: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _teachers.isEmpty
                  ? const Center(child: Text('Không có dữ liệu'))
                  : ListView.builder(
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _teachers[index];
                        final name = teacher['full_name'] as String;
                        final code = teacher['teacher_code'] as String?;
                        return ListTile(
                          title: Text(name),
                          subtitle: code != null ? Text(code) : null,
                          onTap: () {
                            setState(() => _selectedTeacher = name);
                            Navigator.pop(context);
                          },
                          trailing: _selectedTeacher == name
                              ? const Icon(Icons.check, color: Color(0xFF2196F3))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchTeachers() async {
    try {
      final baseUrl = ApiService.baseUrl;
      final url = Uri.parse('$baseUrl/users/teachers?limit=100');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final items = data['items'] as List? ?? [];
        
        setState(() {
          _teachers = items.map((item) => {
            'full_name': item['full_name'] ?? 'Unknown',
            'teacher_code': item['teacher_code'],
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
    }
  }

  void _showSubjectPicker() async {
    if (_subjects.isEmpty) {
      await _fetchSubjects();
    }
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn môn học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedSubject = null);
                    Navigator.pop(context);
                  },
                  child: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _subjects.isEmpty
                  ? const Center(child: Text('Không có dữ liệu'))
                  : ListView.builder(
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        final name = subject['name'] as String;
                        final code = subject['code'] as String?;
                        return ListTile(
                          title: Text(name),
                          subtitle: code != null ? Text(code) : null,
                          onTap: () {
                            setState(() => _selectedSubject = name);
                            Navigator.pop(context);
                          },
                          trailing: _selectedSubject == name
                              ? const Icon(Icons.check, color: Color(0xFF2196F3))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchSubjects() async {
    try {
      final baseUrl = ApiService.baseUrl;
      final url = Uri.parse('$baseUrl/academic/subjects?limit=100');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final items = data['items'] as List? ?? [];
        
        setState(() {
          _subjects = items.map((item) => {
            'name': item['name'] ?? 'Unknown',
            'code': item['code'],
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    }
  }

  void _showFacultyPicker() async {
    if (_faculties.isEmpty) {
      await _fetchFaculties();
    }
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn khoa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedFaculty = null);
                    Navigator.pop(context);
                  },
                  child: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _faculties.isEmpty
                  ? const Center(child: Text('Không có dữ liệu'))
                  : ListView.builder(
                      itemCount: _faculties.length,
                      itemBuilder: (context, index) {
                        final faculty = _faculties[index];
                        final name = faculty['name'] as String;
                        final code = faculty['code'] as String?;
                        return ListTile(
                          title: Text(name),
                          subtitle: code != null ? Text(code) : null,
                          onTap: () {
                            setState(() => _selectedFaculty = name);
                            Navigator.pop(context);
                          },
                          trailing: _selectedFaculty == name
                              ? const Icon(Icons.check, color: Color(0xFF2196F3))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchFaculties() async {
    try {
      final baseUrl = ApiService.baseUrl;
      final url = Uri.parse('$baseUrl/academic/faculties?limit=100');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final items = data['items'] as List? ?? [];
        
        setState(() {
          _faculties = items.map((item) => {
            'name': item['name'] ?? 'Unknown',
            'code': item['code'],
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching faculties: $e');
    }
  }

  void _showCohortPicker() async {
    if (_cohorts.isEmpty) {
      await _fetchCohorts();
    }
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn khóa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedCohort = null);
                    Navigator.pop(context);
                  },
                  child: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _cohorts.isEmpty
                  ? const Center(child: Text('Không có dữ liệu'))
                  : ListView.builder(
                      itemCount: _cohorts.length,
                      itemBuilder: (context, index) {
                        final cohort = _cohorts[index];
                        final name = cohort['name'] as String;
                        return ListTile(
                          title: Text(name),
                          onTap: () {
                            setState(() => _selectedCohort = name);
                            Navigator.pop(context);
                          },
                          trailing: _selectedCohort == name
                              ? const Icon(Icons.check, color: Color(0xFF2196F3))
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchCohorts() async {
    try {
      final baseUrl = ApiService.baseUrl;
      final url = Uri.parse('$baseUrl/academic/cohorts?limit=100');

      final headers = <String, String>{
        'Accept': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final items = data['items'] as List? ?? [];
        
        setState(() {
          _cohorts = items.map((item) => {
            'name': item['name'] ?? 'Unknown',
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching cohorts: $e');
    }
  }
}

class _ClassItem {
  final int id;
  final String title;
  final String code;
  final int students;
  final String teacherName;
  final String subjectName;
  final String facultyName;
  final String cohortName;

  const _ClassItem({
    required this.id,
    required this.title,
    required this.code,
    required this.students,
    this.teacherName = '',
    this.subjectName = '',
    this.facultyName = '',
    this.cohortName = '',
  });
}

class _ClassCard extends StatelessWidget {
  final _ClassItem item;
  final VoidCallback onTap;
  const _ClassCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAECF0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 28 / 18,
                    color: Color(0xFF344054),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Tag(
                      icon: Icons.list_alt_outlined,
                      label: '${item.students} Sinh viên',
                    ),
                    _Tag(
                      icon: Icons.code,
                      label: item.code,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF667085)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 20 / 14,
            color: Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}
