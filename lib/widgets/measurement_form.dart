import 'package:flutter/material.dart';
import '../models/measurement.dart';

/// Reusable measurement form widget
class MeasurementForm extends StatefulWidget {
  final Measurement? initial;
  final void Function(Measurement measurement) onChanged;

  const MeasurementForm({
    super.key,
    this.initial,
    required this.onChanged,
  });

  @override
  State<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _standardFields = [
    'Chest', 'Shoulder', 'Neck', 'Sleeve', 'Waist', 'Hip', 'Pant Length', 'Bottom'
  ];
  final List<MapEntry<String, TextEditingController>> _customFields = [];

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _controllers['Chest'] = TextEditingController(text: _fmt(init?.chest));
    _controllers['Shoulder'] = TextEditingController(text: _fmt(init?.shoulder));
    _controllers['Neck'] = TextEditingController(text: _fmt(init?.neck));
    _controllers['Sleeve'] = TextEditingController(text: _fmt(init?.sleeve));
    _controllers['Waist'] = TextEditingController(text: _fmt(init?.waist));
    _controllers['Hip'] = TextEditingController(text: _fmt(init?.hip));
    _controllers['Pant Length'] = TextEditingController(text: _fmt(init?.pantLength));
    _controllers['Bottom'] = TextEditingController(text: _fmt(init?.bottom));

    // Custom measurements
    if (init != null) {
      init.customMeasurements.forEach((key, value) {
        final ctrl = TextEditingController(text: value.toString());
        _customFields.add(MapEntry(key, ctrl));
      });
    }

    // Listen for changes
    for (final c in _controllers.values) {
      c.addListener(_notify);
    }
  }

  String _fmt(double? v) => v != null ? v.toString() : '';

  void _notify() {
    final custom = <String, double>{};
    for (final e in _customFields) {
      final v = double.tryParse(e.value.text);
      if (v != null) custom[e.key] = v;
    }
    widget.onChanged(Measurement(
      orderId: 0,
      chest: double.tryParse(_controllers['Chest']!.text),
      shoulder: double.tryParse(_controllers['Shoulder']!.text),
      neck: double.tryParse(_controllers['Neck']!.text),
      sleeve: double.tryParse(_controllers['Sleeve']!.text),
      waist: double.tryParse(_controllers['Waist']!.text),
      hip: double.tryParse(_controllers['Hip']!.text),
      pantLength: double.tryParse(_controllers['Pant Length']!.text),
      bottom: double.tryParse(_controllers['Bottom']!.text),
      customMeasurements: custom,
    ));
  }

  void _addCustomField() {
    showDialog<String>(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Custom Measurement'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Measurement Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) Navigator.pop(ctx, name);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((name) {
      if (name != null && name.isNotEmpty) {
        setState(() {
          final ctrl = TextEditingController();
          ctrl.addListener(_notify);
          _customFields.add(MapEntry(name, ctrl));
        });
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final e in _customFields) {
      e.value.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Standard fields in 2-column grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 0,
          childAspectRatio: 3.5,
          children: _standardFields.map((field) {
            return TextField(
              controller: _controllers[field],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '$field (inches)',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Custom measurements
        if (_customFields.isNotEmpty) ...[
          Text('Custom Measurements',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ..._customFields.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: e.value.value,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '${e.value.key} (inches)',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _customFields.removeAt(e.key);
                        _notify();
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ],

        TextButton.icon(
          onPressed: _addCustomField,
          icon: const Icon(Icons.add),
          label: const Text('Add Custom Measurement'),
        ),
      ],
    );
  }
}
