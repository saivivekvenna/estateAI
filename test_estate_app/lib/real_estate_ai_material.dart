import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:soft_edge_blur/soft_edge_blur.dart';
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

    String context = '';

    //TODO: remove the excess informatoin that is being set

    for (int i = 0; i < _pastChats.length; i++) {
      var sult = _pastChats[i]['messages'];
      context += sult.toString();
    }
    //String context = _pastChats.toString() ;

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
                        size: 30,
                      )
                    else if (value.toLowerCase() == 'down')
                      const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.red,
                        size: 30,
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
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          primary: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 200,
          flexibleSpace: Align(
            child: Padding(
              padding: EdgeInsets.only(left: 0, top: 4, right: 330),
              child: Container(
                height: 60,
                width: 100,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(143, 206, 157, 1),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.history,
                    color: Colors.black,
                    size: 35,
                  ),
                  onPressed: () {
                    // Define button action here
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Move the blur effect to the body to ensure the AppBar stays above it
          Positioned.fill(
            child: SoftEdgeBlur(
              edges: [
                EdgeBlur(
                  type: EdgeType.topEdge,
                  size: 160,
                  sigma: 30,
                  controlPoints: [
                    ControlPoint(position: 0.5, type: ControlPointType.visible),
                    ControlPoint(
                        position: 1, type: ControlPointType.transparent),
                  ],
                ),
              ],
              child: Chat(
                messages: _messages,
                onSendPressed: _handleSendPressed,
                user: _user,
                inputOptions: const InputOptions(
                  sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                ),
                theme: const DefaultChatTheme(
                    backgroundColor: Colors.white,
                    inputBackgroundColor: Color.fromRGBO(217, 217, 217, 1),
                    primaryColor: Color.fromRGBO(88, 88, 88, 1),
                    inputBorderRadius: BorderRadius.all(Radius.circular(30)),
                    inputTextColor: Colors.black,
                    inputMargin: EdgeInsets.fromLTRB(20, 20, 20, 30),
                    sendButtonIcon: Icon(Icons.send),
                    secondaryColor: Color.fromRGBO(52, 99, 56, 1),
                    highlightMessageColor: Colors.white,
                    receivedMessageBodyTextStyle:
                        TextStyle(color: Colors.white, fontSize: 17),
                    sentMessageBodyTextStyle:
                        TextStyle(color: Colors.white, fontSize: 17),
                    inputTextCursorColor: Colors.black,
                      inputPadding: EdgeInsets.all(10), // Adjust padding of the text field itself

                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
