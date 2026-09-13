import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  bool _notifications = true;
  String _language = 'English';
  String _currency = 'KRW';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _currency = prefs.getString('currency') ?? 'KRW';
    });
  }

  Future<void> _setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notifications', value);

    if (!mounted) return;

    setState(() {
      _notifications = value;
    });
  }

  Future<void> _selectLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Language'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'English'),
              child: const Text('English'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'বাংলা'),
              child: const Text('বাংলা'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, '한국어'),
              child: const Text('한국어'),
            ),
          ],
        );
      },
    );

    if (selected == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', selected);

    if (!mounted) return;

    setState(() {
      _language = selected;
    });
  }

  Future<void> _selectCurrency() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Currency'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'KRW'),
              child: const Text('₩ KRW - Korean Won'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'BDT'),
              child: const Text('৳ BDT - Bangladeshi Taka'),
            ),
          ],
        );
      },
    );

    if (selected == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', selected);

    if (!mounted) return;

    setState(() {
      _currency = selected;
    });
  }

  Widget _settingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'General Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Customize your BuyNova app experience.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          // 1. Notifications
          _settingCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: _notifications
                ? 'Notifications are enabled'
                : 'Notifications are disabled',
            trailing: Switch(
              value: _notifications,
              onChanged: _setNotifications,
            ),
          ),

          // 2. Dark Mode
          _settingCard(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Change BuyNova appearance',
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Dark Mode will be connected to the whole app next.',
                  ),
                ),
              );
            },
          ),

          // 3. Language
          _settingCard(
            icon: Icons.language,
            title: 'Language',
            subtitle: _language,
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: _selectLanguage,
          ),

          // 4. Currency
          _settingCard(
            icon: Icons.currency_exchange,
            title: 'Currency',
            subtitle: _currency == 'KRW'
                ? '₩ KRW - Korean Won'
                : '৳ BDT - Bangladeshi Taka',
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: _selectCurrency,
          ),
        ],
      ),
    );
  }
}
