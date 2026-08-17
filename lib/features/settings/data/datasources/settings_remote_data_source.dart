import '../../../../core/network/api_client.dart';
import '../models/settings_model.dart';
import '../../domain/entities/settings.dart';

abstract class SettingsRemoteDataSource {
  Future<SettingsModel> getSettings();
  Future<SettingsModel> updateSettings(Settings settings);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final ApiClient apiClient;

  SettingsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<SettingsModel> getSettings() async {
    final response = await apiClient.dio.get('auth/company/');
    return SettingsModel.fromJson(response.data);
  }

  @override
  Future<SettingsModel> updateSettings(Settings settings) async {
    final model = SettingsModel(
      id: settings.id,
      businessName: settings.businessName,
      businessAddress: settings.businessAddress,
      phoneNumber: settings.phoneNumber,
      gstNumber: settings.gstNumber,
      invoicePrefix: settings.invoicePrefix,
      invoiceFooter: settings.invoiceFooter,
      defaultTaxPercentage: settings.defaultTaxPercentage,
      currency: settings.currency,
    );
    final response = await apiClient.dio.put('auth/company/', data: model.toJson());
    return SettingsModel.fromJson(response.data);
  }
}
