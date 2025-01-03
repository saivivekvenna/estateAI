import 'package:flutter/material.dart';
import 'filter_page.dart';
import 'package:test_estate_app/real_estate_ai_material.dart';

class FavsPage extends StatefulWidget {
  const FavsPage({super.key});

  @override
  _FavsPageState createState() => _FavsPageState();
}

class _FavsPageState extends State<FavsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Expanded(
        child: noNotiScreen(),
      ),
    );
  }

}

 Widget noNotiScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'Nothing saved yet!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center
            ),
          ),
          SizedBox(height: 25),
          Padding(
            padding: EdgeInsets.fromLTRB(20,0,20,150),
            child: Text(
              'Save those properties that you want to come back too.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
