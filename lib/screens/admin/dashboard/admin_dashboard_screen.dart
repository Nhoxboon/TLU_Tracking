import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/web/dashboard_card.dart';
import 'package:android_app/widgets/web/sidebar_item.dart';
import 'package:android_app/widgets/web/admin_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final String adminName = "Admin";

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
                  isActive: true,
                  onTap: () {
                    // Already on dashboard
                  },
                ),
                SidebarItem(
                  title: 'Lớp học',
                  onTap: () {
                    // Navigate to classes screen
                  },
                ),
                SidebarItem(
                  title: 'Giảng viên',
                  onTap: () {
                    // Navigate to teachers screen
                  },
                ),
                SidebarItem(
                  title: 'Sinh viên',
                  onTap: () {
                    // Navigate to students screen
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
                      AdminCard(adminName: adminName),
                    ],
                  ),
                ),

                // Dashboard content
                Expanded(
                  child: Container(
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

                        // Dashboard cards
                        Row(
                          children: [
                            // Card for total teachers
                            DashboardCard(
                              title: 'Tổng giảng viên',
                              value: '40',
                              iconColor: AppColors.purple,
                              icon: Icons.person,
                            ),
                            const SizedBox(width: 47),

                            // Card for total students
                            DashboardCard(
                              title: 'Tổng sinh viên',
                              value: '40',
                              iconColor: Colors.redAccent,
                              icon: Icons.groups,
                            ),
                            const SizedBox(width: 47),

                            // Card for total classes
                            DashboardCard(
                              title: 'Tổng lớp học',
                              value: '100',
                              iconColor: const Color(0xFFFEC53D),
                              icon: Icons.school,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
