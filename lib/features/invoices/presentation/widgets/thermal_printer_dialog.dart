import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../../../core/printing/printer_service.dart';
import '../../../../core/printing/receipt_generator.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/entities/invoice.dart';

class ThermalPrinterDialog extends ConsumerStatefulWidget {
  final Invoice invoice;

  const ThermalPrinterDialog({super.key, required this.invoice});

  @override
  ConsumerState<ThermalPrinterDialog> createState() => _ThermalPrinterDialogState();
}

class _ThermalPrinterDialogState extends ConsumerState<ThermalPrinterDialog> {
  final PrinterService _printerService = PrinterService();
  String _connectionType = 'Network';
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.100');
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBluetoothDevices();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _loadBluetoothDevices() async {
    final devices = await _printerService.getBluetoothDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        if (devices.isNotEmpty) {
          _selectedDevice = devices.first;
        }
      });
    }
  }

  void _printReceipt() async {
    final settings = ref.read(settingsProvider).settings;
    if (settings == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await ReceiptGenerator.generateReceipt(widget.invoice, settings);

      var result;
      if (_connectionType == 'Network') {
        result = await _printerService.printViaNetwork(_ipController.text.trim(), 9100, bytes);
      } else {
        if (_selectedDevice == null) {
          throw Exception('No bluetooth device selected');
        }
        result = await _printerService.printViaBluetooth(_selectedDevice!, bytes);
      }

      result.fold(
        (failure) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
        },
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print job sent successfully')));
            Navigator.of(context).pop();
          }
        },
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Print Receipt'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Connection Type', border: OutlineInputBorder()),
              value: _connectionType,
              items: ['Network', 'Bluetooth'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) {
                setState(() => _connectionType = val!);
              },
            ),
            const SizedBox(height: 16),
            if (_connectionType == 'Network')
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(labelText: 'Printer IP Address', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              )
            else
              DropdownButtonFormField<BluetoothDevice>(
                decoration: const InputDecoration(labelText: 'Paired Device', border: OutlineInputBorder()),
                value: _selectedDevice,
                items: _devices.map((d) => DropdownMenuItem(value: d, child: Text(d.name ?? 'Unknown'))).toList(),
                onChanged: (val) {
                  setState(() => _selectedDevice = val);
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _printReceipt,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Print'),
        ),
      ],
    );
  }
}
