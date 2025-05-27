// lib/widgets/category_dropdown.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/category_model.dart';
import '../utils/constants.dart';

class CategoryDropdown extends StatelessWidget {
  final List<Category> categories;
  final int selectedCategoryId;
  final ValueChanged<int> onCategoryChanged;
  final bool isLoading;
  final String? hintText;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const CategoryDropdown({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    this.isLoading = false,
    this.hintText,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColorss.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColorss.shadowColor,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading
          ? _buildLoadingState()
          : _buildDropdown(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 48,
      child: Row(
        children: [
          Icon(
            Icons.category,
            color: Colors.grey[400],
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Loading categories...',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColorss.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    // Check if categories list is empty
    if (categories.isEmpty) {
      return Container(
        height: 48,
        child: Row(
          children: [
            Icon(
              Icons.category,
              color: Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'No categories available',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final dropdownItems = _buildDropdownItems();

    // If items is null or empty, show error state
    if (dropdownItems == null || dropdownItems.isEmpty) {
      return Container(
        height: 48,
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Error loading categories',
              style: GoogleFonts.poppins(
                color: Colors.red[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Validate that selected value exists in items
    final validSelectedValue = _getValidSelectedValue(dropdownItems);

    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: validSelectedValue,
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: AppColorss.primary,
          size: 24,
        ),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColorss.textPrimary,
        ),
        hint: Row(
          children: [
            Icon(
              Icons.category,
              color: AppColorss.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              hintText ?? 'All Categories',
              style: GoogleFonts.poppins(
                color: AppColorss.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        items: dropdownItems,
        onChanged: (value) {
          onCategoryChanged(value ?? 0);
        },
      ),
    );
  }

  int? _getValidSelectedValue(List<DropdownMenuItem<int>> items) {
    if (selectedCategoryId == 0) return null;

    // Check if the selected value exists in the dropdown items
    final hasSelectedValue = items.any((item) => item.value == selectedCategoryId);

    return hasSelectedValue ? selectedCategoryId : null;
  }

  List<DropdownMenuItem<int>>? _buildDropdownItems() {
    // Add null and empty checks
    if (categories.isEmpty) {
      return null;
    }

    try {
      // Remove duplicates and invalid categories first
      final validCategories = _getUniqueValidCategories();

      if (validCategories.isEmpty) {
        return null;
      }

      final items = <DropdownMenuItem<int>>[
        DropdownMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(
                Icons.all_inclusive,
                color: AppColorss.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'All Categories',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColorss.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ];

      // Add categories to dropdown
      for (final category in validCategories) {
        items.add(
          DropdownMenuItem<int>(
            value: category.id,
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category.type ?? ''),
                  color: _getCategoryColor(category.type ?? ''),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColorss.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (category.type == 'both')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorss.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Both',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColorss.info,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return items;
    } catch (e) {
      print('Error building dropdown items: $e');
      return null;
    }
  }

  List<Category> _getUniqueValidCategories() {
    final uniqueCategories = <int, Category>{};

    for (final category in categories) {
      // Skip null categories
      if (category == null) continue;

      // Skip categories with invalid data
      if (category.id <= 0 || category.name.isEmpty) {
        print('Skipping invalid category: ID=${category.id}, Name="${category.name}"');
        continue;
      }

      // Add to map (this automatically handles duplicates by ID)
      uniqueCategories[category.id] = category;
    }

    // Convert back to list and sort by name
    final result = uniqueCategories.values.toList();
    result.sort((a, b) => a.name.compareTo(b.name));

    return result;
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'ebook':
        return Icons.menu_book;
      case 'video':
        return Icons.video_library;
      case 'both':
        return Icons.library_books;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'ebook':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'both':
        return AppColorss.primary;
      default:
        return AppColorss.textSecondary;
    }
  }
}

/// Fixed CategoryDropdownForUpload widget
class CategoryDropdownForUpload extends StatelessWidget {
  final List<Category> categories;
  final int selectedCategoryId;
  final ValueChanged<int> onCategoryChanged;
  final bool isRequired;
  final String contentType; // 'ebook' or 'video'

  const CategoryDropdownForUpload({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    this.isRequired = true,
    required this.contentType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add comprehensive null checks
    if (categories.isEmpty) {
      return _buildErrorState('Loading categories...');
    }

    // Get unique valid categories first, then filter by type
    final uniqueCategories = _getUniqueValidCategories();
    final filteredCategories = uniqueCategories.where((category) {
      final categoryType = category.type ?? 'both';
      return categoryType == contentType || categoryType == 'both';
    }).toList();

    // Check if filtered categories is empty
    if (filteredCategories.isEmpty) {
      return _buildErrorState('No categories available for ${contentType}s');
    }

    // Build dropdown items with null safety
    List<DropdownMenuItem<int>>? dropdownItems;
    try {
      dropdownItems = filteredCategories.map((category) {
        return DropdownMenuItem<int>(
          value: category.id,
          child: Text(
            category.name,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        );
      }).toList();
    } catch (e) {
      print('Error building dropdown items: $e');
      return _buildErrorState('Error loading categories');
    }

    // Final check for items
    if (dropdownItems == null || dropdownItems.isEmpty) {
      return _buildErrorState('No valid categories found');
    }

    // Validate selected value
    final validSelectedValue = _getValidSelectedValue(dropdownItems);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColorss.borderLight),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(
            Icons.category,
            color: AppColorss.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: validSelectedValue,
                hint: Text(
                  'Select Category${isRequired ? ' *' : ''}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                style: GoogleFonts.poppins(
                  color: AppColorss.textPrimary,
                  fontSize: 16,
                ),
                items: dropdownItems,
                onChanged: (value) {
                  onCategoryChanged(value ?? 0);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  int? _getValidSelectedValue(List<DropdownMenuItem<int>> items) {
    if (selectedCategoryId == 0) return null;

    // Check if the selected value exists in the dropdown items
    final hasSelectedValue = items.any((item) => item.value == selectedCategoryId);

    return hasSelectedValue ? selectedCategoryId : null;
  }

  List<Category> _getUniqueValidCategories() {
    final uniqueCategories = <int, Category>{};

    for (final category in categories) {
      // Skip null categories
      if (category == null) continue;

      // Skip categories with invalid data
      if (category.id <= 0 || category.name.isEmpty) {
        print('Skipping invalid category: ID=${category.id}, Name="${category.name}"');
        continue;
      }

      // Add to map (this automatically handles duplicates by ID)
      uniqueCategories[category.id] = category;
    }

    // Convert back to list and sort by name
    final result = uniqueCategories.values.toList();
    result.sort((a, b) => a.name.compareTo(b.name));

    return result;
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColorss.borderLight),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(
            Icons.category,
            color: Colors.grey[400],
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}