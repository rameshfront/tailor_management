import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../models/order.dart';
import '../providers/settings_provider.dart';
import '../services/pdf_service.dart';
import '../utils/helpers.dart';

/// Authentic tailor bill widget replicating the traditional physical bill pad
/// matching the G Tailoring bill design with red print on warm cream paper.
/// Dynamically updates with live Settings (shop name, owner, phone, address)
/// and accurately fetches and displays all customer order measurements.
class BillWidget extends StatelessWidget {
  final Order order;
  final String shopName;
  final String ownerName;
  final String phone;
  final String address;
  final String currency;

  const BillWidget({
    super.key,
    required this.order,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.currency,
  });

  static const Color inkRed = Color(0xFFB71C1C); // Deep red print ink
  static const Color inkRedDark = Color(0xFF8B0000);
  static const Color paperBg = Color(0xFFFFFBE8); // Classic pale cream bill pad paper
  static const Color borderRed = Color(0xFFC62828);

  static String _fmtVal(num? v) {
    if (v == null) return '';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      decoration: BoxDecoration(
        color: paperBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderRed, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ══════════════════════════════════════════════════════════════
            // 1. TOP SECTION: PANT MEASUREMENT & TAILORING DETAILS
            // ══════════════════════════════════════════════════════════════
            _buildPantMeasurementBox(),
            const SizedBox(height: 6),
            _buildPantDetailsRow(),
            const SizedBox(height: 8),

            // Perforated line
            _buildPerforatedLine(),
            const SizedBox(height: 8),

            // ══════════════════════════════════════════════════════════════
            // 2. MIDDLE SECTION: SHIRT MEASUREMENT & STITCHING DETAILS
            // ══════════════════════════════════════════════════════════════
            _buildShirtMeasurementBox(),
            const SizedBox(height: 6),
            _buildShirtDetailsRow(),
            const SizedBox(height: 8),

            // Complete measurement details table (displays all non-empty customer measurements)
            if (order.measurement != null && !order.measurement!.isEmpty) ...[
              _buildAllMeasurementsSummary(),
              const SizedBox(height: 8),
            ],

            // Perforated line
            _buildPerforatedLine(),
            const SizedBox(height: 8),

            // ══════════════════════════════════════════════════════════════
            // 3. BOTTOM SECTION: CUSTOMER BILL SLIP (DYNAMIC SHOP DETAILS)
            // ══════════════════════════════════════════════════════════════
            _buildBillHeader(),
            const SizedBox(height: 6),
            _buildOrderDateBar(),
            const SizedBox(height: 6),
            _buildParticularsTable(),
            const SizedBox(height: 8),
            _buildCustomerAndPaymentSummary(),
            const SizedBox(height: 8),
            _buildTamilFooterNotes(),
          ],
        ),
      ),
    );
  }

  // ── Pant measurement box: [ H | M | W | S | F | D | T.L. | B | NL | J ] ──
  Widget _buildPantMeasurementBox() {
    final m = order.measurement;
    final custom = m?.customMeasurements ?? {};
    final headers = ['H', 'M', 'W', 'S', 'F', 'D', 'T.L.', 'B', 'NL', 'J'];

    // Accurately map customer measurements
    final values = <String, String>{
      'H': _fmtVal(m?.hip ?? custom['hip'] ?? custom['H']),
      'M': _fmtVal(custom['mori'] ?? custom['M'] ?? m?.bottom),
      'W': _fmtVal(m?.waist ?? custom['waist'] ?? custom['W']),
      'S': _fmtVal(custom['seat'] ?? custom['S'] ?? m?.hip),
      'F': _fmtVal(custom['fork'] ?? custom['F']),
      'D': _fmtVal(custom['depth'] ?? custom['down'] ?? custom['D']),
      'T.L.': _fmtVal(m?.pantLength ?? custom['length'] ?? custom['TL'] ?? custom['T.L.']),
      'B': _fmtVal(m?.bottom ?? custom['bottom'] ?? custom['B']),
      'NL': _fmtVal(custom['knee'] ?? custom['NL'] ?? custom['nl']),
      'J': _fmtVal(custom['thigh'] ?? custom['janga'] ?? custom['J']),
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderRed, width: 1.2),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: const BorderSide(color: borderRed, width: 0.8),
        ),
        children: [
          TableRow(
            children: headers
                .map((h) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      color: borderRed.withOpacity(0.06),
                      child: Text(
                        h,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: inkRedDark,
                        ),
                      ),
                    ))
                .toList(),
          ),
          TableRow(
            children: headers
                .map((h) => Container(
                      height: 22,
                      alignment: Alignment.center,
                      child: Text(
                        values[h] ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: inkRed,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Pant tamil details row ──
  Widget _buildPantDetailsRow() {
    final isPant = order.dressType.toLowerCase().contains('pant');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left options
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Pant',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: inkRedDark,
                      decoration: isPant ? TextDecoration.underline : null,
                    ),
                  ),
                  if (isPant) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check, size: 14, color: inkRed),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'கட்லூப், பிளாப், கட்ஹாஜா',
                style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600),
              ),
              const Text(
                'கிராஸ், நேர், ரவுண்ட்',
                style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        // Right options
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'D.No.  ${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: inkRedDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'No. பிலீட்',
                style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600),
              ),
              const Text(
                'பிலீட்',
                style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600),
              ),
              const Text(
                'சைடு தையல்',
                style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shirt measurement box: [ H | B | W | S | SO | HH | N | BL | WL | SL | HL ] ──
  Widget _buildShirtMeasurementBox() {
    final m = order.measurement;
    final custom = m?.customMeasurements ?? {};
    final headers = ['H', 'B', 'W', 'S', 'SO', 'HH', 'N', 'BL', 'WL', 'SL', 'HL'];

    final values = <String, String>{
      'H': _fmtVal(custom['height'] ?? custom['shirt_length'] ?? custom['length'] ?? custom['H']),
      'B': _fmtVal(m?.chest ?? custom['chest'] ?? custom['B']),
      'W': _fmtVal(m?.waist ?? custom['waist'] ?? custom['W']),
      'S': _fmtVal(m?.shoulder ?? custom['shoulder'] ?? custom['S']),
      'SO': _fmtVal(custom['sleeve_open'] ?? custom['SO'] ?? custom['so']),
      'HH': _fmtVal(custom['half_height'] ?? custom['HH'] ?? custom['hh']),
      'N': _fmtVal(m?.neck ?? custom['neck'] ?? custom['N']),
      'BL': _fmtVal(custom['back_length'] ?? custom['BL'] ?? custom['bl']),
      'WL': _fmtVal(custom['waist_length'] ?? custom['WL'] ?? custom['wl']),
      'SL': _fmtVal(m?.sleeve ?? custom['sleeve'] ?? custom['SL']),
      'HL': _fmtVal(custom['hand_length'] ?? custom['HL'] ?? custom['hl']),
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderRed, width: 1.2),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: const BorderSide(color: borderRed, width: 0.8),
        ),
        children: [
          TableRow(
            children: headers
                .map((h) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      color: borderRed.withOpacity(0.06),
                      child: Text(
                        h,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: inkRedDark,
                        ),
                      ),
                    ))
                .toList(),
          ),
          TableRow(
            children: headers
                .map((h) => Container(
                      height: 22,
                      alignment: Alignment.center,
                      child: Text(
                        values[h] ?? '',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: inkRed,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Shirt tamil details row ──
  Widget _buildShirtDetailsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left checkboxes
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('புல்ஸிலாக் ', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600)),
                  _miniBox(),
                  const SizedBox(width: 8),
                  const Text('புல் ஏரோ ', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600)),
                  _miniBox(),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Text('ஆப்சிலாக் ', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600)),
                  _miniBox(),
                  const SizedBox(width: 8),
                  const Text('ஆல் ஏரோ ', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600)),
                  _miniBox(),
                ],
              ),
              const SizedBox(height: 2),
              const Text('F. P.', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.bold)),
              const Text('COLAR', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Right shirt tailoring details
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'D.No.  ${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: inkRedDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text('ரெடிமேட்', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600)),
              const Text('சாதா', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600)),
              const Text('டபுள் தையல்', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600)),
              const Text('எடை தையல்', style: TextStyle(fontSize: 9.5, color: inkRed, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniBox() {
    return Container(
      width: 14,
      height: 10,
      decoration: BoxDecoration(
        border: Border.all(color: borderRed, width: 0.8),
      ),
    );
  }

  // ── All measurements summary (shows all non-empty customer measurements clearly) ──
  Widget _buildAllMeasurementsSummary() {
    final m = order.measurement;
    if (m == null) return const SizedBox.shrink();

    final nonNullMeasurements = m.allMeasurements.entries
        .where((e) => e.value != null && e.value! > 0)
        .toList();

    if (nonNullMeasurements.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: borderRed.withOpacity(0.04),
        border: Border.all(color: borderRed, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CUSTOMER MEASUREMENTS (அளவுகள் inches):',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: inkRedDark,
            ),
          ),
          const SizedBox(height: 3),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: nonNullMeasurements.map((e) {
              return Text(
                '${e.key}: ${_fmtVal(e.value)}"',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: inkRed,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Perforated tear line between slips ──
  Widget _buildPerforatedLine() {
    return Row(
      children: [
        const Icon(Icons.content_cut, size: 10, color: borderRed),
        const SizedBox(width: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 4.0;
              const dashSpace = 3.0;
              final dashCount = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
              return Flex(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                direction: Axis.horizontal,
                children: List.generate(dashCount, (_) {
                  return const SizedBox(
                    width: dashWidth,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: borderRed),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Slip Header: Prop, Shop Name, Address ──
  Widget _buildBillHeader() {
    final dispOwner = ownerName.trim().isNotEmpty ? ownerName.trim() : 'Gunaseelan';
    final dispPhone = phone.trim().isNotEmpty ? phone.trim() : '80983 78746';
    final dispShop = shopName.trim().isNotEmpty ? shopName.trim() : 'G Tailoring';
    final dispAddress = address.trim().isNotEmpty
        ? address.trim()
        : 'East Street,\nPalliyagraharam,\nThanjavur.';
    final initialLetter = dispShop.isNotEmpty ? dispShop[0].toUpperCase() : 'G';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Prop & Cell
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prop. :$dispOwner',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: inkRedDark,
                ),
              ),
              if (dispPhone.isNotEmpty)
                Text(
                  'Cell :$dispPhone',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: inkRedDark,
                  ),
                ),
            ],
          ),
        ),

        // Center: Initial + Heart + Shop Name
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderRed, width: 1),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(1.5),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.favorite,
                            size: 14,
                            color: borderRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    initialLetter,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: inkRedDark,
                    ),
                  ),
                  const Icon(Icons.favorite, size: 14, color: borderRed),
                ],
              ),
              Text(
                dispShop,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: inkRedDark,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Right: Address
        Expanded(
          flex: 4,
          child: Text(
            dispAddress,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: inkRedDark,
              height: 1.15,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── Date Bar: ORDER.DATE | D.DATE | No. 101 ──
  Widget _buildOrderDateBar() {
    final orderDate = Helpers.parseDate(order.orderDate);
    final deliveryDate = order.deliveryDate != null
        ? Helpers.parseDate(order.deliveryDate!)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: borderRed.withOpacity(0.08),
        border: Border.all(color: borderRed, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'ORDER.DATE: ',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: inkRedDark,
                ),
              ),
              Text(
                orderDate != null ? Helpers.formatDate(orderDate) : '-',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'D.DATE: ',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: inkRedDark,
                ),
              ),
              Text(
                deliveryDate != null ? Helpers.formatDate(deliveryDate) : '-',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            'No. ${order.orderNumber}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: inkRedDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Particulars Table: Standard items (Pant, Half Pant, Half Shirt, Full Shirt, Safari) + Custom ──
  Widget _buildParticularsTable() {
    final standardItems = [
      'Pant',
      'Half Pant',
      'Half Shirt',
      'Full Shirt',
      'Safari',
    ];

    final currentItem = order.dressType;
    final totalAmount = order.totalAmount;
    final rsPart = totalAmount.floor().toString();
    final psPart = ((totalAmount - totalAmount.floor()) * 100).round().toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderRed, width: 1.2),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            color: borderRed.withOpacity(0.08),
            child: Row(
              children: [
                const SizedBox(
                  width: 34,
                  child: Center(
                    child: Text('Qty', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: inkRedDark)),
                  ),
                ),
                _vDivider(),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                    child: Center(
                      child: Text(
                        'Particulars',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: inkRedDark),
                      ),
                    ),
                  ),
                ),
                _vDivider(),
                const SizedBox(
                  width: 55,
                  child: Center(
                    child: Text('Rs.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: inkRedDark)),
                  ),
                ),
                _vDivider(),
                const SizedBox(
                  width: 32,
                  child: Center(
                    child: Text('Ps.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: inkRedDark)),
                  ),
                ),
              ],
            ),
          ),
          _hDivider(),

          // Standard items list matching the physical bill
          ...standardItems.map((item) {
            final isMatch = currentItem.toLowerCase().trim() == item.toLowerCase().trim();
            return _buildParticularRow(
              qty: isMatch ? '${order.quantity}' : '',
              title: item,
              rs: isMatch ? rsPart : '',
              ps: isMatch ? (psPart == '00' ? '-' : psPart) : '',
              isHighlighted: isMatch,
            );
          }),

          // If current order item is custom (e.g. Kurta, Suit, Blouse)
          if (!standardItems.any((i) => i.toLowerCase().trim() == currentItem.toLowerCase().trim()))
            _buildParticularRow(
              qty: '${order.quantity}',
              title: currentItem.isNotEmpty ? currentItem : order.dressName,
              rs: rsPart,
              ps: psPart == '00' ? '-' : psPart,
              isHighlighted: true,
            ),

          _hDivider(),
          // Total row
          Container(
            color: borderRed.withOpacity(0.05),
            child: Row(
              children: [
                const SizedBox(width: 34),
                _vDivider(),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      'Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: inkRedDark,
                      ),
                    ),
                  ),
                ),
                _vDivider(),
                SizedBox(
                  width: 55,
                  child: Text(
                    rsPart,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: inkRedDark,
                    ),
                  ),
                ),
                _vDivider(),
                SizedBox(
                  width: 32,
                  child: Text(
                    psPart == '00' ? '-' : psPart,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: inkRedDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticularRow({
    required String qty,
    required String title,
    required String rs,
    required String ps,
    required bool isHighlighted,
  }) {
    return Container(
      color: isHighlighted ? borderRed.withOpacity(0.05) : Colors.transparent,
      height: 22,
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Center(
              child: Text(
                qty,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: inkRed),
              ),
            ),
          ),
          _vDivider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                      color: isHighlighted ? inkRedDark : inkRed.withOpacity(0.85),
                    ),
                  ),
                  if (isHighlighted) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check, size: 12, color: inkRed),
                  ],
                ],
              ),
            ),
          ),
          _vDivider(),
          SizedBox(
            width: 55,
            child: Center(
              child: Text(
                rs,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: inkRedDark),
              ),
            ),
          ),
          _vDivider(),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                ps,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: inkRedDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(width: 0.8, color: borderRed);
  }

  Widget _hDivider() {
    return Container(height: 0.8, color: borderRed);
  }

  // ── Customer Details + Advance & Balance payment summary ──
  Widget _buildCustomerAndPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: borderRed.withOpacity(0.04),
        border: Border.all(color: borderRed, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer: ${order.customerName ?? "-"}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: inkRedDark,
                ),
              ),
              if (order.customerMobile != null)
                Text(
                  'Mob: ${order.customerMobile}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: inkRedDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Advance: $currency${order.advanceAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Text(
                'Balance: $currency${order.balanceAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: order.balanceAmount > 0 ? inkRedDark : const Color(0xFF2E7D32),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: order.paymentStatus == 'Paid'
                      ? const Color(0xFF2E7D32).withOpacity(0.12)
                      : borderRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: order.paymentStatus == 'Paid'
                        ? const Color(0xFF2E7D32)
                        : borderRed,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  order.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: order.paymentStatus == 'Paid'
                        ? const Color(0xFF2E7D32)
                        : inkRedDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Authentic Tamil Footer Notes from the screenshot ──
  Widget _buildTamilFooterNotes() {
    return Column(
      children: [
        const Text(
          'குறிப்பு : பில் காணாமல் போனால் நாங்கள் பொறுப்பல்ல.',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: inkRedDark,
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'தாங்கள் துணியை 90 நாட்களுக்குள் வாங்கிச்செல்லவும்.',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: inkRedDark,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Fullscreen bill preview with pinch-to-zoom interactive viewer,
/// high-resolution PNG screenshot export, and printable PDF invoice generation.
/// Real-time binds to SettingsProvider to show updated shop details immediately.
class BillPreviewScreen extends StatefulWidget {
  final Order order;
  final String shopName;
  final String ownerName;
  final String phone;
  final String address;
  final String currency;

  const BillPreviewScreen({
    super.key,
    required this.order,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.currency,
  });

  @override
  State<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends State<BillPreviewScreen> {
  final GlobalKey _billKey = GlobalKey();
  bool _isExporting = false;
  late Order _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    // If measurement is null, load it from SQLite database
    if (_currentOrder.measurement == null && _currentOrder.id != null) {
      _loadMeasurements();
    }
  }

  Future<void> _loadMeasurements() async {
    try {
      final m = await DatabaseHelper.instance.getMeasurementByOrderId(_currentOrder.id!);
      if (m != null && mounted) {
        setState(() {
          _currentOrder = _currentOrder.copyWith(measurement: m);
        });
      }
    } catch (_) {}
  }

  Future<void> _captureAndShare() async {
    setState(() => _isExporting = true);
    try {
      final boundary = _billKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.5);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/bill_${_currentOrder.orderNumber}.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() => _isExporting = false);
        final settings = context.read<SettingsProvider>();
        final shop = settings.shopName.isNotEmpty ? settings.shopName : widget.shopName;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Tailor Shop Bill #${_currentOrder.orderNumber} - $shop',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final settings = context.read<SettingsProvider>();
      final file = await PdfService.instance.generateOrderBillPdf(
        order: _currentOrder,
        shopName: settings.shopName.isNotEmpty ? settings.shopName : widget.shopName,
        ownerName: settings.ownerName.isNotEmpty ? settings.ownerName : widget.ownerName,
        phone: settings.phone.isNotEmpty ? settings.phone : widget.phone,
        address: settings.address.isNotEmpty ? settings.address : widget.address,
        currency: settings.currency.isNotEmpty ? settings.currency : widget.currency,
      );

      if (mounted) {
        setState(() => _isExporting = false);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Order Bill PDF #${_currentOrder.orderNumber}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printBill() async {
    setState(() => _isExporting = true);
    try {
      final settings = context.read<SettingsProvider>();
      final file = await PdfService.instance.generateOrderBillPdf(
        order: _currentOrder,
        shopName: settings.shopName.isNotEmpty ? settings.shopName : widget.shopName,
        ownerName: settings.ownerName.isNotEmpty ? settings.ownerName : widget.ownerName,
        phone: settings.phone.isNotEmpty ? settings.phone : widget.phone,
        address: settings.address.isNotEmpty ? settings.address : widget.address,
        currency: settings.currency.isNotEmpty ? settings.currency : widget.currency,
      );
      if (mounted) {
        setState(() => _isExporting = false);
        await Printing.layoutPdf(
          onLayout: (_) => file.readAsBytes(),
          name: 'Bill_${_currentOrder.orderNumber}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Real-time dynamic binding to SettingsProvider
    final settings = context.watch<SettingsProvider>();
    final activeShopName = settings.shopName.isNotEmpty ? settings.shopName : widget.shopName;
    final activeOwnerName = settings.ownerName.isNotEmpty ? settings.ownerName : widget.ownerName;
    final activePhone = settings.phone.isNotEmpty ? settings.phone : widget.phone;
    final activeAddress = settings.address.isNotEmpty ? settings.address : widget.address;
    final activeCurrency = settings.currency.isNotEmpty ? settings.currency : widget.currency;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : const Color(0xFFEDE8DA),
      appBar: AppBar(
        title: Text(
          'Bill #${_currentOrder.orderNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Share PDF Invoice',
            onPressed: _isExporting ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Bill',
            onPressed: _isExporting ? null : _printBill,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.camera_alt_outlined),
            tooltip: 'Share Screenshot (PNG)',
            onPressed: _isExporting ? null : _captureAndShare,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222222) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  label: const Text('PDF Bill'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : _printBill,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: FilledButton.icon(
                  onPressed: _isExporting ? null : _captureAndShare,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                  ),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.7,
        maxScale: 4.0,
        boundaryMargin: const EdgeInsets.all(50),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: RepaintBoundary(
              key: _billKey,
              child: BillWidget(
                order: _currentOrder,
                shopName: activeShopName,
                ownerName: activeOwnerName,
                phone: activePhone,
                address: activeAddress,
                currency: activeCurrency,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
