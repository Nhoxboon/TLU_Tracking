import 'package:flutter/material.dart';
import '../../models/teaching_session.dart';
import 'session_form.dart';

class AddSessionScreen extends StatelessWidget {
  final Function(TeachingSession) onSessionAdded;

  const AddSessionScreen({Key? key, required this.onSessionAdded})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SessionForm(title: 'Thêm buổi học', onSave: onSessionAdded);
  }
}
