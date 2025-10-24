import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pinkrain/core/util/date_format_converters.dart';

import '../../features/journal/data/journal_log.dart';
import '../theme/icons.dart';
import '../widgets/color_picker.dart';

extension StringExtensions on String {
  void logType(){
    devPrint(runtimeType);
  }
  void log(){
    devPrint(this);
  }
  /// Returns the debug value if debug mode is enabled, otherwise returns the original value
  String debugValue(String? val){
    if(kDebugMode){
      return val ?? this;
    }
    else{
      return this;
    }

  }
}

void devPrint(dynamic message) {
  if (kDebugMode) {
    print(message);
  }
}

extension DateTimeExtensions on DateTime {
  DateTime normalize() {
    return DateTime(year, month, day);
  }
  String getNameOf(String selectedDateOption) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDate = DateTime(year, month, day);
    
    switch(selectedDateOption) {
      case 'day':
        if (thisDate.isAtSameMomentAs(today)) {
          return 'Today';
        } else {
          return DateFormat('MMMM d, yyyy').format(this);
        }
      case 'month':
        return getMonthName(month);
      case 'year':
        return '$year';
    }
    return '';
  }
    bool isToday() => day == DateTime.now().day && month == DateTime.now().month && year == DateTime.now().year;
}

extension ListExtensions on List<IntakeLog> {
  List<IntakeLog> forMorning() {
    return where((t) => t.treatment.treatmentPlan.timeOfDay.hour >= 4 && t.treatment.treatmentPlan.timeOfDay.hour < 12).toList();
  }

  List<IntakeLog> forNoon() {
    return where((t) => t.treatment.treatmentPlan.timeOfDay.hour >= 12 && t.treatment.treatmentPlan.timeOfDay.hour < 15).toList();
  }

  List<IntakeLog> forAfternoon() {
    return where((t) => t.treatment.treatmentPlan.timeOfDay.hour >= 15 && t.treatment.treatmentPlan.timeOfDay.hour < 18).toList();
  }

  List<IntakeLog> forEvening() {
    return where((t) => t.treatment.treatmentPlan.timeOfDay.hour >= 18 && t.treatment.treatmentPlan.timeOfDay.hour < 21).toList();
  }

  List<IntakeLog> forNight() {
    return where((t) => t.treatment.treatmentPlan.timeOfDay.hour >= 21 || t.treatment.treatmentPlan.timeOfDay.hour < 4).toList();
  }
}

// Extension to add date comparison functionality
extension DateTimeExtension on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

// Extension to add string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension IntExtension on int {
  String ordinal() {
    final dateInt = this % 10;
    return "$this${
        dateInt == 1 ? 'st' : dateInt == 2 ? 'nd' : dateInt == 3 ? 'rd' : 'th'
    }";
  }
}

// Use the centralized colorMap from ColorPicker widget
final Map<String, Color> colorMap = ColorPicker.colorMap;


FutureBuilder<SvgPicture> futureBuildSvg(String text, String selectedColor, [double size = 30, String? secondaryColor]) {
  return FutureBuilder<SvgPicture>(
      future: appSvgDynamicImage(
          fileName: text.toLowerCase(),
          size: size,
          color: colorMap[selectedColor],
          secondaryColor: secondaryColor != null ? colorMap[secondaryColor] : null,
          useColorFilter: false
      ),
      builder: (context, snapshot) {
        return snapshot.data ??
            appVectorImage(
                fileName: text.toLowerCase(),
                size: size,
                color: colorMap[selectedColor],
                useColorFilter: false
            );
      }
  );
}

DateTime getStartDate(String selectedDateOption, DateTime selectedDate) {
  DateTime startDate;
  switch (selectedDateOption) {
    case 'day':
    // For a day, just use the selected date
      startDate = selectedDate;
      break;
    case 'month':
    // For a month, use the first day of the month to the selected date
      startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      break;
    case 'year':
    // For a year, use the first day of the year to the selected date
      startDate = DateTime(selectedDate.year, 1, 1);
      break;
    default:
    // Default to last 30 days
      startDate = selectedDate.subtract(const Duration(days: 30));
  }
  return startDate;
}