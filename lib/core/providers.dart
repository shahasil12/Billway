import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'network/api_client.dart';
import 'network/warmup_service.dart';
import 'database/database_helper.dart';
import 'sync/sync_service.dart';
import 'providers/locale_provider.dart';
import '../features/auth/data/repositories/user_management_repository.dart';
import '../features/auth/presentation/controllers/user_management_controller.dart';
import '../features/customers/data/datasources/customer_local_data_source.dart';
import '../features/products/data/datasources/product_local_data_source.dart';
import '../features/invoices/data/datasources/invoice_local_data_source.dart';
import '../features/auth/data/datasources/auth_local_data_source.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/entities/user.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/customers/data/datasources/customer_remote_data_source.dart';
import '../features/customers/data/repositories/customer_repository_impl.dart';
import '../features/customers/domain/repositories/customer_repository.dart';
import '../features/categories/data/datasources/category_remote_data_source.dart';
import '../features/categories/data/repositories/category_repository_impl.dart';
import '../features/categories/domain/repositories/category_repository.dart';
import '../features/products/data/datasources/product_remote_data_source.dart';
import '../features/products/data/repositories/product_repository_impl.dart';
import '../features/products/domain/repositories/product_repository.dart';
import '../features/invoices/data/datasources/invoice_remote_data_source.dart';
import '../features/invoices/data/repositories/invoice_repository_impl.dart';
import '../features/invoices/domain/repositories/invoice_repository.dart';
import '../features/payments/data/datasources/payment_remote_data_source.dart';
import '../features/payments/data/repositories/payment_repository_impl.dart';
import '../features/payments/domain/repositories/payment_repository.dart';
import '../features/reports/data/datasources/report_remote_data_source.dart';
import '../features/reports/data/repositories/report_repository_impl.dart';
import '../features/reports/domain/repositories/report_repository.dart';
import '../features/settings/data/datasources/settings_remote_data_source.dart';
import '../features/settings/data/repositories/settings_repository_impl.dart';
import '../features/settings/domain/repositories/settings_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioProvider), ref.read(secureStorageProvider));
});

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final warmupServiceProvider = Provider<WarmupService>((ref) {
  return WarmupService(
    Dio(),
    'https://billway-api-a9ea.onrender.com/api/',
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    dbHelper: ref.read(databaseHelperProvider),
    apiClient: ref.read(apiClientProvider),
  );
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.read(secureStorageProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    localDataSource: ref.read(authLocalDataSourceProvider),
  );
});

final authStateProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});


final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  return UserManagementRepository(ref.read(apiClientProvider).dio);
});

final userManagementControllerProvider = StateNotifierProvider<UserManagementController, AsyncValue<List<User>>>((ref) {
  return UserManagementController(ref.read(userManagementRepositoryProvider));
});



final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    remoteDataSource: ref.read(dashboardRemoteDataSourceProvider),
    dbHelper: ref.read(databaseHelperProvider),
  );
});



final customerRemoteDataSourceProvider = Provider<CustomerRemoteDataSource>((ref) {
  return CustomerRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final customerLocalDataSourceProvider = Provider<CustomerLocalDataSource>((ref) {
  return CustomerLocalDataSourceImpl(dbHelper: ref.read(databaseHelperProvider));
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(
    ref.read(customerRemoteDataSourceProvider),
    ref.read(customerLocalDataSourceProvider),
    ref.read(syncServiceProvider),
  );
});

// Category Providers
final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  return CategoryRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    ref.read(categoryRemoteDataSourceProvider),
    ref.read(databaseHelperProvider),
  );
});

// Product Providers
final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final productLocalDataSourceProvider = Provider<ProductLocalDataSource>((ref) {
  return ProductLocalDataSourceImpl(dbHelper: ref.read(databaseHelperProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    ref.read(productRemoteDataSourceProvider),
    ref.read(productLocalDataSourceProvider),
    ref.read(syncServiceProvider),
  );
});

// Invoice Providers
final invoiceRemoteDataSourceProvider = Provider<InvoiceRemoteDataSource>((ref) {
  return InvoiceRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final invoiceLocalDataSourceProvider = Provider<InvoiceLocalDataSource>((ref) {
  return InvoiceLocalDataSourceImpl(dbHelper: ref.read(databaseHelperProvider));
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl(
    ref.read(invoiceRemoteDataSourceProvider),
    ref.read(invoiceLocalDataSourceProvider),
    ref.read(syncServiceProvider),
  );
});

// Payment Providers
final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.read(paymentRemoteDataSourceProvider));
});

// Report Providers
final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.read(reportRemoteDataSourceProvider));
});

// Settings Providers
final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>((ref) {
  return SettingsRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    ref.read(settingsRemoteDataSourceProvider),
    ref.read(databaseHelperProvider),
  );
});
