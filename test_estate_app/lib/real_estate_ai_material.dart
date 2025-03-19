import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:soft_edge_blur/soft_edge_blur.dart';
import 'package:intl/intl.dart';

// Import Uint8List for custom marker creation
import 'dart:ui' as ui;

class RealEstateApp extends StatefulWidget {
  const RealEstateApp({super.key});

  @override
  State<RealEstateApp> createState() => _RealEstateAppState();
}

// Add this to the class definition to enable animation
class _RealEstateAppState extends State<RealEstateApp>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true; // Ensures the state is kept

  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  final _otherUser = const types.User(id: 'bot'); // Another user

  List<dynamic> results = [];
  
  // Track which properties are showing map view
  
  // Track which property is being viewed in full screen
  String? _fullScreenPropertyId;
  dynamic _fullScreenProperty;
  bool _fullScreenIsMapView = false;
  
  // Google Maps controllers
  Map<String, GoogleMapController?> _mapControllers = {};
  GoogleMapController? _fullScreenMapController;
  
  // Track if the map is in interactive mode
  bool _isMapInteractive = false;

  // Add these variables to the state class
  BitmapDescriptor? _customMarker;
  BitmapDescriptor? _nearbyMarker;

  // Add AnimationController and Animation to the state class
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Add this to initState method
  @override
  void initState() {
    super.initState();
    _initMarkers();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Add a small delay and then send the first message to ensure maps are loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_messages.isEmpty) {
        _sendCustomMessage();
      }
    });
  }

  // Add this method to initialize custom markers
void _initMarkers() async {
  try {
    _customMarker = await _createCircleMarker(Colors.green, 80);
    _nearbyMarker = await _createCircleMarker(Colors.blue, 80);
    setState(() {});
  } catch (e) {
    print("Error initializing markers: $e");
    // Use default markers if custom ones fail
  }
}

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
          'nearbyAmenities': ['Shopping Center', 'Park', 'Restaurants', 'Gym'],
          'latitude': 37.7749,
          'longitude': -122.4194
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
          'nearbyAmenities': ['Grocery Store', 'Coffee Shop', 'Fitness Center'],
          'latitude': 37.7739,
          'longitude': -122.4312
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
          'nearbyAmenities': ['Beach Access', 'Marina', 'Seafood Restaurants', 'Boardwalk'],
          'latitude': 37.8199,
          'longitude': -122.4783
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
      _isMapInteractive = false; // Reset interactive mode when opening full screen
    });
    _animationController.forward(from: 0.0);
  }

  // Close full screen property view
  void _closeFullScreenProperty() {
  _animationController.reverse().then((value) {
    if (mounted) {
      setState(() {
        _fullScreenPropertyId = null;
        _fullScreenProperty = null;
        _isMapInteractive = false;
      });
    }
  });
}
  
  // Toggle map interactive mode
  void _toggleMapInteractiveMode() {
    setState(() {
      _isMapInteractive = !_isMapInteractive;
    });
  }

  // Get nearby properties for a given property
  List<dynamic> _getNearbyProperties(dynamic currentProperty) {
    if (_messages.isEmpty) return [];
    
    // Get all properties from the latest message
    final latestMessage = _messages.firstWhere(
      (message) => message is types.CustomMessage && message.metadata?['type'] == 'response',
      orElse: () => types.CustomMessage(author: _otherUser, id: ''),
    ) as types.CustomMessage;
    
    if (latestMessage.metadata == null) return [];
    
    List<dynamic> allProperties = latestMessage.metadata?['properties'] ?? [];
    
    // Filter out the current property and return others
    return allProperties.where((property) => 
      property['title'] != currentProperty['title'] || 
      property['address'] != currentProperty['address']
    ).toList();
  }

  //clears up the memory when user is done
  @override
  void dispose() {
    // Dispose all map controllers
    for (var controller in _mapControllers.values) {
      controller?.dispose();
    }
    _fullScreenMapController?.dispose();
  _animationController.dispose();
  super.dispose();
}

  //FORMATING PRICE
  String formatPrice(int price) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(price);
  }

// Add this method to create custom green circle markers
Future<BitmapDescriptor> _createCircleMarker(Color color, double size) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()..color = color;
  
  // Draw outer circle (border)
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size / 2,
    Paint()..color = Colors.white..style = PaintingStyle.fill
  );
  
  // Draw inner circle
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size / 2 - 4,
    paint..style = PaintingStyle.fill
  );
  
  final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  
  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}

// Replace the customMessageBuilder method with this updated version
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
              
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Dismissible(
                  key: Key(propertyId),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) {
                    // This won't be called because confirmDismiss returns false
                  },
                  confirmDismiss: (direction) async {
                    // Show full screen view based on swipe direction
                    _showFullScreenProperty(
                      property, 
                      propertyId, 
                      direction == DismissDirection.startToEnd // Map if swiped right, details if swiped left
                    );
                    return false; // Prevents card from disappearing
                  },
                  // Background indicators for swipe direction
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: Colors.transparent,
                    child: const Icon(Icons.map, color: Colors.white70, size: 40),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.transparent,
                    child: const Icon(Icons.home_rounded, color: Colors.white70, size: 40,),
                  ),
                  // Removed the GestureDetector and directly using the property card
                  child: _buildPropertyCard(property, propertyId, false),
                ),
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

