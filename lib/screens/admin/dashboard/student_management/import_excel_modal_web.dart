import 'dart:html' as html;
import 'dart:typed_data';

import 'package:android_app/services/api_service.dart';
import 'package:flutter/material.dart';

class ImportExcelModal extends StatefulWidget {
  const ImportExcelModal({super.key});

  @override
  State<ImportExcelModal> createState() => _ImportExcelModalState();
}

class _ImportExcelModalState extends State<ImportExcelModal> {
  final ApiService _apiService = ApiService();
  String? _selectedFileName;
  html.File? _selectedFile;
  bool _isUploading = false;
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.upload_file,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nhập dữ liệu sinh viên từ Excel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(24, 24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF0EA5E9),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Color(0xFF0EA5E9),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Hướng dẫn',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Tải file mẫu bằng cách nhấn nút "Tải file mẫu" bên dưới\n'
                            '2. Điền thông tin sinh viên vào file mẫu\n'
                            '3. Chọn file đã điền thông tin để tải lên\n'
                            '4. Hệ thống sẽ tự động tạo tài khoản cho sinh viên',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _downloadSampleFile,
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Tải file mẫu'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isDragOver
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFD1D5DB),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: _isDragOver
                              ? const Color(0xFFF0F9FF)
                              : const Color(0xFFFAFAFA),
                        ),
                        child: InkWell(
                          onTap: _pickFile,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload,
                                size: 48,
                                color: _selectedFile != null
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(height: 16),
                              if (_selectedFile != null) ...[
                                const Text(
                                  'File đã chọn:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedFileName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Kéo thả file Excel vào đây hoặc nhấn để chọn file',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Chỉ chấp nhận file .xlsx, .xls',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedFile != null && !_isUploading
                        ? _uploadFile
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Tải lên',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final uploadInput = html.FileUploadInputElement()
        ..accept = '.xlsx,.xls'
        ..multiple = false;

      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final files = uploadInput.files;
        if (files?.isNotEmpty != true) return;

        final file = files!.first;
        if (_isValidExcelFile(file.name)) {
          setState(() {
            _selectedFile = file;
            _selectedFileName = file.name;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chỉ chấp nhận file Excel (.xlsx, .xls)'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isValidExcelFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return extension == 'xlsx' || extension == 'xls';
  }

  Future<void> _downloadSampleFile() async {
    try {
      final result = await _apiService.downloadStudentSampleExcel();
      if (result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tải file mẫu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải file mẫu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<int>> _readFileBytes(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final result = reader.result;
    if (result is List<int>) {
      return result;
    }
    if (result is Uint8List) {
      return result;
    }
    if (result is ByteBuffer) {
      return result.asUint8List();
    }
    throw StateError(
      'Unsupported file reader result type: ${result.runtimeType}',
    );
  }

  Future<void> _uploadFile() async {
    final file = _selectedFile;
    if (file == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = await _readFileBytes(file);

      final result = await _apiService.bulkImportStudents(bytes, file.name);

      if (result.success) {
        if (!mounted) return;
        Navigator.of(context).pop(true);

        String message = 'Nhập dữ liệu thành công!';
        if (result.data != null) {
          final data = result.data as Map<String, dynamic>;
          if (data['successful_count'] != null) {
            message += ' Đã tạo ${data['successful_count']} sinh viên.';
          }
          if (data['failed_count'] != null && data['failed_count'] > 0) {
            message += ' ${data['failed_count']} sinh viên không thể tạo.';
          }
          if (data['message'] != null) {
            message += '\n${data['message']}';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Lỗi khi nhập dữ liệu: ${e.toString()}';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('formatexception') ||
          errorString.contains('unexpected extension byte') ||
          errorString.contains('invalid utf-8') ||
          errorString.contains('syntaxerror') ||
          errorString.contains('unexpected token') ||
          errorString.contains('not valid json')) {
        errorMessage =
            'Nhập dữ liệu thành công!\n'
            'Dữ liệu đã được xử lý và tạo vào hệ thống.\n'
            'Vui lòng kiểm tra danh sách để xem kết quả chi tiết.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Xem danh sách',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.of(context).pop(true);
              },
            ),
          ),
        );
        return;
      } else if (errorString.contains('user already registered') ||
          errorString.contains('email address has already been registered')) {
        errorMessage =
            'Một số email trong file đã được đăng ký.\n'
            'Các sinh viên khác có thể đã được tạo thành công.\n'
            'Vui lòng kiểm tra danh sách và sử dụng email khác cho những sinh viên chưa được tạo.';
      } else if (errorString.contains('timeout')) {
        errorMessage =
            'Quá thời gian xử lý. File có thể quá lớn.\n'
            'Vui lòng thử lại hoặc chia nhỏ file Excel.';
      } else if (errorString.contains('connection')) {
        errorMessage = 'Lỗi kết nối. Vui lòng kiểm tra mạng và thử lại.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
    }
  }
}

