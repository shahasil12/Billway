import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'core/router.dart';
import 'core/providers.dart';
import 'core/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: BillwayApp(),
    ),
  );
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
    );
  }
}
