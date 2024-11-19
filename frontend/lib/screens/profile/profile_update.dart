import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
// import 'dart:convert';

class UpdateProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const UpdateProfilePage({super.key, required this.profileData});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profileData['username']);
    _emailController = TextEditingController(text: widget.profileData['email']);
    _firstNameController = TextEditingController(text: widget.profileData['first_name']);
    _lastNameController = TextEditingController(text: widget.profileData['last_name']);
    _phoneController = TextEditingController(text: widget.profileData['phone']);
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    final updatedData = {
      "username": _usernameController.text,
      "email": _emailController.text,
      "first_name": _firstNameController.text,
      "last_name": _lastNameController.text,
      "phone": _phoneController.text,
    };

    try {
      final response = await ApiService.authenticatedPatchRequest("profile", updatedData);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context); // Go back to profile page
      } else {
        throw Exception("Failed to update profile");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: "First Name"),
            ),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text("Submit"),
                  ),
          ],
        ),
      ),
    );
  }
}
