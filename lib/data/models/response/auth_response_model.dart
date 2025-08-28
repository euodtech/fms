import 'dart:convert';

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

class Data {
  final String? fullname;
  final String? apiKey;

  Data({this.fullname, this.apiKey});

  factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Data.fromMap(Map<String, dynamic> json) =>
      Data(fullname: json["Fullname"], apiKey: json["ApiKey"]);

  Map<String, dynamic> toMap() => {"Fullname": fullname, "ApiKey": apiKey};
}
