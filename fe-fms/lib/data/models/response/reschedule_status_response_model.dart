import 'dart:convert';

/// Response model for the reschedule-status endpoint.
class RescheduleStatusResponseModel {
  final bool? success;
  final RescheduleStatusData? data;

  RescheduleStatusResponseModel({this.success, this.data});

  factory RescheduleStatusResponseModel.fromJson(String str) =>
      RescheduleStatusResponseModel.fromMap(json.decode(str));

  factory RescheduleStatusResponseModel.fromMap(Map<String, dynamic> json) =>
      RescheduleStatusResponseModel(
        success: json['Success'] == true || json['success'] == true,
        data: json['Data'] != null
            ? RescheduleStatusData.fromMap(json['Data'])
            : null,
      );
}

class RescheduleStatusData {
  final int? rescheduledId;
  final int? statusApproved;
  final String? statusLabel;
  final String? rescheduledDateJob;
  final String? reasonReject;
  final bool? canFinish;

  RescheduleStatusData({
    this.rescheduledId,
    this.statusApproved,
    this.statusLabel,
    this.rescheduledDateJob,
    this.reasonReject,
    this.canFinish,
  });

  factory RescheduleStatusData.fromMap(Map<String, dynamic> json) =>
      RescheduleStatusData(
        rescheduledId: json['RescheduledID'],
        statusApproved: json['StatusApproved'],
        statusLabel: json['StatusLabel'],
        rescheduledDateJob: json['RescheduledDateJob'],
        reasonReject: json['ReasonReject'],
        canFinish: json['CanFinish'],
      );
}
