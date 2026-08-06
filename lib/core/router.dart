import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/home_screen.dart';

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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == '/login';
      
      if (authState.isLoading) {
        return null;
      }
      
      final isAuthenticated = authState.value != null;
      
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      
      if (isAuthenticated && isLoggingIn) {
        return '/';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerListScreen(),
      ),
      GoRoute(
        path: '/customers/add',
        builder: (context, state) => const AddEditCustomerScreen(),
      ),
      GoRoute(
        path: '/customers/edit',
        builder: (context, state) {
          final customer = state.extra as Customer;
          return AddEditCustomerScreen(customer: customer);
        },
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CustomerDetailScreen(customerId: id);
        },
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/categories/add',
        builder: (context, state) => const AddEditCategoryScreen(),
      ),
      GoRoute(
        path: '/categories/edit',
        builder: (context, state) {
          final category = state.extra as Category;
          return AddEditCategoryScreen(category: category);
        },
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/products/add',
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/products/edit',
        builder: (context, state) {
          final product = state.extra as Product;
          return AddEditProductScreen(product: product);
        },
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final product = state.extra as Product;
          return ProductDetailScreen(product: product);
        },
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: '/invoices/create',
        builder: (context, state) => const CreateInvoiceScreen(),
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (context, state) {
          final invoice = state.extra as Invoice;
          return InvoiceDetailScreen(invoice: invoice);
        },
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentListScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
    ],
  );
});
