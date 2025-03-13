import 'package:flutter/material.dart';

class SwiperPage extends StatefulWidget {
  const SwiperPage({super.key});

  @override
  _SwiperPageState createState() => _SwiperPageState();
}

class _SwiperPageState extends State<SwiperPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          primary: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 200,
          flexibleSpace: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 0, top: 4, right: 0),
                  child: Container(
                    height: 60,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(143, 206, 157, 1),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_alt_rounded,
                        color: Colors.black,
                        size: 35,
                      ),
                      onPressed: () {
                        // Add action for left button
                      },
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(left: 0, top: 4, right: 0),
                  child: Container(
                    height: 60,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(143, 206, 157, 1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.star_rounded,
                        color: Colors.yellow,
                        size: 35,
                      ),
                      onPressed: () {
                        // Add action for right button
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget noHousesScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'Cant find anything with your filter!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center
            ),
          ),
          SizedBox(height: 25),
          Padding(
            padding: EdgeInsets.fromLTRB(20,0,20,150),
            child: Text(
              'Try changing your filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
