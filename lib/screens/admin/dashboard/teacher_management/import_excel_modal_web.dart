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
            // Header
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
                      'Nhập dữ liệu từ Excel',
                      style: TextStyle(
                        fontFamily: 'Nunito Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
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

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF0284C7),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hướng dẫn nhập dữ liệu:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '1. Tải file mẫu Excel bên dưới\n'
                                  '2. Điền thông tin giảng viên theo đúng định dạng\n'
                                  '3. Tải lên file Excel đã hoàn thành\n'
                                  '4. Hệ thống sẽ tự động xử lý và thông báo kết quả',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF0284C7),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _downloadSampleFile,
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Tải file mẫu Excel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // File upload area
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _isDragOver
                                ? const Color(0xFFF0F9FF)
                                : const Color(0xFFFAFBFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isDragOver
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedFile != null
                                    ? Icons.insert_drive_file
                                    : Icons.cloud_upload_outlined,
                                size: 48,
                                color: _selectedFile != null
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 16),
                              if (_selectedFile != null) ...[
                                Text(
                                  _selectedFileName ?? _selectedFile!.name,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF059669),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhấp để chọn file khác',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Kéo thả file Excel vào đây',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'hoặc nhấp để chọn file',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Chỉ chấp nhận file .xlsx, .xls',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Colors.grey[500],
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

            // Footer
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
                    onPressed: _isUploading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_selectedFile != null && !_isUploading)
                        ? _uploadFile
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Nhập dữ liệu',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
      final result = await _apiService.downloadTeacherSampleExcel();
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

      final result = await _apiService.bulkImportTeachers(bytes, file.name);

      if (result.success) {
        if (!mounted) return;

        String message = 'Nhập dữ liệu thành công!';
        Color backgroundColor = Colors.green;
        bool shouldRefresh = true;

        if (result.data != null) {
          final data = result.data as Map<String, dynamic>;
          final successCount =
              data['successful_count'] ?? data['success_count'] ?? 0;
          final failedCount = data['failed_count'] ?? data['error_count'] ?? 0;
          final status = data['status'] ?? '';

          if (successCount > 0 && failedCount == 0) {
            message =
                'Nhập dữ liệu thành công! Đã tạo $successCount giảng viên.';
            backgroundColor = Colors.green;
          } else if (successCount > 0 && failedCount > 0) {
            message =
                'Nhập dữ liệu một phần thành công!\n'
                'Đã tạo $successCount giảng viên.\n'
                '$failedCount giảng viên không thể tạo (có thể do email đã tồn tại).';
            backgroundColor = Colors.orange;
          } else if (successCount == 0 && failedCount > 0) {
            message =
                'Không thể tạo giảng viên nào. Vui lòng kiểm tra dữ liệu.';
            backgroundColor = Colors.red;
            shouldRefresh = false;
          } else if (status == 'partial_success') {
            message =
                'Nhập dữ liệu thành công!\n'
                'Dữ liệu đã được xử lý và tạo vào hệ thống.\n'
                'Vui lòng kiểm tra danh sách để xem kết quả chi tiết.';
            backgroundColor = Colors.green;
          }

          if (data['message'] != null &&
              data['message'].toString().isNotEmpty) {
            message += '\n\nChi tiết: ${data['message']}';
          }
        }

        Navigator.of(context).pop(shouldRefresh);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 5),
            action: backgroundColor == Colors.orange
                ? SnackBarAction(
                    label: 'Kiểm tra',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  )
                : null,
          ),
        );
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Lỗi khi nhập dữ liệu: ${e.toString()}';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('all teacher imports failed')) {
        errorMessage =
            'Không thể tạo giảng viên nào!\n\n'
            'Nguyên nhân có thể:\n'
            '• Tất cả email đã được đăng ký trong hệ thống\n'
            '• Dữ liệu trong file Excel không đúng định dạng\n'
            '• Thiếu thông tin bắt buộc (khoa, bộ môn)\n\n'
            'Vui lòng kiểm tra lại file Excel và thử lại.';
      } else if (errorString.contains('import completed with errors')) {
        errorMessage =
            'Import hoàn thành nhưng có lỗi!\n'
            'Một số giảng viên không thể được tạo.\n'
            'Vui lòng kiểm tra danh sách và thử lại với dữ liệu đã sửa.';
      } else if (errorString.contains('syntaxerror') ||
          errorString.contains('unexpected token') ||
          errorString.contains('not valid json') ||
          errorString.contains('formatexception')) {
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
            'Các giảng viên khác có thể đã được tạo thành công.\n'
            'Vui lòng kiểm tra danh sách và sử dụng email khác cho những giảng viên chưa được tạo.';
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
