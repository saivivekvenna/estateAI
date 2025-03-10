import 'package:flutter/material.dart';
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
  final _otherUser = const types.User(id: 'bot'); // Another user

  List<dynamic> results = [];

  // void _simulateOtherUserMessage() {
  //   final otherMessage = types.TextMessage(
  //     author: _otherUser,
  //     createdAt: DateTime.now().millisecondsSinceEpoch,
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     text: 'Heres what I found, let me know what you think',
  //   );

  //   setState(() {
  //     _messages.insert(0, otherMessage);
  //   });
  // }

  void _sendCustomMessage(String type) {
    Map<String, dynamic> metadata;

    metadata = {
      'type': 'response',
      'property': {
        'title': 'Luxury Apartment',
        'address': '456 Elm St, Citytown',
        'price': '\$750,000',
        'beds': 4,
        'baths': 3,
        'area': '2200 sqft',
        'status': 'up'
      },
      'message': {
        'content':
            'This looks like a great property! Would you like to book a viewing?'
      }
    };

    final customMessage = types.CustomMessage(
      author: _otherUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      metadata: metadata, // Store message type and data
    );

    setState(() {
      _messages.insert(0, customMessage);
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().toString(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
      _sendCustomMessage(" ");
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

  Widget customMessageBuilder(types.CustomMessage message,
      {required int messageWidth}) {
    if (message.metadata?['type'] == 'response') {
      return Card(
        color: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(message.metadata?['property']['title'] ?? 'Unknown',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(
                    message.metadata?['property']['status'] == 'up'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: message.metadata?['property']['status'] == 'up'
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),
              Text(message.metadata?['property']['address'] ?? 'Unknown',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(message.metadata?['property']['price'] ?? '\$0',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${message.metadata?['property']['beds']} Beds"),
                  Text("${message.metadata?['property']['baths']} Baths"),
                  Text(message.metadata?['property']['area'] ?? 'N/A'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink(); // Return an empty widget if no match
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
      color: Colors.white, // Background color
      elevation: 8, // Shadow effect for depth
      margin: const EdgeInsets.all(12), // Outer spacing
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to left
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
                        overflow: TextOverflow.ellipsis, // Cut text if too long
                      ),
                    ),
                    if (value.toLowerCase() == 'up')
                      const Icon(Icons.arrow_upward_rounded,
                          color: Colors.green, size: 30)
                    else if (value.toLowerCase() == 'down')
                      const Icon(Icons.arrow_downward_rounded,
                          color: Colors.red, size: 30),
                  ],
                ),
                const SizedBox(height: 6),
                Text(address,
                    style: const TextStyle(fontSize: 14, color: Colors.black)),
                const SizedBox(height: 10),
                Text(price,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.bed, color: Colors.black),
                      const SizedBox(width: 4),
                      Text("$beds Beds")
                    ]),
                    Row(children: [
                      const Icon(Icons.bathtub, color: Colors.black),
                      const SizedBox(width: 4),
                      Text("$baths Baths")
                    ]),
                    Row(children: [
                      const Icon(Icons.square_foot_rounded,
                          color: Colors.black),
                      const SizedBox(width: 4),
                      Text("$livingArea sq ft")
                    ]),
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
                  size: 200,
                  sigma: 30,
                  controlPoints: [
                    ControlPoint(position: 0.5, type: ControlPointType.visible),
                    ControlPoint(
                        position: 1, type: ControlPointType.transparent),
                  ],
                ),
              ],
              child: SizedBox.expand(
                child: Chat(
                  messages: _messages,
                  onSendPressed: _handleSendPressed,
                  user: _user,
                  customMessageBuilder: customMessageBuilder,
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
                    inputPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
