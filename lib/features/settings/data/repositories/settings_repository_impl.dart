import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;
  final DatabaseHelper dbHelper;

  SettingsRepositoryImpl(this.remoteDataSource, this.dbHelper);

  @override
  Future<Either<Failure, Settings>> getSettings() async {
    try {
      final localRow = await dbHelper.getLocalSettings();

      // Fire-and-forget: pull fresh settings from server & cache them
      _syncRemoteSettings();

      if (localRow != null) {
        // Return cached settings instantly — zero loading time
        return Right(SettingsModel(
          id: localRow['id'] as int,
          businessName: localRow['business_name'] as String,
          businessAddress: localRow['business_address'] as String,
          phoneNumber: localRow['phone_number'] as String,
          gstNumber: localRow['gst_number'] as String?,
          invoicePrefix: localRow['invoice_prefix'] as String,
          invoiceFooter: localRow['invoice_footer'] as String,
          defaultTaxPercentage: (localRow['default_tax_percentage'] as num).toDouble(),
          currency: localRow['currency'] as String,
        ));
      }

      // First launch: no cache yet — fetch from network
      final settings = await remoteDataSource.getSettings();
      await _cacheSettings(settings);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure('Failed to load settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Settings>> updateSettings(Settings settings) async {
    try {
      // Save locally immediately so the user doesn't wait
      await _cacheSettings(settings);

      // Push to server in background
      _pushSettingsUpdate(settings);

      return Right(settings);
    } catch (e) {
      return Left(ServerFailure('Failed to update settings: $e'));
    }
  }

  Future<void> _syncRemoteSettings() async {
    try {
      final remote = await remoteDataSource.getSettings();
      await _cacheSettings(remote);
    } catch (_) {
      // Ignore — we already returned local data
    }
  }

  Future<void> _pushSettingsUpdate(Settings settings) async {
    try {
      await remoteDataSource.updateSettings(settings);
    } catch (_) {
      // Will sync next time network available
    }
  }

  Future<void> _cacheSettings(Settings s) async {
    await dbHelper.saveLocalSettings({
      'id': s.id == 0 ? 1 : s.id,
      'business_name': s.businessName,
      'business_address': s.businessAddress,
      'phone_number': s.phoneNumber,
      'gst_number': s.gstNumber,
      'invoice_prefix': s.invoicePrefix,
      'invoice_footer': s.invoiceFooter,
      'default_tax_percentage': s.defaultTaxPercentage,
      'currency': s.currency,
    });
  }
}
