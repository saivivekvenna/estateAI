import 'package:flutter/material.dart';
import 'login_page.dart';

// This is a placeholder wrapper that will handle authentication state
// You'll replace this with your actual implementation when you have a backend
class AuthWrapper extends StatefulWidget {
  final Widget child;
  
  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;

  void _handleAuthSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If authenticated, show the main app
    if (_isAuthenticated) {
      return widget.child;
    }
    
    // Otherwise, show the login page
    return LoginPage(onLogin: _handleAuthSuccess);
  }
}

