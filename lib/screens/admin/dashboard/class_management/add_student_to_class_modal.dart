import 'package:flutter/material.dart';

class AddStudentToClassModal extends StatefulWidget {
  final String classCode;
  final String className;

  const AddStudentToClassModal({
    super.key,
    required this.classCode,
    required this.className,
  });

  @override
  State<AddStudentToClassModal> createState() => _AddStudentToClassModalState();
}

class _AddStudentToClassModalState extends State<AddStudentToClassModal> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStudentCode;
  String _studentName = '';

  // Sample available students that are not yet in the class
  final Map<String, String> _availableStudents = {
    '20210015': 'Nguyễn Văn An',
    '20210016': 'Trần Thị Bình',
    '20210017': 'Lê Hoàng Cường',
    '20210018': 'Phạm Minh Dương',
    '20210019': 'Hoàng Thu Hà',
    '20210020': 'Vũ Đình Khang',
    '20210021': 'Đỗ Thị Lan',
    '20210022': 'Bùi Văn Minh',
    '20210023': 'Cao Thị Nga',
    '20210024': 'Đinh Quốc Phong',
    '20210025': 'Lý Thị Quỳnh',
    '20210026': 'Mạc Văn Sơn',
    '20210027': 'Phan Thị Tâm',
    '20210028': 'Tạ Văn Uy',
    '20210029': 'Ông Thị Vân',
  };

  void _onStudentCodeChanged(String? studentCode) {
    setState(() {
      _selectedStudentCode = studentCode;
      _studentName = studentCode != null
          ? (_availableStudents[studentCode] ?? '')
          : '';
    });
  }

  void _handleConfirm() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement actual student addition logic here
      // This is where the real logic for adding a student to class should be implemented
      // - Validate selected student code
      // - Add student to class in database/API
      // - Update the students list in the parent widget
      // - Show success message
      // - Close the modal

      Navigator.of(
        context,
      ).pop({'studentCode': _selectedStudentCode, 'studentName': _studentName});

      // For now, just show a placeholder message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'TODO: Add student $_studentName ($_selectedStudentCode) to class ${widget.className}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 640,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A0D12).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF0A0D12).withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            _buildModalHeader(),

            // Modal Content
            _buildModalContent(),

            // Modal Actions
            _buildModalActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Stack(
        children: [
          // Title
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Thêm sinh viên',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.56,
                color: Color(0xFF181D27),
              ),
            ),
          ),

          // Close Button
          Positioned(
            right: 0,
            top: -8,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF717680),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Student Code Dropdown
            _buildStudentCodeDropdown(),
            const SizedBox(height: 16),

            // Student Name Field (Read-only)
            _buildStudentNameField(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCodeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mã sinh viên*',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF414651),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedStudentCode,
          onChanged: _onStudentCodeChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn sinh viên';
            }
            return null;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD5D7DA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2264E5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF181D27),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Color(0xFF717680),
          ),
          hint: const Text(
            'Chọn mã sinh viên',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA1A9B8),
            ),
          ),
          items: _availableStudents.keys.map<DropdownMenuItem<String>>((
            String studentCode,
          ) {
            return DropdownMenuItem<String>(
              value: studentCode,
              child: Text(
                studentCode,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF181D27),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudentNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tên sinh viên',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            color: Color(0xFF414651),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(
              0xFF999999,
            ).withValues(alpha: 0.4), // Grayed out background
            border: Border.all(color: const Color(0xFF999999)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A0D12).withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _studentName.isEmpty
                  ? 'Tên sinh viên sẽ hiển thị khi chọn mã'
                  : _studentName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _studentName.isEmpty
                    ? const Color(0xFFA1A9B8)
                    : const Color(0xFF181D27),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModalActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD5D7DA)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A0D12).withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF414651),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Confirm Button
          Expanded(
            child: InkWell(
              onTap: _handleConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2264E5),
                  border: Border.all(color: const Color(0xFF7F56D9)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A0D12).withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Xác nhận',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
