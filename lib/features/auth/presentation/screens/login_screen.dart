import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _serverReady = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _wakeServer();
  }

  Future<void> _wakeServer() async {
    // Warmup was already fired from main.dart, but we track readiness here
    // to update the UI hint. Wait a moment then mark as ready-ish.
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _serverReady = true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authLocalDataSourceProvider).setRememberMe(_rememberMe);
      final success = await ref.read(authStateProvider.notifier).login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        context.go('/');
      } else if (!success && mounted) {
        final error = ref.read(authStateProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error?.toString() ?? 'Login failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Billway',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Subtle server readiness indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _serverReady
                      ? const SizedBox.shrink()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Connecting to server...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Remember Me'),
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text("Don't have an account? Register Company"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
