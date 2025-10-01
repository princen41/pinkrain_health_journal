import 'package:hive/hive.dart';

class DisclaimerService {
  static const String _disclaimerBoxName = 'disclaimer_box';
  static const String _disclaimerAcceptedKey = 'disclaimer_accepted';
  
  static Box? _box;

  /// Initialize the disclaimer service
  static Future<void> init() async {
    _box = await Hive.openBox(_disclaimerBoxName);
  }

  /// Check if the user has accepted the disclaimer
  static bool hasAcceptedDisclaimer() {
    return _box?.get(_disclaimerAcceptedKey, defaultValue: false) ?? false;
  }

  /// Mark the disclaimer as accepted
  static Future<void> acceptDisclaimer() async {
    await _box?.put(_disclaimerAcceptedKey, true);
  }

  /// Reset disclaimer acceptance (for testing purposes)
  static Future<void> resetDisclaimer() async {
    await _box?.delete(_disclaimerAcceptedKey);
  }
}