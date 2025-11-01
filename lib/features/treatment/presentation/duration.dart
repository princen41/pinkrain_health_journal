import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

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
  DateTime startDate = DateTime.now().add(const Duration(days: 1)).normalize();
  String selectedStartOption = 'tomorrow';
  final TreatmentManager treatmentManager = TreatmentManager();

  @override
  void initState() {
    super.initState();
    durationController = TextEditingController(text: selectedDuration.toString());
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
              child: CustomTextField(
                controller: durationController,
                hintText: 'Duration',
                keyboardType: TextInputType.number,
                isNumberField: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () async {
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
          ],
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
                int durationInDays;
                switch (selectedDurationUnit) {
                  case 'days':
                    durationInDays = selectedDuration;
                    break;
                  case 'weeks':
                    durationInDays = selectedDuration * 7;
                    break;
                  case 'months':
                    durationInDays = selectedDuration * 30; // Approximate
                    break;
                  default:
                    durationInDays = selectedDuration;
                }

                widget.treatment.treatmentPlan.startDate = startDate;
                widget.treatment.treatmentPlan.endDate =
                    startDate.add(Duration(days: durationInDays - 1)).normalize();

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
                  endDate: startDate.add(Duration(days: durationInDays - 1)).normalize(),
                  mealOption: widget.treatment.treatmentPlan.mealOption,
                  instructions: widget.treatment.treatmentPlan.instructions,
                  frequency: widget.treatment.treatmentPlan.frequency,
                  selectedDays: selectedDays,
                );
                
                // Preserve the time from the original treatment
                updatedTreatment.treatmentPlan.timeOfDay = widget.treatment.treatmentPlan.timeOfDay;
                
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
                  devPrint("Reloading logs for treatment range: $startDate to ${startDate.add(Duration(days: durationInDays - 1))}");
                  
                  // Reload all dates in the range (limited to reasonable range to avoid performance issues)
                  DateTime currentDate = startDate;
                  int daysLoaded = 0;
                  while (daysLoaded < durationInDays && daysLoaded < 365) { // Limit to 1 year for performance
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
                    await notificationService.showUntakenMedicationNotifications(todayMeds, forceReschedule: true);
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
