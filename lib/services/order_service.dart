import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/cart.dart';

class OrderService {
  final String baseUrl = 'http://localhost:8000/api'; // Update with your actual API URL

  Future<Order> createOrder({
    required Cart cart,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your authentication token here if needed
        },
        body: jsonEncode({
          'cart': cart.id,
          'shipping_name': shippingName,
          'shipping_phone': shippingPhone,
          'shipping_address': shippingAddress,
        }),
      );

      if (response.statusCode == 201) {
        return Order.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  Future<Order> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/update_status/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your authentication token here if needed
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update order status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<Order> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/update_payment_status/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your authentication token here if needed
        },
        body: jsonEncode({'payment_status': paymentStatus}),
      );

      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update payment status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating payment status: $e');
    }
  }

  Future<Map<String, dynamic>> getSellerInfo(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/seller_info/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your authentication token here if needed
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get seller info: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting seller info: $e');
    }
  }

  Future<Map<String, dynamic>> getBuyerInfo(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/buyer_info/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your authentication token here if needed
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get buyer info: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting buyer info: $e');
    }
  }
} 