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

  List<String> filterOptions = <String>[
    "Top Results",
    "Price: Low to High",
    "Price: High to Low",
  ];
  String dropdownValue = "Top Results";

  List<Property> _properties = [];
  List<Property> _visibleProperties = [];
  bool _isLoading = false;
  String? _errorMessage;

  Property? _selectedProperty;
  String? _selectedPropertyId;

  String? _fullScreenPropertyId;
  Property? _fullScreenProperty;
  bool _fullScreenIsMapView = false;

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

  late FocusNode _chatInputFocusNode;

  LatLng _mapCenter = const LatLng(37.7749, -122.4194);
  double _mapZoom = 12.0;

  bool _isListViewVisible = false;

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
        _addBotTextMessage("Hello! Ask me about real estate in your area :)");
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
      if (!serviceEnabled) {
        print("Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Location permission denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("Location permission permanently denied.");
        return;
      }

      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _mapCenter =
            LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude);
      });

      if (_backgroundMapController != null) {
        await _backgroundMapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                  _lastKnownPosition!.latitude, _lastKnownPosition!.longitude),
              zoom: 12.0,
            ),
          ),
        );
      }
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
    return propertyType != null
        ? (propertyTypeMap[propertyType] ?? propertyType)
        : 'Property';
  }

  Future<BitmapDescriptor> _createCircleMarker(Color color, double size) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 4,
      paint..style = PaintingStyle.fill,
    );

    final img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
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
        _isListViewVisible = false; // Switch to chat view
        // Add property card as a user message
        final customMessage = types.CustomMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          metadata: {
            'type': 'selected_property',
            'property': property.toJson(),
          },
        );
        _messages.insert(0, customMessage);
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

  void _updateVisibleProperties() async {
    if (_backgroundMapController == null) return;

    final bounds = await _backgroundMapController!.getVisibleRegion();
    final visibleProperties = _properties.where((property) {
      if (property.latitude == null || property.longitude == null) return false;
      final latLng = LatLng(property.latitude!, property.longitude!);
      return bounds.contains(latLng);
    }).toList();

    setState(() {
      _visibleProperties = visibleProperties;
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
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      String conversationHistory = "";
      Map<String, dynamic>? selectedPropertyData;

      if (_selectedProperty != null) {
        selectedPropertyData = _selectedProperty!.toJson();
        conversationHistory +=
            "SELECTED_PROPERTY_QUERY: true\n\nSELECTED_PROPERTY:\n";
        conversationHistory += "Address: ${_selectedProperty!.address}\n";
        conversationHistory += "Price: ${_selectedProperty!.price}\n";
        conversationHistory += "Bedrooms: ${_selectedProperty!.bedrooms}\n";
        conversationHistory += "Bathrooms: ${_selectedProperty!.bathrooms}\n";
        conversationHistory +=
            "Living Area: ${_selectedProperty!.formattedLivingArea}\n";
        conversationHistory +=
            "Property Type: ${_selectedProperty!.propertyType}\n";
        conversationHistory += "ZPID: ${_selectedProperty!.zpid}\n";
        if (_selectedProperty!.photoURL != null) {
          conversationHistory += "Photo URL: ${_selectedProperty!.photoURL}\n";
        }
        if (_selectedProperty!.imageUrls.isNotEmpty) {
          conversationHistory +=
              "Image URLs: ${_selectedProperty!.imageUrls.join(', ')}\n";
        }
        if (_selectedProperty!.lotAreaValue != null) {
          conversationHistory +=
              "Lot Area Value: ${_selectedProperty!.lotAreaValue} ${_selectedProperty!.lotAreaUnit ?? ''}\n";
        }
        if (_selectedProperty!.yearBuilt != null) {
          conversationHistory +=
              "Year Built: ${_selectedProperty!.yearBuilt}\n";
        }
        if (_selectedProperty!.zillowLink != null) {
          conversationHistory +=
              "Zillow Link: ${_selectedProperty!.zillowLink}\n";
        }
        if (_selectedProperty!.listingStatus != null) {
          conversationHistory +=
              "Listing Status: ${_selectedProperty!.listingStatus}\n";
        }
        if (_selectedProperty!.daysOnZillow != null) {
          conversationHistory +=
              "Days on Zillow: ${_selectedProperty!.daysOnZillow}\n";
        }
        if (_selectedProperty!.latitude != null &&
            _selectedProperty!.longitude != null) {
          conversationHistory +=
              "Coordinates: (${_selectedProperty!.latitude}, ${_selectedProperty!.longitude})\n";
        }
        conversationHistory +=
            "Has Pool: ${_selectedProperty!.hasPool ?? 'N/A'}\n";
        conversationHistory +=
            "Has Air Conditioning: ${_selectedProperty!.hasAirConditioning ?? 'N/A'}\n";
        conversationHistory +=
            "Has Garage: ${_selectedProperty!.hasGarage ?? 'N/A'}\n";
        conversationHistory +=
            "Parking Spots: ${_selectedProperty!.parkingSpots ?? 'N/A'}\n";
        conversationHistory +=
            "Has City View: ${_selectedProperty!.isCityView ?? 'N/A'}\n";
        conversationHistory +=
            "Has Mountain View: ${_selectedProperty!.isMountainView ?? 'N/A'}\n";
        conversationHistory +=
            "Has Water View: ${_selectedProperty!.isWaterView ?? 'N/A'}\n";
        conversationHistory +=
            "Has Park View: ${_selectedProperty!.isParkView ?? 'N/A'}\n";
        conversationHistory +=
            "Is 3D Home: ${_selectedProperty!.is3dHome ?? 'N/A'}\n";
        conversationHistory +=
            "Is Foreclosed: ${_selectedProperty!.isForeclosed ?? 'N/A'}\n";
        conversationHistory +=
            "Is Pre-Foreclosure: ${_selectedProperty!.isPreForeclosure ?? 'N/A'}\n";
        if (_selectedProperty!.description != null) {
          conversationHistory +=
              "Description: ${_selectedProperty!.description}\n";
        }
        if (_selectedProperty!.county != null) {
          conversationHistory += "County: ${_selectedProperty!.county}\n";
        }
        if (_selectedProperty!.city != null) {
          conversationHistory += "City: ${_selectedProperty!.city}\n";
        }
        if (_selectedProperty!.state != null) {
          conversationHistory += "State: ${_selectedProperty!.state}\n";
        }
        if (_selectedProperty!.zipcode != null) {
          conversationHistory += "Zipcode: ${_selectedProperty!.zipcode}\n";
        }
        if (_selectedProperty!.timeOnZillow != null) {
          conversationHistory +=
              "Time on Zillow: ${_selectedProperty!.timeOnZillow}\n";
        }
        if (_selectedProperty!.pageViewCount != null) {
          conversationHistory +=
              "Page View Count: ${_selectedProperty!.pageViewCount}\n";
        }
        if (_selectedProperty!.favoriteCount != null) {
          conversationHistory +=
              "Favorite Count: ${_selectedProperty!.favoriteCount}\n";
        }
        if (_selectedProperty!.virtualTour != null) {
          conversationHistory +=
              "Virtual Tour: ${_selectedProperty!.virtualTour}\n";
        }
        if (_selectedProperty!.brokerageName != null) {
          conversationHistory +=
              "Brokerage Name: ${_selectedProperty!.brokerageName}\n";
        }
        if (_selectedProperty!.agentName != null) {
          conversationHistory +=
              "Agent Name: ${_selectedProperty!.agentName}\n";
        }
        if (_selectedProperty!.agentPhoneNumber != null) {
          conversationHistory +=
              "Agent Phone: ${_selectedProperty!.agentPhoneNumber}\n";
        }
        if (_selectedProperty!.brokerPhoneNumber != null) {
          conversationHistory +=
              "Broker Phone: ${_selectedProperty!.brokerPhoneNumber}\n";
        }
        if (_selectedProperty!.stories != null) {
          conversationHistory += "Stories: ${_selectedProperty!.stories}\n";
        }
        if (_selectedProperty!.levels != null) {
          conversationHistory += "Levels: ${_selectedProperty!.levels}\n";
        }
        conversationHistory +=
            "Has Fireplace: ${_selectedProperty!.hasFireplace ?? 'N/A'}\n";
        if (_selectedProperty!.fireplaces != null) {
          conversationHistory +=
              "Fireplaces: ${_selectedProperty!.fireplaces}\n";
        }
        conversationHistory +=
            "Has Basement: ${_selectedProperty!.basementYN ?? 'N/A'}\n";
        if (_selectedProperty!.basement != null) {
          conversationHistory += "Basement: ${_selectedProperty!.basement}\n";
        }
        if (_selectedProperty!.roofType != null) {
          conversationHistory += "Roof Type: ${_selectedProperty!.roofType}\n";
        }
        if (_selectedProperty!.coolingSystem != null) {
          conversationHistory +=
              "Cooling System: ${_selectedProperty!.coolingSystem}\n";
        }
        if (_selectedProperty!.heatingSystem != null) {
          conversationHistory +=
              "Heating System: ${_selectedProperty!.heatingSystem}\n";
        }
        if (_selectedProperty!.lotSize != null) {
          conversationHistory += "Lot Size: ${_selectedProperty!.lotSize}\n";
        }
        if (_selectedProperty!.fencing != null) {
          conversationHistory += "Fencing: ${_selectedProperty!.fencing}\n";
        }
        if (_selectedProperty!.bathroomsFull != null) {
          conversationHistory +=
              "Full Bathrooms: ${_selectedProperty!.bathroomsFull}\n";
        }
        if (_selectedProperty!.bathroomsHalf != null) {
          conversationHistory +=
              "Half Bathrooms: ${_selectedProperty!.bathroomsHalf}\n";
        }
        if (_selectedProperty!.aboveGradeFinishedArea != null) {
          conversationHistory +=
              "Above Grade Area: ${_selectedProperty!.aboveGradeFinishedArea}\n";
        }
        if (_selectedProperty!.belowGradeFinishedArea != null) {
          conversationHistory +=
              "Below Grade Area: ${_selectedProperty!.belowGradeFinishedArea}\n";
        }
        if (_selectedProperty!.parkingFeatures != null) {
          conversationHistory +=
              "Parking Features: ${_selectedProperty!.parkingFeatures}\n";
        }
        if (_selectedProperty!.parkingCapacity != null) {
          conversationHistory +=
              "Parking Capacity: ${_selectedProperty!.parkingCapacity}\n";
        }
        if (_selectedProperty!.garageParkingCapacity != null) {
          conversationHistory +=
              "Garage Parking Capacity: ${_selectedProperty!.garageParkingCapacity}\n";
        }
        if (_selectedProperty!.appliances != null) {
          conversationHistory +=
              "Appliances: ${_selectedProperty!.appliances}\n";
        }
        if (_selectedProperty!.interiorFeatures != null) {
          conversationHistory +=
              "Interior Features: ${_selectedProperty!.interiorFeatures}\n";
        }
        if (_selectedProperty!.exteriorFeatures != null) {
          conversationHistory +=
              "Exterior Features: ${_selectedProperty!.exteriorFeatures}\n";
        }
        if (_selectedProperty!.constructionMaterials != null) {
          conversationHistory +=
              "Construction Materials: ${_selectedProperty!.constructionMaterials}\n";
        }
        if (_selectedProperty!.patioAndPorchFeatures != null) {
          conversationHistory +=
              "Patio/Porch Features: ${_selectedProperty!.patioAndPorchFeatures}\n";
        }
        if (_selectedProperty!.laundryFeatures != null) {
          conversationHistory +=
              "Laundry Features: ${_selectedProperty!.laundryFeatures}\n";
        }
        if (_selectedProperty!.pricePerSquareFoot != null) {
          conversationHistory +=
              "Price per Sqft: ${_selectedProperty!.pricePerSquareFoot}\n";
        }
        if (_selectedProperty!.photoCount != null) {
          conversationHistory +=
              "Photo Count: ${_selectedProperty!.photoCount}\n";
        }
        conversationHistory += "\n";
      } else if (_properties.isNotEmpty) {
        conversationHistory += "AVAILABLE_PROPERTIES:\n";
        for (int i = 0; i < _properties.length; i++) {
          final property = _properties[i];
          conversationHistory +=
              "Property ${i + 1}: ${property.address}, ${property.price}, ${property.bedrooms} beds, ${property.bathrooms} baths, ${property.formattedLivingArea}";
          List<String> additionalDetails = [];
          if (property.hasPool == true) additionalDetails.add("has pool");
          if (property.hasAirConditioning == true) {
            additionalDetails.add("has air conditioning");
          }
          if (property.hasGarage == true) additionalDetails.add("has garage");
          if (property.parkingSpots != null && property.parkingSpots != "--") {
            additionalDetails.add("${property.parkingSpots} parking spots");
          }
          if (property.yearBuilt != null) {
            additionalDetails.add("built in ${property.yearBuilt}");
          }
          if (property.isCityView == true) {
            additionalDetails.add("has city view");
          }
          if (property.isMountainView == true) {
            additionalDetails.add("has mountain view");
          }
          if (property.isWaterView == true) {
            additionalDetails.add("has water view");
          }
          if (property.isParkView == true) {
            additionalDetails.add("has park view");
          }
          if (additionalDetails.isNotEmpty) {
            conversationHistory += " (${additionalDetails.join(", ")})";
          }
          conversationHistory += "\n";
        }
        conversationHistory += "\n";
      }

      if (_isNearMeMode && _lastKnownPosition != null) {
        conversationHistory +=
            "User's current location: (${_lastKnownPosition!.latitude}, ${_lastKnownPosition!.longitude})\n";
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
      if (agentResponse == null) {
        throw Exception("Agent response missing in API response");
      }

      final propertyResults = response['results'] as List<dynamic>?;

      if (propertyResults != null && propertyResults.isNotEmpty) {
        setState(() {
          _selectedProperty = null;
          _selectedPropertyId = null;
          _properties =
              propertyResults.map((json) => Property.fromJson(json)).toList();
          _visibleProperties = _properties;
        });
        _addCombinedResponse(_properties, agentResponse);
        _updateVisibleProperties();
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

  void _showFullScreenProperty(
      Property property, String propertyId, bool isMapView) {
    setState(() {
      _fullScreenPropertyId = propertyId;
      _fullScreenProperty = property;
      _fullScreenIsMapView = isMapView;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward(from: 0.0);
    });
  }

  void _closeFullScreenProperty() {
    _animationController.reverse().then((value) {
      if (mounted) {
        setState(() {
          _fullScreenMapController?.dispose();
          _fullScreenMapController = null;
          _fullScreenPropertyId = null;
          _fullScreenProperty = null;
          _fullScreenIsMapView = false;
        });
      }
    });
  }

  String formatPrice(String price) {
    String cleanedPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
    double priceValue = double.tryParse(cleanedPrice) ?? 0.0;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(priceValue);
  }

  void _showPropertyDetailsWithFetch(Property property) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Store the original property data to preserve existing fields
      final originalJson = property.toJson();

      // Fetch images and details concurrently
      final imagesResponseFuture = _apiCalls.getPropertyImages(property.zpid);
      final detailsResponseFuture = _apiCalls.getPropertyDetails(property.zpid);

      final [imagesResponse, detailsResponse] = await Future.wait([
        imagesResponseFuture,
        detailsResponseFuture,
      ]);

      // Log API responses for debugging
      print('Images response: $imagesResponse');
      print('Details response: $detailsResponse');

      // Initialize the JSON map with original data to preserve all fields
      Map<String, dynamic> updatedJson = Map.from(originalJson);

      // Process images (update imageUrls if provided)
      if (imagesResponse != null && imagesResponse['images'] != null) {
        final List<dynamic> imageData =
            imagesResponse['images'] as List<dynamic>;
        if (imageData.isNotEmpty) {
          updatedJson['imageUrls'] = imageData
              .map((img) => img is Map<String, dynamic>
                  ? img['url'] as String
                  : img as String)
              .toList();
        }
      }

      // Process details with selective merge
      if (detailsResponse != null && detailsResponse['details'] != null) {
        final detailedData = detailsResponse['details'] as Map<String, dynamic>;

        // Helper function to update only null fields
        void updateIfNull(String key, dynamic value) {
          if (value != null && updatedJson[key] == null) {
            updatedJson[key] = value;
          }
        }

        // Map /details fields, including nested resoFacts and attributionInfo
        // Only update fields that are null in the original Property
        updateIfNull('description', detailedData['description']);
        updateIfNull(
            'county', detailedData['county'] ?? detailedData['countyName']);
        updateIfNull(
            'city', detailedData['city'] ?? detailedData['resoFacts']?['city']);
        updateIfNull('state',
            detailedData['state'] ?? detailedData['resoFacts']?['state']);
        updateIfNull('zipcode',
            detailedData['zipcode'] ?? detailedData['resoFacts']?['zipCode']);
        updateIfNull(
            'virtualTour',
            detailedData['virtualTour'] ??
                detailedData['resoFacts']?['virtualTour']);
        updateIfNull(
            'brokerageName',
            detailedData['brokerageName'] ??
                detailedData['attributionInfo']?['brokerName']);
        updateIfNull(
            'agentName',
            detailedData['agentName'] ??
                detailedData['attributionInfo']?['agentName']);
        updateIfNull(
            'agentPhoneNumber',
            detailedData['agentPhoneNumber'] ??
                detailedData['attributionInfo']?['agentPhoneNumber']);
        updateIfNull(
            'brokerPhoneNumber',
            detailedData['brokerPhoneNumber'] ??
                detailedData['attributionInfo']?['brokerPhoneNumber']);
        updateIfNull('stories',
            detailedData['stories'] ?? detailedData['resoFacts']?['stories']);
        updateIfNull('levels',
            detailedData['levels'] ?? detailedData['resoFacts']?['levels']);
        updateIfNull(
            'hasFireplace',
            detailedData['hasFireplace'] ??
                detailedData['resoFacts']?['hasFireplace']);
        updateIfNull(
            'fireplaces',
            detailedData['fireplaces'] ??
                detailedData['resoFacts']?['fireplaces']);
        updateIfNull(
            'basementYN',
            detailedData['basementYN'] ??
                detailedData['resoFacts']?['hasBasement']);
        updateIfNull('basement',
            detailedData['basement'] ?? detailedData['resoFacts']?['basement']);
        updateIfNull('roofType',
            detailedData['roofType'] ?? detailedData['resoFacts']?['roofType']);
        updateIfNull(
            'coolingSystem',
            detailedData['coolingSystem'] ??
                detailedData['resoFacts']?['cooling']);
        updateIfNull(
            'heatingSystem',
            detailedData['heatingSystem'] ??
                detailedData['resoFacts']?['heating']);
        updateIfNull('lotSize',
            detailedData['lotSize'] ?? detailedData['resoFacts']?['lotSize']);
        updateIfNull('fencing',
            detailedData['fencing'] ?? detailedData['resoFacts']?['fencing']);
        updateIfNull(
            'bathroomsFull',
            detailedData['bathroomsFull'] ??
                detailedData['resoFacts']?['bathroomsFull']);
        updateIfNull(
            'bathroomsHalf',
            detailedData['bathroomsHalf'] ??
                detailedData['resoFacts']?['bathroomsHalf']);
        updateIfNull(
            'aboveGradeFinishedArea',
            detailedData['aboveGradeFinishedArea'] ??
                detailedData['resoFacts']?['aboveGradeFinishedArea']);
        updateIfNull(
            'belowGradeFinishedArea',
            detailedData['belowGradeFinishedArea'] ??
                detailedData['resoFacts']?['belowGradeFinishedArea']);
        updateIfNull(
            'parkingFeatures',
            detailedData['parkingFeatures'] ??
                detailedData['resoFacts']?['parkingFeatures']);
        updateIfNull(
            'parkingCapacity',
            detailedData['parkingCapacity'] ??
                detailedData['resoFacts']?['parkingCapacity']);
        updateIfNull(
            'garageParkingCapacity',
            detailedData['garageParkingCapacity'] ??
                detailedData['resoFacts']?['garageParkingCapacity']);
        updateIfNull(
            'appliances',
            detailedData['appliances'] ??
                detailedData['resoFacts']?['appliances']);
        updateIfNull(
            'interiorFeatures',
            detailedData['interiorFeatures'] ??
                detailedData['resoFacts']?['interiorFeatures']);
        updateIfNull(
            'exteriorFeatures',
            detailedData['exteriorFeatures'] ??
                detailedData['resoFacts']?['exteriorFeatures']);
        updateIfNull(
            'constructionMaterials',
            detailedData['constructionMaterials'] ??
                detailedData['resoFacts']?['constructionMaterials']);
        updateIfNull(
            'patioAndPorchFeatures',
            detailedData['patioAndPorchFeatures'] ??
                detailedData['resoFacts']?['patioAndPorchFeatures']);
        updateIfNull(
            'laundryFeatures',
            detailedData['laundryFeatures'] ??
                detailedData['resoFacts']?['laundryFeatures']);
        updateIfNull(
            'pricePerSquareFoot',
            detailedData['pricePerSquareFoot'] ??
                detailedData['resoFacts']?['pricePerSquareFoot']);
        updateIfNull(
            'photoCount',
            detailedData['photoCount'] ??
                detailedData['resoFacts']?['photoCount']);
        updateIfNull(
            'lotAreaValue',
            detailedData['lotAreaValue'] ??
                detailedData['resoFacts']?['lotSize']);
        updateIfNull(
            'lotAreaUnit',
            detailedData['lotAreaUnit'] ??
                detailedData['resoFacts']?['lotSizeUnits']);
        updateIfNull(
            'yearBuilt',
            detailedData['yearBuilt'] ??
                detailedData['resoFacts']?['yearBuilt']);
        updateIfNull('listingStatus',
            detailedData['listingStatus'] ?? detailedData['status']);
        updateIfNull('daysOnZillow',
            detailedData['daysOnZillow'] ?? detailedData['timeOnZillow']);
        updateIfNull('hasPool',
            detailedData['hasPool'] ?? detailedData['resoFacts']?['hasPool']);
        updateIfNull(
            'hasAirConditioning',
            detailedData['hasAirConditioning'] ??
                detailedData['resoFacts']?['hasCooling']);
        updateIfNull(
            'hasGarage',
            detailedData['hasGarage'] ??
                detailedData['resoFacts']?['hasGarage']);
        updateIfNull(
            'parkingSpots',
            detailedData['parkingSpots'] ??
                detailedData['resoFacts']?['parking']);
        updateIfNull(
            'isCityView',
            detailedData['isCityView'] ??
                detailedData['resoFacts']?['cityView']);
        updateIfNull(
            'isMountainView',
            detailedData['isMountainView'] ??
                detailedData['resoFacts']?['mountainView']);
        updateIfNull(
            'isWaterView',
            detailedData['isWaterView'] ??
                detailedData['resoFacts']?['waterView']);
        updateIfNull(
            'isParkView',
            detailedData['isParkView'] ??
                detailedData['resoFacts']?['parkView']);
        updateIfNull(
            'is3dHome',
            detailedData['is3dHome'] ??
                detailedData['resoFacts']?['has3DModel']);
        updateIfNull(
            'isForeclosed',
            detailedData['isForeclosed'] ??
                detailedData['resoFacts']?['isForeclosed']);
        updateIfNull(
            'isPreForeclosure',
            detailedData['isPreForeclosure'] ??
                detailedData['resoFacts']?['isPreForeclosure']);
        updateIfNull('timeOnZillow', detailedData['timeOnZillow']);
        updateIfNull('pageViewCount', detailedData['pageViewCount']);
        updateIfNull('favoriteCount', detailedData['favoriteCount']);

        // Log the fields that were updated
        print(
            'Updated fields: ${updatedJson.entries.where((e) => e.value != originalJson[e.key]).map((e) => '${e.key}: ${e.value}').toList()}');
      }

      // Create updated Property object
      final updatedProperty = Property.fromJson(updatedJson);

      // Update the property in _properties and _visibleProperties
      setState(() {
        _properties = _properties.map((p) {
          return p.zpid == property.zpid ? updatedProperty : p;
        }).toList();
        _visibleProperties = _visibleProperties.map((p) {
          return p.zpid == property.zpid ? updatedProperty : p;
        }).toList();
      });

      // Show the updated property in full-screen view
      _showFullScreenProperty(updatedProperty, updatedProperty.zpid, false);
    } catch (e) {
      print('Error getting property details or images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load property details or images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mapControllers.forEach((key, controller) {
      controller?.dispose();
    });
    _mapControllers.clear();
    _fullScreenMapController?.dispose();
    _backgroundMapController?.dispose();
    _chatHeightController.dispose();
    _animationController.dispose();
    _selectionAnimationController.dispose();
    _chatInputFocusNode.dispose();
    super.dispose();
  }

  Widget customMessageBuilder(types.CustomMessage message,
      {required int messageWidth}) {
    if (message.metadata?['type'] == 'combined_response') {
      String? agentResponse = message.metadata?['agentResponse'] as String?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (agentResponse != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
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
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isListViewVisible = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text("View Houses"),
                  ),
                ],
              ),
            ),
        ],
      );
    } else if (message.metadata?['type'] == 'selected_property') {
      final propertyJson =
          message.metadata?['property'] as Map<String, dynamic>?;
      if (propertyJson == null) return const SizedBox.shrink();
      final property = Property.fromJson(propertyJson);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          width: messageWidth.toDouble() * 0.8,
          child:
              _buildPropertyCard(property, property.zpid, false, isChat: true),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDescriptionSection(Property property) {
    const int maxLines = 3;
    final bool isExpanded = _expandedDescriptions[property.zpid] ?? false;
    final String description =
        property.description ?? "No description available";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isExpanded
                  ? [Colors.black, Colors.black]
                  : [Colors.black, Colors.transparent],
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
                  style: const TextStyle(
                      color: Color.fromRGBO(27, 94, 32, 1),
                      fontWeight: FontWeight.bold),
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
            for (var amenity in [
              'Shopping Center',
              'Park',
              'School',
              'Restaurant',
              'Grocery Store',
              'Hospital',
              'Gym'
            ])
              Chip(
                label: Text(amenity),
                backgroundColor: const Color.fromRGBO(27, 94, 32, 1),
                side: BorderSide(
                    color:
                        const Color.fromRGBO(27, 94, 32, 1).withOpacity(0.3)),
              ),
          ],
        ),
      ],
    );
  }

  List<Property> _sortLowToHigh(List<Property> properties) {
    List<Property> sorted = List.from(properties);
    sorted.sort((a, b) {
      double priceA =
          double.tryParse(a.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      double priceB =
          double.tryParse(b.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      return priceA.compareTo(priceB);
    });
    return sorted;
  }

  List<Property> _sortHighToLow(List<Property> properties) {
    List<Property> sorted = List.from(properties);
    sorted.sort((a, b) {
      double priceA =
          double.tryParse(a.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      double priceB =
          double.tryParse(b.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      return priceB.compareTo(priceA);
    });
    return sorted;
  }

  Widget _buildPropertyListView() {
    // Apply sorting based on dropdownValue
    List<Property> displayProperties = _visibleProperties;
    if (dropdownValue == "Price: Low to High") {
      displayProperties = _sortLowToHigh(_visibleProperties);
    } else if (dropdownValue == "Price: High to Low") {
      displayProperties = _sortHighToLow(_visibleProperties);
    } // "Top Results" uses backend order, so no sorting

    return Column(
      children: [
        if (_isListViewVisible)
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 8, 70, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color.fromRGBO(27, 94, 32, 1)),
              ),
              child: DropdownButton<String>(
                value: dropdownValue,
                dropdownColor: Colors.white,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Color.fromRGBO(27, 94, 32, 1)),
                style: const TextStyle(
                    color: Color.fromRGBO(27, 94, 32, 1), fontSize: 16),
                items:
                    filterOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                  });
                },
              ),
            ),
          ),
        Expanded(
          child: displayProperties.isEmpty
              ? const Center(child: Text("No properties available"))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: displayProperties.length,
                  itemBuilder: (context, index) {
                    final property = displayProperties[index];
                    return Dismissible(
                      key: Key(property.zpid),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _selectProperty(property, property.zpid);
                      },
                      background: Container(
                        color: Colors.white,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.reply_rounded,
                          color: Colors.green,
                          size: 50,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _showPropertyDetailsWithFetch(property);
                        },
                        child:
                            _buildPropertyCard(property, property.zpid, false),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _propertyFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: const Color.fromRGBO(27, 94, 32, 0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color.fromRGBO(27, 94, 32, 1)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color.fromRGBO(27, 94, 32, 1))),
        ],
      ),
    );
  }

  Widget _propertyFeatureChipResizable(String label, bool isFullScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: const Color.fromRGBO(27, 94, 32, 0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: isFullScreen ? 14 : 12,
                  color: const Color.fromRGBO(27, 94, 32, 1)),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildAgentInformationSection(Property property) {
    if (property.agentName == null && property.brokerageName == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Agent Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (property.agentName != null)
          _detailRow("Agent Name", property.agentName!, 16),
        if (property.agentPhoneNumber != null)
          _detailRow("Agent Phone", property.agentPhoneNumber!, 16),
        if (property.brokerageName != null)
          _detailRow("Brokerage", property.brokerageName!, 16),
        if (property.brokerPhoneNumber != null)
          _detailRow("Broker Phone", property.brokerPhoneNumber!, 16),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPropertyCard(
      Property property, String propertyId, bool isFullScreen,
      {bool isChat = false}) {
    // Use fallback values for null fields
    final displayAddress =
        property.address.isNotEmpty ? property.address : 'Address N/A';
    final displayPrice =
        property.price.isNotEmpty ? formatPrice(property.price) : '\$0';
    final displayBedrooms = property.bedrooms?.toString() ?? 'N/A';
    final displayBathrooms = property.bathrooms?.toString() ?? 'N/A';
    final displayLivingArea = property.formattedLivingArea.isNotEmpty
        ? property.formattedLivingArea
        : 'N/A';

    return Card(
      color: Colors.white,
      elevation: isFullScreen ? 0 : 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin:
          isFullScreen || isChat ? EdgeInsets.zero : const EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(isChat ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    formatPropertyType(property.propertyType) ?? 'Property',
                    style: TextStyle(
                        fontSize: isFullScreen ? 18 : (isChat ? 16 : 18),
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              displayAddress,
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: isFullScreen ? 14 : (isChat ? 12 : 14)),
            ),
            if (isFullScreen &&
                (property.city != null ||
                    property.state != null ||
                    property.zipcode != null ||
                    property.county != null))
              Text(
                "${property.city ?? ''}${property.city != null && property.state != null ? ', ' : ''}${property.state ?? ''} ${property.zipcode ?? ''}${property.county != null ? ' (${property.county})' : ''}",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            const SizedBox(height: 8),
            Text(
              displayPrice,
              style: TextStyle(
                  fontSize: isFullScreen ? 16 : (isChat ? 14 : 16),
                  color: const Color.fromRGBO(27, 94, 32, 1),
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _propertyFeatureChipResizable(
                    "$displayBedrooms Beds", isFullScreen),
                _propertyFeatureChipResizable(
                    "$displayBathrooms Baths", isFullScreen),
                _propertyFeatureChipResizable(displayLivingArea, isFullScreen),
              ],
            ),
            if (isFullScreen) ...[
              const Divider(height: 32),
              const Text("Photos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildPhotoGallery(property),
              const SizedBox(height: 16),
              const Text("Description",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDescriptionSection(property),
              const SizedBox(height: 20),
              const Text("Property Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _detailRow(
                            "Year Built", property.yearBuilt ?? 'N/A', 16),
                        _detailRow("Parking",
                            "${property.parkingSpots ?? 'N/A'} spots", 16),
                        if (property.lotSize != null)
                          _detailRow("Lot Size", property.lotSize!, 16),
                        if (property.pricePerSquareFoot != null)
                          _detailRow("Price per Sqft",
                              "\$${property.pricePerSquareFoot}", 16),
                      ])),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _detailRow("School District", "Local District", 16),
                        _detailRow(
                            "Type",
                            formatPropertyType(property.propertyType) ??
                                "Residential",
                            16),
                        if (property.fencing != null)
                          _detailRow("Fencing", property.fencing!, 16),
                        if (property.daysOnZillow != null)
                          _detailRow("Days on Market",
                              property.daysOnZillow.toString(), 16),
                      ])),
                ],
              ),
              const SizedBox(height: 20),
              _buildAgentInformationSection(property),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _fullScreenIsMapView = true),
                  icon: const Icon(Icons.map,
                      color: Color.fromRGBO(27, 94, 32, 1)),
                  label: const Text("View on Map",
                      style: TextStyle(color: Color.fromRGBO(27, 94, 32, 1))),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                          color: Color.fromRGBO(27, 94, 32, 1))),
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
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8)),
            child: Center(
                child: Icon(Icons.photo, size: 50, color: Colors.grey[700])),
          ),
      ],
    );
  }

  Widget _buildPhotoGallery(Property property) {
    if (property.imageUrls.isEmpty && property.photoURL == null) {
      return _buildPlaceholderGallery();
    }

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
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      allImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: Center(
                              child: Icon(Icons.error_outline,
                                  size: 50, color: Colors.grey[700]))),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text("${index + 1}/${allImages.length}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
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
          Text("$label: ",
              style:
                  TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize)),
          Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: fontSize),
                  overflow: TextOverflow.ellipsis)),
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
          backgroundColor: const Color.fromRGBO(27, 94, 32, 1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
    );
  }

  Widget _buildMapView(
      Property property, String propertyId, bool isFullScreen) {
    final double lat = property.latitude ?? 37.7749;
    final double lng = property.longitude ?? -122.4194;
    final LatLng propertyLocation = LatLng(lat, lng);

    Set<Marker> markers = {
      Marker(
        markerId: MarkerId(propertyId),
        position: propertyLocation,
        icon: _customMarker ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
            title: formatPropertyType(property.propertyType) ?? 'Property',
            snippet: formatPrice(property.price)),
      ),
    };

    if (isFullScreen) {
      for (var nearbyProperty in _properties) {
        if (nearbyProperty.zpid != propertyId &&
            nearbyProperty.latitude != null &&
            nearbyProperty.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId(nearbyProperty.zpid),
              position:
                  LatLng(nearbyProperty.latitude!, nearbyProperty.longitude!),
              icon: _nearbyMarker ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
              infoWindow: InfoWindow(
                  title: formatPropertyType(nearbyProperty.propertyType) ??
                      'Property',
                  snippet: formatPrice(nearbyProperty.price)),
            ),
          );
        }
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = isFullScreen ? screenHeight * 0.7 : 150.0;

    GoogleMapController? existingController =
        isFullScreen ? _fullScreenMapController : _mapControllers[propertyId];

    return Container(
      height: mapHeight,
      decoration: const BoxDecoration(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      margin: isFullScreen ? EdgeInsets.zero : EdgeInsets.zero,
      child: Stack(
        children: [
          GoogleMap(
            key: ValueKey('${propertyId}_${isFullScreen}'),
            initialCameraPosition: CameraPosition(
                target: propertyLocation, zoom: isFullScreen ? 13 : 15),
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
                if (_fullScreenMapController == null) {
                  _fullScreenMapController = controller;
                } else {
                  controller.dispose();
                }
              } else {
                if (_mapControllers[propertyId] == null) {
                  _mapControllers[propertyId] = controller;
                } else {
                  controller.dispose();
                }
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
    if (_fullScreenPropertyId == null || _fullScreenProperty == null)
      return const SizedBox.shrink();

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
                    height: _fullScreenIsMapView
                        ? screenSize.height * 0.75
                        : cardHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withOpacity(0.3 * _fadeAnimation.value),
                            blurRadius: 15,
                            spreadRadius: 5)
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16))),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _closeFullScreenProperty,
                                  iconSize: 24),
                              Text(
                                  formatPropertyType(
                                          _fullScreenProperty!.propertyType) ??
                                      'Property Details',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              if (!_fullScreenIsMapView)
                                TextButton.icon(
                                  onPressed: () => setState(
                                      () => _fullScreenIsMapView = true),
                                  icon: const Icon(Icons.map,
                                      size: 18, color: Colors.green),
                                  label: const Text("Map",
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.green)),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16)),
                            child: _fullScreenIsMapView
                                ? _buildMapView(_fullScreenProperty!,
                                    _fullScreenPropertyId!, true)
                                : SingleChildScrollView(
                                    child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: _buildPropertyCard(
                                            _fullScreenProperty!,
                                            _fullScreenPropertyId!,
                                            true))),
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
        _chatHeightAnimation =
            Tween<double>(begin: _chatHeightFraction, end: 0.4)
                .animate(_chatHeightController);
        _chatHeightFraction = 0.4;
      } else if (_currentLevel == 1) {
        _currentLevel = 2;
        _chatHeightAnimation =
            Tween<double>(begin: _chatHeightFraction, end: 0.8)
                .animate(_chatHeightController);
        _chatHeightFraction = 0.8;
      } else {
        _currentLevel = 0;
        _chatHeightAnimation =
            Tween<double>(begin: _chatHeightFraction, end: 0.165)
                .animate(_chatHeightController);
        _chatHeightFraction = 0.165;
      }
      _chatHeightController.forward(from: 0.0);
    });
  }

  void _collapseChatTo40Percent() {
    setState(() {
      _currentLevel = 1;
      _chatHeightAnimation = Tween<double>(begin: _chatHeightFraction, end: 0.4)
          .animate(_chatHeightController);
      _chatHeightFraction = 0.4;
      _chatHeightController.forward(from: 0.0);
    });
  }

  void _cycleChatHeight() {
    setState(() {
      _currentLevel = (_currentLevel + 1) % 3;
      double newHeight;
      switch (_currentLevel) {
        case 0:
          newHeight = 0.165;
          break;
        case 1:
          newHeight = 0.4;
          break;
        case 2:
          newHeight = 0.8;
          break;
        default:
          newHeight = 0.8;
      }
      _chatHeightAnimation =
          Tween<double>(begin: _chatHeightFraction, end: newHeight)
              .animate(_chatHeightController);
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
            icon: _customMarker ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
                title: formatPropertyType(property.propertyType) ?? 'Property',
                snippet: formatPrice(property.price)),
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
                  initialCameraPosition:
                      CameraPosition(target: initialPosition, zoom: 12),
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
                  onMapCreated: (GoogleMapController controller) {
                    _backgroundMapController = controller;
                    _updateVisibleProperties();
                  },
                  onCameraMove: (CameraPosition position) {
                    setState(() {
                      _mapCenter = position.target;
                      _mapZoom = position.zoom;
                    });
                  },
                  onCameraIdle: _updateVisibleProperties,
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
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, -2))
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_currentLevel == 0) {
                            _toggleChatHeight();
                          } else {
                            _cycleChatHeight();
                          }
                        },
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity! < 0 &&
                              _currentLevel < 2) {
                            setState(() {
                              _currentLevel++;
                              double newHeight = _currentLevel == 0
                                  ? 0.165
                                  : _currentLevel == 1
                                      ? 0.4
                                      : 0.8;
                              _chatHeightAnimation = Tween<double>(
                                      begin: _chatHeightFraction,
                                      end: newHeight)
                                  .animate(_chatHeightController);
                              _chatHeightFraction = newHeight;
                              _chatHeightController.forward(from: 0.0);
                            });
                          } else if (details.primaryVelocity! > 0 &&
                              _currentLevel > 0) {
                            setState(() {
                              _currentLevel--;
                              double newHeight = _currentLevel == 0
                                  ? 0.165
                                  : _currentLevel == 1
                                      ? 0.4
                                      : 0.8;
                              _chatHeightAnimation = Tween<double>(
                                      begin: _chatHeightFraction,
                                      end: newHeight)
                                  .animate(_chatHeightController);
                              _chatHeightFraction = newHeight;
                              _chatHeightController.forward(from: 0.0);
                            });
                          }
                        },
                        child: Container(
                          height: 30,
                          color: Colors.transparent,
                          child: Center(
                              child: Container(
                                  width: 45,
                                  height: 5,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius:
                                          BorderRadius.circular(10)))),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            if (_isListViewVisible)
                              _buildPropertyListView()
                            else
                              Chat(
                                messages: _messages,
                                onSendPressed: _handleSendPressed,
                                user: _user,
                                customMessageBuilder: customMessageBuilder,
                                inputOptions: const InputOptions(
                                    sendButtonVisibilityMode:
                                        SendButtonVisibilityMode.always),
                                theme: const DefaultChatTheme(
                                  backgroundColor: Colors.white,
                                  inputBackgroundColor:
                                      Color.fromARGB(255, 230, 230, 230),
                                  primaryColor: Color.fromRGBO(88, 88, 88, 1),
                                  inputBorderRadius:
                                      BorderRadius.all(Radius.circular(0)),
                                  inputTextColor: Colors.black,
                                  inputMargin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                  sendButtonIcon: Icon(Icons.send,
                                      size: 24,
                                      color: Color.fromRGBO(4, 36, 6, 1)),
                                  secondaryColor: Color.fromRGBO(52, 99, 56, 1),
                                  highlightMessageColor: Colors.white,
                                  receivedMessageBodyTextStyle: TextStyle(
                                      color: Colors.white, fontSize: 17),
                                  sentMessageBodyTextStyle: TextStyle(
                                      color: Colors.white, fontSize: 17),
                                  inputTextCursorColor:
                                      Color.fromRGBO(4, 36, 6, 1),
                                  inputPadding:
                                      EdgeInsets.fromLTRB(12, 20, 12, 25),
                                  inputContainerDecoration:
                                      BoxDecoration(color: Colors.transparent),
                                ),
                              ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _isListViewVisible
                                        ? Icons.chat_rounded
                                        : Icons.list_rounded,
                                  ),
                                  color: const Color.fromRGBO(27, 94, 32, 1),
                                  onPressed: () {
                                    setState(() {
                                      _isListViewVisible = !_isListViewVisible;
                                    });
                                  },
                                  iconSize: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                    child: CircularProgressIndicator(
                        color: Color.fromRGBO(27, 94, 32, 1)))),
          if (_errorMessage != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red)),
                child: Text(_errorMessage!,
                    style: TextStyle(color: Colors.red[900])),
              ),
            ),
          if (_selectedProperty != null)
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom + 80,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    const Text("Property Selected",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    GestureDetector(
                        onTap: () => setState(() {
                              _selectedProperty = null;
                              _selectedPropertyId = null;
                            }),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18)),
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
