import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

final breathingExerciseProvider =
    StateNotifierProvider<BreathingExerciseNotifier, BreathingState>(
  (ref) => BreathingExerciseNotifier(),
);

class BreathingState {
  final BreathingStage stage;
  final BreathingStage? previousStage;
  final int secondsRemaining;
  final int totalCycles;
  final int currentCycle;
  final String exerciseType;

  BreathingState({
    required this.stage,
    this.previousStage,
    required this.secondsRemaining,
    required this.totalCycles,
    required this.currentCycle,
    required this.exerciseType,
  });

  BreathingState copyWith({
    BreathingStage? stage,
    BreathingStage? previousStage,
    int? secondsRemaining,
    int? totalCycles,
    int? currentCycle,
    String? exerciseType,
  }) {
    return BreathingState(
      stage: stage ?? this.stage,
      previousStage: previousStage ?? this.previousStage,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      totalCycles: totalCycles ?? this.totalCycles,
      currentCycle: currentCycle ?? this.currentCycle,
      exerciseType: exerciseType ?? this.exerciseType,
    );
  }
}

enum BreathingStage { inhale, hold, exhale, rest, initial, completed }

class BreathingExerciseNotifier extends StateNotifier<BreathingState> {
  Timer? _timer;

  BreathingExerciseNotifier()
      : super(BreathingState(
          stage: BreathingStage.initial,
          previousStage: null,
          secondsRemaining: 0,
          totalCycles: 4,
          currentCycle: 0,
          exerciseType: 'box',
        ));

  void startExercise(String type, int cycles) {
    // Reset state
    state = BreathingState(
      stage: BreathingStage.inhale,
      previousStage: null,
      secondsRemaining: _getDuration(type, BreathingStage.inhale),
      totalCycles: cycles,
      currentCycle: 1,
      exerciseType: type,
    );

    _startTimer();
  }

  void pauseExercise() {
    _timer?.cancel();
  }

  void resumeExercise() {
    if (state.stage != BreathingStage.initial &&
        state.stage != BreathingStage.completed) {
      _startTimer();
    }
  }

  void stopExercise() {
    _timer?.cancel();
    state = BreathingState(
      stage: BreathingStage.initial,
      previousStage: null,
      secondsRemaining: 0,
      totalCycles: 4,
      currentCycle: 0,
      exerciseType: 'box',
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsRemaining > 1) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        _moveToNextStage();
      }
    });
  }

  void _moveToNextStage() {
    BreathingStage nextStage;

    switch (state.stage) {
      case BreathingStage.inhale:
        // Box and 4-7-8 use holds after inhale, calm goes straight to exhale
        nextStage = (state.exerciseType == 'box' || state.exerciseType == '4-7-8')
            ? BreathingStage.hold
            : BreathingStage.exhale;
        break;
      case BreathingStage.hold:
        // If hold followed inhale -> exhale (for both box and 4-7-8)
        // If hold followed exhale -> rest (only for box)
        if (state.previousStage == BreathingStage.inhale) {
          nextStage = BreathingStage.exhale;
        } else if (state.previousStage == BreathingStage.exhale) {
          nextStage = BreathingStage.rest;
        } else {
          // Fallback: assume hold after inhale
          nextStage = BreathingStage.exhale;
        }
        break;
      case BreathingStage.exhale:
        // Box exercise: exhale -> hold
        // 4-7-8 and calm: exhale -> rest
        nextStage = state.exerciseType == 'box'
            ? BreathingStage.hold
            : BreathingStage.rest;
        break;
      case BreathingStage.rest:
        // Check if we need to move to the next cycle or complete the exercise
        if (state.currentCycle < state.totalCycles) {
          nextStage = BreathingStage.inhale;
          state = state.copyWith(
            stage: nextStage,
            previousStage: state.stage,
            secondsRemaining: _getDuration(state.exerciseType, nextStage),
            currentCycle: state.currentCycle + 1,
          );
          return;
        } else {
          nextStage = BreathingStage.completed;
          _timer?.cancel();
          state = state.copyWith(
            stage: nextStage,
            previousStage: state.stage,
            secondsRemaining: 0,
          );
          return;
        }
      default:
        nextStage = BreathingStage.inhale;
    }

    state = state.copyWith(
      stage: nextStage,
      previousStage: state.stage,
      secondsRemaining: _getDuration(state.exerciseType, nextStage),
    );
  }

  int _getDuration(String exerciseType, BreathingStage stage) {
    switch (exerciseType) {
      case 'box':
        return 4; // All stages are 4 seconds in box breathing
      case '4-7-8':
        switch (stage) {
          case BreathingStage.inhale:
            return 4;
          case BreathingStage.hold:
            return 7;
          case BreathingStage.exhale:
            return 8;
          case BreathingStage.rest:
            return 2;
          default:
            return 4;
        }
      case 'calm':
        switch (stage) {
          case BreathingStage.inhale:
            return 5;
          case BreathingStage.exhale:
            return 5;
          case BreathingStage.rest:
            return 2;
          default:
            return 5;
        }
      default:
        return 4;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

int getStageDuration(String exerciseType, BreathingStage stage) {
  switch (exerciseType) {
    case 'box':
      return 4;
    case '4-7-8':
      switch (stage) {
        case BreathingStage.inhale:
          return 4;
        case BreathingStage.hold:
          return 7;
        case BreathingStage.exhale:
          return 8;
        case BreathingStage.rest:
          return 2;
        default:
          return 4;
      }
    case 'calm':
      switch (stage) {
        case BreathingStage.inhale:
          return 5;
        case BreathingStage.exhale:
          return 5;
        case BreathingStage.rest:
          return 2;
        default:
          return 5;
      }
    default:
      return 4;
  }
}

String getStageText(BreathingStage stage) {
  switch (stage) {
    case BreathingStage.inhale:
      return 'Breathe In';
    case BreathingStage.hold:
      return 'Hold';
    case BreathingStage.exhale:
      return 'Breathe Out';
    case BreathingStage.rest:
      return 'Rest';
    case BreathingStage.completed:
      return 'Completed';
    default:
      return '';
  }
}

dynamic getStageIcon(BreathingStage stage) {
  switch (stage) {
    case BreathingStage.inhale:
      return HugeIcons.strokeRoundedArrowUp02;
    case BreathingStage.hold:
      return HugeIcons.strokeRoundedPause;
    case BreathingStage.exhale:
      return HugeIcons.strokeRoundedArrowDown02;
    case BreathingStage.rest:
      return HugeIcons.strokeRoundedMoreHorizontalSquare01;
    default:
      return HugeIcons.strokeRoundedArrowUp02;
  }
}

