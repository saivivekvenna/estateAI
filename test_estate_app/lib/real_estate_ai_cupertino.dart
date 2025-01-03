import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RealEstateApp extends StatefulWidget {
  const RealEstateApp({super.key});

  @override
  State<RealEstateApp> createState() => _RealEstateAppState();
}

class _RealEstateAppState extends State<RealEstateApp> {
  final TextEditingController textEditingController = TextEditingController();
  late GoogleMapController mapController;

  List<Map<String, dynamic>> _properties = [];

  final LatLng _center = const LatLng(51.0447, -114.0719);
  bool _showMap = true; // map is visible

  bool _propertiesFound = false;

  // DraggableScrollableController to control the position of the sheet
  final DraggableScrollableController _controller = DraggableScrollableController();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Widget card(
    String image,
    String title,
    String address,
    String price,
    String beds,
    String baths,
    String value,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: <Widget>[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.heart,
                      color: CupertinoColors.systemRed,
                      size: 40,
                    ),
                    onPressed: () {},
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 0),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (value.toLowerCase() == 'up')
                          const Icon(CupertinoIcons.arrow_up_circle_fill, color: CupertinoColors.activeGreen),
                        if (value.toLowerCase() == 'down')
                          const Icon(CupertinoIcons.arrow_down_circle_fill, color: CupertinoColors.destructiveRed),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.inactiveGray,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.bed_double_fill, color: CupertinoColors.inactiveGray),
                        const SizedBox(width: 4),
                        Text("$beds Beds"),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.exclamationmark, color: CupertinoColors.inactiveGray),
                        const SizedBox(width: 4),
                        Text("$baths Baths"),
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

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        middle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.search,
                color: CupertinoColors.activeGreen,
                size: 30,
              ),
              onPressed: () {},
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.bell,
                color: CupertinoColors.systemYellow,
                size: 30,
              ),
              onPressed: () {},
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.heart,
                color: CupertinoColors.systemRed,
                size: 30,
              ),
              onPressed: () {},
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.person,
                color: CupertinoColors.black,
                size: 30,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 10.0,
                ),
              ),
            ),
            // Draggable sheet containing the list view
            DraggableScrollableSheet(
              controller: _controller, // DraggableScrollableController
              initialChildSize: 0.4,
              minChildSize: 0.16,
              maxChildSize: 1,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Draggable handle
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          _controller.animateTo(
                            _controller.size - details.delta.dy / MediaQuery.of(context).size.height,
                            duration: const Duration(milliseconds: 1),
                            curve: Curves.linear,
                          );
                        },
                        child: Container(
                          height: 6,
                          width: 40,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                      // ListView Builder
                      Expanded(
                        child: _propertiesFound
                            ? ListView.builder(
                                controller: scrollController,
                                itemCount: _properties.length + 1, // Add 1 for the extra padding
                                shrinkWrap: true,
                                itemBuilder: (BuildContext context, int index) {
                                  if (index == _properties.length) {
                                    return const SizedBox(
                                      height: 50,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(color: CupertinoColors.systemBackground),
                                      ),
                                    );
                                  }
                                  return card(
                                    _properties[index]['photoURL'],
                                    "",
                                    _properties[index]['address'],
                                    _properties[index]['price'].toString(),
                                    _properties[index]['bedrooms'].toString(),
                                    _properties[index]['bathrooms'].toString(),
                                    "none",
                                  );
                                },
                              )
                            : _noResultsScreen(),
                      )
                    ],
                  ),
                );
              },
            ),
            // Search bar and buttons at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  border: Border(
                    top: BorderSide(color: CupertinoColors.systemGrey, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _sendRequestToServer,
                      child: const Icon(CupertinoIcons.search, color: CupertinoColors.black, size: 30),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: CupertinoTextField(
                          controller: textEditingController,
                          style: const TextStyle(color: CupertinoColors.black),
                          placeholder: "Describe your home :)", 
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: CupertinoColors.systemGrey,
                              width: 0.3,
                            ),
                          ),
                          onSubmitted: (_) => _sendRequestToServer(),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.map_fill, color: CupertinoColors.black, size: 30),
                          onPressed: () {
                            setState(() {
                              if (_showMap) {
                                _controller.animateTo(
                                  0.05,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _controller.animateTo(
                                  1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                              _showMap = !_showMap;
                            });
                          },
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.slider_horizontal_3, color: CupertinoColors.black, size: 30),
                          onPressed: () {
                            // Action for the filter button
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequestToServer() async {
    final url = Uri.parse('http://192.168.1.91:5000/search');
    final searchQuery = textEditingController.text;
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': searchQuery}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          _properties = List<Map<String, dynamic>>.from(jsonResponse);
          _propertiesFound = true;
        });
      } else {
        setState(() {
          _propertiesFound = false;
        });
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Widget _noResultsScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(),
          SizedBox(height: 20),
          Text(
            'No properties found, please try again later.',
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }
}
