import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/home_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import 'widgets/app_shell.dart';

import '../features/customers/presentation/screens/customer_list_screen.dart';
import '../features/customers/presentation/screens/add_edit_customer_screen.dart';
import '../features/customers/presentation/screens/customer_detail_screen.dart';
import '../features/customers/domain/entities/customer.dart';

import '../features/categories/presentation/screens/category_list_screen.dart';
import '../features/categories/presentation/screens/add_edit_category_screen.dart';
import '../features/categories/domain/entities/category.dart';

import '../features/products/presentation/screens/product_list_screen.dart';
import '../features/products/presentation/screens/product_detail_screen.dart';
import '../features/products/presentation/screens/add_edit_product_screen.dart';
import '../features/products/domain/entities/product.dart';

import '../features/invoices/presentation/screens/invoice_list_screen.dart';
import '../features/invoices/presentation/screens/create_invoice_screen.dart';
import '../features/invoices/presentation/screens/invoice_detail_screen.dart';
import '../features/invoices/domain/entities/invoice.dart';

import '../features/payments/presentation/screens/payment_list_screen.dart';

import '../features/reports/presentation/screens/reports_screen.dart';

import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/auth/presentation/screens/manage_users_screen.dart';
import '../features/pos/presentation/screens/pos_screen.dart';

CustomTransitionPage _fadeTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';
      final isSplash = state.uri.path == '/splash';
      final authState = ref.read(authStateProvider);
      
      if (authState.isLoading) {
        return null;
      }
      
      final isAuthenticated = authState.value != null;
      
      if (!isAuthenticated && !isLoggingIn && !isRegistering && !isSplash) {
        return '/login';
      }
      
      if (isAuthenticated && (isLoggingIn || isRegistering || isSplash)) {
        return '/';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadeTransition(const SplashScreen(), state),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeTransition(const LoginScreen(), state),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fadeTransition(const RegisterScreen(), state),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _fadeTransition(const HomeScreen(), state),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) => _fadeTransition(const CustomerListScreen(), state),
          ),
          GoRoute(
            path: '/customers/add',
            pageBuilder: (context, state) => _fadeTransition(const AddEditCustomerScreen(), state),
          ),
          GoRoute(
            path: '/customers/edit',
            pageBuilder: (context, state) {
              final customer = state.extra as Customer;
              return _fadeTransition(AddEditCustomerScreen(customer: customer), state);
            },
          ),
          GoRoute(
            path: '/customers/:id',
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return _fadeTransition(CustomerDetailScreen(customerId: id), state);
            },
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) => _fadeTransition(const CategoryListScreen(), state),
          ),
          GoRoute(
            path: '/categories/add',
            pageBuilder: (context, state) => _fadeTransition(const AddEditCategoryScreen(), state),
          ),
          GoRoute(
            path: '/categories/edit',
            pageBuilder: (context, state) {
              final category = state.extra as Category;
              return _fadeTransition(AddEditCategoryScreen(category: category), state);
            },
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) => _fadeTransition(const ProductListScreen(), state),
          ),
          GoRoute(
            path: '/products/add',
            pageBuilder: (context, state) => _fadeTransition(const AddEditProductScreen(), state),
          ),
          GoRoute(
            path: '/products/edit',
            pageBuilder: (context, state) {
              final product = state.extra as Product;
              return _fadeTransition(AddEditProductScreen(product: product), state);
            },
          ),
          GoRoute(
            path: '/products/:id',
            pageBuilder: (context, state) {
              final product = state.extra as Product;
              return _fadeTransition(ProductDetailScreen(product: product), state);
            },
          ),
          GoRoute(
            path: '/invoices',
            pageBuilder: (context, state) => _fadeTransition(const InvoiceListScreen(), state),
          ),
          GoRoute(
            path: '/invoices/create',
            pageBuilder: (context, state) => _fadeTransition(const CreateInvoiceScreen(), state),
          ),
          GoRoute(
            path: '/invoices/:id',
            pageBuilder: (context, state) {
              final invoice = state.extra as Invoice;
              return _fadeTransition(InvoiceDetailScreen(invoice: invoice), state);
            },
          ),
          GoRoute(
            path: '/payments',
            pageBuilder: (context, state) => _fadeTransition(const PaymentListScreen(), state),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => _fadeTransition(const ReportsScreen(), state),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _fadeTransition(const SettingsScreen(), state),
          ),
          GoRoute(
            path: '/settings/users',
            pageBuilder: (context, state) => _fadeTransition(const ManageUsersScreen(), state),
          ),
          GoRoute(
            path: '/pos',
            pageBuilder: (context, state) => _fadeTransition(const POSScreen(), state),
          ),
        ],
      ),
    ],
  );
});
