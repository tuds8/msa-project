import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/profile/profile_update.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiService.authenticatedGetRequest("profile");
      if (response.statusCode == 200) {
        if (mounted) { // Ensure the widget is still in the widget tree
          setState(() {
            _profileData = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load profile");
      }
    } catch (e) {
      if (mounted) { // Ensure the widget is still in the widget tree
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _refresh() async {
    await _fetchProfile();
  }

  @override
  void dispose() {
    // Clean up any resources here if needed before the widget is destroyed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.deleteTokens(); // Clear stored tokens
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: "Logout",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _profileData != null
                  ? ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Text("Username: ${_profileData!['username']}", style: const TextStyle(fontSize: 18)),
                        Text("Email: ${_profileData!['email']}", style: const TextStyle(fontSize: 18)),
                        Text("First Name: ${_profileData!['first_name']}", style: const TextStyle(fontSize: 18)),
                        Text("Last Name: ${_profileData!['last_name']}", style: const TextStyle(fontSize: 18)),
                        Text("Phone: ${_profileData!['phone']}", style: const TextStyle(fontSize: 18)),
                        Text("Rating: ${_profileData!['rating']}", style: const TextStyle(fontSize: 18)),
                        Text("Role: ${_profileData!['role']}", style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdateProfilePage(profileData: _profileData!),
                              ),
                            ).then((_) {
                              if (mounted) {
                                _fetchProfile(); // Refresh profile after update if widget is mounted
                              }
                            });
                          },
                          child: const Text("Update Profile"),
                        ),
                      ],
                    )
                  : const Center(child: Text("Failed to load profile")),
            ),
    );
  }
}

