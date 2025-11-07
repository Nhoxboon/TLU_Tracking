// Platform-agnostic interface
export 'mobile_platform.dart'
    if (dart.library.html) 'web_platform.dart';
