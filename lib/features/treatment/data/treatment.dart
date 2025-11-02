import 'package:pinkrain/core/util/helpers.dart';

import '../domain/reminder_rl.dart';

class TreatmentPlan {
  DateTime startDate;
  DateTime endDate;
  DateTime timeOfDay = DateTime(1970, 1, 1, 11, 0);
  List<DateTime> doseTimes; // Support for multiple doses per day
  final String mealOption;
  final String instructions;
  final Duration frequency;
  final List<bool> selectedDays; // 0=Monday, 1=Tuesday, ..., 6=Sunday
  ReminderRL reminderRL = ReminderRL([]);

  TreatmentPlan({
    required this.startDate,
    required this.endDate,
    required this.timeOfDay,
    List<DateTime>? doseTimes,
    this.mealOption = '',
    this.instructions = '',
    this.frequency = const Duration(days: 1),
    this.selectedDays = const [true, true, true, true, true, true, true] // Default to all days
  }) : doseTimes = doseTimes ?? []; // Initialize doseTimes list
  
  /// Get all dose times for this treatment. If doseTimes is populated, use it.
  /// Otherwise, fall back to the single timeOfDay for backward compatibility.
  List<DateTime> getAllDoseTimes() {
    if (doseTimes.isNotEmpty) {
      return doseTimes;
    }
    return [timeOfDay];
  }

  bool isOnGoing() {
    return startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
  }

  String intakeFrequency() {
    final String freq = frequency.inDays <= 1
        ? '${24 / frequency.inHours} times a day'
        : 'Every ${frequency.inDays} days';
    return freq;
  }

  int requiredPills(int currentMedicationAmount) {
    'Current medication amount: $currentMedicationAmount'.log();
    Duration remainingPeriod = endDate.difference(DateTime.now());
    'Remaining period: ${remainingPeriod.inDays} days'.log();
    final double requiredPills =
        (remainingPeriod.inHours / frequency.inHours) - currentMedicationAmount;
    return requiredPills.toInt();
  }

  String pillStatus(int currentMedicationAmount) {
    final requiredNumber = requiredPills(currentMedicationAmount);
    return requiredNumber < 1
        ? 'Extra pills: $requiredNumber'
        : 'Pills needed: $requiredNumber';
  }

  /// Check if this treatment should be taken on the given date
  /// Returns true if the date is within the treatment period AND on a selected day
  bool shouldTakeOnDate(DateTime date) {
    // Normalize dates to compare only date parts
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    
    // Check if date is within treatment period
    if (normalizedDate.isBefore(normalizedStart) || normalizedDate.isAfter(normalizedEnd)) {
      return false;
    }
    
    // Check if the day of week is selected
    // DateTime.weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
    // selectedDays: 0=Monday, 1=Tuesday, ..., 6=Sunday
    final dayIndex = (normalizedDate.weekday - 1) % 7;
    return selectedDays[dayIndex];
  }
}
