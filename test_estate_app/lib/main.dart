import 'package:flutter/material.dart';
import 'package:test_estate_app/chat_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        extendBodyBehindAppBar: true,
        drawerEnableOpenDragGesture: false, // Prevents default drawer button
        // appBar: PreferredSize(
        //   preferredSize: const Size.fromHeight(50),
        //   child: Builder(
        //     builder: (context) => AppBar(
        //       automaticallyImplyLeading: false, // Removes default drawer button
        //       backgroundColor: Colors.transparent,
        //       shadowColor: Colors.transparent,
        //       surfaceTintColor: Colors.transparent,
        //       elevation: 0,
        //       flexibleSpace: Align(
        //         alignment: Alignment.bottomCenter,
        //         child: Padding(
        //           padding: const EdgeInsets.only(bottom: 0, left: 20, right: 20),
        //           child: SizedBox(
        //             height: 60,
        //             child: Row(
        //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //               children: [
        //                 IconButton(
        //                   icon: const Icon(
        //                     Icons.menu_rounded,
        //                     size: 40,
        //                     color: Color.fromRGBO(7, 77, 12, 0.8),
        //                   ),
        //                   onPressed: () {
        //                     Scaffold.of(context).openDrawer();
        //                   },
        //                 ),
        //                 IconButton(
        //                   icon: const Icon(
        //                     Icons.add_rounded,
        //                     size: 40,
        //                     color: Color.fromRGBO(7, 77, 12, 0.8),
        //                   ),
        //                   onPressed: () {
        //                     print("Add button tapped");
        //                   },
        //                 ),
        //               ],
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
        // drawer: Drawer(
        //   backgroundColor: Colors.white,
        //   child: Column(
        //     children: [
        //       // Spacing at the top
        //       const SizedBox(height: 55),

        //       // Main drawer items
        //       Padding(
        //         padding: const EdgeInsets.symmetric(horizontal: 10),
        //         child: Column(
        //           children: [
        //             _buildListTitle("Updates", const Color.fromRGBO(27, 94, 32, 1)),
        //             _buildListTitle(
        //                 "Developer Feedback", const Color.fromRGBO(27, 94, 32, 1)),
        //             const Divider(thickness: 1, indent: 15, endIndent: 15),
        //             Padding(
        //               padding:
        //                   const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        //               child: Text(
        //                 "Chat History",
        //                 style: TextStyle(
        //                   fontSize: 14,
        //                   fontWeight: FontWeight.w600,
        //                   color: Color.fromRGBO(27, 94, 32, 1),
        //                 ),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),

        //       // Chat history list
        //       Expanded(
        //         child: ListView.builder(
        //           padding: const EdgeInsets.symmetric(horizontal: 10),
        //           itemCount: 20, // Replace with actual count
        //           itemBuilder: (context, index) {
        //             return _buildListTitle(
        //                 "Chat $index", const Color.fromARGB(255, 62, 61, 61));
        //           },
        //         ),
        //       ),

        //       // Bottom account header
        //       Container(
        //         padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
        //         decoration: const BoxDecoration(
        //           color: Color.fromARGB(255, 240, 239, 239),
        //           borderRadius: BorderRadius.only(
        //             topLeft: Radius.circular(20),
        //             topRight: Radius.circular(20),
        //           ),
        //         ),
        //         child: Material(
        //           color: Colors.transparent,
        //           child: InkWell(
        //             borderRadius: BorderRadius.circular(20),
        //             onTap: () {
        //               print("Account header tapped");
        //             },
        //             child: Padding(
        //               padding: const EdgeInsets.all(10),
        //               child: Row(
        //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //                 children: [
        //                   Row(
        //                     children: [
        //                       CircleAvatar(
        //                         backgroundColor: Colors.grey,
        //                         child: Icon(Icons.person,
        //                             size: 25, color: Colors.white),
        //                       ),
        //                       const SizedBox(width: 10),
        //                       Text(
        //                         "Liam Desouza",
        //                         style: TextStyle(
        //                           color: Colors.black87,
        //                           fontSize: 15,
        //                           fontWeight: FontWeight.w500,
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //                   Icon(Icons.more_vert, color: Colors.black54),
        //                 ],
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        body: const RealEstateApp(),
      ),
    );
  }

  Widget _buildListTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
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
}