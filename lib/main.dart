import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class BillwayApp extends ConsumerStatefulWidget {
  const BillwayApp({super.key});

  @override
  ConsumerState<BillwayApp> createState() => _BillwayAppState();
}

class _BillwayAppState extends ConsumerState<BillwayApp> {
  @override
  void initState() {
    super.initState();
    // Silently wake up the Render server the moment the app opens.
    // The free plan spins down after inactivity — this ping runs
    // in the background so the server is ready before the user taps Login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(warmupServiceProvider).warmup();
      ref.read(syncServiceProvider); // also eagerly init SyncService
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Billway POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme, // Always light — POS screens must be readable on counter
      themeMode: ThemeMode.light,     // Never follow system dark mode
      routerConfig: router,
    );
  }
}
