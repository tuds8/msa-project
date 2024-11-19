import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  String? selectedRole; // Nullable to ensure validation
  final List<String> roles = ["Customer", "Seller"];

  Future<void> registerUser(BuildContext context) async {
    if (selectedRole == null) {
      // Show an alert if role is not selected
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Missing Role"),
          content: const Text("Please select a role before submitting."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    print(selectedRole);

    final requestData = {
      "first_name": firstNameController.text,
      "last_name": lastNameController.text,
      "username": usernameController.text,
      "email": emailController.text,
      "password": passwordController.text,
      "phone": phoneNumberController.text,
      "role": selectedRole!.toLowerCase(),
    };

    try {
      final response = await ApiService.postRequest('register', requestData);

      if (response.statusCode == 201) {
        print("Registration successful");
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        print("Registration failed: ${response.body}");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Registration Failed"),
            content: Text(response.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error during registration: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
              ),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              TextField(
                controller: phoneNumberController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                items: roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: "Role"),
                validator: (value) =>
                    value == null ? "Please select a role" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => registerUser(context),
                child: const Text("Register"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Already have an account? Login here."),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
