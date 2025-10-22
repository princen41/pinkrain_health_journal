import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/util/helpers.dart';
import '../../../core/widgets/index.dart';
import '../../../core/theme/tokens.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('New treatment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProgressBar(),
                  SizedBox(height: 20),
                  _buildTreatmentTypeOptions(),
                  SizedBox(height: 30),
                  _buildColorOptions(),
                  SizedBox(height: 30),
                  _buildNameField(),
                  SizedBox(height: 30),
                  _buildDoseField(),
                  SizedBox(height: 30),
                  _buildMealOptions(),
                  SizedBox(height: 30),
                  _buildCommentField(),
                  SizedBox(height: 30),
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Expanded(child: Container(height: 4, color: Colors.pink[100])),
        Expanded(child: Container(height: 4, color: Colors.grey[300])),
        Expanded(child: Container(height: 4, color: Colors.grey[300])),
      ],
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_validateInput()) {
            // Generate a unique ID for this new treatment
            final uniqueId = generateUniqueId();
            devPrint("Creating new treatment with generated ID: $uniqueId");

            final treatment = Treatment.newTreatment(
              id: uniqueId, // Explicitly pass the generated ID
              name: nameController.text,
              type: selectedTreatmentType,
              color: colorMap[selectedColor]?.toString() ?? Colors.white.toString(),
              dose: double.parse(doseController.text),
              unit: selectedDoseUnit,
              mealOption: selectedMealOption,
              instructions: commentController.text.isNotEmpty ? commentController.text : '',
            );
            context.push('/schedule', extra: treatment);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFFD0FF),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text('Continue', style: TextStyle(color: Colors.black)),
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
}
