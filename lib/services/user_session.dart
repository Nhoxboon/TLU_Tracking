import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';

class UserSession extends ChangeNotifier {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  UserRole? _userRole;
  Map<String, dynamic>? _userData;
  String? _username;
  String? _accessToken;
  String? _tokenType;

  UserRole? get userRole => _userRole;
  Map<String, dynamic>? get userData => _userData;
  String? get username => _username;
  String? get accessToken => _accessToken;
  String? get tokenType => _tokenType;
  bool get isLoggedIn => _userRole != null;

  void setUser({
    required UserRole role,
    required Map<String, dynamic> userData,
    required String username,
    String? accessToken,
    String? tokenType,
  }) {
    _userRole = role;
    _userData = userData;
    _username = username;
    _accessToken = accessToken;
    _tokenType = tokenType;
    notifyListeners();
    _persist();
  }

  void logout() {
    _userRole = null;
    _userData = null;
    _username = null;
    _accessToken = null;
    _tokenType = null;
    notifyListeners();
    _clearPersisted();
  }

  // Helper methods to get typed user data
  Student? get studentData {
    if (_userRole == UserRole.student && _userData != null) {
      return Student.fromJson(_userData!);
    }
    return null;
  }

  Teacher? get teacherData {
    if (_userRole == UserRole.teacher && _userData != null) {
      return Teacher.fromJson(_userData!);
    }
    return null;
  }

  Admin? get adminData {
    if (_userRole == UserRole.admin && _userData != null) {
      return Admin.fromJson(_userData!);
    }
    return null;
  }

  // Persistence
  static const _kKey = 'user_session_v1';

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'role': _userRole?.toString(),
        'userData': _userData,
        'username': _username,
        'accessToken': _accessToken,
        'tokenType': _tokenType,
      };
      await prefs.setString(_kKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _clearPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kKey);
    } catch (_) {}
  }

  Future<bool> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null) return false;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final roleStr = (map['role'] as String? ?? '').split('.').last;
      _userRole = UserRole.fromString(roleStr);
      _userData = (map['userData'] as Map?)?.cast<String, dynamic>();
      _username = map['username'] as String?;
      _accessToken = map['accessToken'] as String?;
      _tokenType = map['tokenType'] as String?;
      notifyListeners();
      return _userRole != null;
    } catch (_) {
      return false;
    }
  }
}
