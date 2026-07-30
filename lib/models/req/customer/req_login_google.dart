// To parse this JSON data, do
//
//     final loginGoogle = loginGoogleFromJson(jsonString);

import 'dart:convert';

LoginGoogle loginGoogleFromJson(String str) => LoginGoogle.fromJson(json.decode(str));

String loginGoogleToJson(LoginGoogle data) => json.encode(data.toJson());

class LoginGoogle {
    String googleId;

    LoginGoogle({
        required this.googleId,
    });

    factory LoginGoogle.fromJson(Map<String, dynamic> json) => LoginGoogle(
        googleId: json["google_id"],
    );

    Map<String, dynamic> toJson() => {
        "google_id": googleId,
    };
}
