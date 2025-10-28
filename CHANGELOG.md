# Changelog

All notable changes to PinkRain will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2025-10-29

### Added
- "Today" button in journal date selector for quick navigation back to current date
- Icon to "Add Note" button in journal entry dialog
- Granular delete options for treatments (just this occurrence, from this date onwards, all occurrences)

### Changed
- Replaced custom SVG icons with HugeIcons throughout bottom navigation for better consistency
- Bottom navigation now uses modern HugeIcons with proper color states (primary/secondary)
- Improved journal date navigation to support scrolling backwards to past dates
- Enhanced treatment creation/edit UX with persistent cursor and better form handling
- Updated treatment duration to support different units (days/weeks/months) with proper conversion
- Improved day labels (M/Tu/W/Th/F/Sa/Su) clarity throughout treatment screens
- Journal time ranges updated: Morning (0-12pm), Night (9pm-11:59pm)
- Date picker in edit treatment now allows past dates (removed minimumDate constraint)

### Fixed
- Fixed journal medication display when creating/editing treatments
- Fixed journal log creation to properly add new treatments to dates with existing logs
- Fixed data refresh after treatment deletion to immediately reflect changes
- Fixed navigation to properly close both edit screen and treatment overview modal after deletion
- Fixed treatment duration text field cursor persistence
- Fixed string interpolation linter warnings

### UI/UX Improvements
- Replaced delete treatment AlertDialog with PinkRain-styled bottom modal
- Adjusted bottom navigation icon sizing and spacing to prevent overflow
- Improved visual feedback in date selector
- Better alignment and spacing throughout treatment management screens

## [2.1.4] - Previous Version

[Previous changes...]

