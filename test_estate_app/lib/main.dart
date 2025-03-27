// Import the auth wrapper and related files
import 'auth/auth_wrapper.dart';

// Original main.dart code with AuthWrapper integration
import 'package:flutter/material.dart';
import 'package:test_estate_app/chat_page.dart';
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
      // Wrap the entire app with AuthWrapper to handle authentication state
      // Comment out the line below to bypass authentication during development
      home: AuthWrapper(
        child: MainAppContent(
          selectedIndex: _selectedIndex,
          onIndexChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      // Uncomment the line below to bypass authentication during development
      // home: MainAppContent(selectedIndex: _selectedIndex, onIndexChanged: (index) => setState(() => _selectedIndex = index)),
    );
  }
}

// Extracted the main app content to a separate widget for cleaner integration
class MainAppContent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const MainAppContent({
    Key? key,
    required this.selectedIndex,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(143, 206, 157, 1), // Lighter green
                      Color.fromRGBO(143, 206, 157, 1),   // Medium green (lighter than before)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabIcon(Icons.search, 0, Colors.white),
                    _buildTabIcon(
                        Icons.swipe_down_rounded, 1, Colors.white),
                    _buildTabIcon(Icons.notifications, 2, Colors.white),
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
            index: selectedIndex,
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
                  selectedIndex), // Ensures animation updates properly
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, int index, Color activeColor) {
    return IconButton(
      icon: Icon(
        icon,
        color: selectedIndex == index ? activeColor : Colors.black,
        size: 40,
      ),
      onPressed: () {
        onIndexChanged(index);
      },
    );
  }
}

