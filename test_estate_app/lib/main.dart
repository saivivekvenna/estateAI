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
      drawerEnableOpenDragGesture: false, // Prevents default drawer button
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: Builder(
          builder: (context) => AppBar(
            automaticallyImplyLeading: false, // Removes default drawer button
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
                      IconButton(
                        icon: Icon(Icons.menu_rounded,
                            size: 35, color: Color.fromRGBO(7, 77, 12, 0.8)),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      _buildTabIcon(Icons.add_rounded, 1, Colors.black),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Spacing at the top
            SizedBox(height: 55),

            // Main drawer items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  _buildListTitle("Updates", Color.fromRGBO(27, 94, 32, 1)),
                  _buildListTitle(
                      "Developer Feedback", Color.fromRGBO(27, 94, 32, 1)),
                  Divider(thickness: 1, indent: 15, endIndent: 15),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                    child: Text(
                      "Chat History",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(27, 94, 32, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

// Chat history list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 10),
                itemCount: 20, // Replace with actual count
                itemBuilder: (context, index) {
                  return _buildListTitle(
                      "Chat $index", const Color.fromARGB(255, 62, 61, 61));
                },
              ),
            ),

// Bottom account header
            Container(
              padding: EdgeInsets.fromLTRB(20, 15, 20, 30),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 240, 239, 239),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    print("Account header tapped");
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person,
                                  size: 25, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Liam Desouza",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.more_vert, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: const [
              RealEstateApp(),
              RealEstateApp(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(15), // Keeps splash inside rounded shape
          onTap: () {
            print("$title tapped");
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, int index, Color activeColor) {
    return IconButton(
      icon: Icon(icon, color: Color.fromRGBO(7, 77, 12, 0.8), size: 35),
      onPressed: () {
        onIndexChanged(index);
      },
    );
  }
}
