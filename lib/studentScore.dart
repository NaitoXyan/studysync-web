import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Score {
  int score;
  String studentUsername;
  int quizID;

  Score({
    required this.score,
    required this.studentUsername,
    required this.quizID,
  });

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      score: json['score'],
      studentUsername: json['student']['username'],
      quizID: json['quizID'],
    );
  }
}

class Album {
  List<Score> scores;

  Album({required this.scores});

  factory Album.fromJson(Map<String, dynamic> json) {
    var list = json['scores'] as List;
    List<Score> scoreList = list.map((i) => Score.fromJson(i)).toList();

    return Album(scores: scoreList);
  }
}

Future<Album> fetchScores(int quizID) async {
  var uri = Uri.https('educserver-production.up.railway.app', '/student_scores/$quizID');
  final response = await http.get(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load scores');
  }
}

class QuizScoresPage extends StatefulWidget {
  int quizID;

  QuizScoresPage({
    required this.quizID,
    super.key,
  });

  @override
  State<QuizScoresPage> createState() => _QuizScoresPageState();
}

class _QuizScoresPageState extends State<QuizScoresPage> {
  late Future<Album> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchScores(widget.quizID);
  }

  Widget centerInfo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/studysync1.png',
            scale: 8,
          ),
          const Text(
            'Students have not taken the quiz.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scores'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<Album>(
        future: futureAlbum,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load scores: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.scores.isEmpty) {
            return centerInfo();
          } else {
            var scores = snapshot.data!.scores;
            return ListView.builder(
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final score = scores[index];
                return Card(
                  child: ListTile(
                    title: Text('Student: ${score.studentUsername}'),
                    trailing: Text('Score: ${score.score}'),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
