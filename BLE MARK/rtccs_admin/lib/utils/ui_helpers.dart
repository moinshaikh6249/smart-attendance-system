import 'package:flutter/material.dart';
import '../theme.dart';

/// Helper mixin for consistent UI styling across screens
mixin UIHelpers {
  /// Build a styled section header
  Widget buildSectionHeader(BuildContext context, String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: kGradientBottom, size: 24),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  /// Build a styled dropdown
  Widget buildStyledDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [kCardShadow],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: kCardBackground,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          prefixIcon: icon != null ? Icon(icon, color: kGradientBottom) : null,
          labelStyle: TextStyle(color: kWhiteText.withOpacity(0.7)),
        ),
        style: const TextStyle(color: kWhiteText, fontSize: 16),
      ),
    );
  }

  /// Build a styled text field
  Widget buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [kCardShadow],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: kWhiteText),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: kGradientBottom) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          labelStyle: TextStyle(color: kWhiteText.withOpacity(0.7)),
          hintStyle: TextStyle(color: kWhiteText.withOpacity(0.4)),
        ),
      ),
    );
  }

  /// Build a styled info card
  Widget buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return StyledCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? kGradientBottom).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? kGradientBottom,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: kWhiteText.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: kWhiteText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a styled status chip
  Widget buildStatusChip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build an animated loading indicator
  Widget buildLoadingIndicator({String? message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kGradientBottom),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: kWhiteText),
            ),
          ],
        ],
      ),
    );
  }

  /// Build an error message widget
  Widget buildErrorMessage(String message) {
    return StyledCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Build an empty state widget
  Widget buildEmptyState({
    required String message,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 80,
            color: kWhiteText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: kWhiteText.withOpacity(0.6),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            StyledButton(
              text: actionLabel,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
