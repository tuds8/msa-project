import 'package:flutter/material.dart';
import 'package:frontend/screens/home/home_page.dart';
import 'package:frontend/screens/orders/orders_page.dart';
import 'package:frontend/screens/profile/profile_page.dart';
import 'package:frontend/screens/shop/shop_page.dart';
import 'package:frontend/screens/shop/shop_register.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool isLoading = true; // Track loading state
  bool isSeller = false;
  int? sellerId; // Store seller ID
  Map<String, dynamic>? shopDetails;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // Fetch user profile
      final profileResponse = await ApiService.authenticatedGetRequest('profile');
      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        sellerId = profileData['id']; // Extract user ID
        final role = profileData['role'];
        isSeller = role == 'seller';

        // If the user is a seller, fetch shop details
        if (isSeller) {
          final shopResponse = await ApiService.authenticatedGetRequest('shop/manage');
          if (shopResponse.statusCode == 200) {
            shopDetails = jsonDecode(shopResponse.body); // Set shop details
          } else if (shopResponse.statusCode == 404) {
            shopDetails = null; // No shop associated
          } else {
            throw Exception('Failed to fetch shop details');
          }
        }
      } else {
        throw Exception('Failed to fetch profile data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    // Initialize pages after fetching data
    setState(() {
      _pages = [
        const HomePage(),
        const OrdersPage(),
        const ProfilePage(),
        if (isSeller)
          shopDetails == null
              ? RegisterShopPage(sellerId: sellerId!) // Pass seller ID to RegisterShopPage
              : ShopPage(isSeller: isSeller, sellerId: sellerId!), // Pass sellerId to ShopPage
      ];
      isLoading = false; // Loading complete
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          if (isSeller)
            const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // Selected icon color
        unselectedItemColor: Colors.grey, // Unselected icon color
        backgroundColor: Colors.white, // Background color for contrast
      ),
    );
  }
}
