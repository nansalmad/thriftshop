class Order {
  final int id;
  final Cart cart;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final String shippingName;
  final String shippingPhone;
  final String shippingAddress;
  final DateTime createdAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? paidAt;

  Order({
    required this.id,
    required this.cart,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.shippingName,
    required this.shippingPhone,
    required this.shippingAddress,
    required this.createdAt,
    this.shippedAt,
    this.deliveredAt,
    this.paidAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      cart: Cart.fromJson(json['cart']),
      status: json['status'],
      paymentStatus: json['payment_status'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      shippingName: json['shipping_name'],
      shippingPhone: json['shipping_phone'],
      shippingAddress: json['shipping_address'],
      createdAt: DateTime.parse(json['created_at']),
      shippedAt: json['shipped_at'] != null ? DateTime.parse(json['shipped_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart': cart.toJson(),
      'status': status,
      'payment_status': paymentStatus,
      'total_amount': totalAmount,
      'shipping_name': shippingName,
      'shipping_phone': shippingPhone,
      'shipping_address': shippingAddress,
      'created_at': createdAt.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
} 