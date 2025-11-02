import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hux/hux.dart';

import '../../../core/util/helpers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/index.dart';
import '../../../features/journal/presentation/journal_notifier.dart';
import '../domain/treatment_manager.dart';
import '../services/medication_notification_service.dart';

class DurationScreen extends ConsumerStatefulWidget {
  final Treatment treatment;

  const DurationScreen({
    super.key,
    required this.treatment,
  });

  @override
  ConsumerState<DurationScreen> createState() => DurationScreenState();
}

class DurationScreenState extends ConsumerState<DurationScreen> {
  final List<bool> selectedDays = List.generate(7, (index) => false);
  int selectedDuration = 5;
  late TextEditingController durationController;
  String selectedDurationUnit = 'days';
  bool isUnlimitedDuration = false;
  DateTime startDate = DateTime.now().add(const Duration(days: 1)).normalize();
  String selectedStartOption = 'tomorrow';
  final TreatmentManager treatmentManager = TreatmentManager();

  /// Derive the start option from a stored date by comparing it to today/tomorrow/next Monday
  String _deriveStartOption(DateTime storedDate) {
    final now = DateTime.now();
    final today = now.normalize();
    final tomorrow = now.add(const Duration(days: 1)).normalize();
    final storedNormalized = storedDate.normalize();
    
    // Check if it's today
    if (storedNormalized.year == today.year && 
        storedNormalized.month == today.month && 
        storedNormalized.day == today.day) {
      return 'today';
    }
    
    // Check if it's tomorrow
    if (storedNormalized.year == tomorrow.year && 
        storedNormalized.month == tomorrow.month && 
        storedNormalized.day == tomorrow.day) {
      return 'tomorrow';
    }
    
    // Check if it's next Monday
    int daysUntilMonday = (8 - now.weekday) % 7;
    if (daysUntilMonday == 0) daysUntilMonday = 7;
    final nextMonday = now.add(Duration(days: daysUntilMonday)).normalize();
    if (storedNormalized.year == nextMonday.year && 
        storedNormalized.month == nextMonday.month && 
        storedNormalized.day == nextMonday.day) {
      return 'next Monday';
    }
    
    // Otherwise, it's a specific date
    return 'Select specific date';
  }

  @override
  void initState() {
    super.initState();
    
    final plan = widget.treatment.treatmentPlan;
    
    // Hydrate selectedDays from the plan
    for (int i = 0; i < 7; i++) {
      if (i < plan.selectedDays.length) {
        selectedDays[i] = plan.selectedDays[i];
      } else {
        selectedDays[i] = false; // Default to false if plan doesn't have enough days
      }
    }
    
    // Normalize and set startDate from the stored plan (handle timezone/UTC normalization)
    startDate = plan.startDate.normalize();
    
    // Compute duration from plan.startDate and plan.endDate
    final durationDays = plan.endDate.difference(plan.startDate).inDays + 1;
    
    // Check if it's unlimited duration (100 years in the future indicates unlimited)
    final durationYears = durationDays / 365.0;
    isUnlimitedDuration = durationYears > 50; // Treat > 50 years as unlimited
    
    if (isUnlimitedDuration) {
      // For unlimited, use a default duration for display purposes
      selectedDuration = 30;
      selectedDurationUnit = 'days';
    } else {
      // Determine the appropriate unit and value
      if (durationDays % 30 == 0 && durationDays >= 30) {
        // Try months first (approximate)
        final months = durationDays ~/ 30;
        if (months >= 1 && months <= 24) {
          selectedDuration = months;
          selectedDurationUnit = 'months';
        } else {
          // Too many months, use weeks or days
          if (durationDays % 7 == 0) {
            selectedDuration = durationDays ~/ 7;
            selectedDurationUnit = 'weeks';
          } else {
            selectedDuration = durationDays;
            selectedDurationUnit = 'days';
          }
        }
      } else if (durationDays % 7 == 0 && durationDays >= 7) {
        // Use weeks
        selectedDuration = durationDays ~/ 7;
        selectedDurationUnit = 'weeks';
      } else {
        // Use days
        selectedDuration = durationDays;
        selectedDurationUnit = 'days';
      }
    }
    
    // Update selectedStartOption by deriving it from the stored date
    selectedStartOption = _deriveStartOption(plan.startDate);
    
    // Set durationController.text to the derived duration
    durationController = TextEditingController(text: selectedDuration.toString());
    
    // Only then attach the controller listener so the initial text change doesn't overwrite seeded values
    durationController.addListener(() {
      final intValue = int.tryParse(durationController.text);
      if (intValue != null && intValue > 0) {
        setState(() {
          selectedDuration = intValue;
        });
      }
    });
  }

  @override
  void dispose() {
    durationController.dispose();
    super.dispose();
  }

