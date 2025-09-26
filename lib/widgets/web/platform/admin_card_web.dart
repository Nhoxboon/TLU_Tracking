// Platform-specific implementation for web
import 'dart:html' as html show window;

void redirectToLogin() {
  html.window.location.href = '/#/admin/login';
}
