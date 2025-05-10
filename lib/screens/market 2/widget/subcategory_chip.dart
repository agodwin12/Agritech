import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';

class SubcategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  final bool isDarkMode;
  final Color textColor;

  const SubcategoryChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.isDarkMode,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: isSelected ? Colors.white : textColor.withOpacity(0.7),
          ),
        ),
        selected: isSelected,
        selectedColor: MarketplaceTheme.accentColor,
        backgroundColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: 0,
        pressElevation: 0,
        onSelected: onSelected,
      ),
    );
  }
}