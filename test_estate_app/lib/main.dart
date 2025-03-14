import 'package:flutter/material.dart';
import 'package:test_estate_app/real_estate_ai_material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: AppBar(
              primary: false, // Removes default app bar padding and divider
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
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
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor:
                          Colors.transparent, // Removes the default line
                      dividerColor: Colors.transparent, // Removes the divider

                      indicator: BoxDecoration(),
                      tabs: [
                        Tab(
                          icon: Icon(
                            Icons.search,
                            color: _tabController.index == 0
                                ? Colors.green
                                : Colors.black,
                            size: 40,
                          ),
                        ),
                        Tab(
                          icon: Icon(
                            Icons.swipe_down_rounded,
                            color: _tabController.index == 1
                                ? Colors.blueAccent
                                : Colors.black,
                            size: 40,
                          ),
                        ),
                        Tab(
                          icon: Icon(
                            Icons.notifications,
                            color: _tabController.index == 2
                                ? Colors.yellow
                                : Colors.black,
                            size: 40,
                          ),
                        ),
                      ],
                      onTap: (index) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              RealEstateApp(),
              Icon(Icons.android),
              Icon(Icons.android),

            ],
          ),
        ),
      ),
    );
  }
}
