// To parse this JSON data, do
//
//     final createCustomer = createCustomerFromJson(jsonString);

import 'dart:convert';

CreateCustomer createCustomerFromJson(String str) => CreateCustomer.fromJson(json.decode(str));

String createCustomerToJson(CreateCustomer data) => json.encode(data.toJson());

class CreateCustomer {
    String username;
    String password;

    CreateCustomer({
        required this.username,
        required this.password,
    });

    factory CreateCustomer.fromJson(Map<String, dynamic> json) => CreateCustomer(
        username: json["username"],
        password: json["password"],
    );

    Map<String, dynamic> toJson() => {
        "username": username,
        "password": password,
    };
}
