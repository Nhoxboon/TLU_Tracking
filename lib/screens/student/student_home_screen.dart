import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../../utils/navigation.dart';
import '../student_settings_screen.dart';
import 'student_class_detail_screen.dart';
import 'class_search_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();

  List<_ClassItem> _classes = [];
  bool _isLoading = false;
  String? _error;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes so we can refresh when coming back
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final studentId = UserSession().profileId;
    if (studentId == null) {
      setState(() {
        _error = 'Không xác định được student_id. Vui lòng đăng nhập lại.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final baseUrl = ApiService.baseUrl;
      final url = Uri.parse('$baseUrl/classes/student/$studentId?active_only=true');

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      debugPrint('DEBUG - Fetching student classes: $url');
      final resp = await http.get(url, headers: headers);
      debugPrint('DEBUG - Status: ${resp.statusCode}');
      debugPrint('DEBUG - Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        final loaded = data.map((e) {
          final m = e as Map<String, dynamic>;
          return _ClassItem(
            id: (m['id'] ?? 0) is int ? m['id'] as int : int.tryParse('${m['id']}') ?? 0,
            title: (m['name'] ?? m['class_name'] ?? 'Chưa rõ').toString(),
            code: (m['code'] ?? m['class_code'] ?? '—').toString(),
            students: (m['student_count'] ?? m['students_count'] ?? 0) as int,
          );
        }).toList();
        setState(() {
          _classes = loaded;
        });
      } else {
        setState(() {
          _error = 'Lỗi tải danh sách lớp (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách lớp',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.36,
                      height: 1.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/student/settings');
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  // Navigate to advanced search screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClassSearchScreen(),
                    ),
                  );
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
                      const Expanded(
                        child: Text(
                          'Tìm kiếm lớp',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.235,
                            letterSpacing: -0.32,
                            color: Color(0xB3333333), // 70%
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // List of classes
            Expanded(
              child: _isLoading
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
                                  onPressed: _fetchClasses,
                                  child: const Text('Thử lại'),
                                )
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(13, 12, 13, 100),
                          itemCount: _classes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _classes[index];
                            return _ClassCard(
                              item: item,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentClassDetailScreen(
                                      classId: item.id,
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

      // Center QR scan button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2196F3),
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.pushNamed(context, '/qr/scanner');
        },
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),

      // Bottom bar
      bottomNavigationBar: BottomAppBar(
        height: 60,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Colors.white,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                size: 25,
                color: _currentIndex == 0 ? const Color(0xFF2196F3) : Colors.black.withOpacity(0.7),
              ),
              onPressed: () {
                setState(() => _currentIndex = 0);
              },
            ),
            const SizedBox(width: 40), // space for the FAB notch
            IconButton(
              icon: Icon(
                Icons.person_outline,
                size: 25,
                color: Colors.black.withOpacity(0.7),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/student/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassItem {
  final int id;
  final String title;
  final String code;
  final int students;
  const _ClassItem({required this.id, required this.title, required this.code, required this.students});
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
                    color: Color(0xFF344054), // Gray/700
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
            color: Color(0xFF667085), // Gray/500
          ),
        ),
      ],
    );
  }
}
