// Web-specific implementations
import 'dart:html' as html;
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..style.display = 'none'
    ..download = filename;
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

Future<Uint8List> readFileAsBytes(html.File file) async {
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;
  return reader.result as Uint8List;
}

html.File? castToHtmlFile(dynamic file) {
  return file as html.File?;
}

html.FileUploadInputElement createFileUploadInput() {
  return html.FileUploadInputElement();
}
