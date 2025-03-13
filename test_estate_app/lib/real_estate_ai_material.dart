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
  
  // Track which properties are showing map view
  final Map<String, bool> _showMapView = {};
  
  // Track which property is being viewed in full screen
  String? _fullScreenPropertyId;
  dynamic _fullScreenProperty;
  bool _fullScreenIsMapView = false;

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

  void _sendCustomMessage() {
    Map<String, dynamic> input;

    input = {
      'type': 'response',
      'properties': [
        {
          'title': 'Luxury Apartment',
          'address': '456 Elm St, Citytown',
          'price': '\$750,000',
          'beds': 4,
          'baths': 3,
          'area': '2200 sqft',
          'status': 'up',
          'description': 'Stunning luxury apartment with high-end finishes, open floor plan, and panoramic city views. Features include a gourmet kitchen, marble bathrooms, and a private balcony.',
          'yearBuilt': '2018',
          'parkingSpots': 2,
          'schoolDistrict': 'Citytown Unified',
          'nearbyAmenities': ['Shopping Center', 'Park', 'Restaurants', 'Gym']
        },
        {
          'title': 'Modern Condo',
          'address': '789 Oak St, Citytown',
          'price': '\$600,000',
          'beds': 3,
          'baths': 2,
          'area': '1800 sqft',
          'status': 'up',
          'description': 'Contemporary condo in a prime location with sleek design and modern amenities. Features include stainless steel appliances, hardwood floors, and a community pool.',
          'yearBuilt': '2020',
          'parkingSpots': 1,
          'schoolDistrict': 'Citytown Unified',
          'nearbyAmenities': ['Grocery Store', 'Coffee Shop', 'Fitness Center']
        },
        {
          'title': 'Beachfront House',
          'address': '123 Shoreline Dr, Beachtown',
          'price': '\$1,200,000',
          'beds': 5,
          'baths': 4,
          'area': '3500 sqft',
          'status': 'up',
          'description': 'Spectacular beachfront property with direct ocean access and breathtaking views. Features include a gourmet kitchen, multiple decks, and a private path to the beach.',
          'yearBuilt': '2015',
          'parkingSpots': 3,
          'schoolDistrict': 'Beachtown School District',
          'nearbyAmenities': ['Beach Access', 'Marina', 'Seafood Restaurants', 'Boardwalk']
        }
      ],
      'message': {
        'content':
            'Here are some properties I found that match your criteria. Would you like to book a viewing?'
      }
    };

    final customMessage = types.CustomMessage(
      author: _otherUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      metadata: input, // Store message type and data
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
      _sendCustomMessage();
    });
  }

  // Show full screen property view
  void _showFullScreenProperty(dynamic property, String propertyId, bool isMapView) {
    setState(() {
      _fullScreenPropertyId = propertyId;
      _fullScreenProperty = property;
      _fullScreenIsMapView = isMapView;
    });
  }

  // Close full screen property view
  void _closeFullScreenProperty() {
    setState(() {
      _fullScreenPropertyId = null;
      _fullScreenProperty = null;
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
    List<dynamic> properties = message.metadata?['properties'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var property in properties)
          Builder(
            builder: (context) {
              // Generate a unique ID for this property
              final propertyId = '${property['title']}-${property['address']}';
              
              // Initialize this property in the state maps if not already there
              _showMapView.putIfAbsent(propertyId, () => false);
              
              return Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.location_on_rounded, color: Colors.orange, size: 40),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.list_alt, color: Colors.blue, size: 40),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Dismissible(
                      key: Key(propertyId),
                      direction: DismissDirection.horizontal,
                      onDismissed: (_) {
                        // This won't be called because confirmDismiss returns false
                      },
                      confirmDismiss: (direction) async {
                        // Toggle between map and details view based on swipe direction
                        setState(() {
                          if (direction == DismissDirection.startToEnd) {
                            // Swiped right - show map
                            _showMapView[propertyId] = true;
                          } else {
                            // Swiped left - show details
                            _showMapView[propertyId] = false;
                          }
                        });
                        return false; // Prevents card from disappearing
                      },
                      child: GestureDetector(
                        onTap: () {
                          // Show full screen view
                          _showFullScreenProperty(
                            property, 
                            propertyId, 
                            _showMapView[propertyId] ?? false
                          );
                        },
                        child: _showMapView[propertyId]! 
                            ? _buildMapView(property, propertyId, false)
                            : _buildPropertyCard(property, propertyId, false),
                      ),
                    ),
                  ),
                ],
              );
            }
          ),

        if (message.metadata?['message'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              message.metadata?['message']['content'] ?? '',
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontStyle: FontStyle.normal),
            ),
          ),
      ],
    );
  }

  return const SizedBox.shrink(); // Return an empty widget if no match
}

