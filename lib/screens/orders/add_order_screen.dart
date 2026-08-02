import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/measurement.dart';
import '../../models/order.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/measurement_form.dart';
import '../customers/add_customer_screen.dart';

class AddOrderScreen extends StatefulWidget {
  final Order? order;

  const AddOrderScreen({super.key, this.order});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  late final TextEditingController _orderNumCtrl;
  late final TextEditingController _dressNameCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _advanceCtrl;

  Customer? _selectedCustomer;
  String _dressType = AppConstants.dressTypes.first;
  String _orderStatus = AppConstants.statusPending;
  String _paymentStatus = AppConstants.paymentPending;
  DateTime _orderDate = DateTime.now();
  DateTime? _deliveryDate;

  String? _clothPhoto;
  String? _referencePhoto;
  String? _finishedPhoto;

  Measurement _measurement = const Measurement(orderId: 0);
  bool _isSaving = false;

  bool get _isEditing => widget.order != null;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _orderNumCtrl = TextEditingController(
      text: o?.orderNumber ?? Helpers.generateOrderNumber(),
    );
    _dressNameCtrl = TextEditingController(text: o?.dressName ?? '');
    _quantityCtrl =
        TextEditingController(text: o?.quantity.toString() ?? '1');
    _notesCtrl = TextEditingController(text: o?.notes ?? '');
    _totalCtrl =
        TextEditingController(text: o?.totalAmount.toStringAsFixed(2) ?? '');
    _advanceCtrl = TextEditingController(
        text: o?.advanceAmount.toStringAsFixed(2) ?? '0.00');

