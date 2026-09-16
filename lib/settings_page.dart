import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _deleteAccountConfirm(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This will permanently delete your account. '
            'This action cannot be undone. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Full account deletion will be connected later.',
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<String>(
          valueListenable: AppSettings.language,
          builder: (context, currentLanguage, child) {
            return AlertDialog(
              title: const Text('Language'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('English'),
                    value: 'English',
                    groupValue: currentLanguage,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setLanguage(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('বাংলা'),
                    value: 'বাংলা',
                    groupValue: currentLanguage,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setLanguage(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('한국어'),
                    value: '한국어',
                    groupValue: currentLanguage,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setLanguage(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<String>(
          valueListenable: AppSettings.currency,
          builder: (context, currentCurrency, child) {
            return AlertDialog(
              title: const Text('Currency'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('₩ Korean Won'),
                    value: 'KRW',
                    groupValue: currentCurrency,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setCurrency(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('\$ US Dollar'),
                    value: 'USD',
                    groupValue: currentCurrency,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setCurrency(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('৳ Bangladeshi Taka'),
                    value: 'BDT',
                    groupValue: currentCurrency,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setCurrency(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showVideoQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<String>(
          valueListenable: AppSettings.videoQuality,
          builder: (context, currentQuality, child) {
            return AlertDialog(
              title: const Text('Video Quality'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Auto'),
                    value: 'Auto',
                    groupValue: currentQuality,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setVideoQuality(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Low'),
                    value: 'Low',
                    groupValue: currentQuality,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setVideoQuality(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Medium'),
                    value: 'Medium',
                    groupValue: currentQuality,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setVideoQuality(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('High'),
                    value: 'High',
                    groupValue: currentQuality,
                    onChanged: (value) async {
                      if (value == null) return;

                      await AppSettings.setVideoQuality(value);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    await AppSettings.clearCache();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully.'),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required ValueNotifier<bool> notifier,
    required Future<void> Function(bool) onChanged,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, child) {
        return SwitchListTile(
          secondary: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          value: value,
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // =====================================================
          // 1. GENERAL
          // =====================================================

          _sectionHeader('GENERAL'),

          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: AppSettings.notifications,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_outlined,
                      ),
                      title: const Text('Notifications'),
                      subtitle: const Text(
                        'Receive BuyNova notifications',
                      ),
                      value: value,
                      onChanged: (newValue) {
                        AppSettings.setNotifications(
                          newValue,
                        );
                      },
                    );
                  },
                ),

                const Divider(height: 1),

                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppSettings.themeMode,
                  builder: (context, mode, child) {
                    final isDark =
                        mode == ThemeMode.dark;

                    return SwitchListTile(
                      secondary: const Icon(
                        Icons.dark_mode_outlined,
                      ),
                      title: const Text('Dark Mode'),
                      subtitle: const Text(
                        'Use dark appearance',
                      ),
                      value: isDark,
                      onChanged: (value) {
                        AppSettings.setDarkMode(
                          value,
                        );
                      },
                    );
                  },
                ),

                const Divider(height: 1),

                ValueListenableBuilder<String>(
                  valueListenable: AppSettings.language,
                  builder: (context, value, child) {
                    return _tile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: value,
                      onTap: () {
                        _showLanguageDialog(
                          context,
                        );
                      },
                    );
                  },
                ),

                const Divider(height: 1),

                ValueListenableBuilder<String>(
                  valueListenable: AppSettings.currency,
                  builder: (context, value, child) {
                    String text;

                    switch (value) {
                      case 'USD':
                        text = '\$ US Dollar';
                        break;
                      case 'BDT':
                        text = '৳ Bangladeshi Taka';
                        break;
                      default:
                        text = '₩ Korean Won';
                    }

                    return _tile(
                      icon: Icons.currency_exchange,
                      title: 'Currency',
                      subtitle: text,
                      onTap: () {
                        _showCurrencyDialog(
                          context,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // =====================================================
          // 2. VIDEO & MEDIA
          // =====================================================

          _sectionHeader('VIDEO & MEDIA'),

          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Column(
              children: [
                _settingSwitch(
                  icon: Icons.play_circle_outline,
                  title: 'Auto Play Videos',
                  subtitle:
                      'Automatically play videos when opened',
                  notifier:
                      AppSettings.autoPlayVideos,
                  onChanged:
                      AppSettings.setAutoPlayVideos,
                ),

                const Divider(height: 1),

                _settingSwitch(
                  icon: Icons.volume_up_outlined,
                  title: 'Video Sound',
                  subtitle:
                      'Enable sound when videos play',
                  notifier:
                      AppSettings.videoSound,
                  onChanged:
                      AppSettings.setVideoSound,
                ),

                const Divider(height: 1),

                _settingSwitch(
                  icon: Icons.vibration,
                  title: 'Vibration',
                  subtitle:
                      'Allow vibration feedback',
                  notifier:
                      AppSettings.vibration,
                  onChanged:
                      AppSettings.setVibration,
                ),

                const Divider(height: 1),

                _settingSwitch(
                  icon: Icons.data_saver_off,
                  title: 'Data Saver',
                  subtitle:
                      'Reduce mobile data usage',
                  notifier:
                      AppSettings.dataSaver,
                  onChanged:
                      AppSettings.setDataSaver,
                ),

                const Divider(height: 1),

                ValueListenableBuilder<String>(
                  valueListenable:
                      AppSettings.videoQuality,
                  builder: (context, value, child) {
                    return _tile(
                      icon: Icons.high_quality_outlined,
                      title: 'Video Quality',
                      subtitle: value,
                      onTap: () {
                        _showVideoQualityDialog(
                          context,
                        );
                      },
                    );
                  },
                ),

                const Divider(height: 1),

                _settingSwitch(
                  icon: Icons.animation_outlined,
                  title: 'Reduce Motion',
                  subtitle:
                      'Reduce animations in the app',
                  notifier:
                      AppSettings.reduceMotion,
                  onChanged:
                      AppSettings.setReduceMotion,
                ),

                const Divider(height: 1),

                _tile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear Cache',
                  subtitle:
                      'Reset temporary app settings',
                  onTap: () {
                    _clearCache(context);
                  },
                ),
              ],
            ),
          ),

          // =====================================================
          // 3. ACCOUNT & SECURITY
          // =====================================================

          _sectionHeader('ACCOUNT & SECURITY'),

          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password change will be connected next.',
                        ),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _tile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Email management will be connected next.',
                        ),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _tile(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Phone management will be connected next.',
                        ),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _tile(
                  icon: Icons.security_outlined,
                  title: 'Login & Security',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Login & Security will be connected next.',
                        ),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _tile(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () {
                    _deleteAccountConfirm(
                      context,
                    );
                  },
                ),

                const Divider(height: 1),

                _tile(
                  icon: Icons.logout,
                  title: 'Logout',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () {
                    _logout(context);
                  },
                ),
              ],
            ),
          ),

          // =====================================================
          // 4. PRIVACY
          // =====================================================

          _sectionHeader('PRIVACY'),

          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & Security',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Privacy & Security will be connected next.',
                        ),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _tile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Settings',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Privacy Settings will be connected next.',
                        ),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _tile(
                  icon: Icons.data_usage_outlined,
                  title: 'Data & Personalization',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Data & Personalization will be connected next.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // =====================================================
          // 5. HELP & SUPPORT
          // =====================================================

          _sectionHeader('HELP & SUPPORT'),

          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Help & Support will be added later.',
                        ),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _tile(
                  icon: Icons.quiz_outlined,
                  title: 'FAQ',
                  onTap: () {
                   
