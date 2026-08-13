import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/customer_list_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/app_buttons.dart';
import 'dart:async';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerListProvider.notifier).fetchCustomers();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(customerListProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerListProvider);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: PrimaryButton(
              label: 'Add Customer',
              onPressed: () => context.push('/customers/add'),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
              vertical: AppSpacing.p8,
            ),
            child: SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hint: 'Search customers by name or phone...',
            ),
          ),
        ),
      ),
      body: _buildBody(context, state, isTablet),
    );
  }

  Widget _buildBody(BuildContext context, CustomerListState state, bool isTablet) {
    if (state.isLoading && state.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.p16),
            Text(state.error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: AppSpacing.p16),
            SizedBox(
              width: 120,
              child: PrimaryButton(
                label: 'Retry',
                onPressed: () => ref.read(customerListProvider.notifier).fetchCustomers(isRefresh: true),
              ),
            ),
          ],
        ),
      );
    }

    if (state.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.p16),
            const Text('No customers yet', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.p24),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Add First Customer',
                onPressed: () => context.push('/customers/add'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(customerListProvider.notifier).fetchCustomers(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? AppSpacing.p32 : 0,
          vertical: AppSpacing.p16,
        ),
        itemCount: state.customers.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.customers.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.p16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final customer = state.customers[index];
          
          final row = ListRow(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                customer.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            title: customer.name,
            subtitle: customer.phone ?? customer.email ?? 'No contact info',
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
              onPressed: () => context.push('/customers/edit', extra: customer),
            ),
            onTap: () => context.push('/customers/${customer.id}'),
          );

          if (isTablet) {
            return AppCard(
              padding: EdgeInsets.zero,
              child: row,
            );
          }
          return row;
        },
      ),
    );
  }
}
