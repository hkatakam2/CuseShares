import 'dart:io'; // For Platform check
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    final bool isAuthenticating = authViewModel.status == AuthStatus.authenticating;

    final Widget logo = Icon(
        Platform.isIOS ? CupertinoIcons.shopping_cart : Icons.food_bank_outlined,
        size: 80,
        color: Theme.of(context).primaryColor
    );

    final Widget title = Text(
      'Welcome to CuseFoodShare!',
      textAlign: TextAlign.center,
      style: Platform.isIOS
          ? CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)
          : Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );

    final Widget emailField = Platform.isIOS
      ? CupertinoTextFormFieldRow(
          controller: _emailController,
          prefix: Icon(CupertinoIcons.mail, color: CupertinoTheme.of(context).primaryColor),
          placeholder: 'Email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        )
      : TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        );

     final Widget passwordField = Platform.isIOS
      ? CupertinoTextFormFieldRow(
          controller: _passwordController,
          prefix: Icon(CupertinoIcons.lock, color: CupertinoTheme.of(context).primaryColor),
          placeholder: 'Password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        )
      : TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        );

      final Widget displayNameField = Platform.isIOS
        ? CupertinoTextFormFieldRow(
            controller: _displayNameController,
            prefix: Icon(CupertinoIcons.person, color: CupertinoTheme.of(context).primaryColor),
            placeholder: 'Display Name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your display name';
              }
              return null;
            },
          )
        : TextFormField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: 'Display Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your display name';
              }
              return null;
            },
          );

      final Widget submitButton = Platform.isIOS
        ? CupertinoButton.filled(
            child: isAuthenticating ? CupertinoActivityIndicator(color: Colors.white) : Text(_isLogin ? 'Login' : 'Register'),
            onPressed: isAuthenticating ? null : _submitForm,
          )
        : ElevatedButton(
            child: isAuthenticating ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isLogin ? 'Login' : 'Register'),
            onPressed: isAuthenticating ? null : _submitForm,
            // style: ElevatedButton.styleFrom(...), // From theme
          );

      // Google Button REMOVED
      /*
      final Widget googleButton = Platform.isIOS
        ? CupertinoButton(...)
        : ElevatedButton.icon(...);
      */

      final Widget toggleButton = Platform.isIOS
        ? CupertinoButton(
            child: Text(_isLogin ? 'Need an account? Register' : 'Have an account? Login'),
            onPressed: isAuthenticating ? null : () => setState(() => _isLogin = !_isLogin),
          )
        : TextButton(
            child: Text(_isLogin ? 'Need an account? Register' : 'Have an account? Login'),
            onPressed: isAuthenticating ? null : () => setState(() => _isLogin = !_isLogin),
          );

      final Widget loadingIndicator = Center(child: Platform.isIOS ? CupertinoActivityIndicator(radius: 15) : CircularProgressIndicator());

      final Widget errorMessage = authViewModel.errorMessage != null
        ? Padding(
            padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
            child: Text(
              authViewModel.errorMessage!,
              style: TextStyle(color: Platform.isIOS ? CupertinoColors.systemRed : Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          )
        : SizedBox.shrink(); // Empty space if no error


    // --- Build Method ---
    final Widget formContent = Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            logo,
            SizedBox(height: 20),
            title,
            SizedBox(height: 30),
            if (!_isLogin) displayNameField,
            if (!_isLogin && !Platform.isIOS) SizedBox(height: 16),
             if (!_isLogin && Platform.isIOS) SizedBox(height: 8),
            emailField,
            if (!Platform.isIOS) SizedBox(height: 16),
             if (Platform.isIOS) SizedBox(height: 8),
            passwordField,
            SizedBox(height: 24),
            if (authViewModel.status == AuthStatus.authenticating) loadingIndicator,
            errorMessage, // Show error message here
            submitButton,
            SizedBox(height: 12),
            // Google Button REMOVED
            // googleButton,
            // SizedBox(height: 20),
            toggleButton,
          ],
        ),
      );


     final PreferredSizeWidget appBar = Platform.isIOS
        ? CupertinoNavigationBar(
            middle: Text(_isLogin ? 'Login' : 'Register'),
          )
        : AppBar(
            title: Text(_isLogin ? 'Login - CuseFoodShare' : 'Register - CuseFoodShare'),
          );

     return Platform.isIOS
        ? CupertinoPageScaffold(
            navigationBar: appBar as ObstructingPreferredSizeWidget,
            child: SafeArea( // Ensure content is below navigation bar
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: formContent,
                ),
              ),
            ),
          )
        : Scaffold(
            appBar: appBar,
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: formContent,
              ),
            ),
          );
  }

  // Helper function for form submission logic
  void _submitForm() async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      bool isValid = true;
      if (Platform.isAndroid) {
          isValid = _formKey.currentState?.validate() ?? false; // Check if form state exists
      } else {
         // Basic manual checks for iOS
         if (_emailController.text.isEmpty || !_emailController.text.contains('@')) isValid = false;
         if (_passwordController.text.isEmpty || _passwordController.text.length < 6) isValid = false;
         if (!_isLogin && _displayNameController.text.isEmpty) isValid = false;
      }

      if (isValid) {
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
        // Navigation handled by AuthWrapper
      } else if (Platform.isIOS) {
          // Show simple alert for validation error on iOS if needed
          showCupertinoDialog(
             context: context,
             builder: (ctx) => CupertinoAlertDialog(
                title: Text('Invalid Input'),
                content: Text('Please check your entries and try again.'),
                actions: [CupertinoDialogAction(isDefaultAction: true, child: Text('OK'), onPressed: () => Navigator.pop(ctx))],
             )
          );
      }
  }
}

// Helper class for CupertinoTextFormFieldRow (keep as previously provided)
class CupertinoTextFormFieldRow extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final void Function(String)? onChanged;


  const CupertinoTextFormFieldRow({
    Key? key,
    this.controller,
    this.placeholder,
    this.prefix,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
  }) : super(key: key);

  @override
  _CupertinoTextFormFieldRowState createState() => _CupertinoTextFormFieldRowState();
}

class _CupertinoTextFormFieldRowState extends State<CupertinoTextFormFieldRow> {
  String? errorText;

  // Method to be called by parent Form or equivalent to trigger validation display
  bool validate() {
    if (widget.validator != null) {
      final String? currentError = widget.validator!(widget.controller?.text ?? '');
      if (errorText != currentError) {
         setState(() {
           errorText = currentError;
         });
      }
      return errorText == null;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: widget.controller,
          placeholder: widget.placeholder,
          prefix: widget.prefix,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            border: Border.all(color: errorText != null ? CupertinoColors.systemRed : CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8.0),
          ),
          onChanged: widget.onChanged, // Pass onChanged
          // onChanged: (_) => validate(), // Optionally validate on change
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 16.0),
            child: Text(
              errorText!,
              style: TextStyle(color: CupertinoColors.systemRed, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
