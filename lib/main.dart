import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'core/router.dart';
import 'core/providers.dart';
import 'core/theme.dart';

void main() {
  // Fire-and-forget warmup ping so Render wakes up before user navigates
  _warmupServer();
  runApp(
    const ProviderScope(
      child: BillwayApp(),
    ),
  );
}

Future<void> _warmupServer() async {
  try {
    await Dio().get(
      'https://billway-api-a9ea.onrender.com/api/auth/login/',
      options: Options(validateStatus: (_) => true, receiveTimeout: const Duration(seconds: 60)),
    );
  } catch (_) {
    // Ignore errors — this is just a warmup ping
  }
}

class BillwayApp extends ConsumerWidget {
  const BillwayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'Billway POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        if (authState.isLoading && authState.value == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child!;
      },
    );
  }
}
