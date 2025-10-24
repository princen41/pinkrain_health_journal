import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/util/helpers.dart';
import '../../../core/widgets/index.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/colors.dart';
import '../domain/treatment_manager.dart';

class NewTreatmentScreen extends StatefulWidget {
  const NewTreatmentScreen({super.key});

  @override
  NewTreatmentScreenState createState() => NewTreatmentScreenState();
}

class NewTreatmentScreenState extends State<NewTreatmentScreen> {
  final TreatmentManager treatmentManager = TreatmentManager();

  String selectedTreatmentType = 'Tablets';
  String selectedColor = 'White';
  String? selectedSecondaryColor;
  String selectedMealOption = 'Before meal';
  String selectedDoseUnit = 'mg';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  // Validation state
  bool showNameError = false;
  bool showDoseError = false;

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
          quantityController: doseController,
          selectedUnit: selectedDoseUnit,
          onUnitChanged: (value) => setState(() => selectedDoseUnit = value!),
          units: ['mg', 'g', 'ml'], // Treatment screens don't need 'pills'
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
                  String colorDescription = selectedColor;
                  if (selectedTreatmentType == 'Capsule' && selectedSecondaryColor != null) {
                    colorDescription = '$selectedColor & $selectedSecondaryColor';
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
      setState(() => showNameError = true);
      isValid = false;
    } else {
      setState(() => showNameError = false);
    }

    if (doseController.text.isEmpty) {
      setState(() => showDoseError = true);
      isValid = false;
    } else {
      try {
        double.parse(doseController.text);
        setState(() => showDoseError = false);
      } catch (e) {
        setState(() => showDoseError = true);
        isValid = false;
      }
    }

    return isValid;
  }
}
