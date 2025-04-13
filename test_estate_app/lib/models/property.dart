class Property {
  final String? photoURL;
  final List<String> imageUrls;
  final String address;
  final String price;
  final dynamic bedrooms;
  final dynamic bathrooms;
  final dynamic livingArea;
  final dynamic lotAreaValue;
  final String? lotAreaUnit;
  final String? yearBuilt;
  final String? zillowLink;
  final String propertyType;
  final String? listingStatus;
  final dynamic daysOnZillow;
  final String zpid;
  final double? latitude;
  final double? longitude;
  final bool? hasPool;
  final bool? hasAirConditioning;
  final bool? hasGarage;
  final dynamic parkingSpots;
  final bool? isCityView;
  final bool? isMountainView;
  final bool? isWaterView;
  final bool? isParkView;
  final bool? is3dHome;
  final bool? isForeclosed;
  final bool? isPreForeclosure;
  final String? description;
  final String? county;
  final String? city;
  final String? state;
  final String? zipcode;
  final String? timeOnZillow;
  final int? pageViewCount;
  final int? favoriteCount;
  final String? virtualTour;
  final String? brokerageName;
  final String? agentName;
  final String? agentPhoneNumber;
  final String? brokerPhoneNumber;
  final dynamic stories;
  final String? levels;
  final bool? hasFireplace;
  final int? fireplaces;
  final bool? basementYN;
  final String? basement;
  final String? roofType;
  final dynamic coolingSystem;
  final dynamic heatingSystem;
  final String? lotSize;
  final String? fencing;
  final int? bathroomsFull;
  final int? bathroomsHalf;
  final String? aboveGradeFinishedArea;
  final String? belowGradeFinishedArea;
  final dynamic parkingFeatures;
  final int? parkingCapacity;
  final int? garageParkingCapacity;
  final dynamic appliances;
  final dynamic interiorFeatures;
  final dynamic exteriorFeatures;
  final dynamic constructionMaterials;
  final dynamic patioAndPorchFeatures;
  final dynamic laundryFeatures;
  final int? pricePerSquareFoot;
  final int? photoCount;

  String get formattedLivingArea {
    if (livingArea == null || livingArea == '--') return '-- sqft';
    return '$livingArea sqft';
  }

  Property({
    this.photoURL,
    required this.address,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.livingArea,
    this.lotAreaValue,
    this.lotAreaUnit,
    this.yearBuilt,
    this.zillowLink,
    required this.propertyType,
    this.listingStatus,
    this.daysOnZillow,
    required this.zpid,
    this.latitude,
    this.longitude,
    this.hasPool,
    this.hasAirConditioning,
    this.hasGarage,
    this.parkingSpots,
    this.isCityView,
    this.isMountainView,
    this.isWaterView,
    this.isParkView,
    this.is3dHome,
    this.isForeclosed,
    this.isPreForeclosure,
    this.imageUrls = const [],
    this.description,
    this.county,
    this.city,
    this.state,
    this.zipcode,
    this.timeOnZillow,
    this.pageViewCount,
    this.favoriteCount,
    this.virtualTour,
    this.brokerageName,
    this.agentName,
    this.agentPhoneNumber,
    this.brokerPhoneNumber,
    this.stories,
    this.levels,
    this.hasFireplace,
    this.fireplaces,
    this.basementYN,
    this.basement,
    this.roofType,
    this.coolingSystem,
    this.heatingSystem,
    this.lotSize,
    this.fencing,
    this.bathroomsFull,
    this.bathroomsHalf,
    this.aboveGradeFinishedArea,
    this.belowGradeFinishedArea,
    this.parkingFeatures,
    this.parkingCapacity,
    this.garageParkingCapacity,
    this.appliances,
    this.interiorFeatures,
    this.exteriorFeatures,
    this.constructionMaterials,
    this.patioAndPorchFeatures,
    this.laundryFeatures,
    this.pricePerSquareFoot,
    this.photoCount,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Handle imageUrls if present in the JSON
    List<String> imageUrls = [];
    if (json['imageUrls'] != null) {
      imageUrls = List<String>.from(json['imageUrls']);
    }

    // Parse latitude and longitude carefully
    double? lat;
    double? lng;
    if (json['latitude'] != null) {
      if (json['latitude'] is double) {
        lat = json['latitude'];
      } else {
        try {
          lat = double.parse(json['latitude'].toString());
        } catch (_) {}
      }
    }
    if (json['longitude'] != null) {
      if (json['longitude'] is double) {
        lng = json['longitude'];
      } else {
        try {
          lng = double.parse(json['longitude'].toString());
        } catch (_) {}
      }
    }

    // Helper to convert dynamic to String?, handling List<dynamic>
    String? toStringValue(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        if (value.isEmpty) return null;
        return value.first.toString(); // Convert first item in list to string
      }
      return value.toString();
    }

    return Property(
      photoURL: toStringValue(json['photoURL']),
      address: toStringValue(json['address']) ?? 'Unknown Address',
      price: toStringValue(json['price']) ?? '\$0',
      bedrooms: json['bedrooms'] ?? '--',
      bathrooms: json['bathrooms'] ?? '--',
      livingArea: json['livingArea'] ?? '--',
      lotAreaValue: json['lotAreaValue'],
      lotAreaUnit: toStringValue(json['lotAreaUnit']),
      yearBuilt: toStringValue(json['yearBuilt']),
      zillowLink: toStringValue(json['zillowLink']),
      propertyType: toStringValue(json['propertyType']) ?? 'Property',
      listingStatus: toStringValue(json['listingStatus']),
      daysOnZillow: json['daysOnZillow'],
      zpid: toStringValue(json['zpid']) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: lat,
      longitude: lng,
      hasPool: json['hasPool'],
      hasAirConditioning: json['hasAirConditioning'],
      hasGarage: json['hasGarage'],
      parkingSpots: json['parkingSpots'],
      isCityView: json['isCityView'],
      isMountainView: json['isMountainView'],
      isWaterView: json['isWaterView'],
      isParkView: json['isParkView'],
      is3dHome: json['is3dHome'],
      isForeclosed: json['isForeclosed'],
      isPreForeclosure: json['isPreForeclosure'],
      imageUrls: imageUrls,
      description: toStringValue(json['description']),
      county: toStringValue(json['county']),
      city: toStringValue(json['city']),
      state: toStringValue(json['state']),
      zipcode: toStringValue(json['zipcode']),
      timeOnZillow: toStringValue(json['timeOnZillow']),
      pageViewCount: json['pageViewCount'] is int ? json['pageViewCount'] : (json['pageViewCount'] != null ? int.tryParse(json['pageViewCount'].toString()) : null),
      favoriteCount: json['favoriteCount'] is int ? json['favoriteCount'] : (json['favoriteCount'] != null ? int.tryParse(json['favoriteCount'].toString()) : null),
      virtualTour: toStringValue(json['virtualTour']),
      brokerageName: toStringValue(json['brokerageName']),
      agentName: toStringValue(json['agentName']),
      agentPhoneNumber: toStringValue(json['agentPhoneNumber']),
      brokerPhoneNumber: toStringValue(json['brokerPhoneNumber']),
      stories: json['stories'],
      levels: toStringValue(json['levels']),
      hasFireplace: json['hasFireplace'],
      fireplaces: json['fireplaces'] is int ? json['fireplaces'] : (json['fireplaces'] != null ? int.tryParse(json['fireplaces'].toString()) : null),
      basementYN: json['basementYN'],
      basement: toStringValue(json['basement']),
      roofType: toStringValue(json['roofType']),
      coolingSystem: json['coolingSystem'], // Fixed: use JSON value directly
      heatingSystem: json['heatingSystem'], // Fixed: use JSON value directly
      lotSize: toStringValue(json['lotSize']),
      fencing: toStringValue(json['fencing']),
      bathroomsFull: json['bathroomsFull'] is int ? json['bathroomsFull'] : (json['bathroomsFull'] != null ? int.tryParse(json['bathroomsFull'].toString()) : null),
      bathroomsHalf: json['bathroomsHalf'] is int ? json['bathroomsHalf'] : (json['bathroomsHalf'] != null ? int.tryParse(json['bathroomsHalf'].toString()) : null),
      aboveGradeFinishedArea: toStringValue(json['aboveGradeFinishedArea']),
      belowGradeFinishedArea: toStringValue(json['belowGradeFinishedArea']),
      parkingFeatures: json['parkingFeatures'], // Dynamic to handle List<dynamic>
      parkingCapacity: json['parkingCapacity'] is int ? json['parkingCapacity'] : (json['parkingCapacity'] != null ? int.tryParse(json['parkingCapacity'].toString()) : null),
      garageParkingCapacity: json['garageParkingCapacity'] is int ? json['garageParkingCapacity'] : (json['garageParkingCapacity'] != null ? int.tryParse(json['garageParkingCapacity'].toString()) : null),
      appliances: json['appliances'], // Dynamic to handle List<dynamic>
      interiorFeatures: json['interiorFeatures'], // Dynamic to handle List<dynamic>
      exteriorFeatures: json['exteriorFeatures'], // Dynamic to handle Map or List
      constructionMaterials: json['constructionMaterials'], // Dynamic to handle List<dynamic>
      patioAndPorchFeatures: json['patioAndPorchFeatures'], // Dynamic to handle List<dynamic>
      laundryFeatures: json['laundryFeatures'], // Dynamic to handle List<dynamic>
      pricePerSquareFoot: json['pricePerSquareFoot'] is int ? json['pricePerSquareFoot'] : (json['pricePerSquareFoot'] != null ? int.tryParse(json['pricePerSquareFoot'].toString()) : null),
      photoCount: json['photoCount'] is int ? json['photoCount'] : (json['photoCount'] != null ? int.tryParse(json['photoCount'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoURL': photoURL,
      'imageUrls': imageUrls,
      'address': address,
      'price': price,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'livingArea': livingArea,
      'lotAreaValue': lotAreaValue,
      'lotAreaUnit': lotAreaUnit,
      'yearBuilt': yearBuilt,
      'zillowLink': zillowLink,
      'propertyType': propertyType,
      'listingStatus': listingStatus,
      'daysOnZillow': daysOnZillow,
      'zpid': zpid,
      'latitude': latitude,
      'longitude': longitude,
       'hasPool': hasPool,
      'hasAirConditioning': hasAirConditioning,
      'hasGarage': hasGarage,
      'parkingSpots': parkingSpots,
      'isCityView': isCityView,
      'isMountainView': isMountainView,
      'isWaterView': isWaterView,
      'isParkView': isParkView,
      'is3dHome': is3dHome,
      'isForeclosed': isForeclosed,
      'isPreForeclosure': isPreForeclosure,
      'description': description,
      'county': county,
      'city': city,
      'state': state,
      'zipcode': zipcode,
      'timeOnZillow': timeOnZillow,
      'pageViewCount': pageViewCount,
      'favoriteCount': favoriteCount,
      'virtualTour': virtualTour,
      'brokerageName': brokerageName,
      'agentName': agentName,
      'agentPhoneNumber': agentPhoneNumber,
      'brokerPhoneNumber': brokerPhoneNumber,
      'stories': stories,
      'levels': levels,
      'hasFireplace': hasFireplace,
      'fireplaces': fireplaces,
      'basementYN': basementYN,
      'basement': basement,
      'roofType': roofType,
      'coolingSystem': coolingSystem,
      'heatingSystem': heatingSystem,
      'lotSize': lotSize,
      'fencing': fencing,
      'bathroomsFull': bathroomsFull,
      'bathroomsHalf': bathroomsHalf,
      'aboveGradeFinishedArea': aboveGradeFinishedArea,
      'belowGradeFinishedArea': belowGradeFinishedArea,
      'parkingFeatures': parkingFeatures,
      'parkingCapacity': parkingCapacity,
      'garageParkingCapacity': garageParkingCapacity,
      'appliances': appliances,
      'interiorFeatures': interiorFeatures,
      'exteriorFeatures': exteriorFeatures,
      'constructionMaterials': constructionMaterials,
      'patioAndPorchFeatures': patioAndPorchFeatures,
      'laundryFeatures': laundryFeatures,
      'pricePerSquareFoot': pricePerSquareFoot,
      'photoCount': photoCount,
    };
  }
}
