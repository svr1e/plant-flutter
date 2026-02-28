import 'dart:ui';
import 'package:flutter/material.dart';

class GlossyCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderOpacity;
  final double fillOpacity;
  final List<Color>? gradientColors;
  final bool useBlur;

  const GlossyCard({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.borderOpacity = 0.2,
    this.fillOpacity = 0.1,
    this.gradientColors,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: useBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: borderOpacity),
                      width: 1.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors ??
                          [
                            Colors.white.withValues(alpha: fillOpacity + 0.1),
                            Colors.white.withValues(alpha: fillOpacity),
                          ],
                    ),
                  ),
                  child: child,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: borderOpacity),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors ??
                        [
                          Colors.white.withValues(alpha: fillOpacity + 0.05),
                          Colors.white.withValues(alpha: fillOpacity),
                        ],
                  ),
                ),
                child: child,
              ),
      ),
    );
  }
}

class GlossyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget label;
  final IconData? icon;
  final Color? color;
  final bool isLoading;

  const GlossyButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).primaryColor;
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    const SizedBox(width: 12),
                  ],
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    child: label,
                  ),
                ],
              ),
      ),
    );
  }
}
