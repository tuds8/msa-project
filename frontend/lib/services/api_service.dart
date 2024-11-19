import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000";
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: "accessToken", value: accessToken);
    await _secureStorage.write(key: "refreshToken", value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: "accessToken");
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: "refreshToken");
  }

  static Future<void> deleteTokens() async {
    await _secureStorage.delete(key: "accessToken");
    await _secureStorage.delete(key: "refreshToken");
  }

  static Future<void> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      final url = Uri.parse('$baseUrl/token/refresh/');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access'] != null) {
          await saveTokens(data['access'], refreshToken);
        }
      } else {
        throw Exception("Failed to refresh access token");
      }
    }
  }

  // defined the requests

  // POST without authorization header used for login & register
  static Future<http.Response> postRequest(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint/');
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
  }

  // GET with authorization header (jwt access token)
  static Future<http.Response> authenticatedGetRequest(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint/');
    String? accessToken = await getAccessToken();

    var response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        if (accessToken != null) "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 401) {
      // Token expired, try refreshing it
      await refreshAccessToken();
      accessToken = await getAccessToken();

      response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null) "Authorization": "Bearer $accessToken",
        },
      );
    }

    return response;
  }

  // POST with authorization header (jwt access token)
  static Future<http.Response> authenticatedPostRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint/');
    String? accessToken = await getAccessToken();

    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        if (accessToken != null) "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 401) {
      await refreshAccessToken();
      accessToken = await getAccessToken();

      response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null) "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(data),
      );
    }

    return response;
  }

  // PATCH with authorization header (jwt access token)
  static Future<http.Response> authenticatedPatchRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/$endpoint/');
    String? accessToken = await getAccessToken();

    var response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        if (accessToken != null) "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 401) {
      await refreshAccessToken();
      accessToken = await getAccessToken();

      response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null) "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(data),
      );
    }

    return response;
  }

  // DELETE with authorization header (jwt access token)
  static Future<http.Response> authenticatedDeleteRequest(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint/');
    String? accessToken = await getAccessToken();

    var response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        if (accessToken != null) "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 401) {
      await refreshAccessToken();
      accessToken = await getAccessToken();

      response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null) "Authorization": "Bearer $accessToken",
        },
      );
    }

    return response;
  }

}
