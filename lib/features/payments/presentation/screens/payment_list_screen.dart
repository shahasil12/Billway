import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/payment_list_controller.dart';
import 'package:intl/intl.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({super.key});

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(paymentListProvider.notifier).fetchPayments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentListProvider);

    ref.listen<PaymentListState>(paymentListProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Ledger'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(paymentListProvider.notifier).fetchPayments(isRefresh: true),
        child: state.payments.isEmpty && state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.payments.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No payments recorded yet.')),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: state.payments.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.payments.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final payment = state.payments[index];
                      final date = payment.paymentDate != null ? DateFormat('MMM dd, yyyy h:mm a').format(DateTime.parse(payment.paymentDate!).toLocal()) : 'Unknown Date';
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: const Icon(Icons.payments, color: Colors.white),
                        ),
                        title: Text('Payment for Invoice #${payment.invoiceId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$date\nMethod: ${payment.paymentMethod}${payment.referenceNumber != null ? ' (Ref: ${payment.referenceNumber})' : ''}'),
                        isThreeLine: true,
                        trailing: Text(
                          '\$${payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
