import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/customer_list_controller.dart';
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

    ref.listen<CustomerListState>(customerListProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customerListProvider.notifier).fetchCustomers(isRefresh: true),
        child: state.customers.isEmpty && state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.customers.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No customers found.')),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: state.customers.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.customers.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final customer = state.customers[index];
                      return Dismissible(
                        key: ValueKey(customer.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text("Are you sure you wish to delete this customer?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("CANCEL")),
                                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("DELETE")),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          ref.read(customerListProvider.notifier).deleteCustomer(customer.id!);
                        },
                        child: ListTile(
                          title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${customer.email ?? ''} • ${customer.phone ?? ''}'),
                          onTap: () {
                            context.push('/customers/${customer.id}');
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.push('/customers/edit', extra: customer),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/customers/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
