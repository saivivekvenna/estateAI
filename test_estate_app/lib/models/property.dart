//object for every property so i dont have to work with arrays 24/7, god bless object orinented programming 
class Property {
  final String? photoURL;
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
  
  // // Computed property for status (up/down)
  // String get status => daysOnZillow != null && daysOnZillow < 7 ? 'up' : 'down';
  
  // Computed property for formatted living area
  String get formattedLivingArea {
    if (livingArea == null || livingArea == '--') return 'N/A';
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
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      photoURL: json['photoURL'],
      address: json['address'] ?? 'Unknown Address',
      price: json['price'] ?? '\$0',
      bedrooms: json['bedrooms'] ?? '--',
      bathrooms: json['bathrooms'] ?? '--',
      livingArea: json['livingArea'] ?? '--',
      lotAreaValue: json['lotAreaValue'],
      lotAreaUnit: json['lotAreaUnit'],
      yearBuilt: json['yearBuilt'],
      zillowLink: json['zillowLink'],
      propertyType: json['propertyType'],
      listingStatus: json['listingStatus'],
      daysOnZillow: json['daysOnZillow'],
      zpid: json['zpid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoURL': photoURL,
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
    };
  }
}

