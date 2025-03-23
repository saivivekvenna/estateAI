/*each call for diffrent endpoint for server. three endpoints right now, 
1. basic chat operation
2. swipe for location to show similar properties 
3. swipe to see more info to show images 
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class ApiCalls {
  // Base URL for your backend server
  final String baseUrl = 'http://localhost:5000'; // Use this for Android emulator
  // Use 'http://localhost:5000' for iOS simulator or web
  // Use your actual server IP address for physical devices

  // Search endpoint - converts natural language to property results
  Future<Map<String, dynamic>> searchProperties(String query, {String? context}) async {
  try {
    print('Sending query with context: $context');
    
    final response = await http.post(
      Uri.parse('$baseUrl/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'context': context ?? '', // Ensure we always send a context(chat history), even if empty
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error response: ${response.body}');
      throw Exception('Failed to search properties: ${response.statusCode}');
    }
  } catch (e) {
    print('Error searching properties: $e');
    throw Exception('Network error: $e');
  }
}

  // Images endpoint - retrieves property images (left swipe)
  Future<Map<String, dynamic>> getPropertyImages(String propertyId) async {
  try {
    print('Requesting images for property ID: $propertyId');
    
    final response = await http.post(
      Uri.parse('$baseUrl/images'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'zpid': propertyId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Log the response for debugging
      print('Images API response: ${response.body.substring(0, min(100, response.body.length))}...');
      print('Number of images received: ${data['images']?.length ?? 0}');
      
      return data;
    } else {
      print('Failed to get property images. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to get property images: ${response.statusCode}');
    }
  } catch (e) {
    print('Error getting property images: $e');
    throw Exception('Network error: $e');
  }
}

  // More properties endpoint - finds similar properties (right swipe)
  Future<Map<String, dynamic>> getSimilarProperties(Map<String, dynamic> propertyData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/more-properties'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'propertyData': propertyData,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get similar properties: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting similar properties: $e');
      throw Exception('Network error: $e');
    }
  }
}

