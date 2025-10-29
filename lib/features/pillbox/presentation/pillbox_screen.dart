import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pinkrain/features/pillbox/data/pillbox_model.dart';
import 'package:pinkrain/features/pillbox/presentation/pillbox_notifier.dart';
import 'package:pinkrain/features/treatment/data/treatment.dart';
import 'package:pinkrain/features/treatment/domain/treatment_manager.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/theme/icons.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/helpers.dart';
import '../../../core/widgets/index.dart';

class PillboxScreen extends ConsumerStatefulWidget {
  const PillboxScreen({super.key});

  @override
  ConsumerState<PillboxScreen> createState() => _PillboxScreenState();
}

class _PillboxScreenState extends ConsumerState<PillboxScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PillBoxManager.init(ref);

    return Scaffold(
      //backgroundColor: AppTokens.bgMuted,
      backgroundColor: Colors.white,
      appBar: buildAppBar('Pill Box'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicineDialog(context, ref),
        backgroundColor: AppTokens.bgPrimary,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          size: 24,
          strokeWidth: 1,
          color: AppTokens.iconPrimary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text fields
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
            // Search Bar
            CustomTextField(
              controller: _searchController,
              hintText: 'Find medication',
              prefixIcon: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 24,
                  strokeWidth: 1,
                  color: AppTokens.textPlaceholder,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? Center(
                      child: GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                          FocusScope.of(context).unfocus();
                        },
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 20,
                          strokeWidth: 1,
                          color: AppTokens.textPlaceholder,
                        ),
                      ),
                    )
                  : null,
              onChanged: () {
                // Update UI when search text changes
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            // Medication Cards - Using GridView with custom aspect ratio or empty state
            Expanded(
              child: _buildMedicationContent(ref, context),
            ),
          ],
        ),
        ),
      ),
      bottomNavigationBar:
      buildBottomNavigationBar(context: context, currentRoute: 'pillbox'),
    );
  }

  // Calculate aspect ratio based on content requirements
  double _calculateCardAspectRatio(BuildContext context) {
    // Base this on your content requirements:
    // - SVG icon: 60px
    // - Spacing: 10px
    // - Medicine name: ~24px (font size 18 + line height)
    // - Medicine type: ~20px (font size 16 + line height)
    // - Spacing from Spacer: variable
    // - Quantity: ~25px (font size 20 + line height)
    // - "pills left": ~20px (font size 16 + line height)
    // - Padding: 32px (16px top + 16px bottom)

    // Estimated content height: 60 + 10 + 24 + 20 + 25 + 20 + 32 = ~191px
    // Add some buffer for spacing: ~210px

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 50) / 2; // Account for padding and spacing
    final desiredCardHeight = 230.0;

    return cardWidth / desiredCardHeight;
  }

  // Build Medication Content (cards or empty state)
  Widget _buildMedicationContent(WidgetRef ref, BuildContext context) {
    final IPillBox pillBox = ref.watch(pillBoxProvider);
    final searchQuery = _searchController.text;

    // Filter medications based on search query
    final filteredStock = searchQuery.isEmpty
        ? pillBox.pillStock
        : pillBox.pillStock.where((inventory) {
            final medicineName = inventory.medicine.name.toLowerCase();
            final query = searchQuery.toLowerCase();
            return medicineName.contains(query);
          }).toList();

    // Show empty state if no medications found
    if (filteredStock.isEmpty) {
      return _buildEmptyState(searchQuery.isNotEmpty);
    }

    // Show medication cards
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: _calculateCardAspectRatio(context),
      children: _buildMedicationCards(ref, context, filteredStock),
    );
  }

  // Build Empty State
  Widget _buildEmptyState(bool isSearchResult) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          appVectorImage(
            fileName: 'medicine',
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            isSearchResult
                ? 'No medications found'
                : 'No medications in pillbox',
            style: AppTokens.textStyleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isSearchResult
                ? 'Try searching with a different term'
                : 'Tap + to add your first medication',
            style: AppTokens.textStyleSmall.copyWith(
              color: AppTokens.textPlaceholder,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build Medication Cards
  List<Widget> _buildMedicationCards(WidgetRef ref, BuildContext context, List<MedicineInventory> filteredStock) {
    final List<Treatment> sampleTreatments = Treatment.getSampleForPillBox();

    return filteredStock.map((medicineInventory) {
      Medicine med = medicineInventory.medicine;
      return GestureDetector(
        onTap: () {
          // Find treatment plan for this medicine
          sampleTreatments.firstWhere(
                (t) => t.medicine.name == med.name,
            orElse: () => Treatment(
              medicine: med,
              treatmentPlan: TreatmentPlan(
                startDate: DateTime.now(),
                endDate: DateTime.now().add(const Duration(days: 30)),
                timeOfDay: DateTime(2023, 1, 1, 12, 0),
                mealOption: 'Take as needed',
                instructions: 'Consult your doctor for specific instructions',
                frequency: const Duration(days: 1),
              ),
            ),
          );
          context.push('/medicine_detail/${medicineInventory.quantity}', extra: medicineInventory);
        },
        child: Card(
          color: AppTokens.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: AppTokens.borderLight, // stroke color
              width: 1,),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                futureBuildSvg(med.type, med.color, 60),
                const SizedBox(height: 10),
                Text(
                  med.name,
                  style: AppTokens.textStyleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  med.type,
                  style: AppTokens.textStyleMedium.copyWith(
                    color: AppTokens.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(), // Back to spacer to push content to bottom
                Text(
                  '${medicineInventory.quantity}',
                  style: AppTokens.textStyleXLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${med.specs.unit} left',
                  style: AppTokens.textStyleMedium.copyWith(
                    color: AppTokens.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showAddMedicineDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController useCaseController = TextEditingController();

    // Define initial values
    String initialMedicationType = 'Tablet';
    String initialColor = 'White';
    String initialUnit = 'pills';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return GestureDetector(
          onTap: () => FocusScope.of(dialogContext).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: _AddMedicineDialogContent(
            initialMedicationType: initialMedicationType,
            initialColor: initialColor,
            initialUnit: initialUnit,
            nameController: nameController,
            quantityController: quantityController,
            useCaseController: useCaseController,
            ref: ref,
          ),
        );
      },
    );
  }
}

// Separate StatefulWidget to properly manage state
class _AddMedicineDialogContent extends ConsumerStatefulWidget {
  final String initialMedicationType;
  final String initialColor;
  final String initialUnit;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController useCaseController;
  final WidgetRef ref;

  const _AddMedicineDialogContent({
    required this.initialMedicationType,
    required this.initialColor,
    required this.initialUnit,
    required this.nameController,
    required this.quantityController,
    required this.useCaseController,
    required this.ref,
  });

  @override
  ConsumerState<_AddMedicineDialogContent> createState() => _AddMedicineDialogContentState();
}

class _AddMedicineDialogContentState extends ConsumerState<_AddMedicineDialogContent> {
  // These variables are now properly managed in StatefulWidget state
  late String selectedMedicationType;
  late String selectedColor;
  String? selectedSecondaryColor;
  late String selectedUnit;
  
  // Validation error states
  String? nameError;
  String? quantityError;
  String? unitError;
  String? useCaseError;

  @override
  void initState() {
    super.initState();
    selectedMedicationType = widget.initialMedicationType;
    selectedColor = widget.initialColor;
    selectedSecondaryColor = null;
    selectedUnit = widget.initialUnit;
  }

  // Validation functions
  void validateName() {
    setState(() {
      if (widget.nameController.text.isEmpty) {
        nameError = 'Medicine name is required';
      } else if (widget.nameController.text.trim().isEmpty) {
        nameError = 'Medicine name cannot be only whitespace';
      } else if (widget.nameController.text.length < 2) {
        nameError = 'Medicine name must be at least 2 characters';
      } else {
        nameError = null;
      }
    });
  }

  void validateQuantity() {
    setState(() {
      if (widget.quantityController.text.isEmpty) {
        quantityError = 'Quantity is required';
      } else {
        final quantity = int.tryParse(widget.quantityController.text);
        if (quantity == null) {
          quantityError = 'Quantity must be a valid number';
        } else if (quantity <= 0) {
          quantityError = 'Quantity must be greater than zero';
        } else if (quantity > 1000) {
          quantityError = 'Quantity cannot exceed 1000';
        } else {
          quantityError = null;
        }
      }
    });
  }

  void validateUnit() {
    setState(() {
      // Unit is now a dropdown, so no validation needed
      unitError = null;
    });
  }

  void validateUseCase() {
    setState(() {
      if (widget.useCaseController.text.isNotEmpty && widget.useCaseController.text.trim().isEmpty) {
        useCaseError = 'Use case cannot be only whitespace';
      } else if (widget.useCaseController.text.length > 100) {
        useCaseError = 'Use case should be 100 characters or less';
      } else {
        useCaseError = null;
      }
    });
  }

  // Function to validate all fields
  bool validateAllFields() {
    validateName();
    validateQuantity();
    validateUnit();
    validateUseCase();
    
    return nameError == null && 
           quantityError == null && 
           unitError == null && 
           useCaseError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.bgPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTokens.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Text(
                'Add New Medication',
                style: AppTokens.textStyleXLarge,
              ),
            const SizedBox(height: 20),
            // Medication Name
            FormFieldLabel(text: 'Medication Name'),
            CustomTextField(
              controller: widget.nameController,
              hintText: 'Paracetamol',
              errorText: nameError,
              onChanged: validateName,
            ),
            const SizedBox(height: 20),

            // Medication Type
            FormFieldLabel(text: 'Medication Type'),
            ChipSelector(
              options: ['Tablet', 'Capsule', 'Drops', 'Cream', 'Spray', 'Injection'],
              selectedValue: selectedMedicationType,
              onChanged: (type) => setState(() => selectedMedicationType = type),
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
            const SizedBox(height: 20),

            // Color
            ColorPicker(
              selectedColor: selectedColor,
              selectedSecondaryColor: selectedSecondaryColor,
              onChanged: (color) => setState(() => selectedColor = color),
              onSecondaryChanged: (color) => setState(() => selectedSecondaryColor = color),
              isDuotone: selectedMedicationType == 'Capsule',
            ),
            const SizedBox(height: 20),

            // Quantity and Unit
            FormFieldLabel(text: 'Quantity'),
            QuantityUnitRow(
              quantityController: widget.quantityController,
              selectedUnit: selectedUnit,
              onUnitChanged: (value) => setState(() => selectedUnit = value!),
              quantityError: quantityError,
              onQuantityChanged: validateQuantity,
            ),
            const SizedBox(height: 16),

            // Use Case
            FormFieldLabel(text: 'Use Case'),
            CustomTextField(
              controller: widget.useCaseController,
              hintText: 'What is this medication for?',
              errorText: useCaseError,
              onChanged: validateUseCase,
            ),
                  ],
                ),
              ),
            ),
            // Fixed buttons at bottom
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: AppTokens.bgPrimary,
                border: Border(
                  top: BorderSide(
                    color: AppTokens.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Button.secondary(
                      onPressed: () => Navigator.of(context).pop(),
                      text: 'Cancel',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Button.primary(
                      onPressed: () {
                        if (validateAllFields()) {
                          // Create color description for bicolore capsules
                          String colorDescription = selectedColor;
                          if (selectedMedicationType == 'Capsule' && selectedSecondaryColor != null) {
                            colorDescription = '$selectedColor & $selectedSecondaryColor';
                          }
                          
                          devPrint('[Pillbox] Saving medicine - Type: $selectedMedicationType, Color: $colorDescription');
                          
                          final newMedicine = Medicine(
                            name: widget.nameController.text.trim(),
                            type: selectedMedicationType,
                            color: colorDescription,
                          );
                          final quantity = int.tryParse(widget.quantityController.text) ?? 0;

                          final specification = Specification(
                            unit: selectedUnit,
                            useCase: widget.useCaseController.text.trim(),
                          );
                          
                          devPrint('[Pillbox] Medicine details - Name: ${widget.nameController.text.trim()}, Type: $selectedMedicationType, Color: $colorDescription, Unit: $selectedUnit');
                          newMedicine.addSpecification(specification);
                          try {
                            final notifier = widget.ref.read(pillBoxProvider.notifier);
                            notifier.addMedicine(newMedicine, quantity);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${newMedicine.name} added to pillbox'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.pink[300],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding medication: ${e.toString()}'),
                                duration: const Duration(seconds: 3),
                                backgroundColor: Colors.red[300],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      text: 'Add Medication',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}