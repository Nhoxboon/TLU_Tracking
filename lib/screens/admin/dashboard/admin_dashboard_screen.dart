import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/utils/constants/dashboard_tabs.dart';
import 'package:android_app/widgets/web/dashboard_card.dart';
import 'package:android_app/widgets/web/sidebar_item.dart';
import 'package:android_app/widgets/web/admin_card.dart';
import 'package:android_app/widgets/web/dashboard_icon.dart';
import 'package:android_app/screens/admin/dashboard/teacher_management/teachers_management_view.dart';
import 'package:android_app/screens/admin/dashboard/student_management/students_management_view.dart';
import 'package:android_app/screens/admin/dashboard/classes_management_view.dart';
import 'package:android_app/screens/admin/dashboard/subjects_management_view.dart';
import 'package:android_app/screens/admin/dashboard/majors_management_view.dart';
import 'package:android_app/screens/admin/dashboard/courses_management_view.dart';
import 'package:android_app/screens/admin/dashboard/change_password_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final String adminName = "Admin";
  DashboardTab _currentTab = DashboardTab.dashboard;

  Widget _buildMainContent() {
    switch (_currentTab) {
      case DashboardTab.dashboard:
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
      case DashboardTab.courses:
        return const CoursesManagementView();
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
                value: '40',
                iconColor: AppColors.purple,
                iconType: DashboardIconType.user,
              ),
              const SizedBox(width: 47),

              // Card for total students
              DashboardCard(
                title: 'Tổng sinh viên',
                value: '40',
                iconColor: const Color(0xFFFF8082),
                iconType: DashboardIconType.users,
              ),
              const SizedBox(width: 47),

              // Card for total classes
              DashboardCard(
                title: 'Tổng lớp học',
                value: '100',
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
                value: '40',
                iconColor: const Color(0xFF8B0507),
                iconType: DashboardIconType.book,
              ),
              const SizedBox(width: 47),

              // Card for total majors
              DashboardCard(
                title: 'Tổng ngành',
                value: '40',
                iconColor: const Color(0xFF80A4FF),
                iconType: DashboardIconType.briefcase,
              ),
              const SizedBox(width: 47),

              // Card for total courses/years
              DashboardCard(
                title: 'Tổng khóa',
                value: '40',
                iconColor: const Color(0xFFFFC280),
                iconType: DashboardIconType.award,
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
                      _currentTab = DashboardTab.dashboard;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Giảng viên',
                  isActive: _currentTab == DashboardTab.teachers,
                  onTap: () {
                    setState(() {
                      _currentTab = DashboardTab.teachers;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Sinh viên',
                  isActive: _currentTab == DashboardTab.students,
                  onTap: () {
                    setState(() {
                      _currentTab = DashboardTab.students;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Lớp học',
                  isActive: _currentTab == DashboardTab.classes,
                  onTap: () {
                    setState(() {
                      _currentTab = DashboardTab.classes;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Môn học',
                  isActive: _currentTab == DashboardTab.subjects,
                  onTap: () {
                    setState(() {
                      _currentTab = DashboardTab.subjects;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Ngành',
                  isActive: _currentTab == DashboardTab.majors,
                  onTap: () {
                    setState(() {
                      _currentTab = DashboardTab.majors;
                    });
                  },
                ),
                SidebarItem(
                  title: 'Khóa',
                  isActive: _currentTab == DashboardTab.courses,
                  onTap: () {
                    setState(() {
                      _currentTab = DashboardTab.courses;
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
