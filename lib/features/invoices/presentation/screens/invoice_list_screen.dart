import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/invoice_list_controller.dart';
import 'dart:async';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
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
      ref.read(invoiceListProvider.notifier).fetchInvoices();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(invoiceListProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceListProvider);

    ref.listen<InvoiceListState>(invoiceListProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by customer name...',
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
        onRefresh: () => ref.read(invoiceListProvider.notifier).fetchInvoices(isRefresh: true),
        child: state.invoices.isEmpty && state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.invoices.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No invoices found.')),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: state.invoices.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.invoices.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final invoice = state.invoices[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: invoice.status == 'PAID' ? Colors.green : Colors.orange,
                          child: const Icon(Icons.receipt, color: Colors.white),
                        ),
                        title: Text(invoice.customer?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Invoice #${invoice.id} • ${invoice.paymentMethod}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${invoice.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(invoice.status, style: TextStyle(color: invoice.status == 'PAID' ? Colors.green : Colors.orange, fontSize: 12)),
                          ],
                        ),
                        onTap: () => context.push('/invoices/${invoice.id}', extra: invoice),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/invoices/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }
}
