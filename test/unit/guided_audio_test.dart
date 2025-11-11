import 'package:flutter_test/flutter_test.dart';
import 'package:pinkrain/features/guided-meditation/guided_audio.dart';

// Helper function to sanitize asset paths
String sanitizeAssetPath(String assetPath) {
  return assetPath.replaceAll("'", "");
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MeditationTrack', () {
    test('should create a MeditationTrack with correct properties', () {
      // Arrange
      const title = "Test Track";
      const duration = "5 min test";
      const description = "Test description";
      const assetPath = "assets/audio-tracks/Test_Track.m4a";
      const category = "Test Category";

      // Act
      final track = MeditationTrack(
        title: title,
        duration: duration,
        description: description,
        assetPath: assetPath,
        category: category,
      );

      // Assert
      expect(track.title, equals(title));
      expect(track.duration, equals(duration));
      expect(track.description, equals(description));
      expect(track.assetPath, equals(assetPath));
      expect(track.category, equals(category));
    });
  });

  group('GuidedMeditationScreenState', () {
    late GuidedMeditationScreenState state;

    setUp(() {
      state = GuidedMeditationScreenState();
    });

    test('categories getter should return unique categories', () {
      // Act
      final categories = state.categories;

      // Assert
      expect(categories, isA<List<String>>());
      expect(categories.length, equals(3)); // Based on the currently active tracks (Rest & Stillness tracks are commented out)
      expect(categories, contains("Self-Acceptance"));
      expect(categories, contains("Emotional Processing"));
      expect(categories, contains("Grief & Loss"));

      // Verify no duplicates
      expect(categories.length, equals(Set<String>.from(categories).length));
    });

    test('getTracksByCategory should return tracks for a specific category',
        () {
      // Act
      final selfAcceptanceTracks = state.getTracksByCategory("Self-Acceptance");
      final emotionalProcessingTracks = state.getTracksByCategory("Emotional Processing");
      final griefLossTracks = state.getTracksByCategory("Grief & Loss");

      // Assert
      expect(selfAcceptanceTracks.length,
          equals(2)); // Based on the currently active tracks
      expect(emotionalProcessingTracks.length, equals(1)); // Based on the currently active tracks
      expect(griefLossTracks.length, equals(1)); // Based on the currently active tracks

      // Verify all tracks in the category have the correct category
      for (var track in selfAcceptanceTracks) {
        expect(track.category, equals("Self-Acceptance"));
      }

      for (var track in emotionalProcessingTracks) {
        expect(track.category, equals("Emotional Processing"));
      }

      for (var track in griefLossTracks) {
        expect(track.category, equals("Grief & Loss"));
      }
    });
  });

  group('Path Sanitization', () {
    test('should sanitize paths with apostrophes', () {
      // Arrange
      final trackWithApostrophe = MeditationTrack(
        title: "You're Not a Burden",
        duration: "5 min test",
        description: "Test description",
        assetPath: "assets/audio-tracks/You're_Not_a_Burden.m4a",
        category: "Test",
      );

      // Act
      final sanitizedPath = sanitizeAssetPath(trackWithApostrophe.assetPath);

      // Assert
      expect(
          sanitizedPath, equals("assets/audio-tracks/Youre_Not_a_Burden.m4a"));
      expect(sanitizedPath, isNot(contains("'")));
    });

    test('should handle paths without apostrophes correctly', () {
      // Arrange
      final trackWithoutApostrophe = MeditationTrack(
        title: "The Voice You Needed",
        duration: "5 min test",
        description: "Test description",
        assetPath: "assets/audio-tracks/The_Voice_You_Needed.m4a",
        category: "Test",
      );

      // Act
      final sanitizedPath = sanitizeAssetPath(trackWithoutApostrophe.assetPath);

      // Assert
      expect(sanitizedPath,
          equals("assets/audio-tracks/The_Voice_You_Needed.m4a"));
      expect(sanitizedPath, equals(trackWithoutApostrophe.assetPath));
    });

    test('should sanitize multiple apostrophes in a path', () {
      // Arrange
      final trackWithMultipleApostrophes = MeditationTrack(
        title: "Track with multiple apostrophes",
        duration: "5 min test",
        description: "Test description",
        assetPath:
            "assets/audio-tracks/Track's_with_multiple's_apostrophes.m4a",
        category: "Test",
      );

      // Act
      final sanitizedPath =
          sanitizeAssetPath(trackWithMultipleApostrophes.assetPath);

      // Assert
      expect(sanitizedPath,
          equals("assets/audio-tracks/Tracks_with_multiples_apostrophes.m4a"));
      expect(sanitizedPath, isNot(contains("'")));
    });
  });
}
