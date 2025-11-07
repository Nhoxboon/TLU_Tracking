// Mobile-specific implementations
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String filename) {
  // Mobile platforms don't support direct file download like web
  // This would typically require using a plugin like path_provider
  // and showing a save dialog or saving to downloads folder
  throw UnsupportedError('File download not implemented for mobile platforms');
}

Future<Uint8List> readFileAsBytes(dynamic file) async {
  throw UnsupportedError('File reading not implemented for mobile platforms');
}

dynamic castToHtmlFile(dynamic file) {
  throw UnsupportedError('HTML File not available on mobile platforms');
}

dynamic createFileUploadInput() {
  throw UnsupportedError('FileUploadInputElement not available on mobile platforms');
}
