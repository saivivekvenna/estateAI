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
    _tabController = TabController(length: 4, vsync: this);
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
        length: 4,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 0, left: 20, right: 20),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white.withOpacity(0.8),
                      ),
                      tabs: [
                        Tab(
                          icon: Icon(
                            Icons.search,
                            color: _tabController.index == 0
                                ? Colors.green
                                : Colors.black,
                            size: 35,
                          ),
                        ),
                        Tab(
                          icon: Icon(
                            Icons.notifications,
                            color: _tabController.index == 1
                                ? Colors.yellow
                                : Colors.black,
                            size: 35,
                          ),
                        ),
                        Tab(
                          icon: Icon(
                            Icons.favorite,
                            color: _tabController.index == 2
                                ? Colors.redAccent
                                : Colors.black,
                            size: 35,
                          ),
                        ),
                        Tab(
                          icon: Icon(
                            Icons.person,
                            color: _tabController.index == 3
                                ? Colors.blue
                                : Colors.black,
                            size: 35,
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
            ],
          ),
        ),
      ),
    );
  }
}

