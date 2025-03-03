import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'filter_page.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
//import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';

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

  final TextEditingController textEditingController =
      TextEditingController(); //setting up the search bar
  late GoogleMapController mapController; //setting up the google map shit

  bool _showMap = true; // is the map currently visible?

  List<Map<String, dynamic>> _properties = []; //list of all the properties the
  late Map<String, dynamic> _filters =
      {}; // list of all the filters that the server used when decoding the prompt
  bool _propertiesFound = false; //did any properties show up?

  final FocusNode _focus = FocusNode();

  final DraggableScrollableController _controller =
      DraggableScrollableController(); //setting up the scroller and draggable page thing for the house cards

  final Set<Marker> _markers = {};

  LatLng _currentLocation = const LatLng(37.42796133580664,
      -122.085749655962); // default to bay area i guess? FUTURE: MAKE IT THE USER CURRENT LOCATION

//gpt code for this function
  Future<void> _getCurrentLocation() async {
    //this shit dont work
    try {
      // ask permission if not granted
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Handle permissions denial
        return;
      }

      // Get the current position of the device
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        // Update the current location
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Handle location retrieval error
      print("Error getting location: $e");
    }
  }

  //creating our own custom marker for google maps
  Future<BitmapDescriptor> createGreenDot() async {
    const int size = 100; // diameter of the dot
    final ui.PictureRecorder pictureRecorder = ui
        .PictureRecorder(); //picuter recorder rememebrs the commands used when we make our marker in canvas
    final Canvas canvas = Canvas(pictureRecorder);

    const double markerSize = 20.0; //  size of the marker in  pixel

    //scalling to device
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final double scaledMarkerSize = markerSize * devicePixelRatio;

    final Paint paint = Paint()
      ..color =
          const Color.fromARGB(255, 17, 17, 17); //creating a circle for  marker
    canvas.drawCircle(
      Offset(scaledMarkerSize, scaledMarkerSize), // center the circle
      scaledMarkerSize / 2, // radious  is half the size
      paint,
    );

    final ui.Image image = await pictureRecorder
        .endRecording()
        .toImage(size, size); // Convert canvas to image
    final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png); //turning the image into binary

    // ignore: deprecated_member_use
    return BitmapDescriptor.fromBytes(byteData!.buffer
        .asUint8List()); //truning image into a bitmapdescriptor(marker)
  }

