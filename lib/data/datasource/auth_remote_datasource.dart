import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/constants/variables.dart';
import 'package:fms/data/models/response/auth_response_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(Variables.loginEndpoint);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'email': email, 'password': password}),
    );
    log(response.body, name: 'AuthRemoteDataSource', level: 800);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final model = AuthResponseModel.fromJson(response.body);
      if (model.success == true && model.data?.apiKey != null) {
        return model;
      } else {
        throw Exception('Login gagal: respons tidak valid');
      }
    } else {
      String message = 'Login gagal (${response.statusCode})';
      log(response.body, name: 'AuthRemoteDataSource', level: 1200);
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['message'] != null) message = decoded['message'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  //logout and remove api key from shared preferences
  Future<void> logout() async {
    final uri = Uri.parse(Variables.logoutEndpoint);
    final response = await http.post(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(Variables.prefApiKey);
      log(response.body, name: 'AuthRemoteDataSource', level: 800);
      return;
    } else {
      log(response.body, name: 'AuthRemoteDataSource', level: 1200);
      throw Exception('Logout gagal');
    }
  }
}
