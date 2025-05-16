import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MarketUpdateScreen extends StatefulWidget {
  @override
  _MarketUpdateScreenState createState() => _MarketUpdateScreenState();
}

class _MarketUpdateScreenState extends State<MarketUpdateScreen> {
  final RefreshController _refreshController = RefreshController();
  bool _isLoading = true;
  String _errorMessage = '';

  // API Endpoints
  final String commodityApi = 'https://www.alphavantage.co/query?function=COMMODITIES&apikey=H2WGONWCSFD5EBHC';
  final String newsApi = 'https://newsapi.org/v2/everything?q=agriculture&apiKey=80d9361201a841c39e9f5418dec247f8';

  List<Map<String, dynamic>> commodities = [];
  List<dynamic> news = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch commodity prices
      final commodityResponse = await http.get(Uri.parse(commodityApi));
      if (commodityResponse.statusCode == 200) {
        final data = json.decode(commodityResponse.body);

        // Parse Alpha Vantage response format
        if (data['data'] != null) {
          setState(() {
            commodities = (data['data'] as List).map<Map<String, dynamic>>((item) {
              return {
                'name': item['name'] ?? 'Unknown',
                'price': double.tryParse(item['value']?.toString() ?? '0') ?? 0.0,
                'change': 0.0, // Alpha Vantage doesn't provide change percentage
                'unit': 'per unit',
                'date': item['date'] ?? 'N/A'
              };
            }).toList();
          });
        } else {
          // Fallback to mock data if API response is unexpected
          _useMockCommodityData();
        }
      } else {
        _useMockCommodityData();
      }

      // Fetch agriculture news
      final newsResponse = await http.get(Uri.parse(newsApi));
      if (newsResponse.statusCode == 200) {
        final newsData = json.decode(newsResponse.body);
        setState(() {
          news = newsData['articles'] ?? [];
        });
      } else {
        _useMockNewsData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
      _useMockData();
    } finally {
      setState(() => _isLoading = false);
      _refreshController.refreshCompleted();
    }
  }

  void _useMockCommodityData() {
    setState(() {
      commodities = [
        {'name': 'Corn', 'price': 210.5, 'change': 1.2, 'unit': 'bushel', 'date': '2023-11-15'},
        {'name': 'Wheat', 'price': 185.75, 'change': -0.8, 'unit': 'kg', 'date': '2023-11-15'},
        {'name': 'Soybeans', 'price': 320.0, 'change': 2.1, 'unit': 'bushel', 'date': '2023-11-15'},
      ];
    });
  }

  void _useMockNewsData() {
    setState(() {
      news = [
        {
          'title': 'Global Wheat Prices Rise Due to Supply Concerns',
          'description': 'Recent weather patterns have affected wheat yields in major producing regions.',
          'urlToImage': 'https://images.unsplash.com/photo-1605000797499-95a51c5269ae',
          'publishedAt': '2023-11-15T10:30:00Z'
        },
        {
          'title': 'New Sustainable Farming Practices Show Promise',
          'description': 'Researchers demonstrate 20% yield increase with regenerative techniques.',
          'urlToImage': 'https://images.unsplash.com/photo-1535254973040-607b474cb50d',
          'publishedAt': '2023-11-14T08:15:00Z'
        }
      ];
    });
  }

  void _useMockData() {
    _useMockCommodityData();
    _useMockNewsData();
  }

  void _onRefresh() {
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Market Updates',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: _isLoading
            ? _buildShimmerLoader()
            : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage))
            : _buildContent(),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            height: 120,
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Today\'s Commodity Prices', FeatherIcons.trendingUp),
        SizedBox(height: 8),
        _buildCommodityList(),
        SizedBox(height: 24),
        _buildSectionHeader('Agriculture News', FeatherIcons.book),
        SizedBox(height: 8),
        _buildNewsList(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF2E7D32)),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildCommodityList() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: commodities.map((commodity) => _buildCommodityItem(commodity)).toList(),
        ),
      ),
    );
  }

  Widget _buildCommodityItem(Map<String, dynamic> commodity) {
    final priceChange = commodity['change'] ?? 0.0;
    final isPositive = priceChange >= 0;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(0xFF2E7D32).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isPositive ? FeatherIcons.arrowUpRight : FeatherIcons.arrowDownRight,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        commodity['name'],
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        'Per ${commodity['unit']} (${DateFormat('MMM d').format(DateTime.parse(commodity['date']))}',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Color(0xFF666666),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${commodity['price'].toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    return Column(
      children: news.map((article) => _buildNewsItem(article)).toList(),
    );
  }

  Widget _buildNewsItem(dynamic article) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Handle news article tap
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article['urlToImage'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article['urlToImage'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
              SizedBox(height: 8),
              Text(
                article['title'] ?? 'No title',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                article['description'] ?? 'No description',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(FeatherIcons.clock, size: 14, color: Color(0xFF666666)),
                  SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, y').format(DateTime.parse(article['publishedAt'])),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Read more',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}