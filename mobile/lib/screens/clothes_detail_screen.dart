import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/clothes_provider.dart';

class ClothesDetailScreen extends StatelessWidget {
  final Map<String, dynamic> clothes;

  const ClothesDetailScreen({
    super.key, 
    required this.clothes,
  });

  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    
    if (price is num) {
      return price.toStringAsFixed(2);
    }
    
    if (price is String) {
      final numValue = double.tryParse(price);
      return numValue?.toStringAsFixed(2) ?? '0.00';
    }
    
    return '0.00';
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'Тодорхойгүй';
    switch (gender) {
      case 'M': return 'Эрэгтэй';
      case 'F': return 'Эмэгтэй';
      case 'U': return 'Хоёр хүйст';
      default: return 'Тодорхойгүй';
    }
  }

  String _formatCondition(String? condition) {
    if (condition == null) return 'Тодорхойгүй';
    switch (condition) {
      case 'new': return 'Шинэ (шошготой)';
      case 'like_new': return 'Шинэ шиг';
      case 'good': return 'Сайн';
      case 'fair': return 'Дунд';
      case 'poor': return 'Муу';
      default: return 'Тодорхойгүй';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Тодорхойгүй';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Тодорхойгүй';
    }
  }

  Widget _buildProductImage() {
    return Hero(
      tag: 'product_${clothes['id']}',
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.1), Colors.transparent],
          ),
        ),
        child: Stack(
          children: [
            if (clothes['image_base64'] != null)
              Positioned.fill(
                child: Image.memory(
                  base64Decode(clothes['image_base64']),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                ),
              )
            else
              _buildPlaceholderImage(),
            
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),

            // Sold overlay
            if (clothes['is_sold'] == true)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ЗАРЛАГДСАН',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 60,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${_formatPrice(clothes['price'])}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (clothes['original_price'] != null)
                Text(
                  'Original: \$${_formatPrice(clothes['original_price'])}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
            ],
          ),
          Chip(
            backgroundColor: clothes['is_sold'] == true ? Colors.red[50] : Colors.green[50],
            label: Text(
              clothes['is_sold'] == true ? 'Зарлагдсан' : 'Боломжтой',
              style: TextStyle(
                color: clothes['is_sold'] == true ? Colors.red[800] : Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Борлуулагчийн мэдээлэл',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                child: clothes['owner']?['profile_image'] != null
                    ? ClipOval(
                        child: Image.memory(
                          base64Decode(clothes['owner']['profile_image']),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        clothes['owner']?['first_name']?.isNotEmpty == true
                            ? clothes['owner']['first_name'][0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${clothes['owner']?['first_name'] ?? ''} ${clothes['owner']?['last_name'] ?? ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Гишүүнчлэл: ${_formatDate(clothes['owner']?['date_joined'])}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Тайлбар',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            clothes['description'] ?? 'Тайлбар байхгүй',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Бүтээгдэхүүний дэлгэрэнгүй',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDetailRow(context, 'Төлөв', _formatCondition(clothes['condition'])),
              _buildDetailRow(context, 'Хэмжээ', clothes['size'] ?? 'Тодорхойгүй'),
              _buildDetailRow(context, 'Хүйс', _formatGender(clothes['gender'])),
              _buildDetailRow(context, 'Брэнд', clothes['brand'] ?? 'Тодорхойгүй'),
              if (clothes['original_price'] != null)
                _buildDetailRow(context, 'Жинхэнэ үнэ', '\$${_formatPrice(clothes['original_price'])}'),
              if (clothes['reason_for_sale'] != null)
                _buildDetailRow(context, 'Зарах шалтгаан', clothes['reason_for_sale']),
              _buildDetailRow(context, 'Зарсан огноо', _formatDate(clothes['created_at'])),
              _buildDetailRow(context, 'Шинэчилсэн огноо', _formatDate(clothes['updated_at'])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Хүргэлт & Авах',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                context, 
                'Авах боломжтой', 
                clothes['available_for_pickup'] == true ? 'Тийм' : 'Үгүй'
              ),
              if (clothes['available_for_pickup'] == true && clothes['pickup_location'] != null)
                _buildDetailRow(context, 'Авах газар', clothes['pickup_location']),
              if (clothes['shipping_cost'] != null)
                _buildDetailRow(context, 'Хүргэлтийн төлбөр', '\$${_formatPrice(clothes['shipping_cost'])}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.contact_page_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Холбоо барих',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (clothes['phone_number'] != null)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  'Утас',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                subtitle: Text(
                  '${clothes['phone_number']}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.phone_forwarded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    // Implement call functionality
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleBuy(BuildContext context) async {
    try {
      final clothesProvider = Provider.of<ClothesProvider>(context, listen: false);
      
      // Attempt to buy the item
      await clothesProvider.buyClothes(clothes['id']);
      
      // Get the updated item details
      final updatedClothes = await clothesProvider.getClothesById(clothes['id']);
      
      // Refresh the main clothes list
      await clothesProvider.loadClothes();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бүтээгдэхүүн амжилттай худалдан авлаа!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return to previous screen with the updated clothes data
        Navigator.pop(context, updatedClothes);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Бүтээгдэхүүн худалдан авахад амжилтгүй боллоо: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          clothes['title'] ?? 'Гарчиггүй',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border, size: 20),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Дуртай болгосон'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share, size: 20),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Хуваалцах сонголт удахгүй ирэх болно'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildProductImage(),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clothes['title'] ?? 'Гарчиггүй',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (clothes['brand'] != null)
                    Text(
                      'by ${clothes['brand']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                    ),
                  const SizedBox(height: 24),
                  _buildPricingSection(context),
                  const SizedBox(height: 32),
                  _buildOwnerSection(context),
                  const SizedBox(height: 32),
                  _buildDescriptionSection(context),
                  const SizedBox(height: 32),
                  _buildDetailsSection(context),
                  const SizedBox(height: 32),
                  _buildShippingSection(context),
                  const SizedBox(height: 32),
                  _buildContactSection(context),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (!clothes['is_sold'])
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleBuy(context),
                            icon: const Icon(Icons.shopping_bag),
                            label: const Text('Одоо худалдан авах'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      if (!clothes['is_sold']) const SizedBox(width: 16),
                      Expanded(
                        child: Consumer<CartProvider>(
                          builder: (context, cartProvider, child) {
                            final isInCart = cartProvider.isInCart(clothes['id']);
                            return ElevatedButton.icon(
                              onPressed: clothes['is_sold'] || isInCart
                                  ? null
                                  : () => cartProvider.addToCart(context, clothes['id']),
                              icon: Icon(isInCart ? Icons.check : Icons.add_shopping_cart),
                              label: Text(isInCart ? 'Сагсанд байна' : 'Сагсанд нэмэх'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}