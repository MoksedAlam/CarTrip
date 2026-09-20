import 'package:flutter/material.dart';

class CarTripNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isHighlight;

  const CarTripNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.isHighlight = false,
  });
}

class CarTripNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<CarTripNavItem> items;

  const CarTripNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              // High quality color grading gradients
              final Gradient selectedGradient;
              final Color shadowColor;

              if (item.isHighlight) {
                // Gold / Amber grading for Super Admin Console
                selectedGradient = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB45309), // Amber 700
                    Color(0xFFD97706), // Amber 600
                    Color(0xFFF59E0B), // Amber 500
                  ],
                );
                shadowColor = const Color(0xFFD97706);
              } else if (isDark) {
                // Electric Royal Sapphire grading in Dark mode
                selectedGradient = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A), // Indigo 900
                    Color(0xFF2563EB), // Blue 600
                    Color(0xFF3B82F6), // Blue 500
                  ],
                );
                shadowColor = const Color(0xFF2563EB);
              } else {
                // Deep Navy to Vibrant Royal Blue grading in Light mode
                selectedGradient = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF091540), // CarTrip Deep Navy
                    Color(0xFF182CC1), // Royal Blue
                    Color(0xFF2E5BFF), // Vibrant Sapphire
                  ],
                );
                shadowColor = const Color(0xFF182CC1);
              }

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onItemSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: EdgeInsets.symmetric(
                      vertical: isSelected ? 7 : 6,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? selectedGradient : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: shadowColor.withValues(alpha: 0.38),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          size: isSelected ? 21 : 20,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            letterSpacing: isSelected ? 0.2 : 0,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
