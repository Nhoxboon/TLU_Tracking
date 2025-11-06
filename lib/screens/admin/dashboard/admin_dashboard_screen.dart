import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/utils/constants/dashboard_tabs.dart';
import 'package:android_app/widgets/web/dashboard_card.dart';
import 'package:android_app/widgets/web/sidebar_item.dart';
import 'package:android_app/widgets/web/admin_card.dart';
import 'package:android_app/widgets/web/dashboard_icon.dart';
import 'package:android_app/screens/admin/dashboard/teacher_management/teachers_management_view.dart';
import 'package:android_app/screens/admin/dashboard/student_management/students_management_view.dart';
import 'package:android_app/screens/admin/dashboard/class_management/classes_management_view.dart';
import 'package:android_app/screens/admin/dashboard/subject_management/subjects_management_view.dart';
import 'package:android_app/screens/admin/dashboard/major_management/majors_management_view.dart';
import 'package:android_app/screens/admin/dashboard/course_management/courses_management_view.dart';
import 'package:android_app/screens/admin/dashboard/study_period_management/study_periods_management_view.dart';
import 'package:android_app/screens/admin/dashboard/semester_management/semesters_management_view.dart';
import 'package:android_app/screens/admin/dashboard/academic_year_management/academic_years_management_view.dart';
import 'package:android_app/screens/admin/dashboard/faculty_management/faculties_management_view.dart';
import 'package:android_app/screens/admin/dashboard/department_management/departments_management_view.dart';
import 'package:android_app/screens/admin/dashboard/change_password_view.dart';
import '../../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String get adminName => "Admin";

  DashboardTab _currentTab = DashboardTab.dashboard;
  DashboardTab? _previousTab;

  // Dashboard counts
  int _totalTeachers = 0;
  int _totalStudents = 0;
  int _totalClasses = 0;
  int _totalSubjects = 0;
  int _totalMajors = 0;
  int _totalCohorts = 0;
  int _totalDepartments = 0;
  int _totalFaculties = 0;
  int _totalAcademicYears = 0;
  bool _isLoadingCounts = true;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDashboardCounts();
  }

  Future<void> _loadDashboardCounts() async {
    setState(() {
      _isLoadingCounts = true;
    });

    try {
      // Fetch all data in parallel to get total counts
      final futures = await Future.wait([
        _apiService.getTeachersPaginated(
          limit: 1,
        ), // We only need the total count
        _apiService.getStudentsPaginated(limit: 1),
        _apiService.getClassesPaginated(limit: 1),
        _apiService.getSubjectsPaginated(limit: 1),
        _apiService.getMajorsPaginated(limit: 1),
        _apiService.getCohortsPaginated(limit: 1),
        _apiService.getDepartmentsPaginated(limit: 1),
        _apiService.getFacultiesPaginated(limit: 1),
        _apiService.getAcademicYearsPaginated(limit: 1),
      ]);

      if (mounted) {
        setState(() {
          _totalTeachers = futures[0].success ? futures[0].data!.total : 0;
          _totalStudents = futures[1].success ? futures[1].data!.total : 0;
          _totalClasses = futures[2].success ? futures[2].data!.total : 0;
          _totalSubjects = futures[3].success ? futures[3].data!.total : 0;
          _totalMajors = futures[4].success ? futures[4].data!.total : 0;
          _totalCohorts = futures[5].success ? futures[5].data!.total : 0;
          _totalDepartments = futures[6].success ? futures[6].data!.total : 0;
          _totalFaculties = futures[7].success ? futures[7].data!.total : 0;
          _totalAcademicYears = futures[8].success ? futures[8].data!.total : 0;
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCounts = false;
        });
      }
    }
  }

  Widget _buildMainContent() {
    switch (_currentTab) {
      case DashboardTab.dashboard:
        // Refresh data when returning to dashboard from another tab
        if (_previousTab != null && _previousTab != DashboardTab.dashboard) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isLoadingCounts) {
              _loadDashboardCounts();
            }
          });
        }
        return _buildDashboardContent();
      case DashboardTab.teachers:
        return const TeachersManagementView();
      case DashboardTab.students:
        return const StudentsManagementView();
      case DashboardTab.classes:
        return const ClassesManagementView();
      case DashboardTab.subjects:
        return const SubjectsManagementView();
      case DashboardTab.majors:
        return const MajorsManagementView();
      case DashboardTab.cohorts:
        return const CoursesManagementView();
      case DashboardTab.departments:
        return const DepartmentsManagementView();
      case DashboardTab.faculties:
        return const FacultiesManagementView();
      case DashboardTab.learningPeriods:
        return const StudyPeriodsManagementView();
      case DashboardTab.semesters:
        return const SemestersManagementView();
      case DashboardTab.academicYears:
        return const AcademicYearsManagementView();
      case DashboardTab.changePassword:
        return const ChangePasswordView();
    }
  }

  Widget _buildDashboardContent() {
    return Container(
      color: const Color(0xFFF5F6FA),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard title
          const Text(
            'Dashboard',
            style: TextStyle(
              fontFamily: 'Nunito Sans',
              fontWeight: FontWeight.w700,
              fontSize: 32,
              letterSpacing: -0.11,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 27),

          // Dashboard cards - Row 1
          Row(
            children: [
              // Card for total teachers
              DashboardCard(
                title: 'Tổng giảng viên',
                value: _isLoadingCounts ? '...' : '$_totalTeachers',
                iconColor: AppColors.purple,
                iconType: DashboardIconType.user,
              ),
              const SizedBox(width: 47),

              // Card for total students
              DashboardCard(
                title: 'Tổng sinh viên',
                value: _isLoadingCounts ? '...' : '$_totalStudents',
                iconColor: const Color(0xFFFF8082),
                iconType: DashboardIconType.users,
              ),
              const SizedBox(width: 47),

              // Card for total classes
              DashboardCard(
                title: 'Tổng lớp học',
                value: _isLoadingCounts ? '...' : '$_totalClasses',
                iconColor: const Color(0xFFFEC53D),
                iconType: DashboardIconType.server,
              ),
            ],
          ),
          const SizedBox(height: 31),

          // Dashboard cards - Row 2
          Row(
            children: [
              // Card for total subjects
              DashboardCard(
                title: 'Tổng môn học',
                value: _isLoadingCounts ? '...' : '$_totalSubjects',
                iconColor: const Color(0xFF8B0507),
                iconType: DashboardIconType.book,
              ),
              const SizedBox(width: 47),

              // Card for total majors
              DashboardCard(
                title: 'Tổng ngành',
                value: _isLoadingCounts ? '...' : '$_totalMajors',
                iconColor: const Color(0xFF80A4FF),
                iconType: DashboardIconType.briefcase,
              ),
              const SizedBox(width: 47),

              // Card for total courses/years
              DashboardCard(
                title: 'Tổng khóa',
                value: _isLoadingCounts ? '...' : '$_totalCohorts',
                iconColor: const Color(0xFFFFC280),
                iconType: DashboardIconType.award,
              ),
            ],
          ),
          const SizedBox(height: 31),

          // Dashboard cards - Row 3
          Row(
            children: [
              // Card for total departments
              DashboardCard(
                title: 'Tổng bộ môn',
                value: _isLoadingCounts ? '...' : '$_totalDepartments',
                iconColor: const Color(0xFF4CAF50),
                iconType: DashboardIconType.department,
              ),
              const SizedBox(width: 47),

              // Card for total faculties
              DashboardCard(
                title: 'Tổng khoa',
                value: _isLoadingCounts ? '...' : '$_totalFaculties',
                iconColor: const Color(0xFF9C27B0),
                iconType: DashboardIconType.faculty,
              ),
              const SizedBox(width: 47),

              // Card for total academic years
              DashboardCard(
                title: 'Tổng năm học',
                value: _isLoadingCounts ? '...' : '$_totalAcademicYears',
                iconColor: const Color(0xFF00BCD4),
                iconType: DashboardIconType.calendar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: AppColors.background,
            child: Column(
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, left: 28.0),
                  child: Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'TLU',
                              style: AppTextStyles.logo.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            TextSpan(
                              text: ' Tracking',
                              style: AppTextStyles.logo,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Menu Items
                SidebarItem(
                  title: 'Dashboard',
                  isActive: _currentTab == DashboardTab.dashboard,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.dashboard;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Giảng viên',
                  isActive: _currentTab == DashboardTab.teachers,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.teachers;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Sinh viên',
                  isActive: _currentTab == DashboardTab.students,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.students;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Lớp học',
                  isActive: _currentTab == DashboardTab.classes,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.classes;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Môn học',
                  isActive: _currentTab == DashboardTab.subjects,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.subjects;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Ngành',
                  isActive: _currentTab == DashboardTab.majors,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.majors;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Khóa',
                  isActive: _currentTab == DashboardTab.cohorts,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.cohorts;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Bộ môn',
                  isActive: _currentTab == DashboardTab.departments,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.departments;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Khoa',
                  isActive: _currentTab == DashboardTab.faculties,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.faculties;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Đợt học',
                  isActive: _currentTab == DashboardTab.learningPeriods,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.learningPeriods;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Học kì',
                  isActive: _currentTab == DashboardTab.semesters,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.semesters;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Năm học',
                  isActive: _currentTab == DashboardTab.academicYears,
                  onTap: () {
                    setState(() {
                      _previousTab = _currentTab;
                      _currentTab = DashboardTab.academicYears;
                    });
                  },
                ),
              ],
            ),
          ),

          // Vertical divider
          Container(width: 1, color: const Color(0xFFE0E0E0)),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Admin card with dropdown
                      AdminCard(
                        adminName: adminName,
                        onTabChange: (tab) {
                          setState(() {
                            _previousTab = _currentTab;
                            _currentTab = tab;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Dashboard content
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
