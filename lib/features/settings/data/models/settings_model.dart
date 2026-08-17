import '../../domain/entities/settings.dart';

class SettingsModel extends Settings {
  SettingsModel({
    required super.id,
    required super.businessName,
    required super.businessAddress,
    required super.phoneNumber,
    super.gstNumber,
    required super.invoicePrefix,
    required super.invoiceFooter,
    required super.defaultTaxPercentage,
    required super.currency,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] ?? 1,
      businessName: json['name'] ?? '',
      businessAddress: json['address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      gstNumber: json['gst_number'],
      invoicePrefix: json['invoice_prefix'] ?? 'INV-',
      invoiceFooter: json['invoice_footer'] ?? '',
      defaultTaxPercentage: double.tryParse((json['default_tax_percentage'] ?? '0').toString()) ?? 0,
      currency: json['currency'] ?? '\$',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': businessName,
      'address': businessAddress,
      'phone_number': phoneNumber,
      'gst_number': gstNumber,
      'invoice_prefix': invoicePrefix,
      'invoice_footer': invoiceFooter,
      'default_tax_percentage': defaultTaxPercentage,
      'currency': currency,
    };
  }
}