// Build the property details card
Widget _buildPropertyCard(dynamic property, String propertyId, bool isFullScreen) {
  return Card(
    color: Colors.white,
    elevation: isFullScreen ? 0 : 6,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
    margin: isFullScreen ? EdgeInsets.zero : const EdgeInsets.all(8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  property['title'] ?? 'Unknown',
                  style: TextStyle(
                      fontSize: isFullScreen ? 24 : 18, 
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  property['status'] == 'up'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: property['status'] == 'up'
                      ? Colors.green
                      : Colors.red,
                  size: isFullScreen ? 28 : 24,
                ),
              ),
            ],
          ),

          Text(
            property['address'] ?? 'Unknown',
            style: TextStyle(
              color: Colors.grey,
              fontSize: isFullScreen ? 16 : 14,
            ),
          ),

          SizedBox(height: isFullScreen ? 16 : 8),

          Text(
            property['price'] ?? '\$0',
            style: TextStyle(
                fontSize: isFullScreen ? 20 : 16,
                color: Colors.green,
                fontWeight: FontWeight.bold),
          ),

          SizedBox(height: isFullScreen ? 16 : 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bed, size: isFullScreen ? 20 : 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "${property['beds']} Beds",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: isFullScreen ? 16 : 14),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bathtub, size: isFullScreen ? 20 : 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "${property['baths']} Baths",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: isFullScreen ? 16 : 14),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.square_foot, size: isFullScreen ? 20 : 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        property['area'] ?? 'N/A',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: isFullScreen ? 16 : 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          //if (!isFullScreen)
            // Center(
            //   child: Padding(
            //     padding: const EdgeInsets.only(top: 8.0),
            //     child: Text(
            //       "Tap for details",
            //       style: TextStyle(
            //         color: Colors.blue,
            //         fontSize: 12,
            //       ),
            //     ),
            //   ),
            // ),
          
          // Full screen content
          if (isFullScreen) ...[
            const Divider(height: 32),
            
            // Image gallery placeholder - MOVED TO TOP
            Text(
              "Photos",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      width: 250,
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.photo,
                          size: 50,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Property description
            Text(
              "Description",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              property['description'] ?? 'No description available.',
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 24),
            
            // Additional property details
            Text(
              "Property Details",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow("Year Built", property['yearBuilt'] ?? 'N/A', 16),
                      _detailRow("Parking", "${property['parkingSpots'] ?? 'N/A'} spots", 16),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow("School District", property['schoolDistrict'] ?? 'N/A', 16),
                      _detailRow("Type", "Residential", 16),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Call to action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: _actionButton(Icons.calendar_today, "Schedule Tour"),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _actionButton(Icons.phone, "Call Agent"),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // View on map button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Switch to map view
                  setState(() {
                    _fullScreenIsMapView = true;
                  });
                },
                icon: Icon(Icons.map),
                label: Text("View on Map"),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _detailRow(String label, String value, double fontSize) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _actionButton(IconData icon, String label) {
  return ElevatedButton.icon(
    onPressed: () {},
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

// Build the map view
Widget _buildMapView(dynamic property, String propertyId, bool isFullScreen) {
  return Card(
    color: Colors.white,
    elevation: isFullScreen ? 0 : 6,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
    margin: isFullScreen ? EdgeInsets.zero : const EdgeInsets.all(8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Location Map",
                style: TextStyle(
                    fontSize: isFullScreen ? 24 : 18, 
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  property['title'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: isFullScreen ? 16 : 14, 
                    color: Colors.grey
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isFullScreen ? 16 : 12),
          
          // Placeholder for map - in a real app, you'd use Google Maps or similar
          Container(
            height: isFullScreen ? 250 : 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: isFullScreen ? 70 : 50, color: Colors.grey[700]),
                  const SizedBox(height: 8),
                  Text(
                    property['address'] ?? 'Unknown Location',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: isFullScreen ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: isFullScreen ? 16 : 10),
          
          Text(
            "Nearby Properties",
            style: TextStyle(
                fontSize: isFullScreen ? 18 : 16,
                fontWeight: FontWeight.bold),
          ),
                  
          SizedBox(height: isFullScreen ? 12 : 8),
          
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  "3 similar properties nearby",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: isFullScreen ? 16 : 14),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  property['price'] ?? '\$0',
                  style: TextStyle(
                      fontSize: isFullScreen ? 16 : 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          
          // if (!isFullScreen)
          //   Center(
          //     child: Padding(
          //       padding: const EdgeInsets.only(top: 8.0),
          //       child: Text(
          //         "Tap for details",
          //         style: TextStyle(
          //           color: Colors.blue,
          //           fontSize: 12,
          //         ),
          //       ),
          //     ),
          //   ),
          
          // Full screen content for map view
          if (isFullScreen) ...[
            const Divider(height: 32),
            
            // Nearby amenities
            Text(
              "Nearby Amenities",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (property['nearbyAmenities'] != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var amenity in property['nearbyAmenities'])
                    Chip(
                      label: Text(amenity),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                    ),
                ],
              ),
            ] else
              Text("No nearby amenities information available."),
            
            const SizedBox(height: 24),
            
            // Similar properties
            Text(
              "Similar Properties",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // List of similar properties
            _similarPropertyItem(
              "Modern Townhouse", 
              "0.5 miles away", 
              "\$${(int.parse(property['price'].toString().replaceAll(RegExp(r'[^\d]'), '')) * 0.9).round()}",
              16
            ),
            const Divider(height: 16),
            _similarPropertyItem(
              "Spacious Condo", 
              "0.8 miles away", 
              "\$${(int.parse(property['price'].toString().replaceAll(RegExp(r'[^\d]'), '')) * 0.85).round()}",
              16
            ),
            const Divider(height: 16),
            _similarPropertyItem(
              "Family Home", 
              "1.2 miles away", 
              "\$${(int.parse(property['price'].toString().replaceAll(RegExp(r'[^\d]'), '')) * 1.1).round()}",
              16
            ),
            
            const SizedBox(height: 24),
            
            // Call to action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _actionButton(Icons.directions, "Get Directions"),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _actionButton(Icons.explore, "Explore Area"),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // View property details button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Switch to property details view
                  setState(() {
                    _fullScreenIsMapView = false;
                  });
                },
                icon: Icon(Icons.home),
                label: Text("View Property Details"),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _similarPropertyItem(String title, String distance, String price, double fontSize) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.home, size: 30, color: Colors.grey[700]),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              distance,
              style: TextStyle(color: Colors.grey[600], fontSize: fontSize - 2),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Text(
        price,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
          fontSize: fontSize,
        ),
      ),
    ],
  );
}

  // Large card overlay widget instead of full screen
  Widget _buildFullScreenOverlay() {
    if (_fullScreenPropertyId == null || _fullScreenProperty == null) {
      return const SizedBox.shrink();
    }
    
    // Calculate the card size based on screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.9; // 90% of screen width
    final cardHeight = screenSize.height * 0.75; // 75% of screen height
    
    // Get app bar height to position the card properly
    final appBarHeight = 25.0; // Same as the PreferredSize in the Scaffold
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = appBarHeight + statusBarHeight + 10; // Extra padding to ensure visibility
    
    return Positioned.fill(
      child: Material(
        color: Colors.black54, // Semi-transparent background
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with close button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: _closeFullScreenProperty,
                          iconSize: 24,
                        ),
                        Text(
                          _fullScreenProperty['title'] ?? 'Property Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Toggle view button
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _fullScreenIsMapView = !_fullScreenIsMapView;
                            });
                          },
                          icon: Icon(
                            _fullScreenIsMapView ? Icons.home : Icons.map,
                            size: 18,
                          ),
                          label: Text(
                            _fullScreenIsMapView ? "Details" : "Map",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _fullScreenIsMapView
                              ? _buildMapView(_fullScreenProperty, _fullScreenPropertyId!, true)
                              : _buildPropertyCard(_fullScreenProperty, _fullScreenPropertyId!, true),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
          
          // Large card overlay when a property is selected
          if (_fullScreenPropertyId != null)
            _buildFullScreenOverlay(),
        ],
      ),
    );
  }
}

