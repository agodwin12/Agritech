import 'package:agritech/screens/feature%20page/feature_page.dart';
import 'package:agritech/screens/market%20place/manage_products_screen.dart';
import 'package:agritech/screens/market%20place/market.dart';
import 'package:agritech/screens/profile/my_profile.dart';
import 'package:agritech/screens/sign%20in/signIn.dart';
import 'package:agritech/screens/signUp/signUp.dart';
import 'package:agritech/screens/weather/weather.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgritTech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF66BB6A),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: AuthScreen(),
      routes: {
        '/signin':(context)=>AuthScreen(),
        '/signup': (context)=>SignUpScreen(),
        '/feature':(context)=>FeaturePage(userData: {}, token: '',),
        '/profile':(context)=>ProfileScreen(userData: {}, token: '',),
        '/weather': (context) => const WeatherScreen(userData: {}, token: '',),
        '/add-product':(context)=>AddProductScreen(userData: {}, token: '', categories: [], onProductAdded: () {  },)
      },
    );
  }
}