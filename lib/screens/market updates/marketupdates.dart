import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class MarketTrendScreen extends StatefulWidget {
  final String token;

  const MarketTrendScreen({Key? key, required this.token}) : super(key: key);

  @override
  _MarketTrendScreenState createState() => _MarketTrendScreenState();
}

class _MarketTrendScreenState extends State<MarketTrendScreen> {
  List<dynamic> trendSummary = [];
  bool isLoading = true;

  String selectedRegion = 'All';
  String selectedDateRange = 'This week';

  @override
  void initState() {
    super.initState();
    fetchMarketTrends();
  }

  Future<void> fetchMarketTrends() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.http('10.0.2.2:3000', '/api/market-trends/summary', {
        'region': selectedRegion,
        'from': '2025-06-01',
        'to': '2025-06-11',
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
      });

      if (response.statusCode == 200) {
        trendSummary = jsonDecode(response.body);
      }
    } catch (e) {
      print('Fetch error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void openCropTrend(String cropName) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/market-trends/$cropName'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final trend = data['trend'] as List<dynamic>;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CropTrendChartScreen(cropName: cropName, trend: trend),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market Trends', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green[700],
      ),
      body: RefreshIndicator(
        onRefresh: fetchMarketTrends,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedRegion,
                      items: ['All', 'North', 'South', 'West']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedRegion = val!);
                        fetchMarketTrends();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedDateRange,
                      items: ['Today', 'This week', 'This month']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedDateRange = val!);
                        fetchMarketTrends();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: trendSummary.length,
                itemBuilder: (_, index) {
                  final item = trendSummary[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      title: Text(
                        item['crop'],
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Avg Price: ${item['avg_price']} FCFA/kg'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => openCropTrend(item['crop']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => PriceSubmissionDialog(token: widget.token),
        ),
        backgroundColor: Colors.green[700],
        child: Icon(Icons.add),
      ),
    );
  }
}

class PriceSubmissionDialog extends StatefulWidget {
  final String token;
  const PriceSubmissionDialog({super.key, required this.token});

  @override
  State<PriceSubmissionDialog> createState() => _PriceSubmissionDialogState();
}

class _PriceSubmissionDialogState extends State<PriceSubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  String crop = '';
  String region = '';
  String price = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Submit Market Price'),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Crop Name'),
            onChanged: (val) => crop = val,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Region'),
            onChanged: (val) => region = val,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Price (FCFA)'),
            keyboardType: TextInputType.number,
            onChanged: (val) => price = val,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final response = await http.post(
              Uri.parse('http://10.0.2.2:3000/api/market-trends/submit'),
              headers: {
                'Authorization': 'Bearer ${widget.token}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'crop_name': crop,
                'market_region': region,
                'price': price,
              }),
            );

            if (response.statusCode == 201) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Price submitted successfully')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Submission failed')),
              );
            }
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}

class CropTrendChartScreen extends StatelessWidget {
  final String cropName;
  final List<dynamic> trend;

  const CropTrendChartScreen({Key? key, required this.cropName, required this.trend}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spots = trend.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), double.parse(entry.value['price'].toString()));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('$cropName Trend', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                color: Colors.green,
                belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.3)),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, interval: 50),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int idx = value.toInt();
                    if (idx >= 0 && idx < trend.length) {
                      final date = trend[idx]['date'].toString().split('T')[0];
                      return Text(date, style: GoogleFonts.poppins(fontSize: 10));
                    }
                    return const SizedBox.shrink();
                  },
                  interval: 1,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true),
          ),
        ),
      ),
    );
  }
}
