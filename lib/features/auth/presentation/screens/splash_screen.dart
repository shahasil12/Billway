import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _statusMessage = 'Waking up the server...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _warmupServer();
  }

  Future<void> _warmupServer() async {
    try {
      final response = await Dio().get(
        'https://billway-api-a9ea.onrender.com/api/auth/login/',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      if (mounted) {
        setState(() {
          _statusMessage = 'Server ready! Logging in...';
        });
        
        // After server is ready, check auto login!
        await ref.read(authStateProvider.notifier).checkAutoLogin();
        
        final authState = ref.read(authStateProvider);
        if (authState.value != null) {
          context.go('/');
        } else {
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error waking up server. Retrying...';
        });
        await Future.delayed(const Duration(seconds: 2));
        _warmupServer();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _animation,
              child: Icon(
                Icons.cloud_sync,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
