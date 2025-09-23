import 'package:flutter/material.dart';

/// نموذج يمثل قائمة أو مجلد لتنظيم جلسات المذاكرة
class StudyList {
  String id;
  String name;
  
  int iconCodePoint;
  int colorValue;

  // --- تعديل: تم إصلاح خطأ `const_eval_property_access` ---
  // تم نقل تعيين القيم الافتراضية إلى قائمة التهيئة الخاصة بالمنشئ
  StudyList({
    required this.id,
    required this.name,
    int? iconCodePoint,
    int? colorValue,
  })  : this.iconCodePoint = iconCodePoint ?? Icons.folder_special_outlined.codePoint,
        this.colorValue = colorValue ?? Colors.blueGrey.value;


  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  factory StudyList.fromJson(Map<String, dynamic> json) {
    return StudyList(
      id: json['id'],
      name: json['name'],
      iconCodePoint: json['iconCodePoint'] ?? Icons.folder_special_outlined.codePoint,
      colorValue: json['colorValue'] ?? Colors.blueGrey.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }
}

