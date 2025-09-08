import 'dart:convert';

class GetJobHistoryResponseModel {
  final bool? success;
  final List<Data>? data;

  GetJobHistoryResponseModel({this.success, this.data});

  factory GetJobHistoryResponseModel.fromJson(String str) =>
      GetJobHistoryResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory GetJobHistoryResponseModel.fromMap(Map<String, dynamic> json) =>
      GetJobHistoryResponseModel(
        success: json["Success"],
        data: json["Data"] == null
            ? []
            : List<Data>.from(json["Data"]!.map((x) => Data.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
    "Success": success,
    "Data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toMap())),
  };
}

class Data {
  final int? jobId;
  final String? jobName;
  final int? userId;
  final int? customerId;
  final int? typeJob;
  final int? createdBy;
  final DateTime? jobDate;
  final DateTime? createdAt;
  final dynamic assignWhen;
  final String? customerName;
  final String? phoneNumber;
  final String? address;

  Data({
    this.jobId,
    this.jobName,
    this.userId,
    this.customerId,
    this.typeJob,
    this.createdBy,
    this.jobDate,
    this.createdAt,
    this.assignWhen,
    this.customerName,
    this.phoneNumber,
    this.address,
  });

  factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Data.fromMap(Map<String, dynamic> json) => Data(
    jobId: json["JobID"],
    jobName: json["JobName"],
    userId: json["UserID"],
    customerId: json["CustomerID"],
    typeJob: json["TypeJob"],
    createdBy: json["CreatedBy"],
    jobDate: json["JobDate"] == null ? null : DateTime.parse(json["JobDate"]),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    assignWhen: json["AssignWhen"],
    customerName: json["CustomerName"],
    phoneNumber: json["PhoneNumber"],
    address: json["Address"],
  );

  Map<String, dynamic> toMap() => {
    "JobID": jobId,
    "JobName": jobName,
    "UserID": userId,
    "CustomerID": customerId,
    "TypeJob": typeJob,
    "CreatedBy": createdBy,
    "JobDate":
        "${jobDate!.year.toString().padLeft(4, '0')}-${jobDate!.month.toString().padLeft(2, '0')}-${jobDate!.day.toString().padLeft(2, '0')}",
    "created_at": createdAt?.toIso8601String(),
    "AssignWhen": assignWhen,
    "CustomerName": customerName,
    "PhoneNumber": phoneNumber,
    "Address": address,
  };
}
