import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Professional Blue-Based Color System
const Color kPrimaryBlue = Color(0xFF0A3D91);
const Color kGradientTop = Color(0xFF0B4FBA);
const Color kGradientBottom = Color(0xFF0E6CE8);
const Color kHeaderNavy = Color(0xFF162235);
const Color kCardBackground = Color(0xFF242B3A);
const Color kWhiteText = Color(0xFFFFFFFF);
const Color kChartPurple = Color(0xFF9C27B0);
const Color kChartPink = Color(0xFFE91E63);
const Color kChartOrange = Color(0xFFFF5722);
const Color kButtonIndigo = Color(0xFF3F51B5);

// Background gradient
const LinearGradient kPrimaryGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [kGradientTop, kGradientBottom],
);

// Card shadow
BoxShadow kCardShadow = BoxShadow(
  color: Colors.black.withOpacity(0.3),
  blurRadius: 8,
  offset: const Offset(0, 2),
);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: GoogleFonts.poppins().fontFamily,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: kPrimaryBlue,
    onPrimary: kWhiteText,
    secondary: kGradientBottom,
    onSecondary: kWhiteText,
    error: Colors.red,
    onError: kWhiteText,
    background: kHeaderNavy,
    onBackground: kWhiteText,
    surface: kCardBackground,
    onSurface: kWhiteText,
  ),
  scaffoldBackgroundColor: kHeaderNavy,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: kWhiteText,
    ),
    iconTheme: const IconThemeData(color: kWhiteText),
  ),
  cardTheme: CardThemeData(
    color: kCardBackground,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    shadowColor: Colors.black.withOpacity(0.3),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kCardBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: kPrimaryBlue.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: kGradientBottom, width: 2),
    ),
    prefixIconColor: kGradientBottom,
    labelStyle: const TextStyle(color: kWhiteText),
    hintStyle: TextStyle(color: kWhiteText.withOpacity(0.5)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kButtonIndigo,
      foregroundColor: kWhiteText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      elevation: 4,
      minimumSize: const Size(double.infinity, 52),
      textStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: kWhiteText,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: kWhiteText,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: kWhiteText,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: kWhiteText,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: kWhiteText,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      color: kWhiteText,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      color: kWhiteText,
    ),
  ),
);

// Reusable styled card widget
class StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const StyledCard({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [kCardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Styled button widget
class StyledButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const StyledButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonIndigo,
          foregroundColor: kWhiteText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 4,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kWhiteText),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Gradient background wrapper
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: kPrimaryGradient),
      child: child,
    );
  }
}