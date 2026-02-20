import 'dart:convert';

/// Response model for authentication requests.
class AuthResponseModel {
  final bool? success;
  final Data? data;

  AuthResponseModel({this.success, this.data});

  factory AuthResponseModel.fromJson(String str) =>
      AuthResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AuthResponseModel.fromMap(Map<String, dynamic> json) =>
      AuthResponseModel(
        success: json["Success"],
        data: json["Data"] == null ? null : Data.fromMap(json["Data"]),
      );

  Map<String, dynamic> toMap() => {"Success": success, "Data": data?.toMap()};
}

/// Data object containing user and company information.
class Data {
  final int? userId;
  final String? apiKey;
  final String? company;
  final int? companyId;
  final int? companyType;
  final String? companyLabel;
  final bool? hasTraxroot;

  Data({
    this.userId,
    this.apiKey,
    this.company,
    this.companyId,
    this.companyType,
    this.companyLabel,
    this.hasTraxroot,
  });

  factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Data.fromMap(Map<String, dynamic> json) => Data(
    userId: json["UserID"],
    apiKey: json["ApiKey"],
    company: json["Company"],
    companyId: json["CompanyID"],
    companyType: json["CompanyType"],
    companyLabel: json["CompanyLabel"],
    hasTraxroot: _parseBool(json["HasTraxroot"]),
  );

  /// Parses a value to bool, handling bool, int (1/0), and string ("true"/"1").
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
    "UserID": userId,
    "ApiKey": apiKey,
    "Company": company,
    "CompanyID": companyId,
    "CompanyType": companyType,
    "CompanyLabel": companyLabel,
    "HasTraxroot": hasTraxroot,
  };
}
