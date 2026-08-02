import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDeliver;

  const OrderCard({
    super.key,
    required this.order,
    required this.currency,
    this.onTap,
    this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppColors.statusColor(order.orderStatus);
    final paymentColor = AppColors.paymentColor(order.paymentStatus);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(label: order.orderStatus, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'Unknown',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  _StatusBadge(label: order.paymentStatus, color: paymentColor),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.checkroom_outlined,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${order.dressType} • ${order.dressName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: order.deliveryDate != null
                        ? Helpers.formatDate(
                            DateTime.parse(order.deliveryDate!))
                        : 'No date',
                    color: order.deliveryDate != null &&
                            Helpers.isOverdue(order.deliveryDate) &&
                            !order.isDelivered
                        ? Colors.red
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Helpers.formatCurrency(order.totalAmount, currency),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (order.balanceAmount > 0)
                        Text(
                          'Bal: ${Helpers.formatCurrency(order.balanceAmount, currency)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red),
                        ),
                    ],
                  ),
                  if (order.orderStatus == AppConstants.statusReady &&
                      onDeliver != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onDeliver,
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      label: const Text('Deliver'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
