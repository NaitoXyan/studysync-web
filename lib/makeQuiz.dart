import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'studentScore.dart';

class QuizPage extends StatefulWidget {
  int classroomID;

  QuizPage({
    required this.classroomID,
    super.key,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class Content {
  int quizID;
  String quizTitle;
  int classroomID;

  Content({
    required this.quizID,
    required this.quizTitle,
    required this.classroomID,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      quizID: json['quizID'],
      quizTitle: json['quizTitle'],
      classroomID: json['classroomID'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizID': quizID,
      'quizTitle': quizTitle,
      'classroomID': classroomID,
    };
  }
}

class Album {
  List<Content> quizzes;

  Album({
    required this.quizzes,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    var list = json['quizzes'] as List;
    List<Content> contentList = list.map((i) => Content.fromJson(i)).toList();

    return Album(
      quizzes: contentList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizzes': quizzes.map((quizzes) => quizzes.toJson()).toList(),
    };
  }
}

Future<Album> fetchAlbum(int classroomID) async {
  var uri = Uri.https('educserver-production.up.railway.app', '/get_quiz/$classroomID');
  final response = await http.get(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class _QuizPageState extends State<QuizPage> {
  late Future<Album> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum(widget.classroomID);
  }

  Future<void> refreshQuizList() async {
    setState(() {
      futureAlbum = fetchAlbum(widget.classroomID);
    });
  }

  Widget displayContents() {
    return FutureBuilder<Album>(
      future: futureAlbum,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show a loading indicator while fetching data
        } else {
          if (snapshot.data!.quizzes.isEmpty) {
            return centerInfo();
          } else {
            return contentsAndButton(snapshot);
          }
        }
      },
    );
  }

  Widget contentsAndButton(snapshot) {
    return Column(
      children: [
        Expanded(
            flex: 8,
            child: ListView.builder(
              itemCount: snapshot.data!.quizzes.length,
              itemBuilder: (context, index) {
                final quiz = snapshot.data!.quizzes[index];
                return Card(
                  child: ListTile(
                    title: Text(quiz.quizTitle),
                    tileColor: const Color(0xFFFFDA78),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QuizScoresPage(quizID: quiz.quizID)),
                      );
                    },
                  ),
                );
              },
            )
        ),

        Expanded(
            flex: 1,
            child: SizedBox(
              width: 300,
              height: 100,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuestionForm(classroomID: widget.classroomID, onQuizSaved: refreshQuizList)),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40A578)
                ),
                child: const Text('Make a quiz',
                  style: TextStyle(
                      fontSize: 30,
                      color: Color(0xFFFCFFE0)
                  ),
                ),
              ),
            )
        ),

        const SizedBox(
          height: 25,
        )
      ],
    );
  }

  Widget centerInfo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
        children: [
          Image.asset(
            'assets/studysync1.png',
            scale: 8,
          ),

          const Text('You have not uploaded any quizzes, make a quiz.',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QuestionForm(classroomID: widget.classroomID, onQuizSaved: refreshQuizList)),
              );
            },
            child: const Text('Make a quiz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return displayContents();
  }
}

class QuestionForm extends StatefulWidget {
  int classroomID;
  final VoidCallback onQuizSaved;

  QuestionForm({
    required this.classroomID,
    required this.onQuizSaved,
    super.key,
  });

  @override
  State<QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  List<Question> questions = [];
  final quizTitleController = TextEditingController();

  @override
  void dispose() {
    quizTitleController.dispose();
    super.dispose();
  }

  Future<void> uploadQuizRequest(String quizTitle, int classroomID) async {
    var uri = Uri.https('educserver-production.up.railway.app', '/create_quiz');
    final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "quizTitle": quizTitle,
          "classroomID": classroomID,
        })
    );

    if (response.statusCode == 200) {
      print('Response: ${response.body}');
      var quizData = jsonDecode(response.body);
      int quizID = quizData['quizID'];

      await uploadQuestionRequest(questions, quizID);
    } else {
      // Request failed, handle error here
      print('uploadQuizRequest Failed with status code: ${response.statusCode}');
    }
  }

  Future<void> uploadQuestionRequest(List<Question> questions, int quizID) async {
    var uri = Uri.https('educserver-production.up.railway.app', '/create_questions');

    List<Map<String, dynamic>> questionList = questions.map((q) {
      return {
        "question": q.questionText,
        "options": q.options,
        "correctOption": q.correctOptionIndex,
        "quizID": quizID,
      };
    }).toList();

    final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(questionList),
    );

    if (response.statusCode == 201) {
      print('Response: ${response.body}');
      widget.onQuizSaved();
      Navigator.pop(context);
    } else {
      // Request failed, handle error here
      print('uploadQuestionRequest Failed with status code: ${response.statusCode}');
    }
  }

  void _addQuestion() {
    setState(() {
      questions.add(Question());
    });
  }

  void _saveQuestionnaire() {
    String quizTitle = quizTitleController.text;
    uploadQuizRequest(quizTitle, widget.classroomID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionnaire Form'),
        backgroundColor: const Color(0xFFA3D8FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: quizTitleController,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Enter your quiz title',
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return QuestionWidget(
                    question: questions[index],
                    onRemove: () {
                      setState(() {
                        questions.removeAt(index);
                      });
                    },
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _addQuestion,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDFFC2)
                    ),
                    child: const Text('Add Question',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveQuestionnaire,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF94FFD8)
                    ),
                    child: const Text('Save Questionnaire',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Question {
  String questionText;
  List<String> options;
  int? correctOptionIndex;

  Question({this.questionText = '', List<String>? options, this.correctOptionIndex})
      : this.options = options ?? ['', '', '', ''];
}

class QuestionWidget extends StatefulWidget {
  final Question question;
  final VoidCallback onRemove;

  QuestionWidget({required this.question, required this.onRemove});

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Question'),
              onChanged: (value) {
                widget.question.questionText = value;
              },
            ),
            const SizedBox(height: 16.0),
            for (int i = 0; i < 4; i++)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                      onChanged: (value) {
                        widget.question.options[i] = value;
                      },
                    ),
                  ),
                  Radio<int>(
                    value: i,
                    groupValue: widget.question.correctOptionIndex,
                    onChanged: (value) {
                      setState(() {
                        widget.question.correctOptionIndex = value;
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: widget.onRemove,
              ),
            ),
          ],
        ),
      ),
    );
  }
}