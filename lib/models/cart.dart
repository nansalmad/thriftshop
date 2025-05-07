class Cart {
  final int id;
  final List<Map<String, dynamic>> items;

  Cart({
    required this.id,
    required this.items,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      items: List<Map<String, dynamic>>.from(json['items']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items,
    };
  }
} 