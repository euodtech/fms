import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../models/response/get_job_history__response_model.dart';

class GetJobHistoryDatasource {
  Future<GetJobHistoryResponseModel> getJobHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);
    final userId = prefs.getString(Variables.prefUserID);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    if (userId == null) {
      throw Exception('User ID not found');
    }

    final endpoint = Variables.getJobHistoryEndpoint(userId);
    final uri = Uri.parse(endpoint).replace(queryParameters: {'x-key': apiKey});
    final response = await http.get(uri);
    log(
      response.statusCode.toString(),
      name: 'GetJobHistoryDatasource',
      level: 800,
    );
    if (response.statusCode == 200) {
      return GetJobHistoryResponseModel.fromJson(response.body);
    } else {
      log(response.body, name: 'GetJobHistoryDatasource', level: 1200);
      throw Exception('Failed to load data');
    }
  }
}
