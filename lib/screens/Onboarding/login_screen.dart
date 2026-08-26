import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/screens/onboarding/auth_gate.dart';
import 'package:rr_fabrication/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _reenterPasswordController = TextEditingController();

  bool _isLoginView = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureReenterPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_clearError);
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _reenterPasswordController.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _reenterPasswordController.dispose();
    super.dispose();
  }

  String _getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code.toLowerCase()) {
        case 'user-not-found':
          return 'No account found with this email. Please check your email or Sign Up.';
        case 'wrong-password':
          return 'Incorrect password. Please check your password and try again.';
        case 'invalid-credential':
        case 'invalid_login_credentials':
          return 'Incorrect email or password. Please verify your credentials.';
        case 'invalid-email':
          return 'Please enter a valid email address format.';
        case 'email-already-in-use':
          return 'An account already exists with this email. Please log in.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed login attempts. Please wait a few minutes and try again.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return error?.toString() ??
        'An unexpected error occurred. Please try again.';
  }

  Future<void> _submit() async {
    _clearError();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      User? user;

      if (_isLoginView) {
        user = await _authService.signInWithEmailPassword(email, password);
      } else {
        final name = _nameController.text.trim();
        user =
            await _authService.signUpWithEmailPassword(name, email, password);
      }

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    } catch (e) {
      if (mounted) {
        final friendlyMsg = _getFriendlyErrorMessage(e);
        setState(() => _errorMessage = friendlyMsg);
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E293B), // Slate 800
              Color(0xFFF1F5F9), // Slate 100
            ],
            stops: [0.0, 0.40, 0.40],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Industrial Brand Header
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.precision_manufacturing_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'RR FABRICATIONS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Precision Operations & Fabrication Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Main Auth Card
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Segmented Switcher Tab
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(9),
                                      onTap: () {
                                        setState(() {
                                          _isLoginView = true;
                                          _errorMessage = null;
                                          _formKey.currentState?.reset();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _isLoginView
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          boxShadow: _isLoginView
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.06),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  )
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: _isLoginView
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: _isLoginView
                                                ? const Color(0xFF1E3A8A)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(9),
                                      onTap: () {
                                        setState(() {
                                          _isLoginView = false;
                                          _errorMessage = null;
                                          _formKey.currentState?.reset();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: !_isLoginView
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          boxShadow: !_isLoginView
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.06),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  )
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Register',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: !_isLoginView
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: !_isLoginView
                                                ? const Color(0xFF1E3A8A)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Error Toast Banner
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFF991B1B),
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Name field for Sign Up
                            if (!_isLoginView) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  hintText: 'e.g. John Doe',
                                  prefixIcon: Icon(Icons.person_outline,
                                      size: 20, color: Color(0xFF64748B)),
                                ),
                                validator: (value) => value!.trim().isEmpty
                                    ? 'Please enter your name'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'name@example.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded,
                                    size: 20, color: Color(0xFF64748B)),
                              ),
                              validator: (value) =>
                                  value!.trim().isEmpty || !value.contains('@')
                                      ? 'Please enter a valid email'
                                      : null,
                            ),
                            const SizedBox(height: 14),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded,
                                    size: 20, color: Color(0xFF64748B)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) => value!.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),

                            // Re-enter Password for Sign Up
                            if (!_isLoginView) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _reenterPasswordController,
                                obscureText: _obscureReenterPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                      color: Color(0xFF64748B)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureReenterPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureReenterPassword =
                                            !_obscureReenterPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) =>
                                    value != _passwordController.text
                                        ? 'Passwords do not match'
                                        : null,
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Submit Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isLoginView
                                          ? 'Sign In to Workspace'
                                          : 'Create Account',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}