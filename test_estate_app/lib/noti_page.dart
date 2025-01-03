import 'package:flutter/material.dart';
import 'filter_page.dart';
import 'package:test_estate_app/real_estate_ai_material.dart';

class NotiPage extends StatefulWidget {
  const NotiPage({super.key});

  @override
  _NotiPageState createState() => _NotiPageState();
}

class _NotiPageState extends State<NotiPage> {

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
              'Looks like there is no updates for you!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center
            ),
          ),
          SizedBox(height: 25),
          Padding(
            padding: EdgeInsets.fromLTRB(20,0,20,150),
            child: Text(
              'To get updates on your favorite properties, click the bell icon in the property details',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
