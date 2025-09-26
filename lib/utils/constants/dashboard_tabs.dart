enum DashboardTab {
  dashboard('Dashboard'),
  teachers('Giảng viên'),
  students('Sinh viên'),
  classes('Lớp học'),
  subjects('Môn học'),
  majors('Ngành'),
  courses('Khóa');

  const DashboardTab(this.displayName);
  final String displayName;
}
