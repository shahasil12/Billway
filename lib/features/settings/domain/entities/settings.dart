class Settings {
  final int id;
  final String businessName;
  final String businessAddress;
  final String phoneNumber;
  final String? gstNumber;
  final String invoicePrefix;
  final String invoiceFooter;
  final double defaultTaxPercentage;
  final String currency;

  Settings({
    required this.id,
    required this.businessName,
    required this.businessAddress,
    required this.phoneNumber,
    this.gstNumber,
    required this.invoicePrefix,
    required this.invoiceFooter,
    required this.defaultTaxPercentage,
    required this.currency,
  });
}