//setting up map controller
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(
        _onFocusChange); //initilizing the checker to see if the search bar is pressed
    //_controller.addListener(_onSheetChange); //checking where the sheet is on the page
    _getCurrentLocation()
        .then((_) {}); //ask to get current loction when app starts up
  }

  //clears up the memory when user is done
  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    //_controller.removeListener(_onSheetChange);
    _focus.dispose();
    _controller.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _visibleProperties =
      []; //list of all the properties the user is currently looking at based on the map

  void _filterVisibleProperties() {
    //if (mapController == null) return;

    mapController.getVisibleRegion().then((LatLngBounds bounds) {
      //getting the region the user is looking at then fetching the bounds of the map in Lat and Long
      final visibleProperties = _properties.where((property) {
        //looping through each propertiy
        final latitude = property['latitude'];
        final longitude = property['longitude'];
        if (latitude == null || longitude == null) {
          return false; //ensureing it has long and lat
        }

        return bounds.contains(LatLng(
            latitude, longitude)); // checks if properties are within bounds
      }).toList(); //convertnig to list

      setState(() {
        _visibleProperties = visibleProperties; //rebuiling UI
      });
    });
  }

  //when focus on search bar
  void _onFocusChange() {
    if (_focus.hasFocus) {
      //when focused on search bar, bring the house cards all the way up
      _controller.animateTo(
        0.85,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      //when unfocused on search bar, bring the house cards all the way down
      _controller.animateTo(
        0.4,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /*when the size of the sheet(the sheet with the house cards) is less than 50% up on the page then unfocus the search button
  ^^^^ IN HINDSIGHT, this is very annoying if you want to select the search bar with the cards down*/
  // void _onSheetChange() {
  //   if (_controller.size < 0.5 && _focus.hasFocus) {
  //     _focus.unfocus();
  //   }
  // }

//FORMATING PRICE
  String formatPrice(int price) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(price);
  }

  Widget card(
    List<String> images,
    String title,
    String address,
    String price,
    String beds,
    String baths,
    String value,
    String livingArea,
  ) {
    return Card(
      color: Color.fromRGBO(217, 217, 217, 1), //color of card background
      elevation: 8, //effect of elevation for each card - adds a shadow
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), //rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, //align on the left
        children: [
          SizedBox(
            //IMAGES
            height: 200,
            child: Stack(
              children: <Widget>[
                PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(
                              12), //rounding so it fits with the already rounder corners
                          topRight: Radius.circular(12),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${images.length}', //displying number of images for the house
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 150,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '< Swipe >', //telling the user that they can swipe - I SHOULD MAKE THIS BE ABLE TO DISSAPEAR ONCE THE USER TAPS IT
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                      onPressed: () {},
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
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

  void updateProperties(List<Map<String, dynamic>> newProperties, bool found) {
    //updateing properties
    setState(() {
      _properties = newProperties;
      _propertiesFound = found;
    });
  }

  @override
  Widget build(BuildContext context) {
    //searching through the list of photo links for each house
    List<String> parseAllPhotos(dynamic allPhotos) {
      if (allPhotos is String) {
        // checking if it is a string
        try {
          // attempting to decode it if it is json
          Map<String, dynamic> photosMap = json.decode(allPhotos);
          if (photosMap.containsKey('images') && photosMap['images'] is List) {
            //checking if the key is 'images' and if it the type list
            return List<String>.from(
                photosMap['images']); //converting it to list<sting>
          }
        } catch (e) {
          print('Error parsing allPhotos: $e');
        }
      } else if (allPhotos is Map<String, dynamic> &&
          allPhotos.containsKey('images')) {
        return List<String>.from(allPhotos['images']);
      }
      // return an empty list if parsing fails or the format is unexpected
      return [];
    }

    //border
    final border = OutlineInputBorder(
      borderSide: const BorderSide(
        color: Colors.black,
        width: 0.3,
        style: BorderStyle.solid,
      ),
      borderRadius: BorderRadius.circular(30),
    );

    return Scaffold(
      backgroundColor: Color.fromRGBO(217, 217, 217, 1),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 10.0,
            ),
            onTap: (LatLng position) {
              FocusScope.of(context).unfocus(); 
            },
            markers: _markers,
            onCameraIdle: _filterVisibleProperties,
          ),
          DraggableScrollableSheet(
            controller: _controller,
            initialChildSize: 0.4, //starting size is 40%
            minChildSize: 0.16,   //min size
            maxChildSize: 0.85,   //max size 
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(217, 217, 217, 0.8),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        _controller.animateTo(
                          _controller.size -
                              details.delta.dy /
                                  MediaQuery.of(context).size.height,
                          duration: const Duration(milliseconds: 1),
                          curve: Curves.linear,
                        );
                      },
                      child: Container(
                        height: 10,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    Expanded(
                      child: _propertiesFound
                          ? ListView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              controller: scrollController,
                              padding: EdgeInsets.zero,
                              itemCount: _visibleProperties.length,
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) {
                                List<String> imageUrls = parseAllPhotos(
                                    _visibleProperties[index]['allPhotos']);
                                return card(
                                    imageUrls,
                                    _visibleProperties[index]['propertyType']
                                        .split('_')
                                        .map((word) =>
                                            word[0] +
                                            word.substring(1).toLowerCase())
                                        .join(' '),
                                    _visibleProperties[index]['address'],
                                    formatPrice(
                                        _visibleProperties[index]['price']),
                                    _visibleProperties[index]['bedrooms']
                                        .toString(),
                                    _visibleProperties[index]['bathrooms']
                                        .toString(),
                                    "up",
                                    _visibleProperties[index]['livingArea']
                                        .toString());
                              },
                            )
                          : _noResultsScreen(),
                    )
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: FocusScope(
              child: Focus(
                focusNode: _focus,
                child: _focus.hasFocus
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: TextField(
                                controller: textEditingController,
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Describe your future home :)",
                                  hintStyle: const TextStyle(
                                      color: Colors.grey, fontSize: 15),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                                onSubmitted: (_) => _sendRequestToServer(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.search,
                                  color: Colors.black, size: 30),
                              onPressed: _sendRequestToServer,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: TextField(
                                controller: textEditingController,
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Search",
                                  hintStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                                onSubmitted: (_) => _sendRequestToServer(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.search,
                                  color: Colors.black, size: 30),
                              onPressed: _sendRequestToServer,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.map_outlined,
                                  color: Colors.black, size: 30),
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
                          ),
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.filter_alt_rounded,
                                  color: Colors.black, size: 30),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FilterPage(
                                      properties: _properties,
                                      propertiesFound: _propertiesFound,
                                      filtersFromPrompt: _filters,
                                      prompted: true,
                                      updateProperties: (newProperties, found) {
                                        setState(() {
                                          _properties = newProperties;
                                          _propertiesFound = found;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequestToServer() async {
    final BitmapDescriptor customIcon = await createGreenDot();

    final url = Uri.parse('http://192.168.1.91:5000/search');
    final searchQuery = textEditingController.text;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': searchQuery}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> results = jsonResponse['results'];
        final Map<String, dynamic> filters = jsonResponse['filters'];

        setState(() {
          _properties = List<Map<String, dynamic>>.from(results);
          _filters = filters; // Update _filters with the backend response
          _propertiesFound = true;

          // Clear existing markers
          _markers.clear();

          // Add new markers for each property
          for (var property in _properties) {
            final latitude = property['latitude'];
            final longitude = property['longitude'];

            if (latitude != null && longitude != null) {
              _markers.add(
                Marker(
                  markerId: MarkerId(property['zpid']?.toString() ?? ''),
                  position: LatLng(latitude, longitude),
                  infoWindow: InfoWindow(
                    title: property['propertyType'] ?? 'Property',
                    snippet: property['address'] ?? '',
                  ),
                  icon: customIcon,
                ),
              );
            }
          }

          // Adjust the camera to fit all markers
          if (_markers.isNotEmpty) {
            final bounds = _calculateBounds(_markers);
            mapController.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 50),
            );
          }

          // Filter properties to show only visible ones
          _filterVisibleProperties();
        });
      } else {
        setState(() {
          _propertiesFound = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _propertiesFound = false;
      });
    }
  }

// Calculate bounds for all markers
  LatLngBounds _calculateBounds(Set<Marker> markers) {
    double? x0, x1, y0, y1;

    for (var marker in markers) {
      if (x0 == null || marker.position.latitude < x0) {
        x0 = marker.position.latitude;
      }
      if (x1 == null || marker.position.latitude > x1) {
        x1 = marker.position.latitude;
      }
      if (y0 == null || marker.position.longitude < y0) {
        y0 = marker.position.longitude;
      }
      if (y1 == null || marker.position.longitude > y1) {
        y1 = marker.position.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(x0!, y0!),
      northeast: LatLng(x1!, y1!),
    );
  }
}

Widget _noResultsScreen() {
  return Container(
    color: Color.fromRGBO(217, 217, 217, 0.5), // Set background color
    child: const SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'No Properties Found :(',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'We couldn\'t find any properties matching your search criteria. Try adjusting your prompt or the filters.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

