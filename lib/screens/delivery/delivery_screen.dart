import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class DeliveryScreen extends StatefulWidget {
  final Order order;

  const DeliveryScreen({super.key, required this.order});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _balanceCtrl;
  String _paymentMethod = AppConstants.paymentCash;
  bool _fullPayment = false;
  DateTime _deliveryDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _balanceCtrl = TextEditingController(
      text: widget.order.balanceAmount > 0
          ? widget.order.balanceAmount.toStringAsFixed(2)
          : '0.00',
    );
  }

  @override
  void dispose() {
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _onFullPaymentToggle(bool val) {
    setState(() {
      _fullPayment = val;
      if (val) {
        _balanceCtrl.text =
            widget.order.balanceAmount.toStringAsFixed(2);
      }
    });
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final balancePaid = double.tryParse(_balanceCtrl.text) ?? 0.0;

    await context.read<OrderProvider>().markDelivered(
          orderId: widget.order.id!,
          balancePaid: balancePaid,
          paymentMethod: _paymentMethod,
          deliveryDate: _deliveryDate.toIso8601String(),
        );

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as delivered!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<SettingsProvider>().currency;
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order summary card
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Summary',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 12),
                    _SummaryRow(
                        label: 'Order',
                        value: order.orderNumber),
                    _SummaryRow(
                        label: 'Customer',
                        value: order.customerName ?? '-'),
                    _SummaryRow(
                        label: 'Dress',
                        value:
                            '${order.dressType} — ${order.dressName}'),
                    const Divider(),
                    _SummaryRow(
                      label: 'Total Amount',
                      value: Helpers.formatCurrency(
                          order.totalAmount, currency),
                    ),
                    _SummaryRow(
                      label: 'Amount Paid',
                      value: Helpers.formatCurrency(
                          order.advanceAmount, currency),
                    ),
                    _SummaryRow(
                      label: 'Balance Due',
                      value: Helpers.formatCurrency(
                          order.balanceAmount, currency),
                      bold: true,
                      valueColor: order.balanceAmount > 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment collection
            _sectionTitle(context, 'Collect Payment'),
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
                    SwitchListTile(
                      title: const Text('Full Payment Received'),
                      subtitle: const Text(
                          'Toggle to auto-fill the balance amount'),
                      value: _fullPayment,
                      onChanged: order.balanceAmount > 0
                          ? _onFullPaymentToggle
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _balanceCtrl,
                      decoration: InputDecoration(
                        labelText: 'Amount Collected ($currency)',
                        prefixIcon:
                            const Icon(Icons.payments_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      validator: Validators.amount,
                    ),
                    const SizedBox(height: 16),

                    // Payment method
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Payment Method',
                          style: theme.textTheme.labelLarge),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: AppConstants.paymentMethods
                          .map((method) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 8),
                                  child: ChoiceChip(
                                    label: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _methodIcon(method),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(method),
                                      ],
                                    ),
                                    selected:
                                        _paymentMethod == method,
                                    onSelected: (_) => setState(
                                        () =>
                                            _paymentMethod = method),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Delivery date
            _sectionTitle(context, 'Delivery Details'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Delivery Date'),
                subtitle: Text(Helpers.formatDate(_deliveryDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deliveryDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _deliveryDate = picked);
                  }
                },
              ),
            ),

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _isSaving ? null : _confirm,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.local_shipping_outlined),
              label: const Text('Mark as Delivered'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.green,
              ),
            ),
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

  IconData _methodIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money_outlined;
      case 'UPI':
        return Icons.phone_android_outlined;
      case 'Card':
        return Icons.credit_card_outlined;
      default:
        return Icons.payment_outlined;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
