import 'package:flutter/material.dart';
import '../models/teaching_session.dart';

class SessionCard extends StatefulWidget {
  final TeachingSession session;
  final Function(TeachingSession)? onEdit;
  final Function(TeachingSession)? onDelete;

  const SessionCard({
    Key? key,
    required this.session,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.session.id),
      background: _buildEditBackground(),
      secondaryBackground: _buildDeleteBackground(),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit action
          if (widget.onEdit != null) {
            widget.onEdit!(widget.session);
          }
          return false; // Don't dismiss, just trigger the edit action
        } else {
          // Delete action
          if (widget.onDelete != null) {
            widget.onDelete!(widget.session);
          }
          return false; // Don't dismiss, we'll handle the deletion manually
        }
      },
      child: _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAECF0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Date and time row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.session.date,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF344054),
                    ),
                  ),
                  Text(
                    widget.session.timeSlot,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF344054),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Attendance and status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Attendance count
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 4),
                        child: const Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Color(0xFF667085),
                        ),
                      ),
                      Text(
                        '${widget.session.attendanceCount}/${widget.session.totalStudents} Sinh viên',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                  
                  // Session status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.session.isOpen ? const Color(0xFF00FF40) : Colors.red,
                      borderRadius: BorderRadius.circular(29),
                    ),
                    child: Text(
                      widget.session.isOpen ? 'Mở' : 'Đóng',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  // Yellow background with edit icon when swiping from left to right
  Widget _buildEditBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE944), // Yellow background from Figma
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.edit,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Red background with trash icon when swiping from right to left
  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444), // Red background from Figma
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}