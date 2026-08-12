import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/settings_controller.dart';
import '../../domain/entities/settings.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/providers.dart';
import '../../../auth/domain/entities/user.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _gstController;
  late TextEditingController _prefixController;
  late TextEditingController _footerController;
  late TextEditingController _taxController;
  late TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _gstController = TextEditingController();
    _prefixController = TextEditingController();
    _footerController = TextEditingController();
    _taxController = TextEditingController();
    _currencyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _prefixController.dispose();
    _footerController.dispose();
    _taxController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _populateFields(Settings settings) {
    _nameController.text = settings.businessName;
    _addressController.text = settings.businessAddress;
    _phoneController.text = settings.phoneNumber;
    _gstController.text = settings.gstNumber ?? '';
    _prefixController.text = settings.invoicePrefix;
    _footerController.text = settings.invoiceFooter;
    _taxController.text = settings.defaultTaxPercentage.toString();
    _currencyController.text = settings.currency;
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final currentState = ref.read(settingsProvider);
      if (currentState.settings == null) return;
      
      final updatedSettings = Settings(
        id: currentState.settings!.id,
        businessName: _nameController.text.trim(),
        businessAddress: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        invoicePrefix: _prefixController.text.trim(),
        invoiceFooter: _footerController.text.trim(),
        defaultTaxPercentage: double.tryParse(_taxController.text.trim()) ?? 0.0,
        currency: _currencyController.text.trim(),
      );

      final success = await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated successfully')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).value;

    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false && next.settings != null) {
        _populateFields(next.settings!);
      }
    });

    if (state.settings != null && _nameController.text.isEmpty) {
      _populateFields(state.settings!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
      ),
      body: state.isLoading && state.settings == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.settings == null
              ? Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (user?.role == UserRole.admin) ...[
                          const Text('Administration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: const Icon(Icons.people, color: Color(0xFFFF2A5F)),
                              title: const Text('Manage Users & Roles'),
                              subtitle: const Text('Add cashiers, managers, and admins'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/settings/users'),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        const Text('Company Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder()),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Business Address', border: OutlineInputBorder()),
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _gstController,
                          decoration: const InputDecoration(labelText: 'GST Number (Optional)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 32),
                        const Text('Invoice Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _prefixController,
                                decoration: const InputDecoration(labelText: 'Invoice Prefix', border: OutlineInputBorder()),
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _currencyController,
                                decoration: const InputDecoration(labelText: 'Currency Symbol', border: OutlineInputBorder()),
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _taxController,
                          decoration: const InputDecoration(labelText: 'Default Tax Percentage (%)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _footerController,
                          decoration: const InputDecoration(labelText: 'Invoice Footer Note', border: OutlineInputBorder()),
                          maxLines: 2,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: state.isLoading ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: state.isLoading 
                              ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2))
                              : const Text('Save Settings', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
