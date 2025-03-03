import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FilterPage extends StatefulWidget {
  final List<Map<String, dynamic>> properties;
  final bool propertiesFound;
  final Function(List<Map<String, dynamic>>, bool) updateProperties;
  final Map<String, dynamic> filtersFromPrompt;
  final bool prompted;

  const FilterPage({
    super.key,
    required this.properties,
    required this.propertiesFound,
    required this.updateProperties,
    required this.filtersFromPrompt,
    required this.prompted,
  });

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late bool _prompted;

  double _minPrice = 0;
  double _maxPrice = 10000000;
  int _bedrooms = 1;
  int _bathrooms = 1;
  String _propertyType = 'Any';
  double _sqftMin = 0;
  double _sqftMax = 10000;
  int _buildYearMin = 1900;
  int _buildYearMax = 2023;
  bool _isBasementFinished = false;
  bool _isComingSoon = false;
  bool _isNewConstruction = false;
  double _lotSizeMin = 0;
  double _lotSizeMax = 1000000;
  bool _saleByAgent = true;
  bool _saleByOwner = true;
  bool _isForSaleForeclosure = false;
  bool _isWaterfront = false;
  bool _hasPool = false;
  bool _hasAirConditioning = false;
  bool _isCityView = false;
  bool _isMountainView = false;
  bool _isWaterView = false;
  bool _isParkView = false;
  bool _hasGarage = false;
  int _parkingSpots = 0;

  @override
  void initState() {
    super.initState();

    _prompted = widget.prompted;

    //is it a bug or a feature ;)
    // if (_prompted){
    //   _updateFiltersFromPrompt();
    // }else{
    //   _loadFilters();
    // }

    _updateFiltersFromPrompt();
    _loadFilters();
  }
  

  void _updateFiltersFromPrompt() {
    setState(() {
      _minPrice = widget.filtersFromPrompt['minPrice']?.toDouble() ?? _minPrice;
      _maxPrice = widget.filtersFromPrompt['maxPrice']?.toDouble() ?? _maxPrice;
      _bedrooms = widget.filtersFromPrompt['bedsMin'] ?? _bedrooms;
      _bathrooms = widget.filtersFromPrompt['bathsMin'] ?? _bathrooms;
      _propertyType = widget.filtersFromPrompt['propertyType'] ?? _propertyType;
      _sqftMin = widget.filtersFromPrompt['sqftMin']?.toDouble() ?? _sqftMin;
      _sqftMax = widget.filtersFromPrompt['sqftMax']?.toDouble() ?? _sqftMax;
      _buildYearMin = widget.filtersFromPrompt['buildYearMin'] ?? _buildYearMin;
      _buildYearMax = widget.filtersFromPrompt['buildYearMax'] ?? _buildYearMax;
      _isBasementFinished = widget.filtersFromPrompt['isBasementFinished'] ?? _isBasementFinished;
      _isComingSoon = widget.filtersFromPrompt['isComingSoon'] ?? _isComingSoon;
      _isNewConstruction = widget.filtersFromPrompt['isNewConstruction'] ?? _isNewConstruction;
      _lotSizeMin = widget.filtersFromPrompt['lotSizeMin']?.toDouble() ?? _lotSizeMin;
      _lotSizeMax = widget.filtersFromPrompt['lotSizeMax']?.toDouble() ?? _lotSizeMax;
      _saleByAgent = widget.filtersFromPrompt['saleByAgent'] ?? _saleByAgent;
      _saleByOwner = widget.filtersFromPrompt['saleByOwner'] ?? _saleByOwner;
      _isForSaleForeclosure = widget.filtersFromPrompt['isForSaleForeclosure'] ?? _isForSaleForeclosure;
      _isWaterfront = widget.filtersFromPrompt['isWaterfront'] ?? _isWaterfront;
      _hasPool = widget.filtersFromPrompt['hasPool'] ?? _hasPool;
      _hasAirConditioning = widget.filtersFromPrompt['hasAirConditioning'] ?? _hasAirConditioning;
      _isCityView = widget.filtersFromPrompt['isCityView'] ?? _isCityView;
      _isMountainView = widget.filtersFromPrompt['isMountainView'] ?? _isMountainView;
      _isWaterView = widget.filtersFromPrompt['isWaterView'] ?? _isWaterView;
      _isParkView = widget.filtersFromPrompt['isParkView'] ?? _isParkView;
      _hasGarage = widget.filtersFromPrompt['hasGarage'] ?? _hasGarage;
      _parkingSpots = widget.filtersFromPrompt['parkingSpots'] ?? _parkingSpots;
    });
  }

  _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _minPrice = prefs.getDouble('minPrice') ?? 0;
      _maxPrice = prefs.getDouble('maxPrice') ?? 10000000;
      _bedrooms = prefs.getInt('bedsMin') ?? 1;
      _bathrooms = prefs.getInt('bathsMin') ?? 1;
      _propertyType = prefs.getString('propertyType') ?? 'Any';
      _sqftMin = prefs.getDouble('sqftMin') ?? 0;
      _sqftMax = prefs.getDouble('sqftMax') ?? 10000;
      _buildYearMin = prefs.getInt('buildYearMin') ?? 1900;
      _buildYearMax = prefs.getInt('buildYearMax') ?? 2023;
      _isBasementFinished = prefs.getBool('isBasementFinished') ?? false;
      _isComingSoon = prefs.getBool('isComingSoon') ?? false;
      _isNewConstruction = prefs.getBool('isNewConstruction') ?? false;
      _lotSizeMin = prefs.getDouble('lotSizeMin') ?? 1;
      _lotSizeMax = prefs.getDouble('lotSizeMax') ?? 1;
      _saleByAgent = prefs.getBool('saleByAgent') ?? true;
      _saleByOwner = prefs.getBool('saleByOwner') ?? true;
      _isForSaleForeclosure = prefs.getBool('isForSaleForeclosure') ?? false;
      _isWaterfront = prefs.getBool('isWaterfront') ?? false;
      _hasPool = prefs.getBool('hasPool') ?? false;
      _hasAirConditioning = prefs.getBool('hasAirConditioning') ?? false;
      _isCityView = prefs.getBool('isCityView') ?? false;
      _isMountainView = prefs.getBool('isMountainView') ?? false;
      _isWaterView = prefs.getBool('isWaterView') ?? false;
      _isParkView = prefs.getBool('isParkView') ?? false;
      _hasGarage = prefs.getBool('hasGarage') ?? false;
      _parkingSpots = prefs.getInt('parkingSpots') ?? 0;
    });
  }

  _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setDouble('minPrice', _minPrice);
    prefs.setDouble('maxPrice', _maxPrice);
    prefs.setInt('bedsMin', _bedrooms);
    prefs.setInt('bathsMin', _bathrooms);
    prefs.setString('propertyType', _propertyType);
    prefs.setDouble('sqftMin', _sqftMin);
    prefs.setDouble('sqftMax', _sqftMax);
    prefs.setInt('buildYearMin', _buildYearMin);
    prefs.setInt('buildYearMax', _buildYearMax);
    prefs.setBool('isBasementFinished', _isBasementFinished);
    prefs.setBool('isComingSoon', _isComingSoon);
    prefs.setBool('isNewConstruction', _isNewConstruction);
    prefs.setDouble('lotSizeMin', _lotSizeMin);
    prefs.setDouble('lotSizeMax', _lotSizeMax);
    prefs.setBool('saleByAgent', _saleByAgent);
    prefs.setBool('saleByOwner', _saleByOwner);
    prefs.setBool('isForSaleForeclosure', _isForSaleForeclosure);
    prefs.setBool('isWaterfront', _isWaterfront);
    prefs.setBool('hasPool', _hasPool);
    prefs.setBool('hasAirConditioning', _hasAirConditioning);
    prefs.setBool('isCityView', _isCityView);
    prefs.setBool('isMountainView', _isMountainView);
    prefs.setBool('isWaterView', _isWaterView);
    prefs.setBool('isParkView', _isParkView);
    prefs.setBool('hasGarage', _hasGarage);
    prefs.setInt('parkingSpots', _parkingSpots);
  }

  Widget _buildSlider(String title, double min, double max, double start,
      double end, Function(double, double) onChanged, int divisions) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        RangeSlider(
          inactiveColor: Colors.grey,
          activeColor: Colors.black,
          values: RangeValues(start, end),
          min: min,
          max: max,
          divisions: divisions,
          labels: RangeLabels(
            start.toStringAsFixed(0),
            end.toStringAsFixed(0),
          ),
          onChanged: (RangeValues values) {
            onChanged(values.start, values.end);
            _saveFilters();
          },
        ),
      ],
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          hoverColor: Colors.grey,
          activeColor: Colors.black,
          value: value,
          onChanged: (bool? newValue) {
            setState(() {
              onChanged(newValue);
            });
            _saveFilters();
          },
        ),
        Text(title),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(217, 217, 217, 100),
        title: const Text('Filters'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _minPrice = 0;
                _maxPrice = 10000000;
                _bedrooms = 1;
                _bathrooms = 1;
                _propertyType = 'Any';
                _sqftMin = 0;
                _sqftMax = 10000;
                _buildYearMin = 1900;
                _buildYearMax = 2023;
                _isBasementFinished = false;
                _isComingSoon = false;
                _isNewConstruction = false;
                _lotSizeMin = 0;
                _lotSizeMax = 1000000;
                _saleByAgent = true;
                _saleByOwner = true;
                _isForSaleForeclosure = false;
                _isWaterfront = false;
                _hasPool = false;
                _hasAirConditioning = false;
                _isCityView = false;
                _isMountainView = false;
                _isWaterView = false;
                _isParkView = false;
                _hasGarage = false;
                _parkingSpots = 0;
              });
              _saveFilters();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSlider('Price Range', 0, 10000000, _minPrice, _maxPrice,
              (start, end) {
            setState(() {
              _minPrice = start;
              _maxPrice = end;
            });
          }, 100),
          _buildSlider('Square Feet', 0, 10000, _sqftMin, _sqftMax,
              (start, end) {
            setState(() {
              _sqftMin = start;
              _sqftMax = end;
            });
          }, 100),
          _buildSlider('Build Year', 1900, 2025, _buildYearMin.toDouble(),
              _buildYearMax.toDouble(), (start, end) {
            setState(() {
              _buildYearMin = start.toInt();
              _buildYearMax = end.toInt();
            });
          }, 120),
          _buildSlider('Lot Size', 0, 1000000, _lotSizeMin, _lotSizeMax,
              (start, end) {
            setState(() {
              _lotSizeMin = start;
              _lotSizeMax = end;
            });
          }, 100),
          const Text(
            'Bedrooms',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Slider(
            value: _bedrooms.toDouble(),
            inactiveColor: Colors.grey,
            activeColor: Colors.black,
            min: 1,
            max: 20,
            divisions: 19,
            label: _bedrooms.toString(),
            onChanged: (double value) {
              setState(() {
                _bedrooms = value.round();
              });
              _saveFilters();
            },
          ),
          const Text('Bathrooms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          Slider(
            value: _bathrooms.toDouble(),
            min: 1,
            max: 20,
            inactiveColor: Colors.grey,
            activeColor: Colors.black,
            divisions: 19,
            label: _bathrooms.toString(),
            onChanged: (double value) {
              setState(() {
                _bathrooms = value.round();
              });
              _saveFilters();
            },
          ),
          const Text('Property Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.0),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: DropdownButton<String>(
                value: _propertyType,
                isExpanded: false,
                onChanged: (String? newValue) {
                  setState(() {
                    _propertyType = newValue!;
                  });
                  _saveFilters();
                },
                items: <String>[
                  'Any',
                  'House',
                  'Apartment',
                  'Condo',
                  'Townhouse'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
            child: const Text('Parking Spots',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          Slider(
            value: _parkingSpots.toDouble(),
            min: 0,
            max: 10,
            inactiveColor: Colors.grey,
            activeColor: Colors.black,
            divisions: 10,
            label: _parkingSpots.toString(),
            onChanged: (double value) {
              setState(() {
                _parkingSpots = value.round();
              });
              _saveFilters();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCheckbox('Finished Basement', _isBasementFinished,
                    (value) => setState(() => _isBasementFinished = value!)),
              ),
              Expanded(
                child: _buildCheckbox('Coming Soon', _isComingSoon,
                    (value) => setState(() => _isComingSoon = value!)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCheckbox('New Construction', _isNewConstruction,
                    (value) => setState(() => _isNewConstruction = value!)),
              ),
              Expanded(
                child: _buildCheckbox('Sale by Agent', _saleByAgent,
                    (value) => setState(() => _saleByAgent = value!)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCheckbox('Sale by Owner', _saleByOwner,
                    (value) => setState(() => _saleByOwner = value!)),
              ),
              Expanded(
                child: _buildCheckbox('Foreclosure', _isForSaleForeclosure,
                    (value) => setState(() => _isForSaleForeclosure = value!)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCheckbox('Waterfront', _isWaterfront,
                    (value) => setState(() => _isWaterfront = value!)),
              ),
              Expanded(
                child: _buildCheckbox('Pool', _hasPool,
                    (value) => setState(() => _hasPool = value!)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCheckbox('Air Conditioning', _hasAirConditioning,
                    (value) => setState(() => _hasAirConditioning = value!)),
              ),
              Expanded(
                child: _buildCheckbox('City View', _isCityView,
                    (value) => setState(() => _isCityView = value!)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCheckbox('Mountain View', _isMountainView,
                    (value) => setState(() => _isMountainView = value!)),
              ),
              Expanded(
                child: _buildCheckbox('Water View', _isWaterView,
                    (value) => setState(() => _isWaterView = value!)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildCheckbox('Park View', _isParkView,
                    (value) => setState(() => _isParkView = value!)),
              ),
              Expanded(
                child: _buildCheckbox('Garage', _hasGarage,
                    (value) => setState(() => _hasGarage = value!)),
              ),
            ],
          ),
        ],
      ),
bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(20.0),
  child: ElevatedButton(
    onPressed: () {
      setState(() {
        _prompted = false; // Update the variable
      });
      _sendRequestToServer(); // Call the function
    },
    child: const Text(
      'Apply Filters',
      style: TextStyle(color: Colors.black, fontSize: 20),
    ),
  ),
),

    );
  }

  Future<void> _sendRequestToServer() async {
    final url = Uri.parse('http://192.168.1.91:5000/filter');
    final filters = {
      'minPrice': _minPrice,
      'maxPrice': _maxPrice,
      'bedsMin': _bedrooms,
      'bathsMin': _bathrooms,
      'propertyType': _propertyType,
      "sqftMin": _sqftMin,
      "sqftMax": _sqftMax,
      "buildYearMin": _buildYearMin,
      "buildYearMax": _buildYearMax,
      "isBasementFinished": _isBasementFinished,
      "isComingSoon": _isComingSoon,
      "isNewConstruction": _isNewConstruction,
      "lotSizeMin": _lotSizeMin,
      "lotSizeMax": _lotSizeMax,
      "saleByAgent": _saleByAgent,
      "saleByOwner": _saleByOwner,
      "isForSaleForeclosure": _isForSaleForeclosure,
      "isWaterfront": _isWaterfront,
      "hasPool": _hasPool,
      "hasAirConditioning": _hasAirConditioning,
      "isCityView": _isCityView,
      "isMountainView": _isMountainView,
      "isWaterView": _isWaterView,
      "isParkView": _isParkView,
      "hasGarage": _hasGarage,
      "parkingSpots": _parkingSpots,
    };
    final jsonString = jsonEncode(filters);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': jsonString}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        final newProperties = List<Map<String, dynamic>>.from(jsonResponse);
        widget.updateProperties(newProperties, true);
      } else {
        print('Error: ${response.statusCode}');
        widget.updateProperties([], false);
      }
    } catch (e) {
      print('Error: $e');
      widget.updateProperties([], false);
    }
  }
}

