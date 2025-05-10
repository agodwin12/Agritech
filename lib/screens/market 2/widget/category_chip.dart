import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  final bool isDarkMode;
  final Color textColor;

  const CategoryChip({
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
            fontSize: 13,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
        selected: isSelected,
        selectedColor: MarketplaceTheme.primaryColor,
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: 0,
        pressElevation: 0,
        onSelected: onSelected,
        avatar: isSelected
            ? const Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: Colors.white,
        )
            : null,
        labelPadding: isSelected
            ? const EdgeInsets.only(left: 4, right: 8)
            : const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}