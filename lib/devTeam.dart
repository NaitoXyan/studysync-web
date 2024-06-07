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
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'address': address,
    };
  }
}

class Album {
  List<User> users;

  Album({required this.users});

  factory Album.fromJson(List<dynamic> json) {
    List<User> userList = json.map((i) => User.fromJson(i)).toList();

    return Album(users: userList);
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((user) => user.toJson()).toList(),
    };
  }
}

class DevTeam extends StatefulWidget {
  const DevTeam({super.key});

  @override
  State<DevTeam> createState() => _DevTeamState();
}

class _DevTeamState extends State<DevTeam> {
  late Future<Album> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchUsers();
  }

  Future<Album> fetchUsers() async {
    var uri = Uri.https('educserver-production.up.railway.app', '/api/get_devTeam');
    final response = await http.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return Album.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load users');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Info'),
      ),
      body: Center(
        child: FutureBuilder<Album>(
          future: futureAlbum,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Center(
                child: SizedBox(
                  width: 500,
                  child: ListView.builder(
                    itemCount: snapshot.data!.users.length,
                    itemBuilder: (context, index) {
                      var user = snapshot.data!.users[index];
                      return Card(
                        color: Colors.red,
                        child: ListTile(
                          title: Text('${user.firstName} ${user.lastName}',
                            style: TextStyle(
                              color: Colors.white
                            ),
                          ),
                          subtitle: Text(user.address,
                            style: TextStyle(
                                color: Colors.white
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            } else {
              return Text('No data found');
            }
          },
        ),
      ),
    );
  }
}