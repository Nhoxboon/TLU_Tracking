import 'package:flutter/material.dart';
import '../models/teaching_session.dart';

class SessionForm extends StatefulWidget {
  final TeachingSession? session;
  final String title;
  final Function(TeachingSession) onSave;

  const SessionForm({
    Key? key,
    this.session,
    required this.title,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<SessionForm> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late bool isOpen;
  
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing session data if editing, or defaults if adding new
    if (widget.session != null) {
      // Parse date string (simplified for demo purposes)
      selectedDate = DateTime.now(); 
      
      // Parse time slot (simplified for demo purposes)
      final timeSlot = widget.session!.timeSlot;
      startTime = const TimeOfDay(hour: 7, minute: 0); // Default
      endTime = const TimeOfDay(hour: 11, minute: 0); // Default
      
      isOpen = widget.session!.isOpen;
      
      // Set controller values
      dateController.text = widget.session!.date;
      startTimeController.text = '07:00:00 AM';
      endTimeController.text = '11:00:00 AM';
    } else {
      // Default values for new session
      selectedDate = DateTime.now();
      startTime = const TimeOfDay(hour: 7, minute: 0);
      endTime = const TimeOfDay(hour: 11, minute: 0);
      isOpen = true;
      
      // Set controller values
      dateController.text = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
      startTimeController.text = '07:00:00 AM';
      endTimeController.text = '11:00:00 AM';
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Color(0xFF2196F3),
            letterSpacing: -0.02,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Text(
            'Hủy',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              fontSize: 24,
              color: Color(0xFFFF5722),
              letterSpacing: -0.02,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        leadingWidth: 80,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date field
            const Text(
              'Ngày',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF2196F3),
                letterSpacing: -0.02,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: _buildTextField(
                  controller: dateController,
                  hint: 'DD/MM/YYYY',
                  suffixIcon: Icons.keyboard_arrow_down,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Time fields
            Row(
              children: [
                // From time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Từ',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Color(0xFF2196F3),
                          letterSpacing: -0.02,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectTime(true),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: startTimeController,
                            hint: 'HH:MM:SS AM/PM',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // To time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đến',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Color(0xFF2196F3),
                          letterSpacing: -0.02,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectTime(false),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: endTimeController,
                            hint: 'HH:MM:SS AM/PM',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Status field
            const Text(
              'Trạng thái',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF2196F3),
                letterSpacing: -0.02,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Open option
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: isOpen,
                      onChanged: (value) {
                        setState(() {
                          isOpen = value!;
                        });
                      },
                      activeColor: const Color(0xFF2196F3),
                    ),
                    const Text(
                      'Mở',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xB3000000), // 70% opacity
                        letterSpacing: -0.02,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Closed option
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: isOpen,
                      onChanged: (value) {
                        setState(() {
                          isOpen = value!;
                        });
                      },
                      activeColor: const Color(0xFF2196F3),
                    ),
                    const Text(
                      'Đóng',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xB3000000), // 70% opacity
                        letterSpacing: -0.02,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSession,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0x1A2196F3), // 10% opacity blue
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Color(0xB3000000), // 70% opacity
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.black.withOpacity(0.3),
          ),
          border: InputBorder.none,
          suffixIcon: suffixIcon != null 
              ? Icon(suffixIcon, color: Colors.black.withOpacity(0.7))
              : null,
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        dateController.text = '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? startTime : endTime;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          startTime = pickedTime;
          startTimeController.text = _formatTimeOfDay(pickedTime);
        } else {
          endTime = pickedTime;
          endTimeController.text = _formatTimeOfDay(pickedTime);
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    final adjustedHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    
    return '$adjustedHour:$minute:00 $period';
  }

  void _saveSession() {
    // Create a formatted time slot string
    final timeSlot = '${_formatTimeOfDay(startTime).split(' ')[0]} - ${_formatTimeOfDay(endTime).split(' ')[0]}${endTime.period == DayPeriod.am ? 'AM' : 'PM'}';
    
    // Create a new session or update existing one
    final session = TeachingSession(
      id: widget.session?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: dateController.text,
      timeSlot: timeSlot,
      attendanceCount: widget.session?.attendanceCount ?? 0, // Default to 0 for new sessions
      totalStudents: widget.session?.totalStudents ?? 40, // Default to 40 for new sessions
      isOpen: isOpen,
    );
    
    // Call the callback function with the new/updated session
    widget.onSave(session);
    
    // Close the form
    Navigator.of(context).pop();
  }
}