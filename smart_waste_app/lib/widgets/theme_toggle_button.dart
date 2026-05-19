import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const ThemeToggleButton({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return GestureDetector(
          onTap: () {
            themeProvider.toggleTheme();
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color:
                  backgroundColor ??
                  (themeProvider.isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFE8F5E9)),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF1B7A3E),
                width: 2,
              ),
            ),
            child: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color:
                  iconColor ??
                  (themeProvider.isDarkMode
                      ? const Color(0xFFFFB74D)
                      : const Color(0xFF1B7A3E)),
              size: size / 2,
            ),
          ),
        );
      },
    );
  }
}
