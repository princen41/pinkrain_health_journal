import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/helpers.dart';
import '../../../core/widgets/index.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/colors.dart';
import '../domain/treatment_manager.dart';
import '../../pillbox/presentation/pillbox_notifier.dart';
import '../../../core/models/medicine_model.dart';

class NewTreatmentScreen extends ConsumerStatefulWidget {
  const NewTreatmentScreen({super.key});

  @override
  NewTreatmentScreenState createState() => NewTreatmentScreenState();
}

class NewTreatmentScreenState extends ConsumerState<NewTreatmentScreen> {
  final TreatmentManager treatmentManager = TreatmentManager();

  String selectedTreatmentType = 'Tablets';
  String? selectedColor;
  String? selectedSecondaryColor;
  String selectedMealOption = 'Before meal';
  String selectedDoseUnit = 'mg';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  // Validation state
  String? nameError;
  String? doseError;
  bool hideSuggestions = false;

  @override
  void dispose() {
    nameController.dispose();
    doseController.dispose();
    commentController.dispose();
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
          'New Treatment',
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
                _buildProgressBar(),
                
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
                        _buildMealOptions(),
                        const SizedBox(height: 30),
                        _buildCommentField(),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
                
                // Navigation buttons
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
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
                color: AppTokens.bgMuted,
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
      isDuotone: selectedTreatmentType == 'Capsule',
    );
  }

  Widget _buildNameField() {
    // Watch pillbox to ensure widget rebuilds when pillbox changes
    final pillbox = ref.watch(pillBoxProvider);
    final medicationOptions = pillbox.pillStock
        .map((inventory) => inventory.medicine.name)
        .toSet()
        .toList();
    
    // Filter suggestions based on current text
    final filteredOptions = nameController.text.isEmpty || hideSuggestions
        ? <String>[]
        : medicationOptions
            .where((option) => option.toLowerCase().contains(nameController.text.toLowerCase()))
            .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: 'Name'),
        CustomTextField(
          controller: nameController,
          hintText: 'Enter medicine name',
          errorText: nameError,
          onChanged: () {
            setState(() {
              hideSuggestions = false; // Show suggestions again when user types
              if (nameController.text.isNotEmpty) {
                nameError = null;
              }
            });
          },
        ),
        // Show suggestions dropdown
        if (filteredOptions.isNotEmpty && nameController.text.isNotEmpty && !hideSuggestions) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: filteredOptions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: AppTokens.borderLight,
                indent: 15,
                endIndent: 15,
              ),
              itemBuilder: (BuildContext context, int index) {
                final String option = filteredOptions[index];
                // Find the inventory for this medication
                MedicineInventory? inventory;
                try {
                  inventory = pillbox.pillStock.firstWhere(
                    (item) => item.medicine.name == option,
                  );
                } catch (e) {
                  inventory = null;
                }
                final quantity = inventory?.quantity ?? 0;
                
                return InkWell(
                  onTap: () {
                    nameController.text = option;
                    
                    // Find the medication in pillbox to get type and color
                    MedicineInventory? inventory;
                    try {
                      inventory = pillbox.pillStock.firstWhere(
                        (item) => item.medicine.name == option,
                      );
                    } catch (e) {
                      inventory = null;
                    }
                    
                    if (inventory != null) {
                      final medicine = inventory.medicine;
                      
                      // Medicine.type already contains the treatment type (Tablet, Capsule, etc.)
                      String treatmentType = medicine.type;
                      
                      // Validate treatment type is in the allowed list
                      final allowedTypes = ['Tablet', 'Capsule', 'Drops', 'Cream', 'Spray', 'Injection'];
                      if (!allowedTypes.contains(treatmentType)) {
                        treatmentType = 'Tablet'; // Default fallback
                      }
                      
                      // Parse color - handle "Color1 & Color2" format for capsules
                      String primaryColor = medicine.color;
                      String? secondaryColor;
                      
                      if (treatmentType == 'Capsule' && primaryColor.contains('&')) {
                        final parts = primaryColor.split('&');
                        if (parts.length == 2) {
                          primaryColor = parts[0].trim();
                          secondaryColor = parts[1].trim();
                        }
                      }
                      
                      setState(() {
                        selectedTreatmentType = treatmentType;
                        selectedColor = primaryColor;
                        selectedSecondaryColor = secondaryColor;
                        hideSuggestions = true; // Hide dropdown after selection
                        nameError = null;
                      });
                    } else {
                      setState(() {
                        hideSuggestions = true;
                        nameError = null;
                      });
                    }
                    
                    // Unfocus to dismiss keyboard
                    FocusScope.of(context).unfocus();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: AppTokens.textStyleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$quantity left',
                          style: AppTokens.textStyleSmall.copyWith(
                            color: AppTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
          quantityController: doseController,
          selectedUnit: selectedDoseUnit,
          onUnitChanged: (value) => setState(() => selectedDoseUnit = value!),
          quantityError: doseError,
          onQuantityChanged: () {
            if (doseController.text.isNotEmpty) {
              setState(() {
                doseError = null;
              });
            }
          },
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
                      child: futureBuildSvg(option.toLowerCase().replaceAll(' ', '-'), selectedColor, 40, selectedSecondaryColor),
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

  Widget _buildContinueButton() {
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
              text: 'Cancel',
              size: ButtonSize.large,
              borderWidth: 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Button.primary(
              onPressed: () {
                if (_validateInput()) {
                  // Generate a unique ID for this new treatment
                  final uniqueId = generateUniqueId();
                  devPrint("Creating new treatment with generated ID: $uniqueId");

                  // Create color description for bicolore capsules
                  String colorDescription = selectedColor ?? 'White';
                  if (selectedTreatmentType == 'Capsule' && selectedSecondaryColor != null) {
                    colorDescription = '${selectedColor ?? 'White'} & $selectedSecondaryColor';
                  }

                  final treatment = Treatment.newTreatment(
                    id: uniqueId, // Explicitly pass the generated ID
                    name: nameController.text,
                    type: selectedTreatmentType,
                    color: colorDescription,
                    dose: double.parse(doseController.text),
                    unit: selectedDoseUnit,
                    mealOption: selectedMealOption,
                    instructions: commentController.text.isNotEmpty ? commentController.text : '',
                  );
                  context.push('/schedule', extra: treatment);
                }
              },
              text: 'Continue',
              size: ButtonSize.large,
            ),
          ),
        ],
      ),
    ),
    );
  }

  bool _validateInput() {
    bool isValid = true;

    if (nameController.text.isEmpty) {
      setState(() => nameError = 'Medicine name is required');
      isValid = false;
    } else {
      setState(() => nameError = null);
    }

    if (doseController.text.isEmpty) {
      setState(() => doseError = 'Dosage amount is required');
      isValid = false;
    } else {
      try {
        double.parse(doseController.text);
        setState(() => doseError = null);
      } catch (e) {
        setState(() => doseError = 'Dosage amount is required');
        isValid = false;
      }
    }

    return isValid;
  }
}