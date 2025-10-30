import 'package:flutter/material.dart';
import '../class_detail_screen.dart';

class ClassStudentScreen extends StatefulWidget {
  final String className;
  final String classCode;
  final int studentCount;

  const ClassStudentScreen({
    Key? key,
    required this.className,
    required this.classCode,
    required this.studentCount,
  }) : super(key: key);

  @override
  State<ClassStudentScreen> createState() => _ClassStudentScreenState();
}

class _ClassStudentScreenState extends State<ClassStudentScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Mock student data
  final List<_StudentItem> _students = const [
    _StudentItem(name: 'Nguyễn Sơn', studentId: '2251171235'),
    _StudentItem(name: 'Trần Minh Anh', studentId: '2251171236'),
    _StudentItem(name: 'Lê Văn Hùng', studentId: '2251171237'),
    _StudentItem(name: 'Phạm Thị Lan', studentId: '2251171238'),
    _StudentItem(name: 'Hoàng Đức Nam', studentId: '2251171239'),
    _StudentItem(name: 'Nguyễn Thị Mai', studentId: '2251171240'),
    _StudentItem(name: 'Vũ Minh Tuấn', studentId: '2251171241'),
  ];

  List<_StudentItem> get filteredStudents {
    if (_searchController.text.isEmpty) {
      return _students;
    }
    final query = _searchController.text.toLowerCase();
    return _students.where((student) =>
        student.name.toLowerCase().contains(query) ||
        student.studentId.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar space
            const SizedBox(height: 8),
            
            // Header with back button and search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Search button
                  GestureDetector(
                    onTap: () {
                      // Toggle search functionality
                      setState(() {});
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Class title
            Center(
              child: Text(
                widget.className,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 32,
                  height: 1.235,
                  letterSpacing: -0.64,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Class info row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Student count
                  Row(
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 20,
                        color: Color(0xFF667085),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.studentCount} sinh viên',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          height: 1.0,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                  // Class code
                  Row(
                    children: [
                      const Icon(
                        Icons.code,
                        size: 24,
                        color: Color(0xFF667085),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.classCode,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          fontSize: 24,
                          height: 0.833,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Students section header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Danh sách sinh viên',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1.235,
                  letterSpacing: -0.36,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Session button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF27C840),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2264E5).withOpacity(0.12),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2264E5),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      // Navigate to class detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassDetailScreen(
                            classCode: widget.classCode,
                          ),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        'Buổi học',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.429,
                          letterSpacing: 0.28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Student list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredStudents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return _StudentCard(student: student);
                },
              ),
            ),
          ],
        ),
      ),
      // Custom bottom navigation to match design
      bottomNavigationBar: Container(
        height: 59,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF565656).withOpacity(0.25),
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
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.home_outlined,
                color: Colors.black.withOpacity(0.7),
                size: 25,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.person_outline,
                color: Colors.black.withOpacity(0.7),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Student item model
class _StudentItem {
  final String name;
  final String studentId;
  
  const _StudentItem({
    required this.name,
    required this.studentId,
  });
}

// Student card widget
class _StudentCard extends StatelessWidget {
  final _StudentItem student;
  
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEAECF0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student name
          Text(
            student.name,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.556,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 8),
          
          // Student ID row
          Row(
            children: [
              const Icon(
                Icons.list_alt_outlined,
                size: 16,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 4),
              Text(
                student.studentId,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.429,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
