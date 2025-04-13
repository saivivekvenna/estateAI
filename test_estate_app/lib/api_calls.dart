/*each call for diffrent endpoint for server. three endpoints right now, 
1. basic chat operation
2. swipe for location to show similar properties 
3. swipe to see more info to show images 
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class ApiCalls {
  final String baseUrl = 'http://localhost:5000'; // Adjust for your environment

  Future<Map<String, dynamic>> searchProperties(
    String query,
    String mapCoordinates, {
    String? context,
    Map<String, dynamic>? selectedProperty,
  }) async {
    try {
      Map<String, dynamic> requestBody = {
        'query': query,
        'context': context ?? '',
        'mapCoordinates': mapCoordinates,
      };
      if (selectedProperty != null) {
        requestBody['selectedProperty'] = selectedProperty;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to search properties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getPropertyImages(String propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/images'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'zpid': propertyId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get property images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getSimilarProperties(
    Map<String, dynamic> propertyData,
    String mapCoordinates,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/more-properties'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'propertyData': propertyData,
          'mapCoordinates': mapCoordinates,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get similar properties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
