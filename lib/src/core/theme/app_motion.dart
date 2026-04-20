import 'package:flutter/material.dart';

/// App-wide durations, curves, and M3 Expressive spring tokens (see Material blog).
class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration sheetEnter = Duration(milliseconds: 320);
  static const Duration sheetExit = Duration(milliseconds: 220);
  static const Duration pageEnter = Duration(milliseconds: 360);
  static const Duration pageExit = Duration(milliseconds: 300);

  static const Curve standard = Easing.standard;
  static const Curve standardAccelerate = Easing.standardAccelerate;
  static const Curve standardDecelerate = Easing.standardDecelerate;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve emphasizedAccelerate = Easing.emphasizedAccelerate;
  static const Curve emphasizedDecelerate = Easing.emphasizedDecelerate;
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve smooth = Easing.standard;
  static const Curve settle = Easing.emphasizedDecelerate;
  static const Curve pageIn = Easing.emphasizedDecelerate;
  static const Curve pageOut = Easing.emphasizedAccelerate;
  static const Curve spring = Curves.easeOutBack;

  /// M3 Expressive `fastSpatialSpec` (Compose reference values).
  static final SpringDescription m3ExpressiveFastSpatial =
      SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 1400.0,
    ratio: 0.6,
  );

  /// M3 Expressive `fastEffectsSpec` (no overshoot).
  static final SpringDescription m3ExpressiveFastEffects =
      SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 3800.0,
    ratio: 1.0,
  );

  static const AnimationStyle sheetEaseOut = AnimationStyle(
    curve: easeOut,
    reverseCurve: easeIn,
    duration: sheetEnter,
    reverseDuration: sheetExit,
  );
}
