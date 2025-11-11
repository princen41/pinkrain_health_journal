import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pinkrain/core/theme/tokens.dart';
import 'package:pinkrain/core/theme/colors.dart';
import 'package:pinkrain/core/widgets/appbar.dart';
import 'package:pinkrain/core/widgets/buttons.dart';
import 'models.dart';
import 'exercises.dart';
import 'player.dart';

class BreathBreakScreen extends ConsumerStatefulWidget {
  const BreathBreakScreen({super.key});

  @override
  ConsumerState<BreathBreakScreen> createState() => _BreathBreakScreenState();
}

class _BreathBreakScreenState extends ConsumerState<BreathBreakScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String selectedExercise = 'box';
  int selectedCycles = 4;
  bool isExerciseStarted = false;
  bool isExercisePaused = false;

  // Background gradient animation controllers
  late Animation<Color?> _gradientStartAnimation;
  late Animation<Color?> _gradientEndAnimation;

  // Particle system
  static const int _particleCount = 14;
  late List<BreathingParticle> _particles;
  final Random _particleRandom = Random();

  // Stage-based gradient colors using PinkRain palette
  final Map<BreathingStage, List<Color>> _stageColors = {
    BreathingStage.inhale: [AppColors.pastelBlue.withValues(alpha: 0.3), AppColors.pastelBlue],
    BreathingStage.hold: [AppColors.pastelPurple.withValues(alpha: 0.3), AppColors.pastelPurple],
    BreathingStage.exhale: [AppColors.pink10, AppColors.pink40],
    BreathingStage.rest: [AppColors.pastelBlue.withValues(alpha: 0.3), AppColors.pastelBlue],
    BreathingStage.initial: [AppTokens.bgPrimary, AppTokens.bgMuted],
    BreathingStage.completed: [AppColors.pastelGreen.withValues(alpha: 0.3), AppColors.pastelGreen],
  };

  // Sound feedback control
  final bool _enableHaptic = true;
  BreathingStage? _lastStage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // Initialize gradient animations
    _gradientStartAnimation = ColorTween(
      begin: _stageColors[BreathingStage.initial]![0],
      end: _stageColors[BreathingStage.initial]![0],
    ).animate(_animationController);

    _gradientEndAnimation = ColorTween(
      begin: _stageColors[BreathingStage.initial]![1],
      end: _stageColors[BreathingStage.initial]![1],
    ).animate(_animationController);

    // Initialize particles
    _initParticles();
  }

  void _initParticles() {
    // Create a fixed set of particles with random orbits and speeds
    _particles = List.generate(_particleCount, (i) {
      final angle = _particleRandom.nextDouble() * 2 * pi;
      final orbitRadius = 120 + _particleRandom.nextDouble() * 40;
      final size = 4 + _particleRandom.nextDouble() * 5;
      final speed = 0.5 + _particleRandom.nextDouble() * 0.8;
      final color = AppTokens.bgPrimary.withAlpha(120 + _particleRandom.nextInt(80));
      return BreathingParticle(
        baseAngle: angle,
        orbitRadius: orbitRadius,
        size: size,
        speedFactor: speed,
        color: color,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final breathingState = ref.watch(breathingExerciseProvider);
    final notifier = ref.read(breathingExerciseProvider.notifier);

    ref.listen<BreathingState>(breathingExerciseProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        // Start exercise if transitioned from initial to another stage
        if (prev?.stage == BreathingStage.initial &&
            next.stage != BreathingStage.initial &&
            next.stage != BreathingStage.completed) {
          if (!isExerciseStarted) {
            setState(() {
              isExerciseStarted = true;
            });
          }
        }
        // Handle animation controller based on stage
        double targetValue = 0.5;
        switch (next.stage) {
          case BreathingStage.inhale:
          case BreathingStage.hold:
            targetValue = 1.0;
            break;
          case BreathingStage.exhale:
          case BreathingStage.rest:
            targetValue = 0.0;
            break;
          default:
            targetValue = 0.5;
        }
        // Only update animation controller if mounted and not already at target
        if (mounted) {
          final duration = Duration(
            seconds: next.secondsRemaining,
            milliseconds: 100,
          );
          if (_animationController.duration != duration) {
            _animationController.duration = duration;
          }
          if (targetValue == 1.0 && _animationController.value < 1.0) {
            _animationController.forward();
          } else if (targetValue == 0.0 && _animationController.value > 0.0) {
            _animationController.reverse();
          }
        }

        // Update gradient colors based on current stage
        if (prev?.stage != next.stage && next.stage != BreathingStage.initial) {
          if (mounted) {
            // Only update if colors actually changed
            final newStartColor = _stageColors[next.stage]![0];
            final newEndColor = _stageColors[next.stage]![1];
            final currentStart = _gradientStartAnimation.value ?? _stageColors[next.stage]![0];
            final currentEnd = _gradientEndAnimation.value ?? _stageColors[next.stage]![1];
            
            if (currentStart != newStartColor || currentEnd != newEndColor) {
              setState(() {
                _gradientStartAnimation = ColorTween(
                  begin: currentStart,
                  end: newStartColor,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeInOut,
                  ),
                );

                _gradientEndAnimation = ColorTween(
                  begin: currentEnd,
                  end: newEndColor,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeInOut,
                  ),
                );
              });
            }
          }
        }

        // Reset state on completion
        if (next.stage == BreathingStage.completed) {
          if (isExerciseStarted && mounted) {
            setState(() {
              isExerciseStarted = false;
            });

            // Completion feedback
            if (_enableHaptic) {
              HapticFeedback.mediumImpact();
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  HapticFeedback.mediumImpact();
                }
              });
            }
          }
        }
      });
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Clean up when navigating away
          final notifier = ref.read(breathingExerciseProvider.notifier);
          notifier.stopExercise();
        }
      },
      child: Scaffold(
        appBar: isExerciseStarted ? null : buildAppBar(
          'Breath Break',
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 24,
              strokeWidth: 1,
              color: AppTokens.iconPrimary,
            ),
            onPressed: () {
              // Stop exercise before navigating
              final notifier = ref.read(breathingExerciseProvider.notifier);
              notifier.stopExercise();
              context.go('/mindfulness');
            },
          ),
          backgroundColor: AppTokens.bgPrimary,
        ),
        backgroundColor: AppTokens.bgPrimary, // White background like other screens
      body: Stack(
        children: [
          // Only show gradient background when exercise is active
          if (isExerciseStarted)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final colors = [
                  (_gradientStartAnimation.value ??
                          _stageColors[breathingState.stage]![0])
                      .withValues(alpha: 0.95),
                  (_gradientStartAnimation.value ??
                          _stageColors[breathingState.stage]![0])
                      .withValues(alpha: 0.75),
                  (_gradientEndAnimation.value ??
                          _stageColors[breathingState.stage]![1])
                      .withValues(alpha: 0.75),
                  (_gradientEndAnimation.value ??
                          _stageColors[breathingState.stage]![1])
                      .withValues(alpha: 0.95),
                ];
                
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: colors,
                      stops: const [
                        0.0,
                        0.10,
                        0.90,
                        1.0
                      ], // Smooth fade at top and bottom
                    ),
                  ),
                );
              },
            ),
          // Content layer
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isExerciseStarted)
                      BreathingExerciseSelector(
                        selectedExercise: selectedExercise,
                        selectedCycles: selectedCycles,
                        onExerciseSelected: (type) {
                          setState(() {
                            selectedExercise = type;
                          });
                        },
                        onCyclesChanged: (cycles) {
                          setState(() {
                            selectedCycles = cycles;
                          });
                        },
                      ),
                    if (isExerciseStarted)
                      BreathingExercisePlayer(
                        state: breathingState,
                        animationController: _animationController,
                        stageColors: _stageColors,
                        gradientStartAnimation: _gradientStartAnimation,
                        gradientEndAnimation: _gradientEndAnimation,
                        particles: _particles,
                        enableHaptic: _enableHaptic,
                        lastStage: _lastStage,
                        onStageChanged: (stage) {
                          // Only update if stage actually changed
                          if (_lastStage != stage && mounted) {
                            setState(() {
                              _lastStage = stage;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          // Static control buttons at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // Add extra padding to account for the height of the navbar
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isExerciseStarted
                    ? (breathingState.stage != BreathingStage.completed
                        ? Row(
                            children: [
                              Expanded(
                                child: Button.primary(
                                  onPressed: () {
                                    if (isExercisePaused) {
                                      // Resume the exercise
                                      _animationController.forward();
                                      notifier.resumeExercise();
                                      setState(() {
                                        isExercisePaused = false;
                                      });
                                    } else {
                                      // Pause the exercise
                                      _animationController.stop();
                                      notifier.pauseExercise();
                                      setState(() {
                                        isExercisePaused = true;
                                      });
                                    }
                                  },
                                  text: isExercisePaused ? 'Resume' : 'Pause',
                                  size: ButtonSize.large,
                                  borderRadius: 30,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Button.secondary(
                                  onPressed: () {
                                    notifier.stopExercise();
                                    setState(() {
                                      isExerciseStarted = false;
                                      isExercisePaused = false;
                                    });
                                  },
                                  text: 'End Session',
                                  size: ButtonSize.large,
                                  borderRadius: 30,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          )
                          : SizedBox(
                            width: double.infinity,
                            child: Button.primary(
                              onPressed: () {
                                setState(() {
                                  isExerciseStarted = false;
                                  isExercisePaused = false;
                                });
                              },
                              text: 'Done',
                              size: ButtonSize.large,
                              borderRadius: 30,
                              fontSize: 18,
                            ),
                          ))
                    : SizedBox(
                        width: double.infinity,
                        child: Button.primary(
                          onPressed: () {
                            setState(() {
                              isExerciseStarted = true;
                              isExercisePaused = false;
                            });
                            notifier.startExercise(
                                selectedExercise, selectedCycles);
                            if (_enableHaptic) {
                              HapticFeedback.lightImpact();
                            }
                          },
                          text: 'Start Exercise',
                          size: ButtonSize.large,
                          borderRadius: 30,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      extendBody: true, // Extend content behind bottom navigation bar
      ),
    );
  }

  @override
  void dispose() {
    // Stop the exercise and clean up state before disposing
    final notifier = ref.read(breathingExerciseProvider.notifier);
    notifier.stopExercise();
    _animationController.dispose();
    super.dispose();
  }
}
