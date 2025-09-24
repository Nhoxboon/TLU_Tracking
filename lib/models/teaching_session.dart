class TeachingSession {
  final String id;
  final String date;
  final String timeSlot;
  final int attendanceCount;
  final int totalStudents;
  final bool isOpen;

  TeachingSession({
    required this.id,
    required this.date,
    required this.timeSlot,
    required this.attendanceCount,
    required this.totalStudents,
    required this.isOpen,
  });

  // In a real app, this would likely come from an API or database
  static List<TeachingSession> getMockSessions() {
    return [
      TeachingSession(
        id: '1',
        date: 'T5 4/9/2025',
        timeSlot: '7AM - 8:15AM',
        attendanceCount: 20,
        totalStudents: 40,
        isOpen: true,
      ),
      TeachingSession(
        id: '2',
        date: 'T5 11/9/2025',
        timeSlot: '7AM - 8:15AM',
        attendanceCount: 18,
        totalStudents: 40,
        isOpen: true,
      ),
      TeachingSession(
        id: '3',
        date: 'T5 18/9/2025',
        timeSlot: '7AM - 8:15AM',
        attendanceCount: 22,
        totalStudents: 40,
        isOpen: true,
      ),
      TeachingSession(
        id: '4',
        date: 'T5 25/9/2025',
        timeSlot: '7AM - 8:15AM',
        attendanceCount: 25,
        totalStudents: 40,
        isOpen: true,
      ),
      TeachingSession(
        id: '5',
        date: 'T5 2/10/2025',
        timeSlot: '7AM - 8:15AM',
        attendanceCount: 19,
        totalStudents: 40,
        isOpen: true,
      ),
    ];
  }
}