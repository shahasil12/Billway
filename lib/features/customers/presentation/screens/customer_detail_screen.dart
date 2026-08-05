import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';
import '../../../../core/providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app you might want to fetch details from API 
    // or pass the customer object directly to avoid extra fetches.
    // For this example, we assume we want to view it. 
    
    // As a simple implementation, we can just use a FutureBuilder 
    // to fetch the specific customer by ID.
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: FutureBuilder(
        future: ref.read(customerRepositoryProvider).getCustomer(customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final result = snapshot.data;
          if (result == null) return const Center(child: Text('Not found'));

          return result.fold(
            (failure) => Center(child: Text(failure.message)),
            (customer) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(customer.name, style: const TextStyle(fontSize: 22)),
                  const Divider(height: 32),
                  const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(customer.email?.isNotEmpty == true ? customer.email! : 'N/A', style: const TextStyle(fontSize: 18)),
                  const Divider(height: 32),
                  const Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(customer.phone?.isNotEmpty == true ? customer.phone! : 'N/A', style: const TextStyle(fontSize: 18)),
                  const Divider(height: 32),
                  const Text('Created At', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(customer.createdAt ?? 'N/A', style: const TextStyle(fontSize: 18)),
                ],
              ),
            )
          );
        }
      ),
    );
  }
}
