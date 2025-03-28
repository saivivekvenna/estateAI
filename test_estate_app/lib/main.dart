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
            // Main Drawer items above the header
            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: SizedBox(
                height: 70,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: ListTile(
                leading: Icon(Icons.update),
                title: Text("Updates"),
                onTap: () {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: ListTile(
                leading: Icon(Icons.feedback),
                title: Text("Feedback"),
                onTap: () {},
              ),
            ),
            Divider(),

            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: ListTile(
                title: Text("Chat History"),
                onTap: () {},
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                itemCount: 20, // Replace with actual chat history count
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("Chat $index"),
                    onTap: () {},
                  );
                },
              ),
            ),

            // Adding the header at the bottom of the drawer
            Container(
              padding: EdgeInsets.fromLTRB(25, 20, 20, 30),
              decoration: BoxDecoration(
                color:
                    const Color.fromARGB(255, 240, 239, 239), // Matching color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 25, color: Colors.white),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Liam Desouza",
                    style: TextStyle(
                      color: Color.fromRGBO(27, 94, 32, 1),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 52),
                  IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
                ],
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

  Widget _buildTabIcon(IconData icon, int index, Color activeColor) {
    return IconButton(
      icon: Icon(icon, color: Color.fromRGBO(7, 77, 12, 0.8), size: 35),
      onPressed: () {
        onIndexChanged(index);
      },
    );
  }
}
