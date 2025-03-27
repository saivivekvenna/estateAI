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
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          primary: false,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 0, left: 20, right: 20),
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTabIcon(Icons.menu_rounded, 0, Colors.black),
                    // _buildTabIcon(
                    //     Icons.swipe_down_rounded, 1, Colors.white),
                    // SizedBox(
                    //   width: 200,
                    // ),
                    _buildTabIcon(Icons.add_circle, 1, Colors.black),
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
        color: Color.fromRGBO(7, 77, 12, 0.8),
        size: 35,
      ),
      onPressed: () {
        onIndexChanged(index);
      },
    );
  }
}
