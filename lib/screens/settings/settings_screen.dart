import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
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
  bool _isClearingCache = false;
  String _cacheSizeStr = 'Calculating...';

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _shopNameCtrl = TextEditingController(text: settings.shopName);
    _ownerNameCtrl = TextEditingController(text: settings.ownerName);
    _phoneCtrl = TextEditingController(text: settings.phone);
    _addressCtrl = TextEditingController(text: settings.address);
    _currency = settings.currency;
    _calculateCacheSize();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalBytes = 0;
      if (tempDir.existsSync()) {
        final files = tempDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            totalBytes += await file.length();
          }
        }
      }
      if (mounted) {
        setState(() {
          if (totalBytes < 1024) {
            _cacheSizeStr = '$totalBytes B';
          } else if (totalBytes < 1024 * 1024) {
            _cacheSizeStr = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
          } else {
            _cacheSizeStr = '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cacheSizeStr = '0 KB');
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Clear Cache'),
          ],
        ),
        content: const Text(
          'This will clear temporary files and image cache to free up memory and storage. Your saved customer records, measurements, and orders will NOT be affected.\n\nProceed to clear cache?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Now'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isClearingCache = true);

    try {
      // 1. Clear Flutter image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 2. Clear temp directory
      int deletedCount = 0;
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final files = tempDir.listSync(recursive: true);
        for (final file in files) {
          try {
            if (file is File) {
              file.deleteSync();
              deletedCount++;
            }
          } catch (_) {}
        }
      }

      await _calculateCacheSize();

      if (mounted) {
        setState(() => _isClearingCache = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'App cache cleared successfully! ($deletedCount files freed)',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClearingCache = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Shop settings updated successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
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
          'This will replace ALL current data with the selected backup file. This cannot be undone. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
          if (mounted) {
            await context.read<OrderProvider>().loadOrders();
            await context.read<OrderProvider>().loadDashboardStats();
            await context.read<CustomerProvider>().loadCustomers();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Database restored successfully! All records refreshed.'),
                backgroundColor: Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
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
        title: const Text(
          'Settings & Shop Info',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Shop Info Section
            _sectionTitle(context, 'Shop Information / கடை விவரங்கள்'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _shopNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Shop Name (கடை பெயர்) *',
                        prefixIcon: Icon(Icons.store_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. G Tailoring',
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
                        labelText: 'Proprietor / Owner Name (உரிமையாளர் பெயர்)',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Gunaseelan',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cell / Phone Number (தொலைபேசி எண்)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. 80983 78746',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Shop Address (முகவரி)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. East Street, Palliyagraharam, Thanjavur.',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Storage & Cache Section
            _sectionTitle(context, 'Storage & Cache / தற்காலிக நினைவகம்'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.cached_outlined,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'App Cache Size',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Temporary cache: $_cacheSizeStr',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isClearingCache ? null : _clearCache,
                          icon: _isClearingCache
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cleaning_services_outlined, size: 16),
                          label: const Text('Clear Cache'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade800,
                            side: BorderSide(color: Colors.orange.shade300),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clearing cache flushes temporary images and cache files to speed up the app and save storage. Your database orders remain completely safe.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Data & Backup Section
            _sectionTitle(context, 'Database Backup & Restore / காப்புப்பிரதி'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.upload_outlined, color: Colors.blue),
                    ),
                    title: const Text('Export Database (Backup)'),
                    subtitle: const Text(
                      'Save & share a full backup of all orders and customers',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _exportBackup,
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.download_outlined, color: Colors.deepOrange),
                    ),
                    title: const Text('Import Database (Restore)'),
                    subtitle: const Text(
                      'Restore records from a previously exported backup file',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _importBackup,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Currency & Appearance
            _sectionTitle(context, 'Preferences / விருப்பங்கள்'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
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
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text(
                'Save Settings / அமைப்புகளை சேமி',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: const Color(0xFF5C3D11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
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
