import 'package:flutter/material.dart';
import '../settings_screen.dart';
import '../class_detail_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_ClassItem> _classes = const [
    _ClassItem(title: 'Mobile app', code: 'CSE', students: 40),
    _ClassItem(title: 'Mobile app', code: 'CSE', students: 40),
    _ClassItem(title: 'Mobile app', code: 'CSE', students: 40),
    _ClassItem(title: 'Mobile app', code: 'CSE', students: 40),
    _ClassItem(title: 'Mobile app', code: 'CSE', students: 40),
  ];

  int _currentIndex = 0;

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

            const SizedBox(height: 12),

            // List of classes
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 100),
                itemCount: _classes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _classes[index];
                  if (_searchController.text.isNotEmpty) {
                    final q = _searchController.text.toLowerCase();
                    if (!item.title.toLowerCase().contains(q) &&
                        !item.code.toLowerCase().contains(q)) {
                      return const SizedBox.shrink();
                    }
                  }
                  return _ClassCard(
                    item: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassDetailScreen(classCode: item.code),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassItem {
  final String title;
  final String code;
  final int students;
  const _ClassItem({required this.title, required this.code, required this.students});
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
