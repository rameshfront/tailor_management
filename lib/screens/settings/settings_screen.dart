import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  String _currency = AppConstants.defaultCurrency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _shopNameCtrl = TextEditingController(text: settings.shopName);
    _ownerNameCtrl = TextEditingController(text: settings.ownerName);
    _phoneCtrl = TextEditingController(text: settings.phone);
    _addressCtrl = TextEditingController(text: settings.address);
    _currency = settings.currency;
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await context.read<SettingsProvider>().updateSettings(
          shopName: _shopNameCtrl.text.trim(),
          ownerName: _ownerNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          currency: _currency,
        );
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _exportBackup() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting database...'),
            ],
          ),
        ),
      );
      final path = await BackupService.instance.exportDatabase();
      if (mounted) {
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(path)],
          text: 'Tailor Shop Database Backup',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Database'),
        content: const Text(
            'This will replace ALL current data with the backup. This cannot be undone. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace Data'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final success = await BackupService.instance.importDatabase();
      if (mounted) {
        if (success) {
          await context.read<SettingsProvider>().loadSettings();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import cancelled')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Shop Info
            _sectionTitle(context, 'Shop Information'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _shopNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Shop Name *',
                        prefixIcon: Icon(Icons.store_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Shop name is required'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Shop Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle(context, 'Currency'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Currency Symbol',
                    prefixIcon: Icon(Icons.currency_exchange_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: ['₹', '\$', '€', '£', '¥', '₺', '₦']
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('$c (${_currencyName(c)})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle(context, 'Appearance'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant),
              ),
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                secondary: Icon(
                  settings.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (_) =>
                    context.read<SettingsProvider>().toggleTheme(),
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle(context, 'Data & Backup'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_outlined,
                        color: Colors.blue),
                    title: const Text('Export Database'),
                    subtitle: const Text(
                        'Save a backup of all your data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _exportBackup,
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.download_outlined,
                        color: Colors.orange),
                    title: const Text('Import Database'),
                    subtitle: const Text(
                        'Restore from a previous backup'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _importBackup,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle(context, 'App Info'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    trailing: Text('1.0.0'),
                  ),
                  Divider(height: 0),
                  ListTile(
                    leading: Icon(Icons.storage_outlined),
                    title: Text('Database'),
                    subtitle: Text('SQLite (local, offline)'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Settings'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _currencyName(String symbol) {
    const names = {
      '₹': 'Indian Rupee',
      '\$': 'US Dollar',
      '€': 'Euro',
      '£': 'British Pound',
      '¥': 'Japanese Yen',
      '₺': 'Turkish Lira',
      '₦': 'Nigerian Naira',
    };
    return names[symbol] ?? symbol;
  }
}