  // Helper function to format date as DD/MM/YYYY
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<Widget> _buildDayButtons() {
    final List<String> days = ['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'];
    return List.generate(7, (index) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              selectedDays[index] = !selectedDays[index];
            });
          },
          child: Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == 6 ? 0 : 4,
            ),
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedDays[index] ? AppColors.pink100 : AppTokens.bgMuted,
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  color: selectedDays[index] ? AppTokens.textPrimary : AppTokens.textSecondary,
                  fontWeight: AppTokens.fontWeightBold,
                  fontFamily: 'Outfit',
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    });
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
                color: AppColors.pink100,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Days taken'),
        Row(
          children: _buildDayButtons(),
        ),
      ],
    );
  }

  Widget _buildStartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Start'),
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
                        String selectedValue = ['today', 'tomorrow', 'next Monday', 'Select specific date'][index];
                        selectedStartOption = selectedValue;
                        
                        if (selectedValue == 'today') {
                          startDate = DateTime.now().normalize();
                        } else if (selectedValue == 'tomorrow') {
                          startDate = DateTime.now().add(const Duration(days: 1)).normalize();
                        } else if (selectedValue == 'next Monday') {
                          // Calculate next Monday
                          DateTime now = DateTime.now();
                          int daysUntilMonday = (8 - now.weekday) % 7;
                          if (daysUntilMonday == 0) daysUntilMonday = 7;
                          startDate = now.add(Duration(days: daysUntilMonday)).normalize();
                        }
                        // For 'Select specific date', we'll handle it separately
                      });
                    },
                    children: [
                      'today',
                      'tomorrow',
                      'next Monday',
                      'select specific date',
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
            
            // If "Select specific date" was selected, show date picker
            if (selectedStartOption == 'Select specific date' && mounted) {
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
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: startDate,
                        minimumDate: DateTime.now(),
                        dateOrder: DatePickerDateOrder.dmy,
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() {
                            startDate = newDateTime.normalize();
                          });
                        },
                      ),
                    ),
                  );
                },
              );
            }
            
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
                  selectedStartOption == 'Select specific date' 
                      ? _formatDate(startDate)
                      : selectedStartOption,
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

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Duration'),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: IgnorePointer(
                ignoring: isUnlimitedDuration,
                child: Opacity(
                  opacity: isUnlimitedDuration ? 0.5 : 1.0,
                  child: CustomTextField(
                    controller: durationController,
                    hintText: 'Duration',
                    keyboardType: TextInputType.number,
                    isNumberField: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Opacity(
                opacity: isUnlimitedDuration ? 0.5 : 1.0,
                child: GestureDetector(
                  onTap: isUnlimitedDuration ? null : () async {
                    String pickedUnit = selectedDurationUnit;
                    await showCupertinoModalPopup(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return Container(
                              height: 200,
                              color: Colors.white,
                              child: CupertinoPicker(
                                itemExtent: 50,
                                scrollController: FixedExtentScrollController(
                                  initialItem: ['days', 'weeks', 'months'].indexOf(selectedDurationUnit),
                                ),
                                onSelectedItemChanged: (int index) {
                                  pickedUnit = ['days', 'weeks', 'months'][index];
                                },
                                children: [
                                  'days',
                                  'weeks',
                                  'months',
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
                      },
                    );
                    setState(() {
                      selectedDurationUnit = pickedUnit;
                    });
                    // Ensure keyboard doesn't appear after picker closes
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      FocusScope.of(context).unfocus();
                    });
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
                          selectedDurationUnit,
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Theme(
          data: Theme.of(context).copyWith(
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.all(AppColors.pink100),
              checkColor: WidgetStateProperty.all(Colors.white),
            ),
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.pink100,
            ),
          ),
          child: HuxCheckbox(
            value: isUnlimitedDuration,
            onChanged: (bool? newValue) {
              setState(() {
                isUnlimitedDuration = newValue ?? false;
                if (isUnlimitedDuration) {
                  // Unfocus any text fields when enabling unlimited duration
                  FocusScope.of(context).unfocus();
                }
              });
            },
            label: 'Ongoing treatment',
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTokens.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
          const SizedBox(width: 12),
          Expanded(
            child: Button.primary(
              onPressed: () async {
                // Convert duration based on selected unit
                DateTime calculatedEndDate;
                
                if (isUnlimitedDuration) {
                  // Set end date to 100 years in the future for unlimited duration
                  calculatedEndDate = DateTime(startDate.year + 100, startDate.month, startDate.day);
                } else {
                  int durationInDays;
                  switch (selectedDurationUnit) {
                    case 'days':
                      durationInDays = selectedDuration;
                      break;
                    case 'weeks':
                      durationInDays = selectedDuration * 7;
                      break;
                    case 'months':
                      // Use real month arithmetic instead of 30-day approximation
                      int targetYear = startDate.year;
                      int targetMonth = startDate.month + selectedDuration;
                      
                      // Handle year overflow
                      while (targetMonth > 12) {
                        targetMonth -= 12;
                        targetYear += 1;
                      }
                      
                      // Handle cases where target month has fewer days
                      int targetDay = startDate.day;
                      int daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
                      if (targetDay > daysInTargetMonth) {
                        targetDay = daysInTargetMonth;
                      }
                      
                      // Calculate end date and compute actual day difference
                      calculatedEndDate = DateTime(targetYear, targetMonth, targetDay);
                      durationInDays = calculatedEndDate.difference(startDate).inDays;
                      break;
                    default:
                      durationInDays = selectedDuration;
                  }
                  calculatedEndDate = startDate.add(Duration(days: durationInDays - 1));
                }

                widget.treatment.treatmentPlan.startDate = startDate;
                widget.treatment.treatmentPlan.endDate = calculatedEndDate.normalize();

                // Save the selected days - create a new TreatmentPlan with selectedDays
                final updatedTreatment = Treatment.newTreatment(
                  id: widget.treatment.id,
                  name: widget.treatment.medicine.name,
                  type: widget.treatment.medicine.type,
                  color: widget.treatment.medicine.color,
                  dose: widget.treatment.medicine.specs.dosage,
                  unit: widget.treatment.medicine.specs.unit,
                  useCase: widget.treatment.medicine.specs.useCase,
                  startDate: startDate,
                  endDate: calculatedEndDate.normalize(),
                  mealOption: widget.treatment.treatmentPlan.mealOption,
                  instructions: widget.treatment.treatmentPlan.instructions,
                  frequency: widget.treatment.treatmentPlan.frequency,
                  selectedDays: selectedDays,
                );
                
                // Preserve the time and ALL dose times from the original treatment
                updatedTreatment.treatmentPlan.timeOfDay = widget.treatment.treatmentPlan.timeOfDay;
                // Preserve all dose times that were set in the schedule screen
                updatedTreatment.treatmentPlan.doseTimes = List.from(widget.treatment.treatmentPlan.doseTimes);
                // Preserve custom dose names that were set in the schedule screen
                updatedTreatment.treatmentPlan.doseNamesMap = Map.from(widget.treatment.treatmentPlan.doseNamesMap);
                
                await treatmentManager.saveTreatment(updatedTreatment);
                
                // Reload treatments to ensure the new treatment is in memory
                await treatmentManager.loadTreatments();
                devPrint("Treatment saved, total count: ${treatmentManager.treatments.length}");

                if (mounted) {
                  // Clear all cached medication logs to ensure new treatment appears on all relevant dates
                  final pillIntakeNotifier = ref.read(pillIntakeProvider.notifier);
                  final journalLog = pillIntakeNotifier.journalLog;
                  journalLog.clearAllCachedMedicationLogs();
                  
                  // Force reload ALL dates in the treatment range
                  devPrint("Reloading logs for treatment range: $startDate to $calculatedEndDate");
                  
                  // Reload all dates in the range (limited to reasonable range to avoid performance issues)
                  DateTime currentDate = startDate;
                  int daysLoaded = 0;
                  int actualDurationInDays = calculatedEndDate.difference(startDate).inDays + 1;
                  while (daysLoaded < actualDurationInDays && daysLoaded < 365) { // Limit to 1 year for performance
                    await journalLog.forceReloadMedicationLogs(currentDate);
                    await journalLog.saveMedicationLogs(currentDate);
                    currentDate = currentDate.add(const Duration(days: 1));
                    daysLoaded++;
                  }
                  
                  devPrint("Reloaded $daysLoaded days in treatment range");
                  
                  // Force reload of journal data
                  final selectedDate = ref.read(selectedDateProvider);
                  await pillIntakeNotifier.populateJournal(selectedDate, forceReload: true);

                  // Immediately schedule notifications for today's untaken medications
                  try {
                    final notificationService = MedicationNotificationService();
                    await notificationService.initialize();
                    
                    // CRITICAL FIX: Clear notification tracking before rescheduling
                    notificationService.clearAllNotificationTracking();
                    
                    final todayMeds = await journalLog.getMedicationsForTheDay(DateTime.now());
                    await notificationService.showUntakenMedicationNotifications(
                      todayMeds,
                      forceReschedule: true,
                      showImmediateNotifications: false, // Don't show immediate notifications when just rescheduling
                    );
                    devPrint('📅 Triggered scheduling after saving treatment');
                  } catch (e) {
                    devPrint('❌ Failed to schedule notifications after saving treatment: $e');
                  }
                  
                  if (mounted && context.mounted) {
                    context.go('/journal');
                  }
                }
              },
              text: 'Add',
              size: ButtonSize.large,
            ),
          ),
        ],
      ),
    ),
    );
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
          'Duration',
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
                        
                        // Days Taken section
                        _buildDaysSection(),
                        
                        const SizedBox(height: 40),
                        
                        // Start section
                        _buildStartSection(),
                        
                        const SizedBox(height: 40),
                        
                        // Duration section
                        _buildDurationSection(),
                        
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
}
