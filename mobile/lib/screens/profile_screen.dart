import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clothes_provider.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 0;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  String? _selectedImageBase64;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();

    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final clothesProvider =
          Provider.of<ClothesProvider>(context, listen: false);

      // Load user data
      if (authProvider.isAuthenticated) {
        _firstNameController.text = authProvider.user?['first_name'] ?? '';
        _lastNameController.text = authProvider.user?['last_name'] ?? '';
        _emailController.text = authProvider.user?['email'] ?? '';

        // Load user's items and ratings
        clothesProvider.loadMyListings();
        clothesProvider.loadSoldItems();
        clothesProvider.loadBoughtItems();
        clothesProvider.loadUserRatings();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          // 2MB limit
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image should be less than 2MB')),
          );
          return;
        }

        setState(() {
          _selectedImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        profileImage: _selectedImageBase64,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      setState(() {
        _isEditing = false;
        _selectedImageBase64 = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle_outlined,
                    size: 80, color: theme.primaryColor),
                const SizedBox(height: 20),
                Text(
                  'Sign in to view your profile',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Profile Header
          _buildProfileHeader(authProvider),

          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton('Profile', 0, Icons.person),
                _buildNavButton('Selling', 1, Icons.store),
                _buildNavButton('Sold', 2, Icons.done_all),
                _buildNavButton('Bought', 3, Icons.shopping_bag),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Content Area
          Expanded(
            child: _getSelectedView(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: _isEditing ? _selectProfileImage : null,
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: _isEditing && _selectedImageBase64 != null
                      ? ClipOval(
                          child: Image.memory(
                            base64Decode(_selectedImageBase64!),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                      : authProvider.user?['profile_image'] != null
                          ? ClipOval(
                              child: Image.memory(
                                base64Decode(
                                    authProvider.user!['profile_image']),
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                ),
              ),
              if (_isEditing)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isEditing)
            Text(
              '${authProvider.user?['first_name']} ${authProvider.user?['last_name']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 4),
          if (!_isEditing)
            Text(
              authProvider.user?['email'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 10),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String label, int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedView() {
    switch (_selectedIndex) {
      case 0:
        return _buildProfileTab();
      case 1:
        return _buildItemsTab('selling');
      case 2:
        return _buildItemsTab('sold');
      case 3:
        return _buildItemsTab('bought');
      default:
        return _buildProfileTab();
    }
  }

  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'First name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Last name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Email is required' : null,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Account Information',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              Icons.person,
              'Name',
              '${authProvider.user?['first_name']} ${authProvider.user?['last_name']}',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              Icons.email,
              'Email',
              authProvider.user?['email'] ?? '',
            ),
          ],
          const SizedBox(height: 30),
          Text(
            'Ratings & Reviews',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Consumer<ClothesProvider>(
            builder: (context, clothesProvider, child) {
              if (clothesProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final ratings = clothesProvider.userRatings;
              if (ratings.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.star_border,
                          size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      const Text(
                        'No ratings yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ratings.length,
                itemBuilder: (context, index) {
                  final rating = ratings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  rating['rating'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'By ${rating['buyer_name']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (rating['comment'] != null) ...[
                            const SizedBox(height: 10),
                            Text(rating['comment']),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab(String type) {
    return Consumer<ClothesProvider>(
      builder: (context, clothesProvider, child) {
        if (clothesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = type == 'selling'
            ? clothesProvider.myListings
            : type == 'sold'
                ? clothesProvider.soldItems
                : clothesProvider.boughtItems;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'selling'
                      ? Icons.add_shopping_cart
                      : type == 'sold'
                          ? Icons.check_circle
                          : Icons.shopping_bag,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  type == 'selling'
                      ? 'No Active Listings'
                      : type == 'sold'
                          ? 'No Sold Items'
                          : 'No Bought Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  type == 'selling'
                      ? 'Your listings will appear here'
                      : type == 'sold'
                          ? 'Items you sell will appear here'
                          : 'Items you buy will appear here',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                if (type == 'selling') ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add navigation to create listing screen
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Listing'),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (type == 'selling') {
              await clothesProvider.loadMyListings();
            } else if (type == 'sold') {
              await clothesProvider.loadSoldItems();
            } else {
              await clothesProvider.loadBoughtItems();
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemCard(item, type);
            },
          ),
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String type) {
    final price = (item['price'] is String)
        ? double.tryParse(item['price']) ?? 0.0
        : (item['price'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: item['image_base64'] != null
                    ? Image.memory(
                        base64Decode(item['image_base64']),
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 40,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'No title',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (type == 'selling')
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptionsBottomSheet(context, item),
              ),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(
      BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading:
                    Icon(Icons.edit, color: Theme.of(context).primaryColor),
                title: const Text('Edit Listing'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit functionality
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Listing',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement delete functionality
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
