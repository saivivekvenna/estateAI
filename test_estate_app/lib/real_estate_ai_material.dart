import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'filter_page.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
//import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'package:intl/intl.dart';

class RealEstateApp extends StatefulWidget {
  const RealEstateApp({super.key});

  @override
  State<RealEstateApp> createState() => _RealEstateAppState();
}

class _RealEstateAppState extends State<RealEstateApp>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Ensures the state is kept

  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  bool _isChatExpanded = false;
  bool _showChat = false;
  List<dynamic> results = [];

  final List<Map<String, dynamic>> _pastChats = []; // Store past chats

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });


    //TODO: LET THE SERVER SEE THE ENTIRE CHAT FOR CONTEXXT
    String context = _pastChats.isNotEmpty
        ? _pastChats.map((chat) => chat['messages'].last.text).join('\n')
        : ''; //leave it empty if nothing is there

    context = '$context\n${message.text}';

    
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.91:5000/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': message.text, 'context': context}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final agentResponse = jsonResponse['agentResponse'];
        final resultsshit = jsonResponse['results'];

        results = resultsshit;

        // the GPT response to the chat
        final botMessage = types.TextMessage(
          author: const types.User(id: 'bot'),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: agentResponse,
        );

        setState(() {
          _messages.insert(0, botMessage);
        });

        // trying to save context - doesnt work
        _pastChats.add({
          'id': DateTime.now().toString(),
          'messages': List<types.Message>.from(_messages),
          'lastUpdated': DateTime.now(),
        });
      } else {
        _handleError('Unable to get a response from the server.');
      }
    } catch (error) {
      _handleError('Unable to connect to the server.');
    }
  }

  void _handleError(String errorMessage) {
    final errorText = types.TextMessage(
      author: const types.User(id: 'bot'),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: errorMessage,
    );

    setState(() {
      _messages.insert(0, errorText);
    });
  }


  //clears up the memory when user is done
  @override
  void dispose() {
    super.dispose();
  }

  //FORMATING PRICE
  String formatPrice(int price) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(price);
  }

  Widget card(
    String title,
    String address,
    String price,
    String beds,
    String baths,
    String value,
    String livingArea,
  ) {
    return Card(
      color: Colors.white, //color of card background
      elevation: 8, //effect of elevation for each card - adds a shadow
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), //rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, //align on the left
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 20),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (value.toLowerCase() == 'up')
                      const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.green,
                        size: 30, // Adjust size as needed
                      )
                    else if (value.toLowerCase() == 'down')
                      const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.red,
                        size: 30, // Adjust size as needed
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bed, color: Colors.black),
                        const SizedBox(width: 4),
                        Text("$beds Beds"),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.bathtub, color: Colors.black),
                        const SizedBox(width: 4),
                        Text("$baths Baths"),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.square_foot_rounded,
                            color: Colors.black),
                        const SizedBox(width: 4),
                        Text("$livingArea sq ft"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(217, 217, 217, 1),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 120, 0, 0),
        child: Stack(
          children: [
            // Scrollable sheet in the background
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: results.length,
              itemBuilder: (BuildContext context, int index) {
                return card(
                    results[index]['propertyType']
                        .split('_')
                        .map(
                            (word) => word[0] + word.substring(1).toLowerCase())
                        .join(' '),
                    results[index]['address'],
                    formatPrice(results[index]['price']),
                    results[index]['bedrooms'].toString(),
                    results[index]['bathrooms'].toString(),
                    "up",
                    results[index]['livingArea'].toString());
              },
            ),

            if (_showChat)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  // hight when expanded 
                  height: _isChatExpanded
                      ? MediaQuery.of(context).size.height * 0.5
                      : 700, // Reduced from 120
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Chat Header - reduce padding
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4), 
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.history),
                              onPressed: () {},
                            ),
                            Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 14, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets
                                  .zero, 
                              constraints:
                                  BoxConstraints(), 
                              icon: Icon(Icons.close, size: 20), 
                              onPressed: () {
                                setState(() {
                                  _showChat = false;
                                  _isChatExpanded = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      if (_isChatExpanded)
                        Expanded(
                          child: Chat(
                            messages: _messages,
                            onSendPressed: _handleSendPressed,
                            user: _user,
                            theme: DefaultChatTheme(
                                backgroundColor: Colors.white,
                                inputBackgroundColor:
                                    Color.fromRGBO(217, 217, 217, 1),
                                primaryColor:
                                    const Color.fromARGB(255, 0, 0, 0),
                                inputBorderRadius:
                                    BorderRadius.all(Radius.circular(30)),
                                inputTextColor: Colors.black,
                                inputMargin: EdgeInsets.all(20),
                                sendButtonIcon: Icon(Icons.search),
                                highlightMessageColor: Colors.white,
                                inputTextCursorColor: Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Chat Toggle Button
            if (!_showChat)
              Positioned(
                bottom: 30,
                left: 40,
                right: 40,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showChat = true;
                      _isChatExpanded = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: Text(
                    "Chat with Assistant",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
