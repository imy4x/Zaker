import 'package:flutter/material.dart';

/// خريطة ثابتة للأيقونات المدعومة
/// تقدر تضيف أيقونات جديدة هنا إذا احتجت
const Map<String, IconData> iconMap = {
  'folder': Icons.folder_special_outlined,
  'book': Icons.book,
  'home': Icons.home,
  'study': Icons.school,
  'note': Icons.note,
};

/// نموذج يمثل قائمة أو مجلد لتنظيم جلسات المذاكرة
class StudyList {
  String id;
  String name;
  String iconName;
  int colorValue;

  StudyList({
    required this.id,
    required this.name,
    String? iconName,
    int? colorValue,
  })  : this.iconName = iconName ?? 'folder',
        this.colorValue = colorValue ?? Colors.blueGrey.value;

  /// يرجع الأيقونة بناءً على الاسم
  IconData get icon => iconMap[iconName] ?? Icons.help_outline;

  /// يرجع اللون من القيمة
  Color get color => Color(colorValue);

  /// إنشاء كائن من JSON
  factory StudyList.fromJson(Map<String, dynamic> json) {
    return StudyList(
      id: json['id'],
      name: json['name'],
      iconName: json['iconName'] ?? 'folder',
      colorValue: json['colorValue'] ?? Colors.blueGrey.value,
    );
  }

  /// تحويل الكائن إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
    };
  }
}
