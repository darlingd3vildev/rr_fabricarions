import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rr_fabrication/screens/onboarding/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Navigate to AuthGate after splash display
    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthGate(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E293B), // Slate 800
              Color(0xFF1E3A8A), // Deep Blue 900
              Color(0xFF0F172A), // Slate 900
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background ambient geometric glow circles
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.3,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                ),
              ),
            ),

            // Center Branding Content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo Badge
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 110,
                          height: 110,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.45),
                                blurRadius: 28,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF0F172A),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.precision_manufacturing_rounded,
                                size: 54,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Brand Title
                      const Text(
                        'RR FABRICATIONS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Brand Tagline / Subtitle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Text(
                          'PRECISION ENGINEERING & METALWORKS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Polished sleek loading progress indicator
                      SizedBox(
                        width: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: Color(0xFF334155),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Initializing workspace...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Version Info
            const Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v1.0.0 • Industrial Fabrication Suite',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
