import 'package:flutter/material.dart';
import 'package:test_estate_app/real_estate_ai_material.dart';
import 'package:test_estate_app/swiper.dart';
import 'package:test_estate_app/noti_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: AppBar(
            primary: false,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 0, left: 90, right: 90),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(143, 206, 157, 1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTabIcon(Icons.search, 0, Colors.grey),
                      _buildTabIcon(
                          Icons.swipe_down_rounded, 1, Colors.grey),
                      _buildTabIcon(Icons.notifications, 2, Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: const [
                RealEstateApp(),
                SwiperPage(),
                NotiPage(),
              ],
            ),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<int>(
                    _selectedIndex), // Ensures animation updates properly
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, int index, Color activeColor) {
    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index ? activeColor : Colors.black,
        size: 40,
      ),
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}
