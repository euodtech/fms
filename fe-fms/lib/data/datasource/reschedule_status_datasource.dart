import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../../core/network/http_error_handler.dart';
import '../models/response/reschedule_status_response_model.dart';

/// Datasource for fetching reschedule status of a job.
class RescheduleStatusDatasource {
  /// Fetches the latest reschedule status for the given job.
  Future<RescheduleStatusResponseModel> getRescheduleStatus({
    required int jobId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    final uri = Uri.parse(Variables.getRescheduleStatusEndpoint(jobId));

    final response = await ApiClient.get(
      uri,
      headers: {
        'X-API-Key': apiKey,
        'Accept': 'application/json',
      },
    );

    log(
      'status: ${response.statusCode}',
      name: 'RescheduleStatusDatasource',
      level: 800,
    );

    if (response.statusCode == 200) {
      return RescheduleStatusResponseModel.fromJson(response.body);
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);

      String errorMessage = 'Failed to fetch reschedule status';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['Message'] != null) {
          errorMessage = decoded['Message'].toString();
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {}

      if (errorMessage.toLowerCase().contains('company subscription mismatch')) {
        ApiClient.resetLogoutFlag();
      }

      return RescheduleStatusResponseModel(success: false, data: null);
    }
  }
}
