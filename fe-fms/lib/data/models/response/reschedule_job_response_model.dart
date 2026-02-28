import 'dart:convert';

/// Response model for reschedule job requests.
class RescheduleJobResponseModel {
  final bool? success;
  final String? message;
  final int? rescheduledId;

  RescheduleJobResponseModel({this.success, this.message, this.rescheduledId});

  factory RescheduleJobResponseModel.fromJson(String str) =>
      RescheduleJobResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RescheduleJobResponseModel.fromMap(Map<String, dynamic> json) {
    final data = json['Data'] ?? json['data'];
    int? rescheduledId;
    if (data is Map<String, dynamic>) {
      rescheduledId = data['RescheduledID'] ?? data['rescheduledId'];
    }
    return RescheduleJobResponseModel(
      success: json['Success'] == true || json['success'] == true,
      message: (json['Message'] ?? json['message'])?.toString(),
      rescheduledId: rescheduledId,
    );
  }

  Map<String, dynamic> toMap() => {
    'Success': success,
    'Message': message,
    if (rescheduledId != null) 'Data': {'RescheduledID': rescheduledId},
  };
}
