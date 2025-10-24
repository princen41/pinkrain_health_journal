import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/index.dart';
import '../domain/treatment_manager.dart';

class ScheduleScreen extends StatefulWidget {
  final Treatment treatment;

  const ScheduleScreen({
    required this.treatment,
    super.key,
  });

  @override
  ScheduleScreenState createState() => ScheduleScreenState();
}

class ScheduleScreenState extends State<ScheduleScreen> {
  Map<String, String> doseTimes = {'Dose 1': '10:00'};
  Map<String, TextEditingController> doseControllers = {
    'Dose 1': TextEditingController(text: 'Dose 1')
  };
  String selectedReminder = 'at time of event';

  // Helper method to parse time string to minutes for comparison
  int _parseTime(String timeString) {
    List<String> parts = timeString.split(':');
    if (parts.length == 2) {
      int? hours = int.tryParse(parts[0]);
      int? minutes = int.tryParse(parts[1]);
      if (hours != null && minutes != null) {
        return hours * 60 + minutes;
      }
    }
    return 0; // Default to 0 if parsing fails
  }

  @override
  void dispose() {
    // Dispose all text controllers
    for (var controller in doseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTokens.bgPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTokens.bgPrimary,
        border: Border(
          bottom: BorderSide(
            color: AppTokens.borderLight,
            width: 0.5,
          ),
        ),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.all(0),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppTokens.textPrimary,
              size: 32,
            ),
          ),
        ),
        middle: Text(
          'Schedule',
          style: AppTokens.textStyleLarge,
        ),
        trailing: Container(width: 0), // Balance the back button
      ),
      child: Material(
        color: AppTokens.bgPrimary,
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside text fields
            FocusScope.of(context).unfocus();
          },
          child: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Dose section
                      _buildDoseSection(),
                        
                        const SizedBox(height: 40),
                        
                        // Reminder section
                        _buildReminderSection(),
                        
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
                
                // Navigation buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.pink100,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.pink100,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppTokens.bgMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Dose'),
        
        // Dose list (sorted chronologically)
        ...() {
          final sortedEntries = doseTimes.entries.toList()
            ..sort((a, b) => _parseTime(a.value).compareTo(_parseTime(b.value)));
          return sortedEntries.map((entry) => _buildDoseRow(entry.key, entry.value));
        }(),
        
        // Add dose button
        Button.secondary(
          onPressed: () {
            setState(() {
              String newDose = 'Dose ${doseTimes.length + 1}';
              doseTimes[newDose] = '10:00';
              doseControllers[newDose] = TextEditingController(text: newDose);
            });
          },
          text: 'add a dose',
          backgroundColor: AppColors.pink100,
          textColor: AppTokens.textPrimary,
          size: ButtonSize.small,
          borderWidth: 0,
          leadingIcon: HugeIcon(
            icon: HugeIcons.strokeRoundedAdd01,
            color: AppTokens.textPrimary,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDoseRow(String doseName, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: doseControllers[doseName]!,
                  hintText: 'Dose name',
                  onChanged: () {
                    // Update the dose name in the maps
                    String newName = doseControllers[doseName]!.text;
                    if (newName.isNotEmpty && newName != doseName) {
                      setState(() {
                        // Update doseTimes with new name
                        String time = doseTimes[doseName]!;
                        doseTimes.remove(doseName);
                        doseTimes[newName] = time;
                        
                        // Update controllers map
                        TextEditingController controller = doseControllers[doseName]!;
                        doseControllers.remove(doseName);
                        doseControllers[newName] = controller;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Time display/button
                GestureDetector(
                  onTap: () async {
                    // Parse current time safely
                    List<String> timeParts = time.split(':');
                    if (timeParts.length == 2) {
                      int? currentHour = int.tryParse(timeParts[0]);
                      int? currentMinute = int.tryParse(timeParts[1]);
                      
                      if (currentHour != null && currentMinute != null) {
                        await showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              height: 300,
                              color: Colors.white,
                              child: CupertinoTheme(
                                data: CupertinoThemeData(
                                  textTheme: CupertinoTextThemeData(
                                    dateTimePickerTextStyle: AppTokens.textStyleLarge,
                                  ),
                                ),
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.time,
                                  use24hFormat: true,
                                  minuteInterval: 5,
                                  initialDateTime: DateTime(2024, 1, 1, currentHour, currentMinute),
                                  onDateTimeChanged: (DateTime newDateTime) {
                                    setState(() {
                                      doseTimes[doseName] = '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        );
                        // Ensure keyboard doesn't appear after picker closes
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).unfocus();
                        });
                      }
                    }
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Text(
                          time,
                          style: AppTokens.textStyleMedium,
                        ),
                        const Spacer(),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowDown01,
                          color: AppTokens.iconMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
              // Delete button (only show if there's more than one dose)
              if (doseTimes.length > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Dispose the controller
                      doseControllers[doseName]?.dispose();
                      doseControllers.remove(doseName);
                      doseTimes.remove(doseName);
                      
                      // Renumber remaining doses
                      final newDoseTimes = <String, String>{};
                      final newDoseControllers = <String, TextEditingController>{};
                      final sortedKeys = doseTimes.keys.toList()..sort();
                      for (int i = 0; i < sortedKeys.length; i++) {
                        String newName = 'Dose ${i + 1}';
                        newDoseTimes[newName] = doseTimes[sortedKeys[i]]!;
                        newDoseControllers[newName] = TextEditingController(text: newName);
                      }
                      doseTimes = newDoseTimes;
                      doseControllers = newDoseControllers;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTokens.stateError.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppTokens.stateError,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Reminder'),
        
        GestureDetector(
          onTap: () async {
            await showCupertinoModalPopup(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 200,
                  color: Colors.white,
                  child: CupertinoPicker(
                    itemExtent: 50,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        selectedReminder = [
                          'at time of event',
                          '5 minutes before',
                          '10 minutes before',
                          '15 minutes before',
                          '30 minutes before',
                        ][index];
                      });
                    },
                    children: [
                      'at time of event',
                      '5 minutes before',
                      '10 minutes before',
                      '15 minutes before',
                      '30 minutes before',
                    ].map((String value) {
                      return Center(
                        child: Text(
                          value,
                          style: AppTokens.textStyleLarge,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            );
            // Ensure keyboard doesn't appear after picker closes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              FocusScope.of(context).unfocus();
            });
          },
          child: Container(
            width: double.infinity,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Text(
                  selectedReminder,
                  style: AppTokens.textStyleMedium,
                ),
                const Spacer(),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  color: AppTokens.iconMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Button.secondary(
              onPressed: () => context.pop(),
              text: 'Previous',
              size: ButtonSize.large,
              borderWidth: 0,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Button.primary(
              onPressed: () {
                // Parse the first dose time for the treatment plan
                String firstDoseTime = doseTimes.values.first;
                List<String> timeParts = firstDoseTime.split(':');
                widget.treatment.treatmentPlan.timeOfDay = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  int.parse(timeParts[0]),
                  int.parse(timeParts[1]),
                );
                context.push('/duration', extra: widget.treatment);
              },
              text: 'Continue',
              size: ButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }
}