// Replace the _buildMapView method with this updated version
Widget _buildMapView(dynamic property, String propertyId, bool isFullScreen) {
  // Get coordinates for the property
  final double lat = property['latitude'] ?? 37.7749;
  final double lng = property['longitude'] ?? -122.4194;
  final LatLng propertyLocation = LatLng(lat, lng);
  
  // Create a set of markers
  Set<Marker> markers = {};
  
  // Add default marker if custom markers aren't loaded yet
  markers.add(
    Marker(
      markerId: MarkerId(propertyId),
      position: propertyLocation,
      icon: _customMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: property['title'],
        snippet: property['price'],
      ),
    ),
  );
  
  // Add nearby properties markers if in full screen and interactive mode
  if (isFullScreen && _isMapInteractive) {
    final nearbyProperties = _getNearbyProperties(property);
    for (var nearbyProperty in nearbyProperties) {
      final nearbyId = '${nearbyProperty['title']}-${nearbyProperty['address']}';
      final nearbyLat = nearbyProperty['latitude'] ?? 37.7749;
      final nearbyLng = nearbyProperty['longitude'] ?? -122.4194;
      
      markers.add(
        Marker(
          markerId: MarkerId(nearbyId),
          position: LatLng(nearbyLat, nearbyLng),
          icon: _nearbyMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: nearbyProperty['title'],
            snippet: nearbyProperty['price'],
          ),
        ),
      );
    }
  }
  
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
          if (!isFullScreen || !_isMapInteractive) 
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
          
          SizedBox(height: (!isFullScreen || !_isMapInteractive) ? (isFullScreen ? 16 : 12) : 0),
          
          // Google Maps widget - takes full height when interactive
          Container(
            height: isFullScreen 
                ? (_isMapInteractive 
                    ? (isFullScreen ? 500 : 250) // Much taller in interactive mode
                    : 250) 
                : 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: propertyLocation,
                    zoom: isFullScreen ? (_isMapInteractive ? 13 : 14) : 15,
                  ),
                  markers: markers,
                  mapType: MapType.normal,
                  myLocationEnabled: false,
                  zoomControlsEnabled: isFullScreen && _isMapInteractive,
                  zoomGesturesEnabled: isFullScreen && _isMapInteractive,
                  scrollGesturesEnabled: isFullScreen && _isMapInteractive,
                  rotateGesturesEnabled: isFullScreen && _isMapInteractive,
                  tiltGesturesEnabled: isFullScreen && _isMapInteractive,
                  compassEnabled: isFullScreen && _isMapInteractive,
                  mapToolbarEnabled: isFullScreen && _isMapInteractive,
                  onMapCreated: (GoogleMapController controller) {
                    if (isFullScreen) {
                      _fullScreenMapController = controller;
                    } else {
                      _mapControllers[propertyId] = controller;
                    }
                  },
                  onTap: isFullScreen ? (_) {
                    _toggleMapInteractiveMode();
                  } : null,
                ),
                
                // Back button for interactive mode
                if (isFullScreen && _isMapInteractive)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: FloatingActionButton.small(
                      onPressed: _toggleMapInteractiveMode,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
          
          if (!isFullScreen || !_isMapInteractive) ...[
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
          ],
          
          // Full screen content for map view
          if (isFullScreen && !_isMapInteractive) ...[
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

// Update the _buildFullScreenOverlay method to use the animation
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
  
  return AnimatedBuilder(
    animation: _fadeAnimation,
    builder: (context, child) {
      return Positioned.fill(
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: Colors.black54.withOpacity(0.5 * _fadeAnimation.value), // Semi-transparent background
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: cardWidth,
                  height: _fullScreenIsMapView && _isMapInteractive 
                      ? screenSize.height * 0.85  // Taller when map is interactive
                      : cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3 * _fadeAnimation.value),
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
                            if (!(_fullScreenIsMapView && _isMapInteractive))
                              Text(
                                _fullScreenProperty['title'] ?? 'Property Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            // Toggle view button
                            if (!_isMapInteractive)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _fullScreenIsMapView = !_fullScreenIsMapView;
                                    _isMapInteractive = false; // Reset interactive mode when switching views
                                  });
                                },
                                icon: Icon(
                                  _fullScreenIsMapView ? Icons.home : Icons.map,
                                  size: 18,
                                  color: Colors.green[900],
                                ),
                                label: Text(
                                  _fullScreenIsMapView ? "Details" : "Map",
                                  style: TextStyle(fontSize: 14, color: Colors.green[900]), 
                                  
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Content
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            // Only handle swipe if not in interactive map mode
                            if (!_isMapInteractive) {
                              if (details.primaryVelocity! > 0) {
                                // Swiped right - show map
                                setState(() {
                                  _fullScreenIsMapView = true;
                                });
                              } else if (details.primaryVelocity! < 0) {
                                // Swiped left - show details
                                setState(() {
                                  _fullScreenIsMapView = false;
                                });
                              }
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: _fullScreenIsMapView && _isMapInteractive
                                ? _buildMapView(_fullScreenProperty, _fullScreenPropertyId!, true)
                                : SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: _fullScreenIsMapView
                                          ? _buildMapView(_fullScreenProperty, _fullScreenPropertyId!, true)
                                          : _buildPropertyCard(_fullScreenProperty, _fullScreenPropertyId!, true),
                                    ),
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
        ),
      );
    },
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