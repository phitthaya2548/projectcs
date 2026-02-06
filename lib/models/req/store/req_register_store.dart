// To parse this JSON data, do
//
//     final registerStore = registerStoreFromJson(jsonString);

import 'dart:convert';

RegisterStore registerStoreFromJson(String str) => RegisterStore.fromJson(json.decode(str));

String registerStoreToJson(RegisterStore data) => json.encode(data.toJson());

class RegisterStore {
    String username;
    String password;

    RegisterStore({
        required this.username,
        required this.password,
    });

    factory RegisterStore.fromJson(Map<String, dynamic> json) => RegisterStore(
        username: json["username"],
        password: json["password"],
    );

    Map<String, dynamic> toJson() => {
        "username": username,
        "password": password,
    };
}
