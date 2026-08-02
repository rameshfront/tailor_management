import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../utils/validators.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;
  bool _isSaving = false;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _mobileCtrl = TextEditingController(text: c?.mobile ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<CustomerProvider>();

    // Check duplicate phone
    final mobile = _mobileCtrl.text.trim();
    final isDuplicate = await provider.isMobileDuplicate(
      mobile,
      excludeId: widget.customer?.id,
    );
    if (isDuplicate && mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A customer with this phone number already exists.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final customer = Customer(
      id: widget.customer?.id,
      name: _nameCtrl.text.trim(),
      mobile: mobile,
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.customer?.createdAt ??
          DateTime.now().toIso8601String(),
    );

    try {
      if (_isEditing) {
        await provider.updateCustomer(customer);
      } else {
        await provider.addCustomer(customer);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Customer updated successfully'
                : 'Customer added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Customer' : 'New Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              context,
              title: 'Personal Information',
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, fieldName: 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mobileCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                    prefixText: '+91 ',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Additional Details',
              children: [
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'Any special notes about this customer',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Update Customer' : 'Add Customer'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
