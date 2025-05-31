import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class AdvisoryScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  AdvisoryScreen({required this.userData, required this.token});

  @override
  _AdvisoryScreenState createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  List<dynamic> allAdvisories = [];
  String? selectedRegion;
  String? selectedSoil;
  String? selectedSeason;
  dynamic resultAdvisory;
  bool isLoading = true;

  // Modern Agriculture Color Palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color earthBrown = Color(0xFF8D6E63);
  static const Color warmBeige = Color(0xFFF5F5DC);
  static const Color softCream = Color(0xFFFAFAFA);
  static const Color darkText = Color(0xFF2C3E50);
  static const Color lightText = Color(0xFF5D6D7E);

  @override
  void initState() {
    super.initState();
    fetchAdvisoryData();
  }

  Future<void> fetchAdvisoryData() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/advisory'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    print("🔄 Fetching advisory data... Status: ${response.statusCode}");
    if (response.statusCode == 200) {
      setState(() {
        allAdvisories = json.decode(response.body);
        isLoading = false;
      });
    } else {
      print("❌ Failed to fetch advisory data.");
      throw Exception('Failed to load advisories');
    }
  }

  Set<String> getUniqueRegions() =>
      allAdvisories.map((e) => e['region'] as String).toSet();

  Set<String> getUniqueSoils() => allAdvisories
      .expand((e) => (e['common_soil_types'] as List<dynamic>).cast<String>())
      .toSet();

  Set<String> getUniqueSeasons() => allAdvisories
      .expand((e) => (e['seasons'] as List<dynamic>).cast<String>())
      .toSet();

  Future<void> handleSubmit() async {
    if (selectedRegion == null || selectedSeason == null) {
      _showSnackBar('Please select at least region and season', isError: true);
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/advisory'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'region': selectedRegion,
        'season': selectedSeason,
        'soil_type': selectedSoil,
      }),
    );

    print("📤 Submitting advisory POST request...");
    print("🧾 Payload: {region: $selectedRegion, season: $selectedSeason, soil: $selectedSoil}");
    print("🔍 Response Status: ${response.statusCode}");
    print("📦 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        resultAdvisory = json.decode(response.body);
      });
      _showSnackBar('Advisory recommendations loaded successfully!', isError: false);
    } else {
      _showSnackBar('No data found or request failed', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.red.shade600 : lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: lightText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryGreen, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.poppins(
              color: darkText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ))
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: GoogleFonts.poppins(color: darkText),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, lightGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Get Advisory',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (resultAdvisory == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.agriculture, color: primaryGreen, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advisory Results',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    Text(
                      'Recommendations for ${resultAdvisory['region']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: lightText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Soil Match Status
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: resultAdvisory['matched_soil']
                  ? lightGreen.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: resultAdvisory['matched_soil']
                    ? lightGreen.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  resultAdvisory['matched_soil']
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: resultAdvisory['matched_soil']
                      ? lightGreen
                      : Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Soil Match: ${resultAdvisory['matched_soil'] ? 'Perfect Match' : 'Partial Match'}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: resultAdvisory['matched_soil']
                        ? lightGreen
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Crop Recommendations
          _buildInfoSection(
            title: 'Recommended Crops',
            icon: Icons.eco,
            content: (resultAdvisory['crop_recommendations'] as List<dynamic>).join(", "),
          ),

          SizedBox(height: 16),

          // Rotation Plan
          _buildInfoSection(
            title: 'Crop Rotation Plan',
            icon: Icons.rotate_right,
            content: (resultAdvisory['crop_rotation_plan'] as List<dynamic>).join("\n\n"),
            isExpandable: true,
          ),

          SizedBox(height: 16),

          // Advisory Notes
          _buildInfoSection(
            title: 'Advisory Notes',
            icon: Icons.note_alt,
            content: resultAdvisory['advisory_notes'],
            isExpandable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required String content,
    bool isExpandable = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryGreen, size: 18),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: lightText,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            maxLines: isExpandable ? null : 3,
            overflow: isExpandable ? null : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softCream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Agricultural Advisory',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.agriculture, color: primaryGreen, size: 24),
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading Advisory Data...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: lightText,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen.withOpacity(0.1), accentGreen.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get Personalized Advice',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select your farming parameters to receive tailored crop recommendations and rotation plans.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: lightText,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Form Section
            _buildModernDropdown(
              label: 'Select Region',
              value: selectedRegion,
              items: getUniqueRegions().toList(),
              onChanged: (value) => setState(() => selectedRegion = value),
              icon: Icons.location_on,
            ),

            _buildModernDropdown(
              label: 'Select Soil Type (Optional)',
              value: selectedSoil,
              items: getUniqueSoils().toList(),
              onChanged: (value) => setState(() => selectedSoil = value),
              icon: Icons.terrain,
            ),

            _buildModernDropdown(
              label: 'Select Season',
              value: selectedSeason,
              items: getUniqueSeasons().toList(),
              onChanged: (value) => setState(() => selectedSeason = value),
              icon: Icons.wb_sunny,
            ),

            SizedBox(height: 8),

            _buildSubmitButton(),

            _buildResultCard(),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}