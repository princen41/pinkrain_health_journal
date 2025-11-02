import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pinkrain/core/widgets/bottom_navigation.dart';
import 'package:pinkrain/core/widgets/components.dart';
import 'package:pinkrain/core/widgets/buttons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinkrain/core/util/helpers.dart' show devPrint;
import 'package:pinkrain/core/services/hive_service.dart';
import 'package:pinkrain/core/theme/tokens.dart';
import 'package:pinkrain/core/theme/colors.dart';
import 'package:pinkrain/features/treatment/services/medication_notification_service.dart';
import 'package:pinkrain/features/treatment/services/medication_scheduler_service.dart';
import 'package:pinkrain/core/services/disclaimer_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool isReminderEnabled = true;
  bool isFillUpPillboxEnabled = false;
  late TextEditingController _nameController;
  final _notificationService = MedicationNotificationService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Load user name from storage
  Future<void> _loadUserName() async {
    final savedName = await HiveService.getUserName();
    if (!mounted || savedName.isEmpty) {
      return;
    }
    setState(() {
      _nameController.text = savedName;
    });
  }

  // Save user name to storage
  Future<void> _saveUserName(String name) async {
    await HiveService.saveUserName(name);
  }

  // Helper method to load asset image and create XFile
  Future<XFile?> _loadAssetAsXFile(String assetPath, String fileName) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      return XFile(tempFile.path);
    } catch (e) {
      devPrint('Error loading asset as XFile: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppTokens.textStyleXLarge.copyWith(
            fontWeight: AppTokens.fontWeightBold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 24,
            strokeWidth: 1,
            color: AppTokens.iconPrimary,
          ),
          onPressed: () => context.go('/wellness'),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Name TextField
              Text(
                'Name',
                style: AppTokens.textStyleMedium,
              ),
             /* SizedBox(height: 10),*/

              nameField(
                controller: _nameController,
                onChanged: () => _saveUserName(_nameController.text),
              ),

             /* SizedBox(height: 30),*/
              // Notifications Section
              Text(
                'Notifications',
                style: AppTokens.textStyleLarge.copyWith(
                  color: AppTokens.textSecondary,
                ),
              ),
              SizedBox(height: 20),
              _buildSwitchTile('Reminder', isReminderEnabled, (value) async {
                setState(() {
                  isReminderEnabled = value;
                });
                
                // If turning off, cancel all notifications
                if (!value) {
                  try {
                    final scheduler = MedicationSchedulerService();
                    await scheduler.cancelAllNotifications();
                    devPrint('🔕 Cancelled all scheduled notifications');
                  } catch (e) {
                    devPrint('❌ Error cancelling notifications: $e');
                  }
                  return;
                }
                
                // Request notification permissions when switch is turned on
                if (value) {
                  try {
                    // Initialize notification service first
                    await _notificationService.initialize();
                    
                    // Check actual notification capability
                    final areEnabled = await _notificationService.areNotificationsEnabled();
                    devPrint('🔔 Initial notification check: $areEnabled');
                    
                    if (areEnabled) {
                      // Notifications are already enabled
                      devPrint('✅ Notifications are already enabled');
                      return;
                    }
                    
                    // Check permission status
                    final status = await Permission.notification.status;
                    devPrint('🔔 Permission status: $status');
                    
                    // If permanently denied, only show dialog after trying to request
                    // (in case user enabled it in settings but permission_handler hasn't updated)
                    if (!status.isPermanentlyDenied) {
                      // Try requesting permission
                      await _notificationService.requestNotificationPermissions();
                    }
                    
                    // Check again after potential request
                    final stillDisabled = !(await _notificationService.areNotificationsEnabled());
                    final finalStatus = await Permission.notification.status;
                    
                    devPrint('🔔 Final check - Enabled: ${!stillDisabled}, Status: $finalStatus');
                    
                    // If notifications are now enabled
                    if (!stillDisabled) {
                      if (!mounted) return;
                      devPrint('✅ Notifications enabled successfully');
                    } else {
                      // Notifications remain disabled - flip switch back off
                      if (mounted) {
                        setState(() {
                          isReminderEnabled = false;
                        });
                      }
                      
                      // Only show settings dialog if:
                      // 1. Notifications are still disabled according to system check, AND
                      // 2. Permission is permanently denied (can't request anymore)
                      if (finalStatus.isPermanentlyDenied && mounted) {
                        _showOpenSettingsDialog();
                      } else if (!finalStatus.isPermanentlyDenied && mounted) {
                        // Notifications disabled but not permanently denied - user might need to grant permission
                        devPrint('⚠️ Notifications disabled but permission can still be requested');
                      }
                      return; // Return early to avoid leaving UI in inconsistent state
                    }
                  } catch (e) {
                    devPrint('❌ Error requesting notification permissions: $e');
                  }
                }
              }),
           /*   _buildSwitchTile('Fill-up Pillbox', isFillUpPillboxEnabled, (value) {
                setState(() {
                  isFillUpPillboxEnabled = value;
                });
              }),

              // Notification Sound Selection
              if (isReminderEnabled) ...[
                SizedBox(height: 20),
                Text(
                  'Notification Sound',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: _notificationSounds.map((sound) {
                      final isSelected = _selectedSound?.name == sound.name;
                      return ListTile(
                        title: Text(sound.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Preview button
                            if (sound.assetPath.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.play_circle_outline),
                                onPressed: () => _playSound(sound),
                              ),
                            // Selection indicator
                            Radio<String>(
                              value: sound.name,
                              groupValue: _selectedSound?.name,
                              onChanged: (value) {
                                _saveSelectedSound(sound);
                              },
                              activeColor: Colors.pink[300],
                            ),
                          ],
                        ),
                        onTap: () {
                          _saveSelectedSound(sound);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],*/
              SizedBox(height: 30),
              // Help Section
              Text(
                'Help',
                style: AppTokens.textStyleLarge.copyWith(
                  color: AppTokens.textSecondary,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Get in touch', style: AppTokens.textStyleMedium),
                trailing: HugeIcon(
                  icon: HugeIcons.strokeRoundedHelpCircle,
                  size: 24,
                  strokeWidth: 1,
                  color: AppTokens.iconPrimary,
                ),
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'zoe@doubl.one',
                    query: 'subject=PinkRain%20App%20Support',
                  );
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Could not launch email client')),
                      );
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error launching email: $e')),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  const inviteUri = 'https://apps.apple.com/us/app/pinkrain/id6752828584';
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    // Load the asset image as XFile
                    final imageFile = await _loadAssetAsXFile(
                      'assets/icons/splash-icon.png',
                      'pinkrain_icon.png'
                    );
                    
                    // Prepare share parameters
                    final shareText = "I've been using PinkRain to track my wellness and journaling."
                        "\nIt's actually really helpful! Check it out! \n$inviteUri\n"
                        "\nBtw no worries, it's privacy first so all data is stored locally on your device and never leaves your phone.";
                    
                    if (imageFile != null) {
                      // Share with image file
                      await SharePlus.instance.share(ShareParams(
                        files: [imageFile],
                        text: shareText,
                        subject: 'You gotta check out PinkRain',
                      ));
                    } else {
                      // Fallback to text-only sharing if image loading fails
                      await SharePlus.instance.share(ShareParams(
                        text: shareText,
                        subject: 'You gotta check out PinkRain',
                      ));
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error sending invite: $e')),
                    );
                  }
                },
                title: Text('Invite a Friend or Family Member', 
                  style: AppTokens.textStyleMedium),
                trailing: HugeIcon(
                  icon: HugeIcons.strokeRoundedMailOpenLove,
                  size: 24,
                  strokeWidth: 1,
                  color: AppTokens.iconPrimary,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  final Uri privacyUri = Uri.parse('https://rain.pink/privacy');
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    if (await canLaunchUrl(privacyUri)) {
                      await launchUrl(privacyUri, mode: LaunchMode.externalApplication);
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Could not launch privacy policy')),
                      );
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error launching privacy policy: $e')),
                    );
                  }
                },
                title: Text('Privacy Policy', style: AppTokens.textStyleMedium),
                trailing: HugeIcon(
                  icon: HugeIcons.strokeRoundedSecurityLock,
                  size: 24,
                  strokeWidth: 1,
                  color: AppTokens.iconPrimary,
                ),
              ),
              _buildHelpTile('Delete All Data'),
              SizedBox(height: 30),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "🔒 Your privacy is important to us; all your data remains securely stored on your device, never sent to our servers 🕊️",
                    textAlign: TextAlign.center,
                    style: AppTokens.textStyleSmall.copyWith(
                      fontWeight: AppTokens.fontWeightNormal,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
              ),
            ),
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: buildBottomNavigationBar(context: context, currentRoute: 'profile'),
    );
  }

  // Switch Tile for Notifications
  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTokens.textStyleMedium),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: (newValue) async {
          await onChanged(newValue);
        },
        activeTrackColor: AppColors.pink100,
      ),
    );
  }

  // Help Tile (Get in Touch, Privacy Policy)
  Widget _buildHelpTile(String title) {
    final bool isDelete = title == 'Delete All Data';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: AppTokens.textStyleMedium.copyWith(
            color: isDelete ? AppTokens.stateError : null,
          )
      ),
      trailing: isDelete ? null: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 24,
        strokeWidth: 1,
        color: AppTokens.iconPrimary,
      ),
      onTap: isDelete ? () => _showDeleteAllDataModal() : () {},
    );
  }

  // Show bottom modal for delete all data confirmation
  void _showDeleteAllDataModal() {
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
                    'Delete All Data',
                    style: AppTokens.textStyleXLarge.copyWith(
                      color: AppTokens.stateError,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Message
                  Text(
                    'This action cannot be undone.\n\n'
                    'All your data will be permanently deleted from your device, including:\n'
                    '• Mood entries\n'
                    '• Symptom data\n'
                    '• Medication logs\n'
                    '• Treatments\n'
                    '• Pillbox data\n'
                    '• User preferences',
                    style: AppTokens.textStyleMedium.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    child: Button.destructive(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        navigator.pop(); // Close modal first
                        
                        if (!mounted) return;
                        final navigatorState = Navigator.of(context);
                        
                        // Show loading indicator
                        if (mounted) {
                          showCupertinoDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const CupertinoAlertDialog(
                              content: Padding(
                                padding: EdgeInsets.only(top: 20.0),
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                          );
                        }
                        
                        try {
                          // Cancel all scheduled notifications
                          final scheduler = MedicationSchedulerService();
                          await scheduler.cancelAllNotifications();
                          
                          // Delete all Hive data
                          await HiveService.deleteAllData();
                          
                          // Delete disclaimer data
                          await DisclaimerService.deleteAllData();
                          
                          // Clear the name from controller
                          _nameController.clear();
                          
                          // Close loading dialog
                          if (!mounted) return;
                          navigatorState.pop();
                          
                          // Show success message and navigate
                          if (!mounted) return;
                          showCupertinoDialog(
                            context: this.context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Data Deleted'),
                              content: const Text(
                                'All your data has been permanently deleted from your device.',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () {
                                    navigatorState.pop();
                                    if (!mounted) return;
                                    // Navigate to a fresh start (could be wellness or splash)
                                    context.go('/wellness');
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          devPrint('❌ Error deleting data: $e');
                          // Close loading dialog
                          if (!mounted) return;
                          navigatorState.pop();
                          
                          // Show error message
                          if (!mounted) return;
                          showCupertinoDialog(
                            context: this.context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Error'),
                              content: Text('Failed to delete data: $e'),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () {
                                    navigatorState.pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      text: 'Delete All Data',
                      size: ButtonSize.large,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: Button.secondary(
                      onPressed: () => Navigator.of(context).pop(),
                      text: 'Cancel',
                      size: ButtonSize.large,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Show dialog to guide user to settings when permission is permanently denied
  void _showOpenSettingsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Notifications Disabled'),
        content: const Text(
          'Notifications are required for medication reminders. '
          'Please enable notifications in your device settings.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.of(context).pop();
              // Open app settings
              await openAppSettings();
            },
            isDefaultAction: true,
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
