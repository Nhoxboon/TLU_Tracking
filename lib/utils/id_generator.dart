/// Tiện ích để tạo ID tự động tăng cho các đối tượng
class IdGenerator {
  // Map lưu trữ giá trị counter hiện tại cho mỗi loại đối tượng
  static final Map<String, int> _counters = {
    'admin': 1,
    'teacher': 1,
    'student': 1,
  };

  // Tạo ID mới cho một đối tượng dựa trên loại
  static String generateId(String type) {
    if (!_counters.containsKey(type)) {
      _counters[type] = 1;
    }

    int currentValue = _counters[type]!;
    _counters[type] = currentValue + 1;

    // Format ID với số 0 phía trước cho đẹp (ví dụ: admin-001)
    String formattedNumber = currentValue.toString().padLeft(3, '0');
    return '$type-$formattedNumber';
  }

  // Phương thức reset counter (chủ yếu để dùng cho testing)
  static void resetCounters() {
    _counters.forEach((key, _) {
      _counters[key] = 1;
    });
  }
}
