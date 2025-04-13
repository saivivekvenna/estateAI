import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:geolocator/geolocator.dart';
import 'package:test_estate_app/api_calls.dart';
import 'package:test_estate_app/models/property.dart';

void main() {
  runApp(const MaterialApp(home: RealEstateApp()));
}

class RealEstateApp extends StatefulWidget {
  const RealEstateApp({super.key});

  @override
  State<RealEstateApp> createState() => _RealEstateAppState();
}

class _RealEstateAppState extends State<RealEstateApp>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  final _otherUser = const types.User(id: 'bot');

  final Map<String, bool> _expandedDescriptions = {};

  final ApiCalls _apiCalls = ApiCalls();

  bool _isNearMeMode = false;
  Position? _lastKnownPosition;

  List<Property> _properties = [];
  bool _isLoading = false;
  String? _errorMessage;

  Property? _selectedProperty;
  String? _selectedPropertyId;

  String? _fullScreenPropertyId;
  Property? _fullScreenProperty;
  bool _fullScreenIsMapView = false;
  bool _fullScreenIsPlaceholderView = false;
  Future<Map<String, dynamic>>? _similarPropertiesFuture;

  Map<String, GoogleMapController?> _mapControllers = {};
  GoogleMapController? _fullScreenMapController;
  GoogleMapController? _backgroundMapController;

  BitmapDescriptor? _customMarker;
  BitmapDescriptor? _nearbyMarker;

  late AnimationController _chatHeightController;
  late Animation<double> _chatHeightAnimation;
  double _chatHeightFraction = 0.8;
  int _currentLevel = 2;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late AnimationController _selectionAnimationController;
  late Animation<double> _pulseAnimation;

  bool _returnToSimilarProperties = false;

  late FocusNode _chatInputFocusNode;

  LatLng _mapCenter = const LatLng(37.7749, -122.4194);
  double _mapZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _initMarkers();

    _chatHeightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _chatHeightAnimation = Tween<double>(begin: 0.8, end: 0.8).animate(
      CurvedAnimation(parent: _chatHeightController, curve: Curves.easeInOut),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _selectionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
          parent: _selectionAnimationController, curve: Curves.easeInOut),
    );
    _selectionAnimationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardVisibilityController = KeyboardVisibilityController();
      keyboardVisibilityController.onChange.listen((bool visible) {
        if (mounted) setState(() {});
      });
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_messages.isEmpty) {
        _addBotTextMessage(
            "Hello! I'm your assistant. How can I help you find your dream home today?");
      }
    });

    _getInitialPosition();

    _chatInputFocusNode = FocusNode();
    _chatInputFocusNode.addListener(() {
      if (_chatInputFocusNode.hasFocus && _currentLevel == 0) {
        _toggleChatHeight();
      }
    });
  }

  Future<void> _getInitialPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _mapCenter = LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude);
      });
    } catch (e) {
      print("Error getting initial position: $e");
    }
  }

  void _initMarkers() async {
    try {
      _customMarker = await _createCircleMarker(Colors.green, 80);
      _nearbyMarker = await _createCircleMarker(Colors.blue, 80);
      setState(() {});
    } catch (e) {
      print("Error initializing markers: $e");
    }
  }

  String formatPropertyType(String? propertyType) {
    const propertyTypeMap = {
      'SingleFamily': 'Single Family',
      'SINGLE_FAMILY': 'Single Family',
      'TOWNHOUSE': 'Townhouse',
      'CONDO': 'Condo',
      'MULTIFAMILY': 'Multi Family',
      'APARTMENT': 'Apartment',
    };
    return propertyType != null ? (propertyTypeMap[propertyType] ?? propertyType) : 'Property';
  }

  Future<BitmapDescriptor> _createCircleMarker(Color color, double size) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 4,
      paint..style = PaintingStyle.fill,
    );

    final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _addBotTextMessage(String text) {
    final textMessage = types.TextMessage(
      author: _otherUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().toString(),
      text: text,
    );
    setState(() {
      _messages.insert(0, textMessage);
    });
  }

  void _selectProperty(Property property, String propertyId) {
    setState(() {
      if (_selectedPropertyId == propertyId) {
        _selectedProperty = null;
        _selectedPropertyId = null;
      } else {
        _selectedProperty = property;
        _selectedPropertyId = propertyId;
      }
    });
  }

  void _addCombinedResponse(List<Property> properties, String agentResponse) {
    if (properties.isEmpty) {
      _addBotTextMessage(
          "I couldn't find any properties matching your criteria. Could you try with different requirements?");
      return;
    }
    final customMessage = types.CustomMessage(
      author: _otherUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      metadata: {
        'type': 'combined_response',
        'properties': properties.map((p) => p.toJson()).toList(),
        'agentResponse': agentResponse,
      },
    );
    setState(() {
      _messages.insert(0, customMessage);
    });
  }

