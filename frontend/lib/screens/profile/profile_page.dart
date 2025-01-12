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
        if (mounted) {
          setState(() {
            _profileData = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load profile");
      }
    } catch (e) {
      if (mounted) {
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
              await ApiService.deleteTokens();
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
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Information Card
                          Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${_profileData!['first_name']} ${_profileData!['last_name']}",
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.email, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _profileData!['email'],
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(
                                        _profileData!['phone'] ?? "N/A",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Rating Information Card
                          Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Rating: ${_profileData!['rating'] ?? 'Not Rated'}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Role Information Card
                          Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.work, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Role: ${_profileData!['role']}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Update Profile Button
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UpdateProfilePage(profileData: _profileData!),
                                    ),
                                  ).then((_) {
                                    if (mounted) {
                                      _fetchProfile();
                                    }
                                  });
                                },
                                child: const Text("Update Profile"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text("Failed to load profile")),
            ),
    );
  }
}
