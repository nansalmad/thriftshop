import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    print('CartScreen initialized'); // Debug print
    Future.microtask(() {
      print('Loading cart in CartScreen'); // Debug print
      Provider.of<CartProvider>(context, listen: false).loadCart(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (cartProvider.cartItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: cartProvider.cartItems.length,
          itemBuilder: (context, index) {
            final cartItem = cartProvider.cartItems[index];
            print('Building cart item: $cartItem'); // Debug print
            
            // Safely extract data with null checks
            final clothes = cartItem['clothes'] as Map<String, dynamic>?;
            if (clothes == null) {
              print('Clothes data is null for cart item: $cartItem');
              return const SizedBox.shrink(); // Skip this item
            }

            final quantity = cartItem['quantity'] as int? ?? 1;
            final cartItemId = cartItem['id'] as int?;
            if (cartItemId == null) {
              print('Cart item ID is null for item: $cartItem');
              return const SizedBox.shrink(); // Skip this item
            }

            // Debug print for clothes data
            print('Clothes data: $clothes');
            print('Image base64: ${clothes['image_base64']}');

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
                            print('Stack trace: $stackTrace');
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (quantity > 1) {
                          cartProvider.updateQuantity(
                            context,
                            cartItemId,
                            quantity - 1,
                          );
                        }
                      },
                    ),
                    Text('$quantity'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        cartProvider.updateQuantity(
                          context,
                          cartItemId,
                          quantity + 1,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        cartProvider.removeFromCart(context, cartItemId);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
} 