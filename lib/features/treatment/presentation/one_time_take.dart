
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:pinkrain/core/models/medicine_model.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/core/widgets/index.dart';
import 'package:pinkrain/core/theme/tokens.dart';
import 'package:pinkrain/features/treatment/data/treatment.dart';
import 'package:pinkrain/features/treatment/domain/treatment_manager.dart';

class OneTimeTakeScreen extends StatefulWidget {
  const OneTimeTakeScreen({super.key});

  @override
  State<OneTimeTakeScreen> createState() => _OneTimeTakeScreenState();
}

class _OneTimeTakeScreenState extends State<OneTimeTakeScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  String selectedType = 'Tablet';
  String selectedColor = 'White';
  String selectedUnit = 'mg';

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    super.dispose();
  }

  Future<void> _saveOneTimeMedication() async {
    if (nameController.text.isEmpty || dosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final medicine = Medicine(
      name: nameController.text,
      type: selectedType,
      color: selectedColor,
    );

    final dosage = double.tryParse(dosageController.text) ?? 1.0;
    medicine.addSpecification(
      Specification(
        dosage: dosage,
        unit: selectedUnit,
      ),
    );

    // Create a treatment plan for today only
    final now = DateTime.now();
    final today = now.normalize(); // Get today's date at midnight
    
    final treatmentPlan = TreatmentPlan(
      startDate: today, // Use normalized today's date
      endDate: today,   // Use normalized today's date  
      timeOfDay: now,   // Keep current time for display
      frequency: const Duration(days: 1),
    );

    final treatment = Treatment(
      medicine: medicine,
      treatmentPlan: treatmentPlan,
    );

    // Save the one-time treatment
    final treatmentManager = TreatmentManager();
    await treatmentManager.saveTreatment(treatment);

     if (mounted) {
       Navigator.of(context).pop(); // Go back to journal screen
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Medication added successfully')),
       );
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('One-time Medication'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dosageController,
                    keyboardType: Platform.isIOS 
                        ? TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: selectedUnit,
                    items: ['mg', 'ml', 'g']
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedUnit = value);
                      }
                    },
                    underline: const SizedBox(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FormFieldLabel(text: 'Type'),
            ChipSelector(
              options: ['Tablet', 'Capsule', 'Drops', 'Cream', 'Spray', 'Injection'],
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
                    ),
                    child: futureBuildSvg(type, selectedColor, 40),
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
            const SizedBox(height: 20),
            ColorPicker(
              selectedColor: selectedColor,
              onChanged: (color) => setState(() => selectedColor = color),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveOneTimeMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Add Medication'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
