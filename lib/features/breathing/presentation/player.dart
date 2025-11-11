import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pinkrain/core/theme/colors.dart';
import 'package:pinkrain/core/theme/tokens.dart';
import 'models.dart';

class BreathingExercisePlayer extends StatefulWidget {
  final BreathingState state;
  final AnimationController animationController;
  final Map<BreathingStage, List<Color>> stageColors;
  final Animation<Color?> gradientStartAnimation;
  final Animation<Color?> gradientEndAnimation;
  final List<BreathingParticle> particles;
  final bool enableHaptic;
  final BreathingStage? lastStage;
  final ValueChanged<BreathingStage>? onStageChanged;

  const BreathingExercisePlayer({
    super.key,
    required this.state,
    required this.animationController,
    required this.stageColors,
    required this.gradientStartAnimation,
    required this.gradientEndAnimation,
    required this.particles,
    this.enableHaptic = true,
    this.lastStage,
    this.onStageChanged,
  });

  @override
  State<BreathingExercisePlayer> createState() =>
      _BreathingExercisePlayerState();
}

class _BreathingExercisePlayerState extends State<BreathingExercisePlayer> {
  @override
  void didUpdateWidget(BreathingExercisePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Provide haptic feedback on stage transitions
    if (widget.lastStage != widget.state.stage &&
        widget.state.stage != BreathingStage.initial &&
        widget.state.stage != BreathingStage.completed) {
      // Use post-frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _provideFeedback(widget.state.stage);
          widget.onStageChanged?.call(widget.state.stage);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String stageText = getStageText(widget.state.stage);

    return Column(
      children: [
        Text(
          'Cycle ${widget.state.currentCycle} of ${widget.state.totalCycles}',
          style: AppTokens.textStyleMedium.copyWith(
            color: AppTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        BlurText(
          key: ValueKey(stageText),
          text: stageText,
          duration: const Duration(milliseconds: 800),
          type: AnimationType.word,
          textStyle: AppTokens.textStyleXLarge,
        ),
        const SizedBox(height: 10),
        Text(
          '${widget.state.secondsRemaining} seconds',
          style: AppTokens.textStyleLarge.copyWith(
            color: AppTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 50),
        Stack(
          alignment: Alignment.center,
          children: [
            // Progress indicator
            SizedBox(
              width: 328,
              height: 328,
              child: CircularProgressIndicator(
                value: () {
                  final stageTotal =
                      getStageDuration(widget.state.exerciseType, widget.state.stage);
                  if (stageTotal == 0) return 0.0;
                  return (stageTotal - widget.state.secondsRemaining) / stageTotal;
                }(),
                strokeWidth: 3,
                backgroundColor: Colors.transparent,
                color: AppTokens.bgPrimary.withAlpha(120),
              ),
            ),
            // Enhanced breathing orb
            AnimatedBuilder(
              animation: widget.animationController,
              builder: (context, child) {
                final Color primaryColor = _getStageColor(widget.state.stage);
                final Color secondaryColor =
                    _getSecondaryStageColor(widget.state.stage);
                final double orbRadius = 320;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glassmorphic + iridescent border effect
                    Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          radius: 0.85,
                          colors: [
                            Colors.white.withValues(alpha: 0.6),
                            primaryColor.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7, 0.95, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.18),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                        border: Border.all(
                          width: 6,
                          style: BorderStyle.solid,
                          color: Colors.transparent,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Frosted glass effect
                          ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          // Iridescent edge overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: IridescentBorderPainter(
                                    primaryColor, secondaryColor),
                              ),
                            ),
                          ),
                          // Gloss highlight
                          Positioned(
                            top: 48,
                            left: 84,
                            right: 84,
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.07),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Breathing icon
                          Center(
                            child: HugeIcon(
                              icon: getStageIcon(widget.state.stage),
                              color: AppTokens.iconPrimary,
                              size: 64,
                              strokeWidth: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Custom painted particles
                    IgnorePointer(
                      child: CustomPaint(
                        painter: ParticlePainter(
                          particles: widget.particles,
                          animationValue: widget.animationController.value,
                          orbRadius: orbRadius,
                        ),
                        size: Size((orbRadius + 40).toDouble(),
                            (orbRadius + 40).toDouble()),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Color _getStageColor(BreathingStage stage) {
    switch (stage) {
      case BreathingStage.inhale:
        return AppColors.pastelBlue;
      case BreathingStage.hold:
        return AppColors.pastelPurple;
      case BreathingStage.exhale:
        return AppColors.pink100;
      case BreathingStage.rest:
        return AppColors.pastelBlue;
      default:
        return AppColors.pastelBlue;
    }
  }

  Color _getSecondaryStageColor(BreathingStage stage) {
    switch (stage) {
      case BreathingStage.inhale:
        return AppColors.strongBlue;
      case BreathingStage.hold:
        return AppColors.pink100;
      case BreathingStage.exhale:
        return AppColors.pink40;
      case BreathingStage.rest:
        return AppColors.pastelBlue;
      default:
        return AppColors.pastelBlue;
    }
  }

  void _provideFeedback(BreathingStage stage) {
    if (widget.enableHaptic) {
      switch (stage) {
        case BreathingStage.inhale:
          HapticFeedback.lightImpact();
          break;
        case BreathingStage.hold:
          HapticFeedback.selectionClick();
          break;
        case BreathingStage.exhale:
          HapticFeedback.mediumImpact();
          break;
        case BreathingStage.rest:
          HapticFeedback.selectionClick();
          break;
        default:
          break;
      }
    }
  }
}

// Particle model
class BreathingParticle {
  final double baseAngle;
  final double orbitRadius;
  final double size;
  final double speedFactor;
  final Color color;
  BreathingParticle({
    required this.baseAngle,
    required this.orbitRadius,
    required this.size,
    required this.speedFactor,
    required this.color,
  });
}

// CustomPainter for breathing particles
class ParticlePainter extends CustomPainter {
  final List<BreathingParticle> particles;
  final double animationValue;
  final double orbRadius;
  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.orbRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final angle = p.baseAngle + animationValue * 2 * pi * p.speedFactor;
      final r = (orbRadius / 2) + p.orbitRadius * (0.7 + 0.3 * animationValue);
      final dx = center.dx + cos(angle) * r;
      final dy = center.dy + sin(angle) * r;
      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.2 + 0.6 * animationValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.orbRadius != orbRadius ||
      oldDelegate.particles != particles;
}

// Iridescent border painter
class IridescentBorderPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  IridescentBorderPainter(this.primary, this.secondary);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 6.28319, // 2*pi
        colors: [
          primary.withValues(alpha: 0.7),
          secondary.withValues(alpha: 0.7),
          primary.withValues(alpha: 0.7),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 3, paint);
  }

  @override
  bool shouldRepaint(covariant IridescentBorderPainter oldDelegate) => true;
}

