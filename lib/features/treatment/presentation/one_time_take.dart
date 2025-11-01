import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pinkrain/core/models/medicine_model.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/core/widgets/index.dart';
import 'package:pinkrain/core/theme/tokens.dart';
import 'package:pinkrain/features/treatment/data/treatment.dart';
import 'package:pinkrain/features/treatment/domain/treatment_manager.dart';
import 'package:pinkrain/features/journal/presentation/journal_notifier.dart';
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/features/treatment/services/medication_notification_service.dart';

class OneTimeTakeScreen extends ConsumerStatefulWidget {
  const OneTimeTakeScreen({super.key});

  @override
  ConsumerState<OneTimeTakeScreen> createState() => _OneTimeTakeScreenState();
}

class _OneTimeTakeScreenState extends ConsumerState<OneTimeTakeScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  String selectedType = 'Tablet';
  String selectedColor = 'White';
  String? selectedSecondaryColor;
  String selectedUnit = 'mg';
  
  // Validation state
  bool showNameError = false;
  bool showDoseError = false;
  
  // Take now functionality
  bool takeNow = true;
  DateTime? selectedTakeTime;

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> _saveOneTimeMedication() async {
    // Create color description for bicolore capsules
    String colorDescription = selectedColor;
    if (selectedType == 'Capsule' && selectedSecondaryColor != null) {
      colorDescription = '$selectedColor & $selectedSecondaryColor';
    }

    final medicine = Medicine(
      name: nameController.text,
      type: selectedType,
      color: colorDescription,
    );

    final dosage = double.tryParse(dosageController.text) ?? 1.0;
    medicine.addSpecification(
      Specification(
        dosage: dosage,
        unit: selectedUnit,
      ),
    );

    // Create a treatment plan for today only
    // Use selected take time or current time
    final takeTime = takeNow ? DateTime.now() : (selectedTakeTime ?? DateTime.now());
    final takeDate = takeTime.normalize(); // Get the date at midnight

    // Create selectedDays array for the specific day of the week
    // DateTime.weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
    // selectedDays: 0=Monday, 1=Tuesday, ..., 6=Sunday
    final dayIndex = (takeTime.weekday - 1) % 7;
    final selectedDays = List<bool>.filled(7, false);
    selectedDays[dayIndex] = true;

    final treatmentPlan = TreatmentPlan(
      startDate: takeDate, // Use selected take date
      endDate: takeDate, // Use selected take date
      timeOfDay: takeTime, // Use selected take time
      frequency: const Duration(days: 1),
      selectedDays: selectedDays, // Only the specific day of the week
    );

    final treatment = Treatment(
      medicine: medicine,
      treatmentPlan: treatmentPlan,
      notes: commentController.text,
    );

    // Debug info
    devPrint("=== ONE-TIME TREATMENT DEBUG ===");
    devPrint("Treatment ID: ${treatment.id}");
    devPrint("Medicine: ${treatment.medicine.name}");
    devPrint("Take Date: $takeDate");
    devPrint("Take Time: $takeTime");
    devPrint("Start Date: ${treatmentPlan.startDate}");
    devPrint("End Date: ${treatmentPlan.endDate}");
    devPrint("Selected Days: $selectedDays");
    devPrint("Should take on date: ${treatmentPlan.shouldTakeOnDate(takeDate)}");

    // Save the one-time treatment
    final treatmentManager = TreatmentManager();
    await treatmentManager.saveTreatment(treatment);
    devPrint("Treatment saved successfully");
    
    // CRITICAL: Reload treatments to ensure the new treatment is in memory
    await treatmentManager.loadTreatments();
    devPrint("Treatments reloaded, total count: ${treatmentManager.treatments.length}");
    final foundTreatment = treatmentManager.treatments.firstWhere(
      (t) => t.id == treatment.id,
      orElse: () => throw Exception("New treatment not found after reload"),
    );
    devPrint("Found new treatment in memory: ${foundTreatment.medicine.name}");
    
    // DEBUG: Let's also check what treatments are actually in storage
    final allTreatments = await HiveService.getTreatments();
    devPrint("Total treatments in storage: ${allTreatments.length}");
    try {
      final storageTreatment = allTreatments.firstWhere(
        (t) => t['id'] == treatment.id,
      );
      devPrint("Found new treatment in storage: ${storageTreatment['medicine']['name']}");
    } catch (e) {
      devPrint("ERROR: New treatment NOT found in storage!");
    }

    if (mounted) {
      // EXACT SAME AS DURATION SCREEN
      // Clear all cached medication logs to ensure new treatment appears on all relevant dates
      final pillIntakeNotifier = ref.read(pillIntakeProvider.notifier);
      pillIntakeNotifier.journalLog.clearAllCachedMedicationLogs();
      
      // Refresh the journal data for the take date (not selected date!)
      await pillIntakeNotifier.populateJournal(takeDate, forceReload: true);
      devPrint("=== JOURNAL STATE AFTER REFRESH ===");
      final journalState = ref.read(pillIntakeProvider);
      devPrint("Total medications in journal for $takeDate: ${journalState.length}");
      for (final log in journalState) {
        devPrint("  - ${log.treatment.medicine.name} (ID: ${log.treatment.id}) at ${log.treatment.treatmentPlan.timeOfDay.hour}:${log.treatment.treatmentPlan.timeOfDay.minute}");
      }

      // Immediately schedule notifications for today's untaken medications
      try {
        final notificationService = MedicationNotificationService();
        await notificationService.initialize();
        
        // CRITICAL FIX: Clear notification tracking before rescheduling
        notificationService.clearAllNotificationTracking();
        
        final todayMeds = await pillIntakeNotifier.journalLog.getMedicationsForTheDay(DateTime.now());
        await notificationService.showUntakenMedicationNotifications(
          todayMeds,
          forceReschedule: true,
          showImmediateNotifications: false, // Don't show immediate notifications when just rescheduling
        );
        devPrint('📅 Triggered scheduling after saving one-time treatment');
      } catch (e) {
        devPrint('❌ Failed to schedule notifications after one-time treatment save: $e');
      }
      
      if (mounted && context.mounted) {
        context.go('/journal');
      }
    }
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
          'One-time Take',
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
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildNameField(),
                        const SizedBox(height: 30),
                        _buildTreatmentTypeOptions(),
                        const SizedBox(height: 30),
                        _buildColorOptions(),
                        const SizedBox(height: 30),
                        _buildDoseField(),
                        const SizedBox(height: 30),
                        _buildCommentField(),
                        const SizedBox(height: 30),
                        _buildTakeNowSection(),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
                
                // Bottom button
                _buildAddButton(),
              ],
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
          selectedValue: selectedType,
          onChanged: (type) => setState(() => selectedType = type),
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
                  border: isSelected
                      ? Border.all(
                          color: AppTokens.textPrimary.withValues(alpha: 0.1),
                          width: 2,
                        )
                      : null,
                ),
                child: futureBuildSvg(type, selectedColor, 40, selectedSecondaryColor),
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
      isDuotone: selectedType == 'Capsule',
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
        if (showNameError) ...[
          const SizedBox(height: 8),
          Text(
            'Medicine name is required',
            style: AppTokens.textStyleSmall.copyWith(
              color: AppTokens.stateError,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDoseField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Dose'),
        QuantityUnitRow(
          quantityController: dosageController,
          selectedUnit: selectedUnit,
          onUnitChanged: (value) => setState(() => selectedUnit = value!),
          units: ['mg', 'g', 'ml'],
        ),
        if (showDoseError) ...[
          const SizedBox(height: 8),
          Text(
            'Dosage amount is required',
            style: AppTokens.textStyleSmall.copyWith(
              color: AppTokens.stateError,
            ),
          ),
        ],
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

  Widget _buildTakeNowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'When did you take this?'),
        const SizedBox(height: 16),
        
        // Radio button options
        Column(
          children: [
            // Take now option
            GestureDetector(
              onTap: () {
                setState(() {
                  takeNow = true;
                });
              },
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: takeNow ? AppTokens.buttonPrimaryBg : AppTokens.borderLight,
                          width: 2,
                        ),
                        color: takeNow ? AppTokens.buttonPrimaryBg : Colors.transparent,
                      ),
                      child: takeNow
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Take now',
                    style: AppTokens.textStyleMedium.copyWith(
                      color: AppTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Select another time option
            GestureDetector(
              onTap: () {
                setState(() {
                  takeNow = false;
                  selectedTakeTime ??= DateTime.now();
                });
              },
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: !takeNow ? AppTokens.buttonPrimaryBg : AppTokens.borderLight,
                          width: 2,
                        ),
                        color: !takeNow ? AppTokens.buttonPrimaryBg : Colors.transparent,
                      ),
                      child: !takeNow
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select another time',
                    style: AppTokens.textStyleMedium.copyWith(
                      color: AppTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Date/time picker (shown when takeNow is false)
        if (!takeNow) ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _showDateTimePicker,
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
                    selectedTakeTime != null 
                        ? _formatDateTime(selectedTakeTime!)
                        : 'Select date and time',
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
      ],
    );
  }

  Future<void> _showDateTimePicker() async {
    final now = DateTime.now();
    final initialDateTime = selectedTakeTime ?? now;
    
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: AppTokens.bgPrimary,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            initialDateTime: initialDateTime,
            maximumDate: now,
            onDateTimeChanged: (DateTime newDateTime) {
              // Update the selected time
              setState(() {
                selectedTakeTime = newDateTime;
              });
            },
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateTimeDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateText;
    if (dateTimeDate == today) {
      dateText = 'Today';
    } else if (dateTimeDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    final timeText = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateText at $timeText';
  }

  Widget _buildAddButton() {
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
        child: SizedBox(
          width: double.infinity,
          child: Button.primary(
            onPressed: () {
              if (_validateInput()) {
                _saveOneTimeMedication();
              }
            },
            text: 'Add Medication',
            size: ButtonSize.large,
          ),
        ),
      ),
    );
  }

  bool _validateInput() {
    bool isValid = true;

    if (nameController.text.isEmpty) {
      setState(() => showNameError = true);
      isValid = false;
    } else {
      setState(() => showNameError = false);
    }

    if (dosageController.text.isEmpty) {
      setState(() => showDoseError = true);
      isValid = false;
    } else {
      try {
        double.parse(dosageController.text);
        setState(() => showDoseError = false);
      } catch (e) {
        setState(() => showDoseError = true);
        isValid = false;
      }
    }

    return isValid;
  }
}
