import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PDFUploadScreen extends StatefulWidget {
  int classroomID;

  PDFUploadScreen({
    required this.classroomID,
    super.key
  });

  @override
  State<PDFUploadScreen> createState() => _PDFUploadScreenState();
}

class Content {
  String contentTitle;
  int classroomID;

  Content({
    required this.contentTitle,
    required this.classroomID,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      contentTitle: json['contentTitle'],
      classroomID: json['classroomID'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentTitle': contentTitle,
      'classroomID': classroomID,
    };
  }
}

class Album {
  List<Content> contents;

  Album({
    required this.contents,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    var list = json['contents'] as List;
    List<Content> contentList = list.map((i) => Content.fromJson(i)).toList();

    return Album(
      contents: contentList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contents': contents.map((classroom) => classroom.toJson()).toList(),
    };
  }
}

Future<Album> fetchAlbum(int classroomID) async {
  var uri = Uri.https('educserver-production.up.railway.app', '/get_content/$classroomID');
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

class _PDFUploadScreenState extends State<PDFUploadScreen> {
  File? file;
  Uint8List? fileBytes;
  String? fileName;
  String? fileUrl;
  late Future<Album> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum(widget.classroomID);
  }

  Future<void> uploadContentRequest(String fileName, int classroomID) async {
    var uri = Uri.https('educserver-production.up.railway.app', '/upload_content');
    final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "contentTitle": fileName,
          "classroomID": classroomID,
        })
    );

    if (response.statusCode == 200) {
      print('Response: ${response.body}');
      setState(() {
        futureAlbum = fetchAlbum(widget.classroomID);
      });
    } else {
      // Request failed, handle error here
      print('Failed with status code: ${response.statusCode}');
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          fileBytes = result.files.first.bytes;
          fileName = result.files.first.name;
        });

        print('Picked file: $fileName');

        uploadImage(); //call func that uploads to cloudinary
      } else {
        // User canceled the picker
        print('File picking cancelled');
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> uploadImage() async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dzmagqbeo/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'boscrhjo'
      ..files.add(await http.MultipartFile.fromBytes('file', fileBytes!, filename: fileName));

    final response = await request.send();
    if (response.statusCode == 200) {
      print('success 200');
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);
      setState(() {
        final url = jsonMap['url'];
        fileUrl = url;
      });

      uploadContentRequest(fileName!, widget.classroomID); //call api to save filename in database
    }
  }

  Widget displayContents() {
    return FutureBuilder<Album>(
      future: futureAlbum,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show a loading indicator while fetching data
        } else {
          if (snapshot.data!.contents.isEmpty) {
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
           itemCount: snapshot.data!.contents.length,
           itemBuilder: (context, index) {
             final content = snapshot.data!.contents[index];
             return Card(
               child: ListTile(
                 title: Text(content.contentTitle),
                 tileColor: const Color(0xFFFFDA78),
                 onTap: () {
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
                pickFile();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF40A578)
              ),
              child: const Text('Upload Content',
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

          const Text('You have no course contents, upload a file.',
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
             pickFile();
            },
            child: const Text('Add Content'),
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