    if (o != null) {
      _dressType = o.dressType;
      _orderStatus = o.orderStatus;
      _paymentStatus = o.paymentStatus;
      _orderDate = DateTime.parse(o.orderDate);
      _deliveryDate =
          o.deliveryDate != null ? DateTime.parse(o.deliveryDate!) : null;
      _clothPhoto = o.clothPhoto;
      _referencePhoto = o.referencePhoto;
      _finishedPhoto = o.finishedPhoto;
      if (o.measurement != null) _measurement = o.measurement!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerProvider>().loadCustomers();
      if (o != null) {
        // Pre-select customer
        final c = context.read<CustomerProvider>().getById(o.customerId);
        if (c != null) setState(() => _selectedCustomer = c);
      }
    });
  }

  @override
  void dispose() {
    _orderNumCtrl.dispose();
    _dressNameCtrl.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    _totalCtrl.dispose();
    _advanceCtrl.dispose();
    super.dispose();
  }

  double get _balance {
    final total = double.tryParse(_totalCtrl.text) ?? 0;
    final advance = double.tryParse(_advanceCtrl.text) ?? 0;
    return total - advance;
  }

  Future<void> _pickImage(String type) async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (img != null && mounted) {
                  setState(() {
                    if (type == 'cloth') _clothPhoto = img.path;
                    if (type == 'reference') _referencePhoto = img.path;
                    if (type == 'finished') _finishedPhoto = img.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (img != null && mounted) {
                  setState(() {
                    if (type == 'cloth') _clothPhoto = img.path;
                    if (type == 'reference') _referencePhoto = img.path;
                    if (type == 'finished') _finishedPhoto = img.path;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final order = Order(
      id: widget.order?.id,
      orderNumber: _orderNumCtrl.text.trim(),
      customerId: _selectedCustomer!.id!,
      orderDate: _orderDate.toIso8601String(),
      deliveryDate: _deliveryDate?.toIso8601String(),
      dressType: _dressType,
      dressName: _dressNameCtrl.text.trim(),
      quantity: int.tryParse(_quantityCtrl.text) ?? 1,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      clothPhoto: _clothPhoto,
      referencePhoto: _referencePhoto,
      finishedPhoto: _finishedPhoto,
      totalAmount: double.tryParse(_totalCtrl.text) ?? 0,
      advanceAmount: double.tryParse(_advanceCtrl.text) ?? 0,
      paymentStatus: _paymentStatus,
      orderStatus: _orderStatus,
      createdAt: widget.order?.createdAt ?? DateTime.now().toIso8601String(),
    );

    try {
      final provider = context.read<OrderProvider>();
      if (_isEditing) {
        await provider.updateOrder(order, _measurement);
      } else {
        await provider.addOrder(order, _measurement);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Order updated successfully'
                : 'Order created successfully'),
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
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<SettingsProvider>().currency;
    final customers = context.watch<CustomerProvider>().allCustomers;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Order' : 'New Order',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
            // Order info
            _sectionTitle(context, 'Order Information'),
            _card(context, [
              TextFormField(
                controller: _orderNumCtrl,
                readOnly: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Order Number',
                  prefixIcon: Icon(Icons.tag_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Customer picker
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'Customer *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: customers
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.name} (${c.mobile})'),
                              ))
                          .toList(),
                      onChanged: (c) =>
                          setState(() => _selectedCustomer = c),
                      validator: (v) =>
                          v == null ? 'Select a customer' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddCustomerScreen(),
                        ),
                      );
                      if (mounted) {
                        await context
                            .read<CustomerProvider>()
                            .loadCustomers();
                      }
                    },
                    icon: const Icon(Icons.person_add_outlined),
                    tooltip: 'Add New Customer',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _orderDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _orderDate = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Order Date',
                          prefixIcon:
                              Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(Helpers.formatDate(_orderDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _deliveryDate ??
                              DateTime.now()
                                  .add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) {
                          setState(() => _deliveryDate = d);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Delivery Date',
                          prefixIcon:
                              Icon(Icons.event_available_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _deliveryDate != null
                              ? Helpers.formatDate(_deliveryDate!)
                              : 'Select date',
                          style: TextStyle(
                            color: _deliveryDate == null
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 16),
            _sectionTitle(context, 'Dress Details'),
            _card(context, [
              DropdownButtonFormField<String>(
                value: _dressType,
                decoration: const InputDecoration(
                  labelText: 'Dress Type *',
                  prefixIcon: Icon(Icons.checkroom_outlined),
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.dressTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _dressType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dressNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dress Name / Description *',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    Validators.required(v, fieldName: 'Dress name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  prefixIcon: Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.quantity,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes / Special Instructions',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
            ]),

            const SizedBox(height: 16),
            _sectionTitle(context, 'Measurements'),
            _card(context, [
              MeasurementForm(
                initial: _measurement,
                onChanged: (m) => _measurement = m,
              ),
            ]),

            const SizedBox(height: 16),
            _sectionTitle(context, 'Photos'),
            _card(context, [
              Row(
                children: [
                  Expanded(
                    child: _PhotoPicker(
                      label: 'Cloth',
                      path: _clothPhoto,
                      onTap: () => _pickImage('cloth'),
                      onRemove: () =>
                          setState(() => _clothPhoto = null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PhotoPicker(
                      label: 'Reference',
                      path: _referencePhoto,
                      onTap: () => _pickImage('reference'),
                      onRemove: () =>
                          setState(() => _referencePhoto = null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PhotoPicker(
                      label: 'Finished',
                      path: _finishedPhoto,
                      onTap: () => _pickImage('finished'),
                      onRemove: () =>
                          setState(() => _finishedPhoto = null),
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 16),
            _sectionTitle(context, 'Payment Details'),
            _card(context, [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalCtrl,
                      decoration: InputDecoration(
                        labelText: 'Total Amount ($currency) *',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          Validators.amount(v, required: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _advanceCtrl,
                      decoration: InputDecoration(
                        labelText: 'Advance ($currency)',
                        prefixIcon:
                            const Icon(Icons.account_balance_wallet_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: Validators.amount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _balance < 0
                      ? Colors.red.withOpacity(0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance Amount:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      Helpers.formatCurrency(_balance < 0 ? 0 : _balance, currency),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _balance < 0
                            ? Colors.red
                            : theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Payment Status',
                  prefixIcon: Icon(Icons.payment_outlined),
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.paymentStatuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _paymentStatus = v!),
              ),
            ]),

            const SizedBox(height: 16),
            _sectionTitle(context, 'Order Status'),
            _card(context, [
              Wrap(
                spacing: 8,
                children: AppConstants.orderStatuses.map((status) {
                  return ChoiceChip(
                    label: Text(status),
                    selected: _orderStatus == status,
                    onSelected: (_) =>
                        setState(() => _orderStatus = status),
                  );
                }).toList(),
              ),
            ]),

            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Update Order' : 'Create Order'),
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

  Widget _card(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String label;
  final String? path;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoPicker({
    required this.label,
    this.path,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              border: Border.all(
                  color: theme.colorScheme.outlineVariant, width: 1.5),
              borderRadius: BorderRadius.circular(10),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: path != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(
                      File(path!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : const Center(
                    child: Icon(Icons.add_photo_alternate_outlined,
                        size: 32)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center),
        if (path != null)
          GestureDetector(
            onTap: onRemove,
            child: const Text('Remove',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    decoration: TextDecoration.underline)),
          ),
      ],
    );
  }
}
