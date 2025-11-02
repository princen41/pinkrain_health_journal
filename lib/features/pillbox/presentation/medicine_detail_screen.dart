import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:pinkrain/core/models/medicine_model.dart';
import 'package:url_launcher/url_launcher.dart';

// import '../data/pillbox_model.dart'; // removed unused import
import '../../../core/util/helpers.dart';
import '../../../core/widgets/index.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/colors.dart';
import 'pillbox_notifier.dart';

// Edit medicine dialog widget
class _EditMedicineDialogContent extends ConsumerStatefulWidget {
  final MedicineInventory inventory;
  final PillBoxNotifier notifier;
  final VoidCallback onUpdate;

  const _EditMedicineDialogContent({
    required this.inventory,
    required this.notifier,
    required this.onUpdate,
  });

  @override
  ConsumerState<_EditMedicineDialogContent> createState() => _EditMedicineDialogContentState();
}

class _EditMedicineDialogContentState extends ConsumerState<_EditMedicineDialogContent> {
  late TextEditingController nameController;
  
  late String selectedMedicationType;
  String? selectedColor;
  String? selectedSecondaryColor;
  String? nameError;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.inventory.medicine.name);
    selectedMedicationType = widget.inventory.medicine.type;
    
    // Parse color for capsules (handle "Color1 & Color2" format)
    String primaryColor = widget.inventory.medicine.color;
    if (widget.inventory.medicine.type == 'Capsule' && primaryColor.contains('&')) {
      final parts = primaryColor.split('&');
      if (parts.length == 2) {
        selectedColor = parts[0].trim();
        selectedSecondaryColor = parts[1].trim();
      } else {
        selectedColor = primaryColor;
      }
    } else {
      selectedColor = primaryColor;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      final name = nameController.text.trim();
      
      if (nameController.text.isEmpty) {
        nameError = 'Medicine name is required';
      } else if (name.isEmpty) {
        nameError = 'Medicine name cannot be only whitespace';
      } else if (name.length < 2) {
        nameError = 'Medicine name must be at least 2 characters';
      } else {
        // Check for duplicate names in the pillbox (excluding current medicine)
        final pillbox = ref.read(pillBoxProvider);
        final duplicateExists = pillbox.pillStock.any(
          (item) => item.medicine.name.toLowerCase() == name.toLowerCase() &&
                     item.medicine.name.toLowerCase() != widget.inventory.medicine.name.toLowerCase(),
        );
        
        if (duplicateExists) {
          nameError = 'A medicine with the name "$name" already exists.';
        } else {
          nameError = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.bgPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                'Edit Medication',
                style: AppTokens.textStyleXLarge,
              ),
              const SizedBox(height: 24),
              // Medication Name
              FormFieldLabel(text: 'Medication Name'),
              CustomTextField(
                controller: nameController,
                hintText: 'Paracetamol',
                errorText: nameError,
                onChanged: () {
                  // Validate name as user types
                  _validateName();
                },
              ),
              const SizedBox(height: 20),
              // Medication Type
              FormFieldLabel(text: 'Medication Type'),
              ChipSelector(
                options: ['Tablet', 'Capsule', 'Drops', 'Cream', 'Spray', 'Injection'],
                selectedValue: selectedMedicationType,
                onChanged: (type) {
                  setState(() {
                    selectedMedicationType = type;
                  });
                },
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
                onChanged: (color) {
                  setState(() {
                    selectedColor = color;
                  });
                },
                onSecondaryChanged: (color) {
                  setState(() {
                    selectedSecondaryColor = color;
                  });
                },
                isDuotone: selectedMedicationType == 'Capsule',
              ),
              const SizedBox(height: 32),
              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: Button.secondary(
                      onPressed: () => Navigator.of(context).pop(),
                      text: 'Cancel',
                      size: ButtonSize.large,
                      borderWidth: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Button.primary(
                      onPressed: () {
                        // Validate all fields before submission
                        _validateName();
                        
                        if (nameError != null) {
                          return; // Don't proceed if validation fails
                        }
                        
                        // Create color description for bicolore capsules
                        String colorDescription = selectedColor ?? 'White';
                        if (selectedMedicationType == 'Capsule' && selectedSecondaryColor != null) {
                          colorDescription = '${selectedColor ?? 'White'} & $selectedSecondaryColor';
                        }
                        
                        final success = widget.notifier.updateMedicine(
                          widget.inventory,
                          nameController.text.trim(),
                          selectedMedicationType,
                          colorDescription,
                        );
                        
                        if (success) {
                        widget.onUpdate();
                        } else {
                          // This should rarely happen since validation catches duplicates
                          // But show error as safety net
                          setState(() {
                            nameError = 'A medicine with the name "${nameController.text.trim()}" already exists.';
                          });
                        }
                      },
                      text: 'Save',
                      size: ButtonSize.large,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MedicineDetailScreen extends ConsumerStatefulWidget {
  final MedicineInventory inventory;

  const MedicineDetailScreen({
    super.key,
    required this.inventory
  });

  @override
  ConsumerState<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen> {

  late Medicine medicine;
  String description = 'Loading medication information...';
  bool isLoading = true;
  bool isExpanded = false;

  // Helper method to safely call setState
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // Sanitize text by removing reference symbols like [1], [4], [6], etc.
  String sanitizeText(String text) {
    // Regular expression to match reference symbols like [1], [4], [6], etc.
    return text.replaceAll(RegExp(r'\[\d+\]'), '');
  }

  Future<void> fetchMedUserDescription() async {
    try {
      final url = Uri.parse('https://en.wikipedia.org/wiki/${Uri.encodeComponent(medicine.name)}');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final doc = parser.parse(response.body);
        final contentDiv = doc.querySelector('#mw-content-text .mw-parser-output');

        if (contentDiv != null) {
          List<String> summaryParas = [];

          for (var child in contentDiv.children) {
            if (child.localName == 'p' && child.text.trim().isNotEmpty) {
              summaryParas.add(child.text.trim());
            }
            if (child.localName == 'h2') break; // Stop at first section
          }

          if (summaryParas.isNotEmpty) {
            final summaryText = sanitizeText(summaryParas.join('\n\n'));
            safeSetState(() {
              description = summaryText;
              isLoading = false;
            });
            return;
          }
        }

        // Default fallback message if no paragraphs found
        safeSetState(() {
          description = "This medication is used to treat various conditions. Please consult your doctor for specific information.";
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        safeSetState(() {
          description = "Information for this medication was not found in our database.";
          isLoading = false;
        });
      } else {
        safeSetState(() {
          description = "Unable to load medication information. Status code: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      safeSetState(() {
        if (e is TimeoutException) {
          description = "Request timed out. Please check your internet connection and try again.";
        } else if (e.toString().contains('SocketException') || 
                  e.toString().contains('Connection refused') ||
                  e.toString().contains('Network is unreachable')) {
          description = "Network error. Please check your internet connection and try again.";
        } else {
          description = "Error loading medication information: ${e.toString().split('\n')[0]}";
        }
        isLoading = false;
      });
    }
  }

  // Returns the truncated version of the description (first 2-3 lines)
  String getTruncatedDescription() {
    if (description.contains("Failed") || 
        description.contains("Error") || 
        description.contains("Loading")) {
      return description;
    }

    final lines = description.split('\n');
    if (lines.length <= 3) {
      return description;
    }

    return lines.take(3).join('\n');
  }

  // Returns the expanded version of the description (up to 20 more lines)
  String getExpandedDescription() {
    if (description.contains("Failed") || 
        description.contains("Error") || 
        description.contains("Loading")) {
      return description;
    }

    final lines = description.split('\n');
    if (lines.length <= 3) {
      return description;
    }

    // Show first 3 lines plus up to 20 more lines
    final maxLines = lines.length > 23 ? 23 : lines.length;
    return lines.take(maxLines).join('\n');
  }

  @override
  void initState() {
    medicine = widget.inventory.medicine;
    fetchMedUserDescription();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(pillBoxProvider.notifier);
    final pillBox = ref.watch(pillBoxProvider);
    final inventory = pillBox.pillStock.firstWhere(
      (item) => item.medicine.name == medicine.name,
      orElse: () => widget.inventory,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(
        '',
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 24,
            strokeWidth: 1,
            color: AppTokens.iconPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedEdit02,
                size: 24,
                strokeWidth: 1,
                color: AppTokens.iconPrimary,
              ),
              onPressed: () async {
                await _showEditMedicineDialog(context, notifier, inventory);
                // Refresh the screen after editing
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${medicine.type} • ${medicine.specs.dosage} ${medicine.specs.unit}',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  futureBuildSvg(medicine.type, medicine.color, 50),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${inventory.quantity} ${medicine.specs.unit} left',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      _showFillUpDialog(context, notifier, inventory);
                    },
                    child: Text(
                      'fill-up >',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading 
                      ? Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Loading medication information...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: isExpanded ? 300 : 70,
                              ),
                              child: Text(
                                isExpanded ? getExpandedDescription() : getTruncatedDescription(),
                                style: TextStyle(color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                                maxLines: isExpanded ? 23 : 3,
                              ),
                            ),
                            if (!(description.contains("Failed") || description.contains("Error") || description.contains("Loading")))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    safeSetState(() {
                                      isExpanded = !isExpanded;
                                    });
                                  },
                                  child: Text(
                                    isExpanded ? 'Show less' : 'Read more',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if (description.contains("Failed") || description.contains("Error"))
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    safeSetState(() {
                                      isLoading = true;
                                      description = 'Loading medication information...';
                                    });
                                    fetchMedUserDescription();
                                  },
                                  icon: Icon(Icons.refresh, color: Colors.white),
                                  label: Text('Retry', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final url = Uri.parse('https://en.wikipedia.org/wiki/${Uri.encodeComponent(medicine.name)}');
                            launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Learn more on Wikipedia >',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final formattedName = medicine.name.toLowerCase().replaceAll(' ', '-');
                            final url = Uri.parse('https://www.drugs.com/$formattedName.html');
                            launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                          child: Text(
                            'Learn more on Drugs.com >',
                            style: TextStyle(color: Colors.pink[400]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                  ],
                ),
              ),
            ),
          ),
          // Remove button fixed at bottom
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppTokens.bgPrimary,
            ),
            child: SafeArea(
              top: false,
              child: Button.destructive(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
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
                                  'Remove Medication',
                                  style: AppTokens.textStyleXLarge.copyWith(
                                    color: AppTokens.stateError,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Message
                                Text(
                                  'Are you sure you want to remove ${medicine.name} from your pillbox?',
                                  style: AppTokens.textStyleMedium.copyWith(
                                    color: AppTokens.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Remove button
                                SizedBox(
                                  width: double.infinity,
                                  child: Button.destructive(
                                    onPressed: () {
                                      notifier.removeMedicine(medicine);
                                      Navigator.of(context).pop(); // Close modal
                                      Navigator.of(context).pop(); // Close detail screen
                                    },
                                    text: 'Remove',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Cancel button
                                SizedBox(
                                  width: double.infinity,
                                  child: Button.secondary(
                                    onPressed: () => Navigator.of(context).pop(),
                                    text: 'Cancel',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                text: 'Remove from Pill Box',
                borderRadius: 12,
                borderWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

void _showFillUpDialog(BuildContext context, PillBoxNotifier notifier, MedicineInventory inventory) {
  int pillsChange = 0;
  bool isAdding = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
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
                      'Update Pills',
                      style: AppTokens.textStyleXLarge,
                    ),
                    const SizedBox(height: 24),
                    // Mode selection (Add/Remove)
                    Text(
                      isAdding ? 'Add pills' : 'Remove pills',
                      style: AppTokens.textStyleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isAdding = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isAdding ? AppColors.pink100 : AppTokens.buttonSecondaryBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTokens.borderLight,
                                  width: isAdding ? 0 : 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Add',
                                  style: AppTokens.textStyleMedium.copyWith(
                                    color: isAdding ? AppTokens.textPrimary : AppTokens.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isAdding = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isAdding ? AppColors.pink100 : AppTokens.buttonSecondaryBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTokens.borderLight,
                                  width: !isAdding ? 0 : 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Remove',
                                  style: AppTokens.textStyleMedium.copyWith(
                                    color: !isAdding ? AppTokens.textPrimary : AppTokens.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Quantity selector
                    Text(
                      'Quantity',
                      style: AppTokens.textStyleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              if (pillsChange > 0) pillsChange--;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTokens.buttonSecondaryBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTokens.borderLight,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.remove,
                              color: pillsChange > 0 ? AppTokens.textPrimary : AppTokens.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '$pillsChange',
                          style: AppTokens.textStyleXLarge,
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              pillsChange++;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTokens.buttonSecondaryBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTokens.borderLight,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              color: AppTokens.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Update button
                    SizedBox(
                      width: double.infinity,
                      child: Opacity(
                        opacity: pillsChange == 0 ? 0.5 : 1.0,
                        child: Button.primary(
                          onPressed: pillsChange == 0
                              ? () {} // No-op when disabled
                              : () {
                                  final pillsLeft = inventory.quantity;
                                  int newPillCount;

                                  if (isAdding) {
                                    newPillCount = pillsLeft + pillsChange;
                                  } else {
                                    newPillCount = (pillsLeft - pillsChange).clamp(0, pillsLeft).toInt();
                                  }
                                  notifier.updateMedicineQuantity(inventory, newPillCount);
                                  Navigator.of(dialogContext).pop();
                                },
                          text: 'Update',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: Button.secondary(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        text: 'Cancel',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showEditMedicineDialog(BuildContext context, PillBoxNotifier notifier, MedicineInventory inventory) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext dialogContext) {
      return _EditMedicineDialogContent(
        inventory: inventory,
        notifier: notifier,
        onUpdate: () {
          Navigator.of(dialogContext).pop();
        },
      );
    },
  );
}
}
