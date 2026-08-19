import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/screens/auth_service.dart';
import 'auth_gate.dart'; // Import AuthGate

class LoginScreen extends StatefulWidget { // Renamed to AuthScreen in spirit
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> { // Removed AuthService as it's not directly used for navigation here
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _reenterPasswordController = TextEditingController();

  bool _isLoginView = true; // Controls whether to show Login or Sign Up form
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _reenterPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      User? user;

      if (_isLoginView) { // Login
        user = await _authService.signInWithEmailPassword(email, password);
      } else { // Sign Up
        final name = _nameController.text.trim();
        user = await _authService.signUpWithEmailPassword(name, email, password);
      }

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is FirebaseAuthException ? e.message : 'An error occurred.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message ?? 'Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Center the entire authentication box
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24), // Padding around the card
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'RR\nFabrications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  // fontStyle: FontStyle.italic, // Removed as it might not be desired for a logo
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 420, // Max width for the card
                child: Card(
                  elevation: 8, // Adds a shadow effect
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Rounded corners for the card
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Make column take minimum space
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoginView = true;
                                    _formKey.currentState?.reset(); // Clear form state on switch
                                  });
                                },
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: _isLoginView ? FontWeight.bold : FontWeight.normal,
                                    color: _isLoginView ? Theme.of(context).primaryColor : Colors.grey,
                                  ),
                                ),
                              ),
                              const Text(' | ', style: TextStyle(fontSize: 18, color: Colors.grey)),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoginView = false;
                                    _formKey.currentState?.reset(); // Clear form state on switch
                                  });
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: !_isLoginView ? FontWeight.bold : FontWeight.normal,
                                    color: !_isLoginView ? Theme.of(context).primaryColor : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (!_isLoginView) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Name'),
                              validator: (value) =>
                                  value!.isEmpty ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value!.isEmpty || !value.contains('@')
                                    ? 'Please enter a valid email'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) => value!.length < 6
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                          if (!_isLoginView) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _reenterPasswordController,
                              decoration: const InputDecoration(labelText: 'Re-enter Password'),
                              obscureText: true,
                              validator: (value) => value != _passwordController.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_isLoginView ? 'Login' : 'Sign Up'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}