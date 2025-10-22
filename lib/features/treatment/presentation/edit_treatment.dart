import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/core/widgets/index.dart';
import 'package:pinkrain/core/theme/tokens.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/theme/icons.dart';
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
  late String selectedTreatmentType;
  late String selectedColor;
  late String? selectedSecondaryColor;
  late String selectedMealOption;
  late String selectedDoseUnit;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.treatment.medicine.name);
    doseController = TextEditingController(text: widget.treatment.medicine.specs.dosage.toString());
    commentController = TextEditingController(text: widget.treatment.notes);
    selectedTreatmentType = widget.treatment.medicine.type;
    selectedColor = widget.treatment.medicine.color;
    selectedSecondaryColor = null; // Initialize as null for now
    selectedMealOption = widget.treatment.treatmentPlan.mealOption;
    selectedDoseUnit = widget.treatment.medicine.specs.unit;
  }

  @override
  void dispose() {
    nameController.dispose();
    doseController.dispose();
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Treatment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _buildCommentField(),
                const SizedBox(height: 30),
                Center(
                  child: _buildSaveButton(),
                ),
                const SizedBox(height: 20),
                Center(
                  child: _buildDeleteButton(),
                ),
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
              // Create updated medicine
              final updatedMedicine = Medicine(
                name: nameController.text,
                type: selectedTreatmentType,
                color: selectedColor, // Store the color name, not the Color object string
              )..addSpecification(
                  Specification(
                    dosage: double.tryParse(doseController.text) ?? widget.treatment.medicine.specs.dosage,
                    unit: selectedDoseUnit,
                    useCase: widget.treatment.medicine.specs.useCase,
                  ),
                );

              // Create updated treatment plan preserving original fields
              final updatedTreatmentPlan = TreatmentPlan(
                startDate: widget.treatment.treatmentPlan.startDate,
                endDate: widget.treatment.treatmentPlan.endDate,
                timeOfDay: widget.treatment.treatmentPlan.timeOfDay,
                mealOption: selectedMealOption,
                instructions: widget.treatment.treatmentPlan.instructions,
                frequency: widget.treatment.treatmentPlan.frequency,
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
              // Update treatment in database
              await treatmentManager.updateTreatment(widget.treatment, updatedTreatment);

              // Directly clear ALL medication data caches to ensure refresh
              if (mounted) {
                try {
                  // Get the JournalLog instance from the pillIntakeProvider
                  final journalLog = ref.read(pillIntakeProvider.notifier).journalLog;

                  // Directly clear all cached medication logs
                  journalLog.clearAllCachedMedicationLogs();

                  // Force reload of today's data
                  final today = DateTime.now().normalize();
                  await journalLog.forceReloadMedicationLogs(today);

                  // Get the currently selected date from the provider
                  final selectedDate = ref.read(selectedDateProvider);

                  // If the selected date is different from today, reload that data too
                  if (selectedDate.day != today.day || 
                      selectedDate.month != today.month || 
                      selectedDate.year != today.year) {
                    devPrint("Also reloading data for selected date: ${selectedDate.toString()}");
                    await journalLog.forceReloadMedicationLogs(selectedDate);
                    await journalLog.saveMedicationLogs(selectedDate);
                  }

                  // Save the updated medication logs to ensure they're persisted
                  await journalLog.saveMedicationLogs(today);

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

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: Button.destructive(
        onPressed: () async {
          // Show confirmation dialog
          final bool? shouldDelete = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Delete Treatment'),
                content: Text(
                  'Are you sure you want to delete "${widget.treatment.medicine.name}"? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );

          if (shouldDelete == true) {
            try {
              // Delete treatment from database
              await treatmentManager.deleteTreatment(widget.treatment);

              // Clear medication data caches to ensure refresh
              if (mounted) {
                // Refresh journal data
                ref.invalidate(pillIntakeProvider);
                
                // Show success message and pop
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Treatment deleted successfully')),
                );

                // Return to previous screen
                Navigator.of(context).pop(true);
              }
            } catch (e) {
              // Show error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting treatment: $e')),
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
