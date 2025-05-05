import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/clothes_category.dart';
import '../services/api_service.dart';

class ClothesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _clothes = [];
  List<Map<String, dynamic>> _myListings = [];
  List<ClothesCategory> _categories = [];
  bool _isLoading = false;
  final String baseUrl = 'http://127.0.0.1:8000/api'; // Update for Android emulator
  // final String baseUrl = 'http://localhost:8000/api'; // Use this for iOS simulator

  List<Map<String, dynamic>> get clothes => _clothes;
  List<Map<String, dynamic>> get myListings => _myListings;
  List<ClothesCategory> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadClothes({
    String? searchQuery,
    int? categoryId,
    String? gender,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _clothes = await _apiService.getClothes(
        searchQuery: searchQuery,
        categoryId: categoryId,
        gender: gender,
      );
      await loadCategories();
    } catch (e) {
      print('Error loading clothes: $e');
      _clothes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyListings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _myListings = await _apiService.getMyListings();
    } catch (e) {
      print('Error loading my listings: $e');
      _myListings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getClothesById(int id) async {
    try {
      _isLoading = true;
      notifyListeners();
      final response = await http.get(
        Uri.parse('$baseUrl/clothes/$id/'),
        headers: {'Accept': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      throw Exception('Failed to load clothes details');
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<List<ClothesCategory>> getCategories() async {
    if (_categories.isEmpty) {
      await loadCategories();
    }
    return _categories;
  }

  Future<void> addClothes(
    String title,
    String description,
    double price,
    String imageBase64,
    String phoneNumber,
    int categoryId,
    String gender,
  ) async {
    try {
      await _apiService.addClothes(
        title,
        description,
        price,
        imageBase64,
        phoneNumber,
        categoryId,
        gender,
      );
      await loadMyListings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getClothes() async {
    try {
      _clothes = await _apiService.getClothes();
      notifyListeners();
    } catch (e) {
      print('Error fetching clothes: $e');
      rethrow;
    }
  }
} 