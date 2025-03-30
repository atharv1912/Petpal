import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/SupabaseServices.dart';
import 'package:flutter_application_1/screens/users/RegisterPage.dart';
import 'package:flutter_application_1/screens/users/HomePage.dart';
import 'package:flutter_application_1/screens/volunteer/AlertScreen.dart'; // Import the volunteer alert screen

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _supabaseService.loginUser(
          context: context,
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (success) {
          // Fetch user details to check role
          final userDetails = await _supabaseService.fetchUserDetails();

          if (userDetails != null) {
            final userRole =
                userDetails['role']?.toString().toLowerCase() ?? 'users';

            // Navigate based on role
            if (userRole == 'volunteer') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AlertScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            }
          } else {
            // If user details couldn't be fetched, go to home page as fallback
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 30),
        color: Color(0xFF222831),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/expenses.png', height: 80),
                  SizedBox(height: 10),
                  Text(
                    "PetPal",
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildEmailField(),
                  SizedBox(height: 15),
                  _buildPasswordField(),
                  SizedBox(height: 24),
                  _isLoading ? _buildLoadingIndicator() : _buildLoginButton(),
                  SizedBox(height: 20),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.email, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        hintText: "Email",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: _validatePassword,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white,
        hintText: "Password",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return CircularProgressIndicator(color: Colors.white);
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 241, 8, 225),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: EdgeInsets.symmetric(horizontal: 140, vertical: 12),
      ),
      child: Text(
        "Login",
        style: TextStyle(fontSize: 18, color: Color(0xFF222831)),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterScreen()),
        );
      },
      child: Text(
        "Don't have an account? Register",
        style: TextStyle(
          color: Colors.white,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
