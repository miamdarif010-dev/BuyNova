// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    _showMessage(
      context,
      'Account deletion will be connected later.',
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return ValueListenableBuilder<String>(
          valueListenable: AppSettings.language,
          builder: (context, language, child) {
            return AlertDialog(
              title: const Text('Language'),
              content: RadioGroup<String>(
                groupValue: language,
                onChanged: (value) {
                  if (value == null) return;

                  AppSettings.setLanguage(value);
                  Navigator.pop(dialogContext);
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      value: 'English',
                      title: Text('English'),
                    ),
                    RadioListTile<String>(
                      value: 'বাংলা',
                      title: Text('বাংলা'),
                    ),
                    RadioListTile<String>(
                      value: '한국어',
                      title: Text('한국어'),
                    ),
                  ],
                ),
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
      builder: (dialogContext) {
        return ValueListenableBuilder<String>(
          valueListenable: AppSettings.currency,
          builder: (context, currency, child) {
            return AlertDialog(
              title: const Text('Currency'),
              content: RadioGroup<String>(
                groupValue: currency,
                onChanged: (value) {
                  if (value == null) return;

                  AppSettings.setCurrency(value);
                  Navigator.pop(dialogContext);
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      value: 'KRW',
                      title: Text('₩ Korean Won'),
                    ),
                    RadioListTile<String>(
                      value: 'BDT',
                      title: Text('৳ Bangladeshi Taka'),
                    ),
                    RadioListTile<String>(
                      value: 'USD',
                      title: Text('\$ US Dollar'),
                    ),
                    RadioListTile<String>(
                      value: 'INR',
                      title: Text('₹ Indian Rupee'),
                    ),
                    RadioListTile<String>(
                      value: 'EUR',
                      title: Text('€ Euro'),
                    ),
                  ],
                ),
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
      builder: (dialogContext) {
        return ValueListenableBuilder<String>(
          valueListenable: AppSettings.videoQuality,
          builder: (context, quality, child) {
            return AlertDialog(
              title: const Text('Video Quality'),
              content: RadioGroup<String>(
                groupValue: quality,
                onChanged: (value) {
                  if (value == null) return;

                  AppSettings.setVideoQuality(value);
                  Navigator.pop(dialogContext);
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      value: 'Auto',
                      title: Text('Auto'),
                    ),
                    RadioListTile<String>(
                      value: 'Low',
                      title: Text('Low'),
                    ),
                    RadioListTile<String>(
                      value: 'Medium',
                      title: Text('Medium'),
                    ),
                    RadioListTile<String>(
                      value: 'High',
                      title: Text('High'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          // =====================================================
          // GENERAL
          // =====================================================

          const _SectionTitle(
            icon: Icons.tune,
            title: 'General',
          ),

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
                  AppSettings.setNotifications(newValue);
                },
              );
            },
          ),

          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppSettings.themeMode,
            builder: (context, themeMode, child) {
              final isDark = themeMode == ThemeMode.dark;

              return SwitchListTile(
                secondary: Icon(
                  isDark
                      ? Icons.dark_mode
                      : Icons.light_mode_outlined,
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(
                  isDark
                      ? 'Dark theme is enabled'
                      : 'Use light theme',
                ),
                value: isDark,
                onChanged: (value) {
                  AppSettings.setDarkMode(value);
                },
              );
            },
          ),

          ValueListenableBuilder<String>(
            valueListenable: AppSettings.language,
            builder: (context, language, child) {
              return ListTile(
                leading: const Icon(
                  Icons.language_outlined,
                ),
                title: const Text('Language'),
                subtitle: Text(language),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  _showLanguageDialog(context);
                },
              );
            },
          ),

          ValueListenableBuilder<String>(
            valueListenable: AppSettings.currency,
            builder: (context, currency, child) {
              String currencyName;

              switch (currency) {
                case 'BDT':
                  currencyName = '৳ Bangladeshi Taka';
                  break;
                case 'USD':
                  currencyName = '\$ US Dollar';
                  break;
                case 'INR':
                  currencyName = '₹ Indian Rupee';
                  break;
                case 'EUR':
                  currencyName = '€ Euro';
                  break;
                case 'KRW':
                default:
                  currencyName = '₩ Korean Won';
              }

              return ListTile(
                leading: const Icon(
                  Icons.currency_exchange,
                ),
                title: const Text('Currency'),
                subtitle: Text(currencyName),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  _showCurrencyDialog(context);
                },
              );
            },
          ),

          // =====================================================
          // SHOPPING
          // =====================================================

          const _SectionTitle(
            icon: Icons.shopping_bag_outlined,
            title: 'Shopping',
          ),

          ListTile(
            leading: const Icon(
              Icons.local_shipping_outlined,
            ),
            title: const Text('Delivery Preferences'),
            subtitle: const Text(
              'Manage delivery options',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Delivery Preferences will be connected later.',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
            ),
            title: const Text('Shopping Location'),
            subtitle: const Text(
              'Set your preferred delivery location',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Shopping Location will be connected later.',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.local_offer_outlined,
            ),
            title: const Text('Coupons'),
            subtitle: const Text(
              'Manage your coupons',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Coupons will be connected later.',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.favorite_border,
            ),
            title: const Text('Favorites'),
            subtitle: const Text(
              'Manage favorite products',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Favorites will be connected later.',
              );
            },
          ),

          // =====================================================
          // VIDEOS
          // =====================================================

          const _SectionTitle(
            icon: Icons.video_library_outlined,
            title: 'Videos',
          ),

          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.autoPlayVideos,
            builder: (context, value, child) {
              return SwitchListTile(
                secondary: const Icon(
                  Icons.play_circle_outline,
                ),
                title: const Text('Auto Play Videos'),
                subtitle: const Text(
                  'Automatically play videos',
                ),
                value: value,
                onChanged: (newValue) {
                  AppSettings.setAutoPlayVideos(newValue);
                },
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.videoSound,
            builder: (context, value, child) {
              return SwitchListTile(
                secondary: const Icon(
                  Icons.volume_up_outlined,
                ),
                title: const Text('Video Sound'),
                subtitle: const Text(
                  'Play sound automatically',
                ),
                value: value,
                onChanged: (newValue) {
                  AppSettings.setVideoSound(newValue);
                },
              );
            },
          ),

          ValueListenableBuilder<String>(
            valueListenable: AppSettings.videoQuality,
            builder: (context, quality, child) {
              return ListTile(
                leading: const Icon(
                  Icons.high_quality_outlined,
                ),
                title: const Text('Video Quality'),
                subtitle: Text(quality),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  _showVideoQualityDialog(context);
                },
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.dataSaver,
            builder: (context, value, child) {
              return SwitchListTile(
                secondary: const Icon(
                  Icons.data_saver_on_outlined,
                ),
                title: const Text('Data Saver'),
                subtitle: const Text(
                  'Reduce mobile data usage',
                ),
                value: value,
                onChanged: (newValue) {
                  AppSettings.setDataSaver(newValue);
                },
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.reduceMotion,
            builder: (context, value, child) {
              return SwitchListTile(
                secondary: const Icon(
                  Icons.animation_outlined,
                ),
                title: const Text('Reduce Motion'),
                subtitle: const Text(
                  'Reduce animations in the app',
                ),
                value: value,
                onChanged: (newValue) {
                  AppSettings.setReduceMotion(newValue);
                },
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.vibration,
            builder: (context, value, child) {
              return SwitchListTile(
                secondary: const Icon(
                  Icons.vibration_outlined,
                ),
                title: const Text('Vibration'),
                subtitle: const Text(
                  'Use vibration for interactions',
                ),
                value: value,
                onChanged: (newValue) {
                  AppSettings.setVibration(newValue);
                },
              );
            },
          ),

          // =====================================================
          // ACCOUNT & SECURITY
          // =====================================================

          const _SectionTitle(
            icon: Icons.security_outlined,
            title: 'Account & Security',
          ),

          if (user != null)
            ListTile(
              leading: const Icon(
                Icons.lock_outline,
              ),
              title: const Text('Change Password'),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                _showMessage(
                  context,
                  'Change Password will be connected later.',
                );
              },
            ),

          if (user != null)
            ListTile(
              leading: const Icon(
                Icons.email_outlined,
              ),
              title: const Text('Email Address'),
              subtitle: Text(
                user.email ?? 'Not available',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                _showMessage(
                  context,
                  'Email settings will be connected later.',
                );
              },
            ),

          if (user != null)
            ListTile(
              leading: const Icon(
                Icons.phone_outlined,
              ),
              title: const Text('Phone Number'),
              subtitle: const Text(
                'Manage phone number',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                _showMessage(
                  context,
                  'Phone settings will be connected later.',
                );
              },
            ),

          if (user != null)
            ListTile(
              leading: const Icon(
                Icons.login_outlined,
              ),
              title: const Text('Login & Security'),
              subtitle: const Text(
                'Manage login and security',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                _showMessage(
                  context,
                  'Login & Security will be connected later.',
                );
              },
            ),

          if (user != null)
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
              ),
              title: const Text('Delete Account'),
              subtitle: const Text(
                'Permanently delete your account',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                _deleteAccount(context);
              },
            ),

          // =====================================================
          // PRIVACY
          // =====================================================

          const _SectionTitle(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
          ),

          ListTile(
            leading: const Icon(
              Icons.visibility_outlined,
            ),
            title: const Text('Privacy Settings'),
            subtitle: const Text(
              'Control your privacy',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Privacy Settings will be connected later.',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.block_outlined,
            ),
            title: const Text('Blocked Users'),
            subtitle: const Text(
              'Manage blocked users',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Blocked Users will be connected later.',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.perm_media_outlined,
            ),
            title: const Text('Media Permissions'),
            subtitle: const Text(
              'Manage photo and video permissions',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Media Permissions will be connected later.',
              );
            },
          ),

          // =====================================================
          // HELP & SUPPORT
          // =====================================================

          const _SectionTitle(
            icon: Icons.help_outline,
            title: 'Help & Support',
          ),

          ListTile(
            leading: const Icon(
              Icons.help_center_outlined,
            ),
            title: const Text('Help Center'),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Help Center will be connected later.',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.support_agent_outlined,
            ),
            title: const Text('Contact Support'),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Contact Support will be connected later.',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.report_problem_outlined,
            ),
            title: const Text('Report a Problem'),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Report a Problem will be connected later.',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.question_answer_outlined,
            ),
            title: const Text('FAQ'),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'FAQ will be connected later.',
              );
            },
          ),

          // =====================================================
          // ABOUT
          // =====================================================

          const _SectionTitle(
            icon: Icons.info_outline,
            title: 'About',
          ),

          ListTile(
            leading: const Icon(
              Icons.info_outline,
            ),
            title: const Text('About BuyNova'),
            subtitle: const Text(
              'BuyNova shopping platform',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'BuyNova',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    '© BuyNova',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.description_outlined,
            ),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Terms & Conditions will be connected later.',
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.policy_outlined,
            ),
            title: const Text('Privacy Policy'),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _showMessage(
                context,
                'Privacy Policy will be connected later.',
              );
            },
          ),

          // =====================================================
          // CLEAR TEMPORARY SETTINGS
          // =====================================================

          const _SectionTitle(
            icon: Icons.cleaning_services_outlined,
            title: 'Storage',
          ),

          ListTile(
            leading: const Icon(
              Icons.cleaning_services_outlined,
            ),
            title: const Text('Clear Temporary Settings'),
            subtitle: const Text(
              'Reset temporary video settings',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () async {
              await AppSettings.clearCache();

              if (!context.mounted) return;

              _showMessage(
                context,
                'Temporary settings cleared.',
              );
            },
          ),

          // =====================================================
          // LOGOUT
          // =====================================================

          if (user != null) ...[
            const Divider(
              height: 30,
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text('Logout'),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================
// SECTION TITLE
// =============================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
