import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clothes_provider.dart';
import 'login_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<ClothesProvider>(context, listen: false).loadMyListings()
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please login to view your listings'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    return Consumer<ClothesProvider>(
      builder: (context, clothesProvider, child) {
        if (clothesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (clothesProvider.myListings.isEmpty) {
          return const Center(child: Text('You have no listings yet'));
        }

        return ListView.builder(
          itemCount: clothesProvider.myListings.length,
          itemBuilder: (context, index) {
            final clothes = clothesProvider.myListings[index];
            
            // Parse price as double
            final price = (clothes['price'] is String) 
                ? double.tryParse(clothes['price']) ?? 0.0
                : (clothes['price'] as num?)?.toDouble() ?? 0.0;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: clothes['image_base64'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(
                          base64Decode(clothes['image_base64']),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: const Icon(Icons.error_outline),
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                title: Text(clothes['title'] ?? 'No title'),
                subtitle: Text('\$${price.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // TODO: Implement delete functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delete functionality coming soon'),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
} 