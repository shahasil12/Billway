import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/settings_controller.dart';
import '../../domain/entities/settings.dart';
import '../../../../core/providers.dart';
import '../../../auth/domain/entities/user.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_containers.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: AppColors.success,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).value;
    final isTablet = MediaQuery.of(context).size.width >= 600;

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
        title: const Text('Settings'),
      ),
      body: state.isLoading && state.settings == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.settings == null
              ? Center(child: Text(state.error!, style: const TextStyle(color: AppColors.error)))
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
                    vertical: AppSpacing.p16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user?.role == UserRole.admin) ...[
                          Text('Administration', style: AppTextStyles.h3),
                          const SizedBox(height: AppSpacing.p16),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(AppSpacing.p8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.people, color: AppColors.primary),
                              ),
                              title: Text('Manage Users & Roles', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text('Add cashiers, managers, and admins', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              onTap: () => context.push('/settings/users'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.p32),
                        ],
                        
                        Text('Company Details', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.p16),
                        AppCard(
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _nameController,
                                label: 'Business Name *',
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: AppSpacing.p16),
                              AppTextField(
                                controller: _addressController,
                                label: 'Business Address *',
                                maxLines: 3,
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: AppSpacing.p16),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _phoneController,
                                      label: 'Phone Number *',
                                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.p16),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _gstController,
                                      label: 'GST Number (Optional)',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.p32),
                        Text('Invoice Preferences', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.p16),
                        
                        AppCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _prefixController,
                                      label: 'Invoice Prefix *',
                                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.p16),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _currencyController,
                                      label: 'Currency Symbol *',
                                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.p16),
                              AppTextField(
                                controller: _taxController,
                                label: 'Default Tax Percentage (%) *',
                                keyboardType: TextInputType.number,
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: AppSpacing.p16),
                              AppTextField(
                                controller: _footerController,
                                label: 'Invoice Footer Note *',
                                maxLines: 2,
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.p32),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            isLarge: true,
                            label: 'Save Settings',
                            isLoading: state.isLoading,
                            onPressed: _saveSettings,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.p32),
                      ],
                    ),
                  ),
                ),
    );
  }
}
