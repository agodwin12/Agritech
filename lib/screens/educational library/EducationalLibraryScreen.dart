import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EducationalLibraryScreen extends StatefulWidget {
  final String token;
  const EducationalLibraryScreen({required this.token, required Map<String, dynamic> userData});

  @override
  State<EducationalLibraryScreen> createState() => _EducationalLibraryScreenState();
}

class _EducationalLibraryScreenState extends State<EducationalLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;

// Static data for agricultural videos
  final List<Map<String, dynamic>> staticVideos = [
    {
      'id': 1,
      'title': 'Introduction to Sustainable Farming',
      'description': 'Learn the fundamentals of sustainable agriculture and eco-friendly farming practices.',
      'thumbnail_url': 'https://picsum.photos/400/300?random=1',
      'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      'duration': '15:30',
      'category': 'Sustainable Agriculture',
      'instructor': 'Dr. Maria Santos',
    },
    {
      'id': 2,
      'title': 'Crop Rotation Techniques',
      'description': 'Master the art of crop rotation to improve soil health and maximize yields.',
      'thumbnail_url': 'https://picsum.photos/400/300?random=2',
      'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
      'duration': '22:45',
      'category': 'Crop Management',
      'instructor': 'James Mitchell',
    },
    {
      'id': 3,
      'title': 'Organic Pest Control Methods',
      'description': 'Discover natural and organic approaches to managing pests in your crops.',
      'thumbnail_url': 'https://picsum.photos/400/300?random=3',
      'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      'duration': '18:15',
      'category': 'Pest Management',
      'instructor': 'Sarah Green',
    },
    {
      'id': 4,
      'title': 'Soil Health and Composting',
      'description': 'Learn how to improve soil fertility through composting and soil management.',
      'thumbnail_url': 'https://picsum.photos/400/300?random=4',
      'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
      'duration': '25:20',
      'category': 'Soil Science',
      'instructor': 'Dr. Robert Chen',
    },
    {
      'id': 5,
      'title': 'Hydroponic Farming Systems',
      'description': 'Explore modern hydroponic techniques for soil-free cultivation.',
      'thumbnail_url': 'https://picsum.photos/400/300?random=5',
      'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      'duration': '20:10',
      'category': 'Modern Agriculture',
      'instructor': 'Lisa Rodriguez',
    },
    {
      'id': 6,
      'title': 'Livestock Management Basics',
      'description': 'Essential practices for raising healthy livestock and managing animal welfare.',
      'thumbnail_url': 'https://picsum.photos/400/300?random=6',
      'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
      'duration': '28:35',
      'category': 'Animal Husbandry',
      'instructor': 'Michael Thompson',
    },
    {
      'id': 7,
      'title': 'Climate-Smart Agriculture',
      'description': 'Adapt your farming practices to climate change and weather variations.',
      'thumbnail_url': 'https://picsum.photos/400/300?random=7',
      'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      'duration': '19:50',
      'category': 'Climate Adaptation',
      'instructor': 'Dr. Emma Wilson',
    },
    {
      'id': 8,
      'title': 'Farm Business Management',
      'description': 'Learn to manage farm finances, marketing, and business planning effectively.',
      'thumbnail_url': 'https://picsum.photos/400/300?random=8',
      'video_url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
      'duration': '24:15',
      'category': 'Farm Business',
      'instructor': 'David Martinez',
    },
  ];

  // Static data for agricultural ebooks
  final List<Map<String, dynamic>> staticEbooks = [
    {
      'id': 1,
      'title': 'Complete Guide to Organic Farming',
      'description': 'Comprehensive handbook covering all aspects of organic agriculture and certification.',
      'cover_image': 'https://picsum.photos/300/400?random=11',
      'price': 35.99,
      'author': 'Dr. Patricia Johnson',
      'pages': 520,
      'category': 'Organic Agriculture',
      'rating': 4.9,
      'pdf_url': 'https://example.com/organic-farming-guide.pdf',
    },
    {
      'id': 2,
      'title': 'Permaculture Design Principles',
      'description': 'Master permaculture design with practical examples and sustainable solutions.',
      'cover_image': 'https://picsum.photos/300/400?random=12',
      'price': 29.99,
      'author': 'Mark Anderson',
      'pages': 380,
      'category': 'Permaculture',
      'rating': 4.7,
      'pdf_url': 'https://example.com/permaculture-design.pdf',
    },
    {
      'id': 3,
      'title': 'Vegetable Gardening Handbook',
      'description': 'Essential guide to growing healthy vegetables in any climate and space.',
      'cover_image': 'https://picsum.photos/300/400?random=13',
      'price': 22.99,
      'author': 'Jennifer Brown',
      'pages': 290,
      'category': 'Vegetable Growing',
      'rating': 4.6,
      'pdf_url': 'https://example.com/vegetable-gardening.pdf',
    },
    {
      'id': 4,
      'title': 'Precision Agriculture Technologies',
      'description': 'Complete guide to modern farming technologies and GPS-guided systems.',
      'cover_image': 'https://picsum.photos/300/400?random=14',
      'price': 42.99,
      'author': 'Dr. Kevin Zhang',
      'pages': 450,
      'category': 'Agricultural Technology',
      'rating': 4.8,
      'pdf_url': 'https://example.com/precision-agriculture.pdf',
    },
    {
      'id': 5,
      'title': 'Integrated Pest Management',
      'description': 'Comprehensive approach to sustainable pest control in agricultural systems.',
      'cover_image': 'https://picsum.photos/300/400?random=15',
      'price': 31.99,
      'author': 'Dr. Rachel Garcia',
      'pages': 340,
      'category': 'Pest Management',
      'rating': 4.5,
      'pdf_url': 'https://example.com/pest-management.pdf',
    },
    {
      'id': 6,
      'title': 'Aquaponics System Design',
      'description': 'Build and maintain successful aquaponics systems for sustainable food production.',
      'cover_image': 'https://picsum.photos/300/400?random=16',
      'price': 27.99,
      'author': 'Thomas Lee',
      'pages': 310,
      'category': 'Aquaponics',
      'rating': 4.4,
      'pdf_url': 'https://example.com/aquaponics-design.pdf',
    },
    {
      'id': 7,
      'title': 'Agroforestry Practices',
      'description': 'Integrate trees and crops for improved sustainability and biodiversity.',
      'cover_image': 'https://picsum.photos/300/400?random=17',
      'price': 33.99,
      'author': 'Dr. Sofia Martinez',
      'pages': 410,
      'category': 'Agroforestry',
      'rating': 4.7,
      'pdf_url': 'https://example.com/agroforestry-practices.pdf',
    },
    {
      'id': 8,
      'title': 'Farm-to-Table Business Guide',
      'description': 'Build successful direct-to-consumer agricultural businesses and marketing.',
      'cover_image': 'https://picsum.photos/300/400?random=18',
      'price': 25.99,
      'author': 'Anna Kim',
      'pages': 280,
      'category': 'Agricultural Business',
      'rating': 4.6,
      'pdf_url': 'https://example.com/farm-to-table-business.pdf',
    },
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _playVideo(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => VideoPlayerDialog(video: video),
    );
  }

  void _openEbook(Map<String, dynamic> ebook) {
    showDialog(
      context: context,
      builder: (context) => EbookViewerDialog(ebook: ebook),
    );
  }

  Widget buildContentGrid({required bool isVideo}) {
    final contentList = isVideo ? staticVideos : staticEbooks;

    return RefreshIndicator(
      onRefresh: () async {
        // Simulate refresh
        await Future.delayed(Duration(milliseconds: 500));
      },
      color: Colors.deepPurple,
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: isVideo ? 0.8 : 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: contentList.length,
        itemBuilder: (context, index) {
          final item = contentList[index];
          return _buildContentCard(item, isVideo);
        },
      ),
    );
  }

  Widget _buildContentCard(Map<String, dynamic> item, bool isVideo) {
    final imageUrl = isVideo ? item['thumbnail_url'] : item['cover_image'];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isVideo) {
              _playVideo(item);
            } else {
              _openEbook(item);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/Thumbnail Section
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      children: [
                        // Main Image
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildFallbackImage(isVideo),
                        ),

                        // Overlay for videos
                        if (isVideo)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.center,
                                end: Alignment.center,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),

                        // Duration badge for videos
                        if (isVideo && item['duration'] != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['duration'],
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        // Category Badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item['category'] ?? (isVideo ? 'VIDEO' : 'EBOOK'),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item['title'] ?? 'Untitled',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4),

                      // Author/Instructor
                      Text(
                        isVideo ? 'by ${item['instructor']}' : 'by ${item['author']}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 6),

                      // Description
                      Expanded(
                        child: Text(
                          item['description'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: 8),

                      // Bottom row - Price/Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price for ebooks
                          if (!isVideo && item['price'] != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\XAF${item['price']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),

                          // Rating for ebooks
                          if (!isVideo && item['rating'] != null)
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 14),
                                SizedBox(width: 2),
                                Text(
                                  '${item['rating']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage(bool isVideo) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isVideo
              ? [Colors.red.withOpacity(0.2), Colors.orange.withOpacity(0.2)]
              : [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.2)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVideo ? Icons.ondemand_video : Icons.menu_book,
            size: 32,
            color: isVideo ? Colors.red[300] : Colors.blue[300],
          ),
          SizedBox(height: 8),
          Text(
            isVideo ? 'Video' : 'Ebook',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Educational Library',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.deepPurple,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey[600],
              tabs: const [
                Tab(text: 'Ebooks'),
                Tab(text: 'Videos'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildContentGrid(isVideo: false),
          buildContentGrid(isVideo: true),
        ],
      ),
    );
  }
}

// Video Player Dialog
class VideoPlayerDialog extends StatelessWidget {
  final Map<String, dynamic> video;

  const VideoPlayerDialog({required this.video});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      video['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Video placeholder (In real app, use video_player package)
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: video['thumbnail_url'],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.video_library, color: Colors.white, size: 64),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 48),
                  ),
                ],
              ),
            ),

            // Video info
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        video['instructor'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        video['duration'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    video['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Handle actual video playing
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Playing: ${video['title']}'),
                            backgroundColor: Colors.deepPurple,
                          ),
                        );
                      },
                      icon: Icon(Icons.play_arrow),
                      label: Text(
                        'Play Video',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ebook Viewer Dialog
class EbookViewerDialog extends StatelessWidget {
  final Map<String, dynamic> ebook;

  const EbookViewerDialog({required this.ebook});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ebook['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Ebook preview
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover image
                  Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: ebook['cover_image'],
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.book, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Ebook info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'By ${ebook['author']}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${ebook['rating']}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.pages, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              '${ebook['pages']} pages',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\XAF${ebook['price']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                ebook['description'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),

            SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Preview: ${ebook['title']}'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: Icon(Icons.preview),
                      label: Text(
                        'Preview',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reading: ${ebook['title']}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: Icon(Icons.book_online),
                      label: Text(
                        'Read Now',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}