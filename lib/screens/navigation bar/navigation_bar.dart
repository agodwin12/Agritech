import 'package:agritech/screens/market%20place/market.dart';
import 'package:flutter/material.dart';

import '../feature page/feature_page.dart';
import '../profile/my_profile.dart';
import '../weather/weather.dart';

class FarmConnectNavBar extends StatelessWidget {
  final bool isDarkMode;
  final Color darkColor;
  final Color primaryColor;
  final Color textColor;
  final int currentIndex;

  final Map<String, dynamic> userData;
  final String token;

  const FarmConnectNavBar({
    Key? key,
    required this.isDarkMode,
    required this.darkColor,
    required this.primaryColor,
    required this.textColor,
    required this.currentIndex,
    required this.userData,
    required this.token,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? darkColor.withOpacity(0.8) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColor.withOpacity(0.5),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture_outlined),
            activeIcon: Icon(Icons.agriculture_rounded),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_cloudy_outlined),
            activeIcon: Icon(Icons.wb_cloudy),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: currentIndex, // Profile tab
      onTap: (index) {
  switch (index) {
    case 0:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeaturePage( // Replace with actual class
            userData: userData,
            token: token,
          ),
        ),
      );
      break;
    case 1:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarketplaceScreen(
            userData: userData,
            token: token,
          ),
        ),
      );
      break;
    case 2:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeatherScreen(
            userData: userData,
            token: token,
          ),
        ),
      );
      break;
    case 3:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userData: userData,
            token: token,
          ),
        ),
      );
      break;
  }
},


      ),
    );
  }
}