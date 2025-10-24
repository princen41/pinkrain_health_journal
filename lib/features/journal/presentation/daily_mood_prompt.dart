import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/theme/tokens.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/core/widgets/buttons.dart';
import 'package:pinkrain/features/journal/presentation/symptom_predicton_notifier.dart';

import '../data/symptom_prediction.dart';
import 'journal_screen.dart';

class DailyMoodPrompt extends ConsumerStatefulWidget {
  final Function onComplete;
  final DateTime? date; // Optional date parameter, defaults to today if not provided
  final int? initialMood; // Initial mood for editing
  final String? initialDescription; // Initial description for editing
  final bool isEditing; // Flag to indicate if this is an edit operation

  const DailyMoodPrompt({
    super.key,
    required this.onComplete,
    this.date,
    this.initialMood,
    this.initialDescription,
    this.isEditing = false,
  });

  @override
  ConsumerState<DailyMoodPrompt> createState() => DailyMoodPromptState();
}

class DailyMoodPromptState extends ConsumerState<DailyMoodPrompt> {
  late int selectedMood;
  final TextEditingController _feelingsController = TextEditingController();
  late List<SymptomPrediction> predictedSymptoms = []; // Initialize with empty list
  final _isExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // Initialize mood and description with provided values or defaults
    selectedMood = widget.initialMood ?? 2; // Default to neutral if not editing
    if (widget.initialDescription != null) {
      _feelingsController.text = widget.initialDescription!;
    }
    // Only load predicted symptoms for new entries
    if (!widget.isEditing) {
      predictedSymptoms = ref.read(symptomPredictionProvider);
    }
  }

  @override
  void dispose() {
    _feelingsController.dispose();
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  // Save the mood data to Hive
  void _saveMoodData() async {
    if (selectedMood != -1) {
      try {
        // Use the provided date or default to today
        final date = widget.date ?? DateTime.now();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        // Log what we're saving
        devPrint('Saving mood data for date: $dateKey');
        devPrint('Mood: $selectedMood, Description: ${_feelingsController.text}');
        devPrint('Is editing mode: ${widget.isEditing}');

        // Add mood entry (appends to existing entries for the day)
        await HiveService.addMoodEntryForDate(
          date,
          selectedMood,
          _feelingsController.text,
        );

        // If it's the first entry of the day, mark it
        final today = DateTime.now();
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        if (isToday) {
          final entries = await HiveService.getMoodEntriesForDate(date);
          if (entries != null && entries.length == 1) {
            // First entry of today, mark the date
            await HiveService.setMoodEntryForToday();
          }
        }

        // Verify the data was saved correctly
        final savedEntries = await HiveService.getMoodEntriesForDate(date);
        if (savedEntries != null && savedEntries.isNotEmpty) {
          devPrint('Mood entries saved successfully. Total entries: ${savedEntries.length}');
        } else {
          devPrint('Warning: Could not verify saved mood data');
        }

        // Call the onComplete callback
        widget.onComplete();
      } catch (e) {
        devPrint('Error saving mood data: $e');
        // Still call onComplete even if there's an error
        widget.onComplete();
      }
    } else {
      // Show error if no mood is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a mood'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to symptom predictions
    predictedSymptoms = ref.watch(symptomPredictionProvider);
    
    // Get keyboard height to adjust bottom padding
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text field
          FocusScope.of(context).unfocus();
        },
        child: Container(
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
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Cute header
                        Text(
                          'How are you feeling today?',
                          style: AppTokens.textStyleXLarge.copyWith(
                            color: AppTokens.iconBold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Mood selection
                        _buildMoodSelection(),
                        const SizedBox(height: 20),

                        // Text field for feelings
                        _buildFeelingsTextField(ref),
                        const SizedBox(height: 16),

                        // Symptom prediction container
                        if (predictedSymptoms.isNotEmpty)
                          _buildSymptomPredictionContainer(),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: Button.primary(
                            onPressed: _saveMoodData,
                            text: 'Submit',
                            size: ButtonSize.large,
                          ),
                        ),
                        
                        // Bottom padding for safe area
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMoodIconName(int index) {
    switch (index) {
      case 0:
        return 'very-sad';
      case 1:
        return 'sad';
      case 2:
        return 'neutral';
      case 3:
        return 'happy';
      case 4:
        return 'very-happy';
      default:
        return 'neutral';
    }
  }

  Widget _buildMoodSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final isSelected = selectedMood == index;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedMood = index;
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji icon with optional shadow when selected
              Container(
                decoration: BoxDecoration(
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTokens.buttonPrimaryBg.withAlpha(128),
                            spreadRadius: 3,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: SvgPicture.asset(
                  'assets/icons/${_getMoodIconName(index)}.svg',
                  width: 50,
                  height: 50,
                  colorFilter: isSelected
                      ? null
                      : ColorFilter.mode(
                          AppTokens.textSecondary,
                          BlendMode.srcIn,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                getMoodLabel(index),
                style: AppTokens.textStyleSmall.copyWith(
                  fontSize: 12,
                  fontWeight: isSelected
                      ? AppTokens.fontWeightBold
                      : AppTokens.fontWeightW500,
                  color: isSelected
                      ? AppTokens.textPrimary
                      : AppTokens.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  TextField _buildFeelingsTextField(WidgetRef ref) {
    return TextField(
      cursorColor: AppTokens.cursor,
      controller: _feelingsController,
      maxLines: 4,
      minLines: 4,
      style: AppTokens.textStyleMedium,
      onChanged: (value) {
        // Don't predict if text is too short
        if (value.length <= 7) {
          "Text too short for prediction (${value.length} chars)".log();
          return;
        }

        // Don't predict if already in progress
        if (SymptomPredictionNotifier.predictionInProgress) {
          "Prediction already in progress, skipping".log();
          return;
        }

        "Initiating prediction for possible symptoms".log();
        // Trigger symptom prediction when text changes
        try {
          final symptomPredictionNotifier =
              ref.read(symptomPredictionProvider.notifier);
          symptomPredictionNotifier.predict(value);
        } catch (e, stack) {
          "Error during symptom prediction: $e\n$stack".log();
        }
      },
      decoration: InputDecoration(
        hintText: 'Tell us more about how you\'re feeling...',
        hintStyle: const TextStyle(
          color: AppTokens.textPlaceholder,
          fontSize: 15,
        ),
        filled: true,
        fillColor: AppTokens.bgMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTokens.borderLight,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTokens.buttonPrimaryBg,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Container _buildSymptomPredictionContainer() {
    final notifier = ref.read(symptomPredictionProvider.notifier);
    final initialPredictions = notifier.getInitialPredictions();
    final additionalPredictions = notifier.getAdditionalPredictions();
    final hasMorePredictions = additionalPredictions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.buttonElevatedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTokens.buttonPrimaryBg.withAlpha(128),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: AppTokens.iconBold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Possible Symptoms',
                  style: AppTokens.textStyleMedium.copyWith(
                    color: AppTokens.iconBold,
                  ),
                ),
              ),
              if (hasMorePredictions)
                ValueListenableBuilder<bool>(
                  valueListenable: _isExpandedNotifier,
                  builder: (context, isExpanded, child) {
                    return IconButton(
                      icon: Icon(
                        isExpanded ? Icons.remove : Icons.add,
                        color: AppTokens.iconBold,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _isExpandedNotifier.value = !isExpanded;
                      },
                    );
                  },
                ),
            ],
          ),
          if (initialPredictions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: _isExpandedNotifier,
              builder: (context, isExpanded, child) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...initialPredictions.map((symptom) => _buildSymptomChip(symptom)),
                    if (isExpanded) ...[
                      ...additionalPredictions.map((symptom) => _buildSymptomChip(symptom)),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSymptomChip(SymptomPrediction symptom) {
    final double probability = symptom.probability;
    final bool isHighProbability = probability >= 0.4;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.bgPrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTokens.borderLight,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: isHighProbability ? 16 : 14,
            color: AppTokens.iconBold,
          ),
          const SizedBox(width: 6),
          Text(
            '${symptom.name} (${(probability * 100).toStringAsFixed(1)}%)',
            style: AppTokens.textStyleSmall.copyWith(
              fontSize: isHighProbability ? 14 : 12,
              fontWeight: isHighProbability 
                  ? AppTokens.fontWeightW600 
                  : AppTokens.fontWeightW500,
              color: AppTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
