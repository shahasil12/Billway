import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/providers.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
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
