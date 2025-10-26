import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/core/widgets/index.dart';
import 'package:pinkrain/core/theme/tokens.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/theme/icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/hive_service.dart';
import '../../../features/journal/presentation/journal_notifier.dart';
import '../data/treatment.dart';
import '../domain/treatment_manager.dart';

class EditTreatmentScreen extends ConsumerStatefulWidget {
  final Treatment treatment;
  const EditTreatmentScreen({super.key, required this.treatment});

  @override
  ConsumerState<EditTreatmentScreen> createState() => EditTreatmentScreenState();
}

class EditTreatmentScreenState extends ConsumerState<EditTreatmentScreen> {
  final TreatmentManager treatmentManager = TreatmentManager();

  late TextEditingController nameController;
  late TextEditingController doseController;
  late TextEditingController commentController;
  late TextEditingController durationController;
  late String selectedTreatmentType;
  late String selectedColor;
  late String? selectedSecondaryColor;
  late String selectedMealOption;
  late String selectedDoseUnit;
  
  // Schedule and duration state
  late Map<String, String> doseTimes;
  late Map<String, TextEditingController> doseControllers;
  late String selectedReminder;
  late List<bool> selectedDays;
  late int selectedDuration;
  late String selectedDurationUnit;
  late DateTime startDate;
  late String selectedStartOption;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.treatment.medicine.name);
    doseController = TextEditingController(text: widget.treatment.medicine.specs.dosage.toString());
    commentController = TextEditingController(text: widget.treatment.notes);
    final durationDays = widget.treatment.treatmentPlan.endDate.difference(widget.treatment.treatmentPlan.startDate).inDays + 1;
    selectedDuration = durationDays;
    durationController = TextEditingController(text: durationDays.toString());
    durationController.addListener(() {
      final intValue = int.tryParse(durationController.text);
      if (intValue != null && intValue > 0) {
        selectedDuration = intValue;
      }
    });
    selectedTreatmentType = widget.treatment.medicine.type;
    
    // Parse bicolore colors from stored color string
    String colorString = widget.treatment.medicine.color;
    if (selectedTreatmentType == 'Capsule' && colorString.contains('&')) {
      final parts = colorString.split('&');
      if (parts.length == 2) {
        selectedColor = parts[0].trim();
        selectedSecondaryColor = parts[1].trim();
      } else {
        selectedColor = colorString;
        selectedSecondaryColor = null;
      }
    } else {
      selectedColor = colorString;
      selectedSecondaryColor = null;
    }
    selectedMealOption = widget.treatment.treatmentPlan.mealOption;
    selectedDoseUnit = widget.treatment.medicine.specs.unit;
    
    // Initialize schedule and duration
    doseTimes = {'Dose 1': widget.treatment.formattedTimeOfDay()};
    doseControllers = {'Dose 1': TextEditingController(text: 'Dose 1')};
    selectedReminder = 'at time of event';
    selectedDays = List.from(widget.treatment.treatmentPlan.selectedDays);
    selectedDurationUnit = 'days';
    startDate = widget.treatment.treatmentPlan.startDate;
    selectedStartOption = 'Select specific date';
  }

  @override
  void dispose() {
    nameController.dispose();
    doseController.dispose();
    commentController.dispose();
    durationController.dispose();
    // Dispose all dose controllers
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
              icon: HugeIcons.strokeRoundedCancel01,
              color: AppTokens.textPrimary,
              size: 28,
            ),
          ),
        ),
        middle: Text(
          'Edit Treatment',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTreatmentTypeOptions(),
                  const SizedBox(height: 30),
                  _buildColorOptions(),
                  const SizedBox(height: 30),
                  _buildNameField(),
                  const SizedBox(height: 30),
                  _buildDoseField(),
                  const SizedBox(height: 30),
                  _buildMealOptions(),
                  const SizedBox(height: 30),
                  _buildScheduleSection(),
                  const SizedBox(height: 30),
                  _buildDurationSection(),
                  const SizedBox(height: 30),
                  _buildCommentField(),
                  const SizedBox(height: 60),
                  _buildSaveButton(),
                  const SizedBox(height: 20),
                  _buildDeleteButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentTypeOptions() {
    List<String> types = ['Tablet', 'Capsule', 'Drops', 'Cream', 'Spray', 'Injection'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Treatment Type'),
        ChipSelector(
          options: types,
          selectedValue: selectedTreatmentType,
          onChanged: (type) => setState(() => selectedTreatmentType = type),
          itemBuilder: (type, isSelected) => Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppTokens.buttonPrimaryBg
                      : AppTokens.buttonSecondaryBg,
                ),
                child: _futureBuildSvg(type),
              ),
              const SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Outfit',
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected
                      ? AppTokens.textPrimary
                      : AppTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorOptions() {
    return ColorPicker(
      selectedColor: selectedColor,
      selectedSecondaryColor: selectedSecondaryColor,
      onChanged: (color) => setState(() => selectedColor = color),
      onSecondaryChanged: (color) => setState(() => selectedSecondaryColor = color),
      isDuotone: selectedTreatmentType == 'Capsule',
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Name'),
        CustomTextField(
          controller: nameController,
          hintText: 'Enter medicine name',
        ),
      ],
    );
  }

  Widget _buildDoseField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Dose'),
        QuantityUnitRow(
          quantityController: doseController,
          selectedUnit: selectedDoseUnit,
          onUnitChanged: (value) => setState(() => selectedDoseUnit = value!),
          units: ['mg', 'g', 'ml'], // Treatment screens don't need 'pills'
        ),
      ],
    );
  }

  Widget _buildMealOptions() {
    List<String> options = [
      'Before meal',
      'After meal',
      'With food',
      'Never mind'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: options.map((option) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onTap: () => setState(() => selectedMealOption = option),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedMealOption == option
                            ? AppTokens.buttonPrimaryBg
                            : AppTokens.buttonSecondaryBg,
                      ),
                      child: _futureBuildSvg(option.toLowerCase().replaceAll(' ', '-')),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Outfit',
                        fontWeight: selectedMealOption == option
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selectedMealOption == option
                            ? AppTokens.textPrimary
                            : AppTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Comments'),
        CustomTextField(
          controller: commentController,
          hintText: 'Write your comment here',
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: Button.primary(
        onPressed: () async {
          if (_validateInput()) {
            try {
              // Create color description for bicolore capsules
              String colorDescription = selectedColor;
              if (selectedTreatmentType == 'Capsule' && selectedSecondaryColor != null) {
                colorDescription = '$selectedColor & $selectedSecondaryColor';
              }

              // Create updated medicine
              final updatedMedicine = Medicine(
                name: nameController.text,
                type: selectedTreatmentType,
                color: colorDescription,
              )..addSpecification(
                  Specification(
                    dosage: double.tryParse(doseController.text) ?? widget.treatment.medicine.specs.dosage,
                    unit: selectedDoseUnit,
                    useCase: widget.treatment.medicine.specs.useCase,
                  ),
                );

              // Parse the first dose time for timeOfDay
              String firstDoseTime = doseTimes.values.first;
              List<String> timeParts = firstDoseTime.split(':');
              int hour = int.tryParse(timeParts[0]) ?? 10;
              int minute = int.tryParse(timeParts[1]) ?? 0;
              DateTime timeOfDay = DateTime(2024, 1, 1, hour, minute);

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

              // Create updated treatment plan with schedule and duration data
              final updatedTreatmentPlan = TreatmentPlan(
                startDate: startDate,
                endDate: startDate.add(Duration(days: durationInDays - 1)).normalize(),
                timeOfDay: timeOfDay,
                mealOption: selectedMealOption,
                instructions: widget.treatment.treatmentPlan.instructions,
                frequency: widget.treatment.treatmentPlan.frequency,
                selectedDays: selectedDays,
              );

              // Create updated treatment
              final updatedTreatment = Treatment(
                id: widget.treatment.id.isEmpty ? generateUniqueId() : widget.treatment.id, // Ensure ID is never empty
                medicine: updatedMedicine,
                treatmentPlan: updatedTreatmentPlan,
                notes: commentController.text,
              );

              // Debug info
              devPrint("Updating treatment - ID: ${widget.treatment.id}, Name: ${widget.treatment.medicine.name} → ${updatedTreatment.medicine.name}");
              devPrint("Treatment ID being used: ${updatedTreatment.id}");
              devPrint("Original dose: ${widget.treatment.medicine.specs.dosage} → New dose: ${updatedTreatment.medicine.specs.dosage}");
              devPrint("Selected Days: $selectedDays");
              devPrint("Days: [M, Tu, W, Th, F, Sa, Su]");
              for (int i = 0; i < selectedDays.length; i++) {
                devPrint("Day $i (${['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'][i]}): ${selectedDays[i]}");
              }
              // Update treatment in database
              await treatmentManager.updateTreatment(widget.treatment, updatedTreatment);

              // Directly clear ALL medication data caches to ensure refresh
              if (mounted) {
                try {
                  // Get the JournalLog instance from the pillIntakeProvider
                  final journalLog = ref.read(pillIntakeProvider.notifier).journalLog;

                  // Directly clear all cached medication logs
                  journalLog.clearAllCachedMedicationLogs();

                  // Force reload ALL dates in the treatment range
                  final startDate = updatedTreatment.treatmentPlan.startDate;
                  final endDate = updatedTreatment.treatmentPlan.endDate;
                  
                  devPrint("Reloading logs for treatment range: $startDate to $endDate");
                  
                  // Reload all dates in the range (limited to reasonable range to avoid performance issues)
                  DateTime currentDate = startDate;
                  int daysLoaded = 0;
                  while (!currentDate.isAfter(endDate) && daysLoaded < 365) { // Limit to 1 year for performance
                    await journalLog.forceReloadMedicationLogs(currentDate);
                    await journalLog.saveMedicationLogs(currentDate);
                    currentDate = currentDate.add(const Duration(days: 1));
                    daysLoaded++;
                  }
                  
                  devPrint("Reloaded $daysLoaded days in treatment range");

                  // Get the currently selected date from the provider
                  final selectedDate = ref.read(selectedDateProvider);

                  devPrint("All medication caches cleared!");

                  // Force rebuild of UI state with the refreshed data
                  await ref.read(pillIntakeProvider.notifier).forceReloadMedicationData(selectedDate);

                  // Force UI rebuild through provider invalidation
                  ref.invalidate(pillIntakeProvider);
                  ref.invalidate(selectedDateProvider);

                  devPrint("All providers invalidated for complete UI refresh");
                } catch (e) {
                  devPrint("Error during complete refresh: $e");
                }

                // Show success message and pop
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Treatment updated successfully')),
                  );

                  // Return to previous screen
                  Navigator.of(context).pop(true);
                }
              }
            } catch (e) {
              // Show error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating treatment: $e')),
                );
              }
            }
          }
        },
        text: 'Save Changes',
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildDeleteOption(
    BuildContext context,
    String title,
    String description,
    String option,
  ) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTokens.bgMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTokens.textStyleMedium.copyWith(
                color: AppTokens.stateError,
              ),
            ),
            Text(
              description,
              style: AppTokens.textStyleSmall.copyWith(
                color: AppTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: Button.destructive(
        onPressed: () async {
          // Show confirmation bottom modal
          final String? deleteOption = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppTokens.bgPrimary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTokens.borderLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Title
                        Text(
                          'Delete Treatment',
                          style: AppTokens.textStyleXLarge,
                        ),
                        const SizedBox(height: 4),
                        // Message
                        Text(
                          'Deleting a treatment is a permanent action and cannot be undone.',
                          style: AppTokens.textStyleMedium.copyWith(
                            color: AppTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Delete options
                        Column(
                          children: [
                            _buildDeleteOption(
                              context,
                              'Just this occurrence',
                              'Remove "${widget.treatment.medicine.name}" only for this date',
                              'just_today',
                            ),
                            const SizedBox(height: 12),
                            _buildDeleteOption(
                              context,
                              'From this date onwards',
                              'Stop "${widget.treatment.medicine.name}" starting from this date',
                              'from_today',
                            ),
                            const SizedBox(height: 12),
                            _buildDeleteOption(
                              context,
                              'All occurrences',
                              'Permanently delete "${widget.treatment.medicine.name}"',
                              'all',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Cancel button
                        SizedBox(
                          width: double.infinity,
                          child: Button.secondary(
                            onPressed: () => Navigator.of(context).pop(),
                            text: 'Cancel',
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            borderWidth: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );

          if (deleteOption != null && deleteOption.isNotEmpty) {
            try {
              final journalLog = ref.read(pillIntakeProvider.notifier).journalLog;
              final selectedDate = ref.read(selectedDateProvider);
              
              if (deleteOption == 'just_today') {
                // Remove the log entry for this treatment on the selected date
                final existingLogs = await HiveService.getMedicationLogsForDate(selectedDate);
                if (existingLogs != null && existingLogs.isNotEmpty) {
                  final updatedLogs = existingLogs.where((log) {
                    final treatmentId = log['treatment_id']?.toString() ?? '';
                    return treatmentId != widget.treatment.id;
                  }).toList();
                  
                  await HiveService.saveMedicationLogsForDate(selectedDate, updatedLogs);
                }
                
                journalLog.clearAllCachedMedicationLogs();
                await journalLog.forceReloadMedicationLogs(selectedDate);
                await ref.read(pillIntakeProvider.notifier).forceReloadMedicationData(selectedDate);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This occurrence deleted')),
                  );
                  Navigator.of(context).pop(); // Close edit screen
                  Navigator.of(context).pop(); // Close treatment overview modal
                }
              } else if (deleteOption == 'from_today') {
                // End the treatment early (set endDate to day before selected date)
                final updatedTreatment = Treatment(
                  id: widget.treatment.id,
                  medicine: widget.treatment.medicine,
                  treatmentPlan: TreatmentPlan(
                    startDate: widget.treatment.treatmentPlan.startDate,
                    endDate: selectedDate.subtract(const Duration(days: 1)).normalize(),
                    timeOfDay: widget.treatment.treatmentPlan.timeOfDay,
                    mealOption: widget.treatment.treatmentPlan.mealOption,
                    instructions: widget.treatment.treatmentPlan.instructions,
                    frequency: widget.treatment.treatmentPlan.frequency,
                    selectedDays: widget.treatment.treatmentPlan.selectedDays,
                  ),
                  notes: widget.treatment.notes,
                );
                await treatmentManager.updateTreatment(widget.treatment, updatedTreatment);
                
                journalLog.clearAllCachedMedicationLogs();
                await journalLog.forceReloadMedicationLogs(selectedDate);
                await ref.read(pillIntakeProvider.notifier).forceReloadMedicationData(selectedDate);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Treatment stopped from selected date')),
                  );
                  Navigator.of(context).pop(); // Close edit screen
                  Navigator.of(context).pop(); // Close treatment overview modal
                }
              } else if (deleteOption == 'all') {
                // Delete treatment completely
                await treatmentManager.deleteTreatment(widget.treatment);

                journalLog.clearAllCachedMedicationLogs();
                await journalLog.forceReloadMedicationLogs(selectedDate);
                await ref.read(pillIntakeProvider.notifier).forceReloadMedicationData(selectedDate);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Treatment deleted successfully')),
                  );
                  Navigator.of(context).pop(); // Close edit screen
                  Navigator.of(context).pop(); // Close treatment overview modal
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          }
        },
        text: 'Delete Treatment',
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  bool _validateInput() {
    String errorMessage = '';

    if (nameController.text.isEmpty) {
      errorMessage += 'Please enter a name for the treatment.\n';
    }

    if (doseController.text.isEmpty) {
      errorMessage += 'Please enter a dose for the treatment.\n';
    } else {
      try {
        double.parse(doseController.text);
      } catch (e) {
        errorMessage += 'Please enter a valid number for the dose.\n';
      }
    }

    if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    }
    return true;
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Schedule'),
        
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

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Days taken'),
        Row(
          children: _buildDayButtons(),
        ),
        const SizedBox(height: 20),
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
        const SizedBox(height: 20),
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

  // Helper function to format date as DD/MM/YYYY
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

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

  FutureBuilder<SvgPicture> _futureBuildSvg(String text) {
    return FutureBuilder<SvgPicture>(
      future: appSvgDynamicImage(
        fileName: text.toLowerCase(),
        size: 30,
        color: colorMap[selectedColor],
        secondaryColor: selectedSecondaryColor != null ? colorMap[selectedSecondaryColor] : null,
        useColorFilter: false
      ),
      builder: (context, snapshot) {
        return snapshot.data ??
            appVectorImage(
              fileName: text.toLowerCase(),
              size: 30,
              color: colorMap[selectedColor],
              useColorFilter: false
            );
      }
    );
  }
}
