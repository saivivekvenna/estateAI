import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:soft_edge_blur/soft_edge_blur.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'api_calls.dart';
import 'models/property.dart';

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

  // API service
  final ApiCalls _apiCalls = ApiCalls();

  // Properties
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Selected property for discussion
  Property? _selectedProperty;
  String? _selectedPropertyId;

  // Full screen property view
  String? _fullScreenPropertyId;
  Property? _fullScreenProperty;
  bool _fullScreenIsMapView = false;

  // Google Maps controllers
  Map<String, GoogleMapController?> _mapControllers = {};
  GoogleMapController? _fullScreenMapController;
  bool _isMapInteractive = false;

  // Markers
  BitmapDescriptor? _customMarker;
  BitmapDescriptor? _nearbyMarker;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Animation for property selection
  late AnimationController _selectionAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initMarkers();

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

    // Setup selection animation
    _selectionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _selectionAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _selectionAnimationController.repeat(reverse: true);

    // Add a keyboard listener for better positioning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This ensures we rebuild when the keyboard appears/disappears
      final keyboardVisibilityController = KeyboardVisibilityController();
      keyboardVisibilityController.onChange.listen((bool visible) {
        if (mounted) setState(() {});
      });
    });

    // Add a welcome message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_messages.isEmpty) {
        _addBotTextMessage(
            "Hello! I'm you. How can I help you find your dream home today?");
      }
    });
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

  String formatPropertyType(String propertyType) {
    const propertyTypeMap = {
      'SingleFamily': 'Single Family',
      'SINGLE_FAMILY': 'Single Family',
      'TOWNHOUSE': 'Townhouse',
      'CONDO': 'Condo',
      'MULTIFAMILY': 'Multi Family',
      'APARTMENT': 'Apartment',
    };

    return propertyTypeMap[propertyType] ??
        propertyType; // Return the original if no mapping is found
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
          ..style = PaintingStyle.fill);

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4,
        paint..style = PaintingStyle.fill);

    final img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // Add a bot text message
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

  // Select a property for discussion
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

    print(
        "Selected Property JSON:\n${jsonEncode(_selectedProperty?.toJson())}");
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

  // Handle sending messages to the server
  void _handleSendPressed(types.PartialText message) async {
    // Add user message to chat
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().toString(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
      _errorMessage = null;
    });

    try {
      // print("TESTTESTTEST DSL;KFJDASFL;JK");
      // print(_selectedProperty?.hasFireplace);

// Build the context based on what's available
      String conversationHistory = "";
      Map<String, dynamic>? selectedPropertyData;

// If there's a selected property, prioritize sending its data
      if (_selectedProperty != null) {
        selectedPropertyData = _selectedProperty!.toJson();

        // Add a special header to indicate that this is a selected property query
        conversationHistory += "SELECTED_PROPERTY_QUERY: true\n\n";

        // Add the selected property details as structured data
        conversationHistory += "SELECTED_PROPERTY:\n";
        conversationHistory += "Address: ${_selectedProperty!.address}\n";
        conversationHistory += "Price: ${_selectedProperty!.price}\n";
        conversationHistory += "Bedrooms: ${_selectedProperty!.bedrooms}\n";
        conversationHistory += "Bathrooms: ${_selectedProperty!.bathrooms}\n";
        conversationHistory +=
            "Living Area: ${_selectedProperty!.formattedLivingArea}\n";
        conversationHistory +=
            "Property Type: ${_selectedProperty!.propertyType}\n";
        conversationHistory += "ZPID: ${_selectedProperty!.zpid}\n";

        // Additional basic fields
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

        // Boolean features
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

        // Detailed fields
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

        // Agent info
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

        // Property features
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

        // Land details
        if (_selectedProperty!.lotSize != null) {
          conversationHistory += "Lot Size: ${_selectedProperty!.lotSize}\n";
        }
        if (_selectedProperty!.fencing != null) {
          conversationHistory += "Fencing: ${_selectedProperty!.fencing}\n";
        }

        // Interior details
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

        // Parking details
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

        // Additional features
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

        // Metrics/Media
        if (_selectedProperty!.pricePerSquareFoot != null) {
          conversationHistory +=
              "Price per Sqft: ${_selectedProperty!.pricePerSquareFoot}\n";
        }
        if (_selectedProperty!.photoCount != null) {
          conversationHistory +=
              "Photo Count: ${_selectedProperty!.photoCount}\n";
        }

        conversationHistory += "\n";
      }
// If no property is selected, include all available properties for context
      else if (_properties.isNotEmpty) {
        conversationHistory += "AVAILABLE_PROPERTIES:\n";
        for (int i = 0; i < _properties.length; i++) {
          final property = _properties[i];
          conversationHistory +=
              "Property ${i + 1}: ${property.address}, ${property.price}, ${property.bedrooms} beds, ${property.bathrooms} baths, ${property.formattedLivingArea}";

          // Add additional property details that might be useful for answering questions
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
      } // Get all messages in chronological order (oldest first)
      final messagesInOrder = _messages.reversed.toList();

      // Add conversation history
      for (var msg in messagesInOrder) {
        if (msg is types.TextMessage) {
          final speaker = msg.author.id == _user.id ? "User" : "Agent";
          conversationHistory += "$speaker: ${msg.text}\n";
        }
      }

      try {
        // Call search API with full conversation history and selected property data
        final response = await _apiCalls.searchProperties(
          message.text,
          context: conversationHistory,
          selectedProperty: selectedPropertyData,
        );

        if (response == null) {
          throw Exception("API response is null");
        }

        // Extract agent response and properties
        final agentResponse = response['agentResponse'] as String?;
        if (agentResponse == null) {
          throw Exception("Agent response missing in API response");
        }

        final propertyResults = response['results'] as List<dynamic>?;

        // Clear the selected property if the user asked for new properties
        if (propertyResults != null && propertyResults.isNotEmpty) {
          setState(() {
            _selectedProperty = null;
            _selectedPropertyId = null;

            // Convert to Property objects
            _properties =
                propertyResults.map((json) => Property.fromJson(json)).toList();
          });

          // Add combined response (properties + agent text)
          _addCombinedResponse(_properties, agentResponse);
        } else {
          // Just add the text response if no properties were returned
          _addBotTextMessage(agentResponse);
        }
      } catch (apiError) {
        // Handle API-specific errors
        print('Error with API request: $apiError');
        setState(() {
          _errorMessage =
              'Failed to fetch property details from the API. Please try again later.';
        });
        _addBotTextMessage(
            'Sorry, I encountered an error while processing your request. Please try again.');
        return; // Return early if there's an API issue
      }
    } catch (e) {
      // Catch general errors that are not related to API
      print('Error handling message: $e');
      setState(() {
        _errorMessage = 'Failed to handle message. Please try again.';
      });
      _addBotTextMessage(
          'Sorry, I encountered an error while processing your message. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add properties response to chat
  void _addPropertiesResponse(List<Property> properties) {
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
        'type': 'response',
        'properties': properties.map((p) => p.toJson()).toList(),
      },
    );

    setState(() {
      _messages.insert(0, customMessage);
    });
  }

  // Show full screen property view
  void _showFullScreenProperty(
      Property property, String propertyId, bool isMapView) {
    setState(() {
      _fullScreenPropertyId = propertyId;
      _fullScreenProperty = property;
      _fullScreenIsMapView = isMapView;
      _isMapInteractive = false;
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

  void _handleLeftSwipe(Property property) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Call images API and await the response
      final response = await _apiCalls.getPropertyImages(property.zpid);

      // Create a new property with the updated image URLs
      Property updatedProperty = property;

      // Extract image URLs from response
      if (response != null && response['images'] != null) {
        final List<dynamic> imageData = response['images'] as List<dynamic>;

        // Check the structure of the image data
        if (imageData.isNotEmpty) {
          List<String> imageUrls = [];

          // Try to extract URLs based on the response structure
          for (var img in imageData) {
            if (img is Map<String, dynamic> && img.containsKey('url')) {
              imageUrls.add(img['url'] as String);
            } else if (img is String) {
              imageUrls.add(img);
            }
          }

          if (imageUrls.isNotEmpty) {
            // Create a new property with the updated image URLs
            Map<String, dynamic> propertyJson = property.toJson();
            propertyJson['imageUrls'] = imageUrls;
            updatedProperty = Property.fromJson(propertyJson);
          }
        }
      }

      // Show property details with images
      _showFullScreenProperty(updatedProperty, updatedProperty.zpid, false);
    } catch (e) {
      print('Error getting property images: $e');
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load property images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle right swipe - get similar properties
  void _handleRightSwipe(Property property) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Call more properties API
      // final response = await _apiCalls.getSimilarProperties(property.toJson());

      // // Extract properties
      // final propertyResults = response['results'] as List<dynamic>;

      // // Convert to Property objects
      // final similarProperties =
      //     propertyResults.map((json) => Property.fromJson(json)).toList();

      // Show map view with similar properties
      _showFullScreenProperty(property, property.zpid, true);

      // Add similar properties to state
      setState(() {
        //_properties = [..._properties, ...similarProperties];
      });
    } catch (e) {
      print('Error getting similar properties: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _mapControllers.values) {
      controller?.dispose();
    }
    _fullScreenMapController?.dispose();
    _animationController.dispose();
    _selectionAnimationController.dispose();
    super.dispose();
  }

  Widget customMessageBuilder(types.CustomMessage message,
      {required int messageWidth}) {
    if (message.metadata?['type'] == 'response' ||
        message.metadata?['type'] == 'combined_response') {
      List<dynamic> propertiesJson = message.metadata?['properties'] ?? [];
      List<Property> properties = propertiesJson
          .map((json) => json is Property ? json : Property.fromJson(json))
          .toList();
      String? agentResponse;
      if (message.metadata != null &&
          message.metadata!['type'] == 'combined_response' &&
          message.metadata!.containsKey('agentResponse')) {
        agentResponse = message.metadata!['agentResponse'] as String?;
      } else {
        agentResponse = null;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Properties section
          for (var property in properties)
            Builder(builder: (context) {
              final propertyId = property.zpid;
              final isSelected = _selectedPropertyId == propertyId;

              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: GestureDetector(
                  onDoubleTap: () {
                    _selectProperty(property, propertyId);
                  },
                  child: Dismissible(
                    key: Key(propertyId),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) {
                      // This won't be called because confirmDismiss returns false
                    },
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Right swipe - show map and similar properties
                        _handleRightSwipe(property);
                      } else {
                        // Left swipe - show details and images
                        _handleLeftSwipe(property);
                      }
                      return false; // Prevents card from disappearing
                    },
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      color: Colors.transparent,
                      child: const Icon(Icons.map,
                          color: Colors.white70, size: 50),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.transparent,
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.white70,
                        size: 50,
                      ),
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
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade600,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                  ),
                ),
              );
            }),

          // Agent response text (only for combined type)
          if (agentResponse != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(8),
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

  // Build property card
  Widget _buildPropertyCard(
      Property property, String propertyId, bool isFullScreen) {
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
                    style: TextStyle(
                        fontSize: isFullScreen ? 24 : 18,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.only(left: 4),
                //   child: Icon(
                //     property.status == 'up'
                //         ? Icons.arrow_upward
                //         : Icons.arrow_downward,
                //     color: property.status == 'up' ? Colors.green : Colors.red,
                //     size: isFullScreen ? 28 : 24,
                //   ),
                // ),
              ],
            ),

            Text(
              property.address,
              style: TextStyle(
                color: Colors.grey,
                fontSize: isFullScreen ? 16 : 14,
              ),
            ),

            SizedBox(height: isFullScreen ? 16 : 8),

            Text(
              property.price,
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
                          "${property.bedrooms} Beds",
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
                          "${property.bathrooms} Baths",
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
                          property.formattedLivingArea,
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

              // Image gallery
              Text(
                "Photos",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildPhotoGallery(property),

              // // Image gallery
              // Text(
              //   "Photos",
              //   style: const TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 12),

              // SizedBox(
              //   height: 200,
              //   child: property.photoURL != null
              //       ? Image.network(
              //           property.photoURL!,
              //           fit: BoxFit.cover,
              //           errorBuilder: (context, error, stackTrace) {
              //             return _buildPlaceholderGallery();
              //           },
              //         )
              //       : _buildPlaceholderGallery(),
              // ),

              // const SizedBox(height: 24),

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
                "Beautiful property located in a prime area with easy access to amenities.",
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
                        _detailRow(
                            "Year Built", property.yearBuilt ?? 'N/A', 16),
                        _detailRow("Parking",
                            "${property.parkingSpots ?? 'N/A'} spots", 16),
                      ],
                    ),
                  ),
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
                      child:
                          _actionButton(Icons.calendar_today, "Schedule Tour"),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _actionButton(Icons.phone, "Message Agent"),
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
                  icon: Icon(Icons.map, color: Color.fromRGBO(27, 94, 32, 1)),
                  label: Text("View on Map",
                      style: TextStyle(color: Color.fromRGBO(27, 94, 32, 1))),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Color.fromRGBO(27, 94, 32, 1)),
                  ),
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
    );
  }

  Widget _buildPhotoGallery(Property property) {
    // If no images are available, show placeholders
    if (property.imageUrls.isEmpty && property.photoURL == null) {
      return _buildPlaceholderGallery();
    }

    // Combine main photo and additional images
    List<String> allImages = [];
    if (property.photoURL != null) {
      allImages.add(property.photoURL!);
    }
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
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      allImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      },
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
                              color: Color.fromRGBO(27, 94, 32, 1),
                            ),
                          ),
                        );
                      },
                    ),
                    // Image counter indicator
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${index + 1}/${allImages.length}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 20,
        ),
        // Image pagination indicators
        // if (allImages.length > 1)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 8.0),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: List.generate(
        //         allImages.length,
        //         (index) => Container(
        //           width: 8,
        //           height: 8,
        //           margin: EdgeInsets.symmetric(horizontal: 4),
        //           decoration: BoxDecoration(
        //             shape: BoxShape.circle,
        //             color: index == 0
        //                 ? Color.fromRGBO(27, 94, 32, 1)
        //                 : Colors.grey[400],
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
      ],
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
        backgroundColor: Color.fromRGBO(27, 94, 32, 1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // Build map view
  Widget _buildMapView(
      Property property, String propertyId, bool isFullScreen) {
    final double lat = property.latitude ?? 37.7749;
    final double lng = property.longitude ?? -122.4194;
    final LatLng propertyLocation = LatLng(lat, lng);

    Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: MarkerId(propertyId),
        position: propertyLocation,
        icon: _customMarker ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: formatPropertyType(property.propertyType) ?? 'Property',
          snippet: property.price,
        ),
      ),
    );

    // Add nearby properties markers if in full screen and interactive mode
    if (isFullScreen && _isMapInteractive) {
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
                snippet: nearbyProperty.price,
              ),
            ),
          );
        }
      }
    }

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
                ],
              ),

            SizedBox(
                height: (!isFullScreen || !_isMapInteractive)
                    ? (isFullScreen ? 16 : 12)
                    : 0),

            // Google Maps widget
            Container(
              height: isFullScreen ? (_isMapInteractive ? 570 : 250) : 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
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
                    onTap: isFullScreen
                        ? (_) {
                            _toggleMapInteractiveMode();
                          }
                        : null,
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

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var amenity in [
                    'Shopping Center',
                    'Park',
                    'School',
                    'Restaurant'
                  ])
                    Chip(
                      label: Text(amenity),
                      backgroundColor:
                          Color.fromRGBO(27, 94, 32, 1).withOpacity(0.1),
                      side: BorderSide(
                          color:
                              Color.fromRGBO(27, 94, 32, 1).withOpacity(0.3)),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Call to action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _actionButton(
                      Icons.directions,
                      "Get Directions",
                    ),
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
                  icon: Icon(Icons.home, color: Color.fromRGBO(27, 94, 32, 1)),
                  label: Text(
                    "View Property Details",
                    style: TextStyle(color: Color.fromRGBO(27, 94, 32, 1)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side:
                        BorderSide(color: const Color.fromRGBO(27, 94, 32, 1)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build full screen overlay
  Widget _buildFullScreenOverlay() {
    if (_fullScreenPropertyId == null || _fullScreenProperty == null) {
      return const SizedBox.shrink();
    }

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
                    height: _fullScreenIsMapView && _isMapInteractive
                        ? screenSize.height * 0.85
                        : cardHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.3 * _fadeAnimation.value),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                  formatPropertyType(
                                          _fullScreenProperty!.propertyType) ??
                                      'Property Details',
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
                                      _fullScreenIsMapView =
                                          !_fullScreenIsMapView;
                                      _isMapInteractive = false;
                                    });
                                  },
                                  icon: Icon(
                                    _fullScreenIsMapView
                                        ? Icons.home
                                        : Icons.map,
                                    size: 18,
                                    color: Colors.green[900],
                                  ),
                                  label: Text(
                                    _fullScreenIsMapView ? "Details" : "Map",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.green[900]),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Content
                        Expanded(
                          child: GestureDetector(
                            onHorizontalDragEnd: (details) {
                              if (!_isMapInteractive) {
                                if (details.primaryVelocity! > 0) {
                                  setState(() {
                                    _fullScreenIsMapView = true;
                                  });
                                } else if (details.primaryVelocity! < 0) {
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
                                  ? _buildMapView(_fullScreenProperty!,
                                      _fullScreenPropertyId!, true)
                                  : SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: _fullScreenIsMapView
                                            ? _buildMapView(
                                                _fullScreenProperty!,
                                                _fullScreenPropertyId!,
                                                true)
                                            : _buildPropertyCard(
                                                _fullScreenProperty!,
                                                _fullScreenPropertyId!,
                                                true),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                    // History button action
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

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color.fromRGBO(27, 94, 32, 1),
                ),
              ),
            ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[900]),
                ),
              ),
            ),

          // Selected property hint - positioned above input box
          if (_selectedProperty != null)
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  80, // Position dynamically based on keyboard height
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      )
                    ]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "Property Selected",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProperty = null;
                          _selectedPropertyId = null;
                        });
                      },
                      child: Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),

          // Full screen overlay
          if (_fullScreenPropertyId != null) _buildFullScreenOverlay(),
        ],
      ),
    );
  }
}
