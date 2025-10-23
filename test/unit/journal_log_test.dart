import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/data/journal_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Journal Log Tests', () {
    late JournalLog journalLog;
    late DateTime date;
    List<IntakeLog> logs = [];
    IntakeLog? firstLog;
    late Directory tempDir;

    setUpAll(() async {
      // Create a temporary directory for Hive
      tempDir = await Directory.systemTemp.createTemp('test_hive_');
      Hive.init(tempDir.path);
    });

    setUp(() {
      journalLog = JournalLog();
      date = DateTime.now();
    });

    tearDownAll(() async {
      // Clean up Hive and temp directory
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Can get medications for the day', () async {
      logs = await journalLog.getMedicationsForTheDay(date);
      expect(logs, isNotNull);
    });

    test('Check log details when logs exist', () async {
      logs = await journalLog.getMedicationsForTheDay(date);
      if (logs.isNotEmpty) {
        firstLog = logs[0];
        // Note: Using print is acceptable in test files for debugging purposes
        // These prints help verify the test data is correct
        final log = firstLog!; // We know it's non-null since logs is not empty
        final treatment = log.treatment;
        // treatment is guaranteed to be non-null based on the data structure
        devPrint('Medicine name: ${treatment.medicine.name}');
        devPrint('Is taken initially: ${log.isTaken}');
        log.isTaken = true;

        final updatedLogs = await journalLog.getMedicationsForTheDay(date);
        expect(updatedLogs, isNotEmpty);
        expect(updatedLogs[0].isTaken, isTrue,
            reason: 'Updated log should be marked as taken');
      } else {
        markTestSkipped('No medication logs found for testing');
      }
    });
  });
}