String _getMapCoordinates() {
  double diameter = (-6.6 * _mapZoom + 133).clamp(1.0, 99.0);
  return "${_mapCenter.longitude} ${_mapCenter.latitude},${diameter.toStringAsFixed(2)}";
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
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      String conversationHistory = "";
      Map<String, dynamic>? selectedPropertyData;

      if (_selectedProperty != null) {
        selectedPropertyData = _selectedProperty!.toJson();
        conversationHistory += "SELECTED_PROPERTY_QUERY: true\n\nSELECTED_PROPERTY:\n";
        conversationHistory += "Address: ${_selectedProperty!.address}\n";
        conversationHistory += "Price: ${_selectedProperty!.price}\n";
        conversationHistory += "Bedrooms: ${_selectedProperty!.bedrooms}\n";
        conversationHistory += "Bathrooms: ${_selectedProperty!.bathrooms}\n";
        conversationHistory += "Living Area: ${_selectedProperty!.formattedLivingArea}\n";
        conversationHistory += "Property Type: ${_selectedProperty!.propertyType}\n";
        conversationHistory += "ZPID: ${_selectedProperty!.zpid}\n";
        if (_selectedProperty!.photoURL != null) conversationHistory += "Photo URL: ${_selectedProperty!.photoURL}\n";
        if (_selectedProperty!.imageUrls.isNotEmpty) conversationHistory += "Image URLs: ${_selectedProperty!.imageUrls.join(', ')}\n";
        if (_selectedProperty!.lotAreaValue != null) conversationHistory += "Lot Area Value: ${_selectedProperty!.lotAreaValue} ${_selectedProperty!.lotAreaUnit ?? ''}\n";
        if (_selectedProperty!.yearBuilt != null) conversationHistory += "Year Built: ${_selectedProperty!.yearBuilt}\n";
        if (_selectedProperty!.zillowLink != null) conversationHistory += "Zillow Link: ${_selectedProperty!.zillowLink}\n";
        if (_selectedProperty!.listingStatus != null) conversationHistory += "Listing Status: ${_selectedProperty!.listingStatus}\n";
        if (_selectedProperty!.daysOnZillow != null) conversationHistory += "Days on Zillow: ${_selectedProperty!.daysOnZillow}\n";
        if (_selectedProperty!.latitude != null && _selectedProperty!.longitude != null) conversationHistory += "Coordinates: (${_selectedProperty!.latitude}, ${_selectedProperty!.longitude})\n";
        conversationHistory += "Has Pool: ${_selectedProperty!.hasPool ?? 'N/A'}\n";
        conversationHistory += "Has Air Conditioning: ${_selectedProperty!.hasAirConditioning ?? 'N/A'}\n";
        conversationHistory += "Has Garage: ${_selectedProperty!.hasGarage ?? 'N/A'}\n";
        conversationHistory += "Parking Spots: ${_selectedProperty!.parkingSpots ?? 'N/A'}\n";
        conversationHistory += "Has City View: ${_selectedProperty!.isCityView ?? 'N/A'}\n";
        conversationHistory += "Has Mountain View: ${_selectedProperty!.isMountainView ?? 'N/A'}\n";
        conversationHistory += "Has Water View: ${_selectedProperty!.isWaterView ?? 'N/A'}\n";
        conversationHistory += "Has Park View: ${_selectedProperty!.isParkView ?? 'N/A'}\n";
        conversationHistory += "Is 3D Home: ${_selectedProperty!.is3dHome ?? 'N/A'}\n";
        conversationHistory += "Is Foreclosed: ${_selectedProperty!.isForeclosed ?? 'N/A'}\n";
        conversationHistory += "Is Pre-Foreclosure: ${_selectedProperty!.isPreForeclosure ?? 'N/A'}\n";
        if (_selectedProperty!.description != null) conversationHistory += "Description: ${_selectedProperty!.description}\n";
        if (_selectedProperty!.county != null) conversationHistory += "County: ${_selectedProperty!.county}\n";
        if (_selectedProperty!.city != null) conversationHistory += "City: ${_selectedProperty!.city}\n";
        if (_selectedProperty!.state != null) conversationHistory += "State: ${_selectedProperty!.state}\n";
        if (_selectedProperty!.zipcode != null) conversationHistory += "Zipcode: ${_selectedProperty!.zipcode}\n";
        if (_selectedProperty!.timeOnZillow != null) conversationHistory += "Time on Zillow: ${_selectedProperty!.timeOnZillow}\n";
        if (_selectedProperty!.pageViewCount != null) conversationHistory += "Page View Count: ${_selectedProperty!.pageViewCount}\n";
        if (_selectedProperty!.favoriteCount != null) conversationHistory += "Favorite Count: ${_selectedProperty!.favoriteCount}\n";
        if (_selectedProperty!.virtualTour != null) conversationHistory += "Virtual Tour: ${_selectedProperty!.virtualTour}\n";
        if (_selectedProperty!.brokerageName != null) conversationHistory += "Brokerage Name: ${_selectedProperty!.brokerageName}\n";
        if (_selectedProperty!.agentName != null) conversationHistory += "Agent Name: ${_selectedProperty!.agentName}\n";
        if (_selectedProperty!.agentPhoneNumber != null) conversationHistory += "Agent Phone: ${_selectedProperty!.agentPhoneNumber}\n";
        if (_selectedProperty!.brokerPhoneNumber != null) conversationHistory += "Broker Phone: ${_selectedProperty!.brokerPhoneNumber}\n";
        if (_selectedProperty!.stories != null) conversationHistory += "Stories: ${_selectedProperty!.stories}\n";
        if (_selectedProperty!.levels != null) conversationHistory += "Levels: ${_selectedProperty!.levels}\n";
        conversationHistory += "Has Fireplace: ${_selectedProperty!.hasFireplace ?? 'N/A'}\n";
        if (_selectedProperty!.fireplaces != null) conversationHistory += "Fireplaces: ${_selectedProperty!.fireplaces}\n";
        conversationHistory += "Has Basement: ${_selectedProperty!.basementYN ?? 'N/A'}\n";
        if (_selectedProperty!.basement != null) conversationHistory += "Basement: ${_selectedProperty!.basement}\n";
        if (_selectedProperty!.roofType != null) conversationHistory += "Roof Type: ${_selectedProperty!.roofType}\n";
        if (_selectedProperty!.coolingSystem != null) conversationHistory += "Cooling System: ${_selectedProperty!.coolingSystem}\n";
        if (_selectedProperty!.heatingSystem != null) conversationHistory += "Heating System: ${_selectedProperty!.heatingSystem}\n";
        if (_selectedProperty!.lotSize != null) conversationHistory += "Lot Size: ${_selectedProperty!.lotSize}\n";
        if (_selectedProperty!.fencing != null) conversationHistory += "Fencing: ${_selectedProperty!.fencing}\n";
        if (_selectedProperty!.bathroomsFull != null) conversationHistory += "Full Bathrooms: ${_selectedProperty!.bathroomsFull}\n";
        if (_selectedProperty!.bathroomsHalf != null) conversationHistory += "Half Bathrooms: ${_selectedProperty!.bathroomsHalf}\n";
        if (_selectedProperty!.aboveGradeFinishedArea != null) conversationHistory += "Above Grade Area: ${_selectedProperty!.aboveGradeFinishedArea}\n";
        if (_selectedProperty!.belowGradeFinishedArea != null) conversationHistory += "Below Grade Area: ${_selectedProperty!.belowGradeFinishedArea}\n";
        if (_selectedProperty!.parkingFeatures != null) conversationHistory += "Parking Features: ${_selectedProperty!.parkingFeatures}\n";
        if (_selectedProperty!.parkingCapacity != null) conversationHistory += "Parking Capacity: ${_selectedProperty!.parkingCapacity}\n";
        if (_selectedProperty!.garageParkingCapacity != null) conversationHistory += "Garage Parking Capacity: ${_selectedProperty!.garageParkingCapacity}\n";
        if (_selectedProperty!.appliances != null) conversationHistory += "Appliances: ${_selectedProperty!.appliances}\n";
        if (_selectedProperty!.interiorFeatures != null) conversationHistory += "Interior Features: ${_selectedProperty!.interiorFeatures}\n";
        if (_selectedProperty!.exteriorFeatures != null) conversationHistory += "Exterior Features: ${_selectedProperty!.exteriorFeatures}\n";
        if (_selectedProperty!.constructionMaterials != null) conversationHistory += "Construction Materials: ${_selectedProperty!.constructionMaterials}\n";
        if (_selectedProperty!.patioAndPorchFeatures != null) conversationHistory += "Patio/Porch Features: ${_selectedProperty!.patioAndPorchFeatures}\n";
        if (_selectedProperty!.laundryFeatures != null) conversationHistory += "Laundry Features: ${_selectedProperty!.laundryFeatures}\n";
        if (_selectedProperty!.pricePerSquareFoot != null) conversationHistory += "Price per Sqft: ${_selectedProperty!.pricePerSquareFoot}\n";
        if (_selectedProperty!.photoCount != null) conversationHistory += "Photo Count: ${_selectedProperty!.photoCount}\n";
        conversationHistory += "\n";
      } else if (_properties.isNotEmpty) {
        conversationHistory += "AVAILABLE_PROPERTIES:\n";
        for (int i = 0; i < _properties.length; i++) {
          final property = _properties[i];
          conversationHistory +=
              "Property ${i + 1}: ${property.address}, ${property.price}, ${property.bedrooms} beds, ${property.bathrooms} baths, ${property.formattedLivingArea}";
          List<String> additionalDetails = [];
          if (property.hasPool == true) additionalDetails.add("has pool");
          if (property.hasAirConditioning == true) additionalDetails.add("has air conditioning");
          if (property.hasGarage == true) additionalDetails.add("has garage");
          if (property.parkingSpots != null && property.parkingSpots != "--") additionalDetails.add("${property.parkingSpots} parking spots");
          if (property.yearBuilt != null) additionalDetails.add("built in ${property.yearBuilt}");
          if (property.isCityView == true) additionalDetails.add("has city view");
          if (property.isMountainView == true) additionalDetails.add("has mountain view");
          if (property.isWaterView == true) additionalDetails.add("has water view");
          if (property.isParkView == true) additionalDetails.add("has park view");
          if (additionalDetails.isNotEmpty) conversationHistory += " (${additionalDetails.join(", ")})";
          conversationHistory += "\n";
        }
        conversationHistory += "\n";
      }

      if (_isNearMeMode && _lastKnownPosition != null) {
        conversationHistory += "User's current location: (${_lastKnownPosition!.latitude}, ${_lastKnownPosition!.longitude})\n";
      }

      final messagesInOrder = _messages.reversed.toList();
      for (var msg in messagesInOrder) {
        if (msg is types.TextMessage) {
          final speaker = msg.author.id == _user.id ? "User" : "Agent";
          conversationHistory += "$speaker: ${msg.text}\n";
        }
      }

      final response = await _apiCalls.searchProperties(
        message.text,
        _getMapCoordinates(),
        context: conversationHistory,
        selectedProperty: selectedPropertyData,
      );

      print(_getMapCoordinates());

      if (response == null) throw Exception("API response is null");

      final agentResponse = response['agentResponse'] as String?;
      if (agentResponse == null) throw Exception("Agent response missing in API response");

      final propertyResults = response['results'] as List<dynamic>?;

      if (propertyResults != null && propertyResults.isNotEmpty) {
        setState(() {
          _selectedProperty = null;
          _selectedPropertyId = null;
          _properties = propertyResults.map((json) => Property.fromJson(json)).toList();
        });
        _addCombinedResponse(_properties, agentResponse);
      } else {
        _addBotTextMessage(agentResponse);
      }
    } catch (e) {
      print('Error handling message: $e');
      setState(() {
        _errorMessage = 'Failed to handle message. Please try again.';
      });
      _addBotTextMessage('Sorry, I encountered an error. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFullScreenProperty(Property property, String propertyId, bool isMapView, bool isPlaceholderView) {
    setState(() {
      _fullScreenPropertyId = propertyId;
      _fullScreenProperty = property;
      _fullScreenIsMapView = isMapView;
      _fullScreenIsPlaceholderView = isPlaceholderView;
      if (isPlaceholderView) {
        _similarPropertiesFuture = _apiCalls.getSimilarProperties(property.toJson(), _getMapCoordinates());
      } else {
        _similarPropertiesFuture = null;
      }
    });
    _animationController.forward(from: 0.0);
  }

  void _showPropertyDetails(Property property) {
    setState(() {
      _returnToSimilarProperties = true;
      _showFullScreenProperty(property, property.zpid, false, false);
    });
  }

  void _closeFullScreenProperty() {
    if (_returnToSimilarProperties && _fullScreenProperty != null && !_fullScreenIsPlaceholderView) {
      _animationController.reverse().then((value) {
        if (mounted) {
          setState(() {
            _fullScreenIsMapView = false;
            _fullScreenIsPlaceholderView = true;
            _returnToSimilarProperties = false;
          });
          _animationController.forward(from: 0.0);
        }
      });
    } else {
      _animationController.reverse().then((value) {
        if (mounted) {
          setState(() {
            _fullScreenPropertyId = null;
            _fullScreenProperty = null;
            _fullScreenIsMapView = false;
            _fullScreenIsPlaceholderView = false;
            _similarPropertiesFuture = null;
            _returnToSimilarProperties = false;
          });
        }
      });
    }
  }

  String formatPrice(String price) {
    String cleanedPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
    double priceValue = double.tryParse(cleanedPrice) ?? 0.0;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(priceValue);
  }

  void _handleLeftSwipe(Property property) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await _apiCalls.getPropertyImages(property.zpid);
      Property updatedProperty = property;

      if (response != null && response['images'] != null) {
        final List<dynamic> imageData = response['images'] as List<dynamic>;
        if (imageData.isNotEmpty) {
          List<String> imageUrls = imageData.map((img) => img is Map<String, dynamic> ? img['url'] as String : img as String).toList();
          if (imageUrls.isNotEmpty) {
            Map<String, dynamic> propertyJson = property.toJson();
            propertyJson['imageUrls'] = imageUrls;
            updatedProperty = Property.fromJson(propertyJson);
          }
        }
      }
      _showFullScreenProperty(updatedProperty, updatedProperty.zpid, false, false);
    } catch (e) {
      print('Error getting property images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load property images: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleRightSwipe(Property property) {
    if (_fullScreenPropertyId == property.zpid && _fullScreenIsPlaceholderView) return;
    setState(() {
      _isLoading = true;
    });
    _showFullScreenProperty(property, property.zpid, false, true);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (var controller in _mapControllers.values) {
      controller?.dispose();
    }
    _fullScreenMapController?.dispose();
    _backgroundMapController?.dispose();
    _chatHeightController.dispose();
    _animationController.dispose();
    _selectionAnimationController.dispose();
    _chatInputFocusNode.dispose();
    super.dispose();
  }

  Widget customMessageBuilder(types.CustomMessage message, {required int messageWidth}) {
    if (message.metadata?['type'] == 'combined_response') {
      List<dynamic> propertiesJson = message.metadata?['properties'] ?? [];
      List<Property> properties = propertiesJson.map((json) => Property.fromJson(json)).toList();
      String? agentResponse = message.metadata?['agentResponse'] as String?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var property in properties)
            Builder(builder: (context) {
              final propertyId = property.zpid;
              final isSelected = _selectedPropertyId == propertyId;
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: GestureDetector(
                  onDoubleTap: () => _selectProperty(property, propertyId),
                  child: Dismissible(
                    key: Key(propertyId),
                    direction: DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        _handleRightSwipe(property);
                      } else {
                        _handleLeftSwipe(property);
                      }
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      color: Colors.transparent,
                      child: const Icon(Icons.maps_home_work_rounded, color: Colors.white70, size: 50),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.transparent,
                      child: const Icon(Icons.home_rounded, color: Colors.white70, size: 50),
                    ),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isSelected ? _pulseAnimation.value : 1.0,
                          child: Stack(
                            children: [
                              _buildPropertyCard(property, propertyId, false),
                              if (isSelected)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          if (agentResponse != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(52, 99, 56, 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  agentResponse,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDescriptionSection(Property property) {
    const int maxLines = 3;
    final bool isExpanded = _expandedDescriptions[property.zpid] ?? false;
    final String description = property.description ?? "N/A";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isExpanded ? [Colors.black, Colors.black] : [Colors.black, Colors.transparent],
              stops: isExpanded ? [0.0, 1.0] : [0.7, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Text(
            description,
            style: const TextStyle(fontSize: 16),
            maxLines: isExpanded ? null : maxLines,
            overflow: isExpanded ? null : TextOverflow.clip,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              setState(() {
                _expandedDescriptions[property.zpid] = !isExpanded;
              });
            },
            child: Container(
              height: 30,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  isExpanded ? "Collapse" : "Expand",
                  style: const TextStyle(color: Color.fromRGBO(27, 94, 32, 1), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nearby Amenities",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var amenity in ['Shopping Center', 'Park', 'School', 'Restaurant', 'Grocery Store', 'Hospital', 'Gym'])
              Chip(
                label: Text(amenity),
                backgroundColor: const Color.fromRGBO(27, 94, 32, 1),
                side: BorderSide(color: const Color.fromRGBO(27, 94, 32, 1).withOpacity(0.3)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderPage(Property property, String propertyId) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Similar Properties", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Properties like ${property.address}", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
            const Divider(height: 32),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _similarPropertiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color.fromRGBO(27, 94, 32, 1)));
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text("Error loading similar properties", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700])),
                          const SizedBox(height: 8),
                          Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700])),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text("No similar properties found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                        ],
                      ),
                    );
                  } else {
                    final results = snapshot.data!['results'];
                    if (results is List<dynamic> && results.isNotEmpty) {
                      final List<Property> similarProperties = results.map((json) => Property.fromJson(json as Map<String, dynamic>)).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${similarProperties.length} similar properties found",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(27, 94, 32, 1)),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.vertical,
                              itemCount: similarProperties.length,
                              itemBuilder: (context, index) {
                                final similarProperty = similarProperties[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: GestureDetector(
                                    onDoubleTap: () {
                                      _selectProperty(similarProperty, similarProperty.zpid);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Property selected for discussion'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
                                      );
                                      _closeFullScreenProperty();
                                    },
                                    onLongPress: () => _showPropertyDetails(similarProperty),
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              formatPropertyType(similarProperty.propertyType) ?? 'Property',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              similarProperty.address,
                                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              formatPrice(similarProperty.price),
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromRGBO(27, 94, 32, 1)),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                _propertyFeatureChip(Icons.bed, "${similarProperty.bedrooms} Beds"),
                                                _propertyFeatureChip(Icons.bathtub, "${similarProperty.bathrooms} Baths"),
                                                _propertyFeatureChip(Icons.square_foot, similarProperty.formattedLivingArea),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text("No similar properties found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _closeFullScreenProperty,
                icon: const Icon(Icons.arrow_back),
                label: const Text("Back to Chat"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(27, 94, 32, 1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertyFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color.fromRGBO(27, 94, 32, 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color.fromRGBO(27, 94, 32, 1)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color.fromRGBO(27, 94, 32, 1))),
        ],
      ),
    );
  }

  Widget _propertyFeatureChipResizable(String label, bool isFullScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color.fromRGBO(27, 94, 32, 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: isFullScreen ? 14 : 12, color: const Color.fromRGBO(27, 94, 32, 1)), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property, String propertyId, bool isFullScreen) {
    return Card(
      color: Colors.white,
      elevation: isFullScreen ? 0 : 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    formatPropertyType(property.propertyType) ?? 'Property',
                    style: TextStyle(fontSize: isFullScreen ? 24 : 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(property.address, style: TextStyle(color: Colors.grey, fontSize: isFullScreen ? 16 : 14)),
            SizedBox(height: isFullScreen ? 16 : 8),
            Text(formatPrice(property.price), style: TextStyle(fontSize: isFullScreen ? 20 : 16, color: const Color.fromRGBO(27, 94, 32, 1), fontWeight: FontWeight.bold)),
            SizedBox(height: isFullScreen ? 16 : 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _propertyFeatureChipResizable("${property.bedrooms} Beds", isFullScreen),
                _propertyFeatureChipResizable("${property.bathrooms} Baths", isFullScreen),
                _propertyFeatureChipResizable(property.formattedLivingArea, isFullScreen),
              ],
            ),
            if (isFullScreen) ...[
              const Divider(height: 32),
              const Text("Photos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildPhotoGallery(property),
              const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDescriptionSection(property),
              const SizedBox(height: 10),
              _buildNearbyAmenitiesSection(),
              const SizedBox(height: 20),
              const Text("Property Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_detailRow("Year Built", property.yearBuilt ?? 'N/A', 16), _detailRow("Parking", "${property.parkingSpots ?? 'N/A'} spots", 16)])),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_detailRow("School District", "Local District", 16), _detailRow("Type", formatPropertyType(property.propertyType) ?? "Residential", 16)])),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    Expanded(child: _actionButton(Icons.calendar_today, "Schedule Tour")),
                    const SizedBox(width: 16),
                    Expanded(child: _actionButton(Icons.phone, "Message Agent")),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _fullScreenIsMapView = true),
                  icon: const Icon(Icons.map, color: Color.fromRGBO(27, 94, 32, 1)),
                  label: const Text("View on Map", style: TextStyle(color: Color.fromRGBO(27, 94, 32, 1))),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Color.fromRGBO(27, 94, 32, 1))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderGallery() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
            child: Center(child: Icon(Icons.photo, size: 50, color: Colors.grey[700])),
          ),
      ],
    );
  }

  Widget _buildPhotoGallery(Property property) {
    if (property.imageUrls.isEmpty && property.photoURL == null) return _buildPlaceholderGallery();

    List<String> allImages = [];
    if (property.photoURL != null) allImages.add(property.photoURL!);
    allImages.addAll(property.imageUrls);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: allImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      allImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: Center(child: Icon(Icons.error_outline, size: 50, color: Colors.grey[700]))),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                              color: const Color.fromRGBO(27, 94, 32, 1),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                        child: Text("${index + 1}/${allImages.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _detailRow(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize)),
          Expanded(child: Text(value, style: TextStyle(fontSize: fontSize), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(27, 94, 32, 1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
    );
  }

  Widget _buildMapView(Property property, String propertyId, bool isFullScreen) {
    final double lat = property.latitude ?? 37.7749;
    final double lng = property.longitude ?? -122.4194;
    final LatLng propertyLocation = LatLng(lat, lng);

    Set<Marker> markers = {
      Marker(
        markerId: MarkerId(propertyId),
        position: propertyLocation,
        icon: _customMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: formatPropertyType(property.propertyType) ?? 'Property', snippet: formatPrice(property.price)),
      ),
    };

    if (isFullScreen) {
      for (var nearbyProperty in _properties) {
        if (nearbyProperty.zpid != propertyId && nearbyProperty.latitude != null && nearbyProperty.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId(nearbyProperty.zpid),
              position: LatLng(nearbyProperty.latitude!, nearbyProperty.longitude!),
              icon: _nearbyMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: InfoWindow(title: formatPropertyType(nearbyProperty.propertyType) ?? 'Property', snippet: formatPrice(nearbyProperty.price)),
            ),
          );
        }
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = isFullScreen ? screenHeight * 0.7 : 150.0;

    return Container(
      height: mapHeight,
      decoration: const BoxDecoration(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      margin: isFullScreen ? EdgeInsets.zero : EdgeInsets.zero,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: propertyLocation, zoom: isFullScreen ? 13 : 15),
            markers: markers,
            mapType: MapType.normal,
            myLocationEnabled: false,
            zoomControlsEnabled: isFullScreen,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: isFullScreen,
            tiltGesturesEnabled: isFullScreen,
            compassEnabled: isFullScreen,
            mapToolbarEnabled: isFullScreen,
            onMapCreated: (GoogleMapController controller) {
              if (isFullScreen) {
                _fullScreenMapController = controller;
              } else {
                _mapControllers[propertyId] = controller;
              }
            },
          ),
          if (isFullScreen)
            Positioned(
              top: 10,
              left: 10,
              child: FloatingActionButton.small(
                onPressed: () => setState(() => _fullScreenIsMapView = false),
                backgroundColor: Colors.white,
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullScreenOverlay() {
    if (_fullScreenPropertyId == null || _fullScreenProperty == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.9;
    final cardHeight = screenSize.height * 0.75;
    final appBarHeight = 25.0;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPadding = appBarHeight + statusBarHeight + 10;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.black54.withOpacity(0.5 * _fadeAnimation.value),
              child: Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: cardWidth,
                    height: _fullScreenIsMapView ? screenSize.height * 0.75 : cardHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3 * _fadeAnimation.value), blurRadius: 15, spreadRadius: 5)],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(icon: const Icon(Icons.close), onPressed: _closeFullScreenProperty, iconSize: 24),
                              if (!_fullScreenIsPlaceholderView) Text(formatPropertyType(_fullScreenProperty!.propertyType) ?? 'Property Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              if (!_fullScreenIsPlaceholderView && !_fullScreenIsMapView)
                                TextButton.icon(
                                  onPressed: () => setState(() => _fullScreenIsMapView = true),
                                  icon: const Icon(Icons.map, size: 18, color: Colors.green),
                                  label: const Text("Map", style: TextStyle(fontSize: 14, color: Colors.green)),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                            child: _fullScreenIsPlaceholderView
                                ? _buildPlaceholderPage(_fullScreenProperty!, _fullScreenPropertyId!)
                                : (_fullScreenIsMapView
                                    ? _buildMapView(_fullScreenProperty!, _fullScreenPropertyId!, true)
                                    : SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16.0), child: _buildPropertyCard(_fullScreenProperty!, _fullScreenPropertyId!, true)))),
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

  void _toggleChatHeight() {
    setState(() {
      if (_currentLevel == 0) {
        _currentLevel = 1;
        _chatHeightAnimation = Tween<double>(begin: _chatHeightFraction, end: 0.4).animate(_chatHeightController);
        _chatHeightFraction = 0.4;
      } else if (_currentLevel == 1) {
        _currentLevel = 2;
        _chatHeightAnimation = Tween<double>(begin: _chatHeightFraction, end: 0.8).animate(_chatHeightController);
        _chatHeightFraction = 0.8;
      } else {
        _currentLevel = 0;
        _chatHeightAnimation = Tween<double>(begin: _chatHeightFraction, end: 0.165).animate(_chatHeightController);
        _chatHeightFraction = 0.165;
      }
      _chatHeightController.forward(from: 0.0);
    });
  }

  void _collapseChatTo40Percent() {
    setState(() {
      _currentLevel = 1;
      _chatHeightAnimation = Tween<double>(begin: _chatHeightFraction, end: 0.4).animate(_chatHeightController);
      _chatHeightFraction = 0.4;
      _chatHeightController.forward(from: 0.0);
    });
  }

  void _cycleChatHeight() {
    setState(() {
      _currentLevel = (_currentLevel + 1) % 3;
      double newHeight;
      switch (_currentLevel) {
        case 0: newHeight = 0.165; break;
        case 1: newHeight = 0.4; break;
        case 2: newHeight = 0.8; break;
        default: newHeight = 0.8;
      }
      _chatHeightAnimation = Tween<double>(begin: _chatHeightFraction, end: newHeight).animate(_chatHeightController);
      _chatHeightFraction = newHeight;
      _chatHeightController.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final initialLat = _lastKnownPosition?.latitude ?? 37.7749;
    final initialLng = _lastKnownPosition?.longitude ?? -122.4194;
    final initialPosition = LatLng(initialLat, initialLng);

    Set<Marker> markers = {};
    for (var property in _properties) {
      if (property.latitude != null && property.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId(property.zpid),
            position: LatLng(property.latitude!, property.longitude!),
            icon: _customMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: formatPropertyType(property.propertyType) ?? 'Property', snippet: formatPrice(property.price)),
          ),
        );
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: initialPosition, zoom: 12),
                  markers: markers,
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  compassEnabled: true,
                  mapToolbarEnabled: true,
                  onMapCreated: (GoogleMapController controller) => _backgroundMapController = controller,
                  onCameraMove: (CameraPosition position) {
                    setState(() {
                      _mapCenter = position.target;
                      _mapZoom = position.zoom;
                    });
                  },
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_currentLevel == 2) _collapseChatTo40Percent();
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _chatHeightAnimation,
              builder: (context, child) {
                return Container(
                  height: screenHeight * _chatHeightAnimation.value,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_currentLevel == 0) _toggleChatHeight();
                          else _cycleChatHeight();
                        },
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity! < 0 && _currentLevel < 2) {
                            setState(() {
                              _currentLevel++;
                              double newHeight = _currentLevel == 0 ? 0.165 : _currentLevel == 1 ? 0.4 : 0.8;
                              _chatHeightAnimation = Tween<double>(begin: _chatHeightFraction, end: newHeight).animate(_chatHeightController);
                              _chatHeightFraction = newHeight;
                              _chatHeightController.forward(from: 0.0);
                            });
                          } else if (details.primaryVelocity! > 0 && _currentLevel > 0) {
                            setState(() {
                              _currentLevel--;
                              double newHeight = _currentLevel == 0 ? 0.165 : _currentLevel == 1 ? 0.4 : 0.8;
                              _chatHeightAnimation = Tween<double>(begin: _chatHeightFraction, end: newHeight).animate(_chatHeightController);
                              _chatHeightFraction = newHeight;
                              _chatHeightController.forward(from: 0.0);
                            });
                          }
                        },
                        child: Container(
                          height: 30,
                          color: Colors.transparent,
                          child: Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)))),
                        ),
                      ),
                      Expanded(
                        child: Chat(
                          messages: _messages,
                          onSendPressed: _handleSendPressed,
                          user: _user,
                          customMessageBuilder: customMessageBuilder,
                          inputOptions: const InputOptions(sendButtonVisibilityMode: SendButtonVisibilityMode.always),
                          theme: const DefaultChatTheme(
                            backgroundColor: Colors.white,
                            inputBackgroundColor: Colors.transparent,
                            primaryColor: Color.fromRGBO(88, 88, 88, 1),
                            inputBorderRadius: BorderRadius.all(Radius.circular(0)),
                            inputTextColor: Colors.black,
                            inputMargin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            sendButtonIcon: Icon(Icons.send, size: 24, color: Color.fromRGBO(4, 36, 6, 1)),
                            secondaryColor: Color.fromRGBO(52, 99, 56, 1),
                            highlightMessageColor: Colors.white,
                            receivedMessageBodyTextStyle: TextStyle(color: Colors.white, fontSize: 17),
                            sentMessageBodyTextStyle: TextStyle(color: Colors.white, fontSize: 17),
                            inputTextCursorColor: Color.fromRGBO(4, 36, 6, 1),
                            inputPadding: EdgeInsets.fromLTRB(12, 20, 12, 25),
                            inputContainerDecoration: BoxDecoration(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator(color: Color.fromRGBO(27, 94, 32, 1)))),
          if (_errorMessage != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red[900])),
              ),
            ),
          if (_selectedProperty != null)
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom + 80,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    const Text("Property Selected", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    GestureDetector(onTap: () => setState(() { _selectedProperty = null; _selectedPropertyId = null; }), child: const Icon(Icons.close, color: Colors.white, size: 18)),
                  ],
                ),
              ),
            ),
          if (_fullScreenPropertyId != null) _buildFullScreenOverlay(),
        ],
      ),
    );
  }
}
