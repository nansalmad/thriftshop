import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/clothes_provider.dart';
import '../models/clothes_category.dart';

class AddClothesScreen extends StatefulWidget {
  const AddClothesScreen({super.key});

  @override
  State<AddClothesScreen> createState() => _AddClothesScreenState();
}

class _AddClothesScreenState extends State<AddClothesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sizeController = TextEditingController();
  final _brandController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _shippingCostController = TextEditingController();
  final _reasonController = TextEditingController();
  final _originalPriceController = TextEditingController();

  XFile? _imageFile;
  String? _imageBase64;
  String _selectedGender = 'U';
  String _selectedCondition = 'good';
  int? _selectedCategoryId;
  bool _availableForPickup = false;
  bool _isSubmitting = false;

  final Map<String, String> _genderChoices = {
    'M': 'Male',
    'F': 'Female',
    'U': 'Unisex',
  };

  final Map<String, String> _conditionChoices = {
    'new': 'Brand New (with tags)',
    'like_new': 'Like New',
    'good': 'Good',
    'fair': 'Fair',
    'poor': 'Poor',
  };

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Parse price and original price
      final price = double.parse(_priceController.text);
      final originalPrice = _originalPriceController.text.isNotEmpty 
          ? double.parse(_originalPriceController.text) 
          : null;
      
      // Parse shipping cost
      final shippingCost = _shippingCostController.text.isNotEmpty 
          ? double.parse(_shippingCostController.text) 
          : null;

      // Get other optional fields
      final size = _sizeController.text.trim().isNotEmpty ? _sizeController.text.trim() : null;
      final brand = _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null;
      final pickupLocation = _pickupLocationController.text.trim().isNotEmpty 
          ? _pickupLocationController.text.trim() 
          : null;
      final reasonForSale = _reasonController.text.trim().isNotEmpty 
          ? _reasonController.text.trim() 
          : null;

      await Provider.of<ClothesProvider>(context, listen: false).addClothes(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        price,
        _imageBase64!,
        _phoneController.text.trim(),
        _selectedCategoryId!,
        _selectedGender,
        condition: _selectedCondition,
        originalPrice: originalPrice,
        size: size,
        brand: brand,
        availableForPickup: _availableForPickup,
        pickupLocation: pickupLocation,
        shippingCost: shippingCost,
        reasonForSale: reasonForSale,
      );

      if (!mounted) return;
      
      // Refresh the clothes list before popping
      await Provider.of<ClothesProvider>(context, listen: false).loadClothes();
      
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _sizeController.dispose();
    _brandController.dispose();
    _pickupLocationController.dispose();
    _shippingCostController.dispose();
    _reasonController.dispose();
    _originalPriceController.dispose();
    super.dispose();
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Icon(Icons.add_a_photo, size: 50)),
      );
    }

    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: kIsWeb
                  ? NetworkImage(_imageFile!.path)
                  : FileImage(File(_imageFile!.path)) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() {
                _imageFile = null;
                _imageBase64 = null;
              }),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item')),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: _buildImagePreview(),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title*'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description*'),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                          labelText: 'Price*', prefixText: '\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        final price = double.tryParse(value!);
                        if (price == null) return 'Invalid number';
                        if (price <= 0) return 'Price must be greater than 0';
                        return null;
                      },
                    ),

                    // Original Price
                    TextFormField(
                      controller: _originalPriceController,
                      decoration: const InputDecoration(
                          labelText: 'Original Price', prefixText: '\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return null;
                        final price = double.tryParse(value!);
                        if (price == null) return 'Invalid number';
                        if (price <= 0) return 'Price must be greater than 0';
                        return null;
                      },
                    ),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Contact Phone*'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value!)) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),

                    // Size
                    TextFormField(
                      controller: _sizeController,
                      decoration: const InputDecoration(labelText: 'Size'),
                    ),

                    // Brand
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(labelText: 'Brand'),
                    ),

                    // Condition
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      items: _conditionChoices.entries
                          .map((e) =>
                              DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCondition = value!),
                      decoration: const InputDecoration(labelText: 'Condition*'),
                    ),

                    // Gender
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      items: _genderChoices.entries
                          .map((e) =>
                              DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedGender = value!),
                      decoration: const InputDecoration(labelText: 'Gender*'),
                    ),

                    // Category
                    FutureBuilder<List<ClothesCategory>>(
                      future: Provider.of<ClothesProvider>(context, listen: false)
                          .getCategories(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        return DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          items: snapshot.data
                              ?.map((category) => DropdownMenuItem(
                                    value: category.id,
                                    child: Text(category.name),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedCategoryId = value),
                          decoration: const InputDecoration(labelText: 'Category*'),
                          validator: (value) => value == null ? 'Required' : null,
                        );
                      },
                    ),

                    // Pickup Options
                    SwitchListTile(
                      title: const Text('Available for Pickup'),
                      value: _availableForPickup,
                      onChanged: (value) =>
                          setState(() => _availableForPickup = value),
                    ),
                    if (_availableForPickup)
                      TextFormField(
                        controller: _pickupLocationController,
                        decoration:
                            const InputDecoration(labelText: 'Pickup Location'),
                        validator: (value) =>
                            _availableForPickup && (value?.isEmpty ?? true)
                                ? 'Required when pickup is available'
                                : null,
                      ),

                    // Shipping Cost
                    TextFormField(
                      controller: _shippingCostController,
                      decoration: const InputDecoration(
                          labelText: 'Shipping Cost', prefixText: '\$ '),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isNotEmpty ?? false) {
                          if (double.tryParse(value!) == null) return 'Invalid number';
                          if (double.parse(value) < 0) return 'Cost cannot be negative';
                        }
                        return null;
                      },
                    ),

                    // Reason for Sale
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Reason for Sale'),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
