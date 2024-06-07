import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class User {
  final String firstName;
  final String lastName;
  final String address;

  User({required this.firstName, required this.lastName, required this.address});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firstName: json['firstName'],
      lastName: json['lastName'],
      address:  json['address'],
    );
  }
}

class DevTeam extends StatefulWidget {
  const DevTeam({super.key});

  @override
  State<DevTeam> createState() => _DevTeamState();
}

class _DevTeamState extends State<DevTeam> {
  late Future<User> futureUser;

  @override
  void initState() {
    super.initState();
    futureUser = fetchUser();
  }

  Future<User> fetchUser() async {
    var uri = Uri.https('educserver-production.up.railway.app');
    final response = await http.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Info'),
      ),
      body: Center(
        child: FutureBuilder<User>(
          future: futureUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Text('Name: ${snapshot.data!.firstName} ${snapshot.data!.lastName}');
            } else {
              return Text('No data found');
            }
          },
        ),
      ),
    );
  }
}