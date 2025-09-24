import 'package:flutter/material.dart';
import '../models/teaching_session.dart';
import 'session_form.dart';

class EditSessionScreen extends StatelessWidget {
  final TeachingSession session;
  final Function(TeachingSession) onSessionUpdated;

  const EditSessionScreen({
    Key? key,
    required this.session,
    required this.onSessionUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SessionForm(
      title: 'Sửa buổi học',
      session: session,
      onSave: onSessionUpdated,
    );
  }
}