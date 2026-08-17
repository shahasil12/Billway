import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/datasources/pos_remote_data_source.dart';
import '../../data/repositories/pos_repository_impl.dart';
import '../../domain/repositories/pos_repository.dart';
import '../controllers/pos_session_controller.dart';
import '../controllers/pos_cart_controller.dart';

import '../../data/datasources/pos_local_data_source.dart';

final posRemoteDataSourceProvider = Provider<POSRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return POSRemoteDataSourceImpl(apiClient);
});

final posLocalDataSourceProvider = Provider<POSLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return POSLocalDataSourceImpl(dbHelper: dbHelper);
});

final posRepositoryProvider = Provider<POSRepository>((ref) {
  final remoteDataSource = ref.watch(posRemoteDataSourceProvider);
  final localDataSource = ref.watch(posLocalDataSourceProvider);
  final syncService = ref.watch(syncServiceProvider);
  
  return POSRepositoryImpl(remoteDataSource, localDataSource, syncService, ref);
});

final posSessionControllerProvider = StateNotifierProvider<POSSessionController, POSSessionState>((ref) {
  final repository = ref.watch(posRepositoryProvider);
  return POSSessionController(repository);
});

final posCartControllerProvider = StateNotifierProvider<POSCartController, POSCartState>((ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return POSCartController(repository);
});
