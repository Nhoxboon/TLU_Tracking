enum DashboardTab {
  dashboard('Dashboard'),
  teachers('Giảng viên'),
  students('Sinh viên'),
  classes('Lớp học'),
  subjects('Môn học'),
  majors('Ngành'),
  academicYears('Năm học'),
  semesters('Học kì'),
  learningPeriods('Đợt học'),
  faculties('Khoa'),
  departments('Bộ môn'),
  cohorts('Khóa'),
  changePassword('Đổi mật khẩu');

  const DashboardTab(this.displayName);
  final String displayName;
}
