import 'package:flutter/material.dart';
import 'package:android_app/widgets/common/custom_action_button.dart';

// Base interface for table data
abstract class TableRowData {
  int get id;
  String get code;
  String get name;
  String get phone;
  String get email;
  String get birthDate;
}

// Extended interface for student data with major
abstract class StudentTableRowData extends TableRowData {
  String get major;
  String get course;
}

// Extended interface for class data with teacher and subject
abstract class ClassTableRowData extends TableRowData {
  String get teacher;
  String get subject;
  String get creationDate;
}

// Extended interface for major data (simple, no additional fields)
abstract class MajorTableRowData extends TableRowData {
  // Majors only need id, code, and name - other fields are inherited but empty
}

// Extended interface for course data with admission year
abstract class CourseTableRowData extends TableRowData {
  String get admissionYear;
}

// Generic reusable table row widget
class DataTableRow<T extends TableRowData> extends StatelessWidget {
  final T data;
  final bool isEven;
  final bool isSelected;
  final List<TableColumn> columns;
  final VoidCallback? onSelectionChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DataTableRow({
    super.key,
    required this.data,
    required this.isEven,
    required this.isSelected,
    required this.columns,
    this.onSelectionChanged,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected
          ? const Color(0xFFCFDDFA) // màu highlight khi select
          : (isEven ? Colors.white : const Color(0xFFF9FAFC)), // màu thường
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 32,
            child: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                onSelectionChanged?.call();
              },
            ),
          ),

          // Dynamic columns
          ...columns.map((column) => _buildColumn(column)),
        ],
      ),
    );
  }

  Widget _buildColumn(TableColumn column) {
    switch (column.type) {
      case TableColumnType.id:
        return Expanded(
          flex: column.flex,
          child: Text(
            data.id.toString(),
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.code:
        return Expanded(
          flex: column.flex,
          child: Text(
            data.code,
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.name:
        return Expanded(
          flex: column.flex,
          child: Text(
            data.name,
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.phone:
        return Expanded(
          flex: column.flex,
          child: Text(
            data.phone,
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.email:
        return Expanded(
          flex: column.flex,
          child: Text(
            data.email,
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.birthDate:
        return Expanded(
          flex: column.flex,
          child: Text(
            data.birthDate,
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.major:
        return Expanded(
          flex: column.flex,
          child: Text(
            (data is StudentTableRowData)
                ? (data as StudentTableRowData).major
                : '',
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.majorName:
        return Expanded(
          flex: column.flex,
          child: Text(
            data.name, // For majors, we use the name field to show major name
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.course:
        return Expanded(
          flex: column.flex,
          child: Text(
            (data is StudentTableRowData)
                ? (data as StudentTableRowData).course
                : '',
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.teacher:
        return Expanded(
          flex: column.flex,
          child: Text(
            (data is ClassTableRowData)
                ? (data as ClassTableRowData).teacher
                : '',
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.subject:
        return Expanded(
          flex: column.flex,
          child: Text(
            (data is ClassTableRowData)
                ? (data as ClassTableRowData).subject
                : '',
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.creationDate:
        return Expanded(
          flex: column.flex,
          child: Text(
            (data is ClassTableRowData)
                ? (data as ClassTableRowData).creationDate
                : data.birthDate,
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.custom:
        String customText = '';
        if (column.customValue == 'admissionYear' &&
            data is CourseTableRowData) {
          customText = (data as CourseTableRowData).admissionYear;
        } else if (column.customGetter != null) {
          customText = column.customGetter!(data);
        } else {
          customText = column.customValue ?? '';
        }

        // Special handling for admissionYear - add left padding to shift text left
        if (column.customValue == 'admissionYear') {
          return Expanded(
            flex: column.flex,
            child: Padding(
              padding: const EdgeInsets.only(right: 55.0),
              child: Text(
                customText,
                textAlign: column.textAlign,
                style: _getTextStyle(column.styleType),
              ),
            ),
          );
        }

        return Expanded(
          flex: column.flex,
          child: Text(
            customText,
            textAlign: column.textAlign,
            style: _getTextStyle(column.styleType),
          ),
        );
      case TableColumnType.actions:
        return Expanded(
          flex: column.flex,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onEdit != null) ...[
                CustomActionButton(
                  icon: Icons.edit_outlined,
                  iconColor: const Color(0xFF000000).withValues(alpha: 0.6),
                  onTap: onEdit!,
                  tooltip: "Chỉnh sửa",
                ),
                const SizedBox(width: 8),
              ],
              if (onDelete != null)
                CustomActionButton(
                  icon: Icons.delete_outline,
                  iconColor: const Color(0xFFEF3826),
                  onTap: onDelete!,
                  tooltip: "Xóa",
                  requiresConfirmation: true,
                  confirmationTitle: 'Xác nhận xóa',
                  confirmationMessage:
                      'Bạn có chắc chắn muốn xóa? Hành động này không thể hoàn tác.',
                ),
            ],
          ),
        );
    }
  }

  TextStyle _getTextStyle(TableColumnStyleType styleType) {
    switch (styleType) {
      case TableColumnStyleType.primary:
        return const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.28,
          color: Color(0xFF171C26),
        );
      case TableColumnStyleType.secondary:
        return const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.28,
          color: Color(0xFF464F60),
        );
      case TableColumnStyleType.normal:
        return const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF464F60),
        );
    }
  }
}

// Table column configuration
class TableColumn {
  final TableColumnType type;
  final int flex;
  final TextAlign textAlign;
  final TableColumnStyleType styleType;
  final String? customValue; // for custom columns
  final String Function(TableRowData)?
  customGetter; // for dynamic custom values

  const TableColumn({
    required this.type,
    required this.flex,
    this.textAlign = TextAlign.left,
    this.styleType = TableColumnStyleType.normal,
    this.customValue,
    this.customGetter,
  });
}

enum TableColumnType {
  id,
  code,
  name,
  major,
  majorName,
  phone,
  email,
  birthDate,
  course,
  teacher,
  subject,
  creationDate,
  custom,
  actions,
}

enum TableColumnStyleType { primary, secondary, normal }
