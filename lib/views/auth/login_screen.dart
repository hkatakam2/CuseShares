import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuse_food_share_app/viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController(); // For registration
  bool _isLogin = true; // Toggle between Login and Register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login - CuseFoodShare' : 'Register - CuseFoodShare'),
        backgroundColor: Colors.orange[800],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo Placeholder (Optional)
                 Icon(Icons.food_bank_outlined, size: 80, color: Colors.orange[800]),
                 SizedBox(height: 20),
                 Text(
                    'Welcome to CuseFoodShare!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                 ),
                 SizedBox(height: 30),

                // Display Name Field (Only for Registration)
                if (!_isLogin)
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your display name';
                      }
                      return null;
                    },
                  ),
                if (!_isLogin) SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Loading Indicator / Error Message
                if (authViewModel.status == AuthStatus.authenticating)
                  Center(child: CircularProgressIndicator())
                else if (authViewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        authViewModel.errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),


                // Submit Button (Login/Register)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)
                    ),
                    textStyle: TextStyle(fontSize: 18)
                  ),
                  child: Text(_isLogin ? 'Login' : 'Register', style: TextStyle(color: Colors.white)),
                  onPressed: authViewModel.status == AuthStatus.authenticating
                      ? null // Disable button while loading
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            bool success;
                            if (_isLogin) {
                              success = await authViewModel.signInWithEmail(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            } else {
                               success = await authViewModel.registerWithEmail(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                                _displayNameController.text.trim(),
                              );
                            }
                            // No need to check success here, the AuthWrapper will navigate
                            // if (success) {
                            //   // Navigation handled by AuthWrapper stream
                            // } else {
                            //   // Error message is shown via the view model listener
                            // }
                          }
                        },
                ),
                SizedBox(height: 12),

                // Google Sign-In Button
                ElevatedButton.icon(
                   icon: Image.asset('assets/images/google_logo.png', height: 24.0), // Make sure you have a google logo asset
                   label: Text('Sign in with Google', style: TextStyle(color: Colors.grey[700])),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     foregroundColor: Colors.black, // Text color
                     padding: EdgeInsets.symmetric(vertical: 12),
                     shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8.0),
                         side: BorderSide(color: Colors.grey[300]!)
                     ),
                     textStyle: TextStyle(fontSize: 16)
                   ),
                  onPressed: authViewModel.status == AuthStatus.authenticating
                      ? null
                      : () {
                          authViewModel.signInWithGoogle();
                        },
                ),
                SizedBox(height: 20),

                // Toggle Button (Login/Register)
                TextButton(
                  child: Text(
                    _isLogin
                        ? 'Need an account? Register'
                        : 'Have an account? Login',
                    style: TextStyle(color: Colors.orange[900]),
                  ),
                  onPressed: authViewModel.status == AuthStatus.authenticating
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                            // Clear errors when switching modes
                            // authViewModel.clearError(); // Add a clearError method if needed
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}