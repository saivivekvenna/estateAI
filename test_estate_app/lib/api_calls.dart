/* API calls for different server endpoints:
1. search: Basic chat operation for property search
2. details: Fetch detailed property information
3. images: Fetch property images on swipe
*/

import 'dart:convert';
import 'package:http/http.dart' as http;

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

  Future<Map<String, dynamic>> getPropertyDetails(String propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/details'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'zpid': propertyId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get property details: ${response.statusCode}');
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
}