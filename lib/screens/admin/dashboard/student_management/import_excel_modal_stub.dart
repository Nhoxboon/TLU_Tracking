import 'package:flutter/material.dart';

class ImportExcelModal extends StatelessWidget {
  const ImportExcelModal({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tính năng không khả dụng'),
      content: const Text(
        'Nhập dữ liệu sinh viên từ Excel hiện chỉ khả dụng trên phiên bản web. '
        'Vui lòng truy cập phiên bản web để sử dụng tính năng này.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

