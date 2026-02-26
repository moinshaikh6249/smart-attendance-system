import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _shrinkController;
  late AnimationController _fadeController;
  
  late Animation<double> _breathingAnimation;
  late Animation<double> _shrinkAnimation;
  late Animation<double> _moveUpAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  bool _showSplash = true;
  bool _startTransition = false;

  @override
  void initState() {
    super.initState();
    
    // Breathing animation (logo pulse)
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    // Shrink animation (logo → header transition)
    _shrinkController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _shrinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _shrinkController,
        curve: const Cubic(0.25, 0.1, 0.25, 1.0),
      ),
    );
    
    _moveUpAnimation = Tween<double>(begin: 0.0, end: -150.0).animate(
      CurvedAnimation(
        parent: _shrinkController,
        curve: const Cubic(0.25, 0.1, 0.25, 1.0),
      ),
    );
    
    // Dashboard reveal animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    // Start transition sequence
    _startTransitionSequence();
  }

  void _startTransitionSequence() async {
    // Show splash for 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!mounted) return;
    
    // Stop breathing animation
    _breathingController.stop();
    
    // Start shrink + move up
    setState(() => _startTransition = true);
    await _shrinkController.forward();
    
    // Start dashboard reveal
    await _fadeController.forward();
    
    // Navigate to main screen
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RootScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _shrinkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    // Responsive logo size
    final logoSize = screenWidth * 0.54;
    
    return Scaffold(
      backgroundColor: isDarkMode ? kHeaderNavy : kWhiteText,
      body: SafeArea(
        child: Stack(
          children: [
            // Splash Screen
            if (!_startTransition)
              AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (context, child) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with breathing animation
                        Transform.scale(
                          scale: _breathingAnimation.value,
                          child: Container(
                            width: logoSize,
                            height: logoSize,
                            padding: EdgeInsets.all(logoSize * 0.18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [kGradientTop, kGradientBottom],
                              ),
                              borderRadius: BorderRadius.circular(logoSize * 0.22),
                              boxShadow: [
                                BoxShadow(
                                  color: kGradientBottom.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              color: kWhiteText,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.08),
                        // App title
                        Text(
                          'BLE Mark Admin',
                          style: TextStyle(
                            color: isDarkMode ? kWhiteText : kHeaderNavy,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subtitle
                        Text(
                          'Smart Bluetooth Attendance System',
                          style: TextStyle(
                            color: isDarkMode 
                                ? kWhiteText.withOpacity(0.7)
                                : kHeaderNavy.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            
            // Transition Animation
            if (_startTransition)
              AnimatedBuilder(
                animation: Listenable.merge([_shrinkController, _fadeController]),
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Background fade-in
                      Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          decoration: const BoxDecoration(gradient: kPrimaryGradient),
                        ),
                      ),
                      
                      // Shrinking logo moving up
                      Positioned(
                        top: (screenHeight / 2 - logoSize / 2) + _moveUpAnimation.value,
                        left: (screenWidth - logoSize * _shrinkAnimation.value) / 2,
                        child: Opacity(
                          opacity: 1.0 - (_shrinkController.value * 0.5),
                          child: Transform.scale(
                            scale: _shrinkAnimation.value,
                            child: Container(
                              width: logoSize,
                              height: logoSize,
                              padding: EdgeInsets.all(logoSize * 0.18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [kGradientTop, kGradientBottom],
                                ),
                                borderRadius: BorderRadius.circular(logoSize * 0.22),
                                boxShadow: [
                                  BoxShadow(
                                    color: kGradientBottom.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                color: kWhiteText,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
