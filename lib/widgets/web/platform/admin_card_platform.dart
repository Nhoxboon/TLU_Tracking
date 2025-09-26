// Platform detection and conditional export
export 'admin_card_io.dart' if (dart.library.html) 'admin_card_web.dart';
