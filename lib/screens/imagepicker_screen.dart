// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageUpload extends StatefulWidget {
  const ImageUpload({Key? key}) : super(key: key);

  @override
  State<ImageUpload> createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  final ImagePicker _picker = ImagePicker();
  PickedFile? _imageFile;
  TextEditingController _textController = TextEditingController();

  String responseFromGemini = '';

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      _imageFile = PickedFile(pickedFile?.path ?? '');
    });
  }

  Future<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?>
      _uploadImage() async {
    if (_imageFile == null) {
      return ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: Colors.red,
        ),
      );
    }
    final url = Uri.parse('http://localhost:8000/upload');
    final bytes = await _imageFile!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'file': base64Image}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded successfully!'),
        ),
      );
    } else {
      // Handle upload error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: ${response}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> sendText() async {
    try {
      if (_imageFile == null) {
        return;
      }
      const url = "http://localhost:8000/gemini";
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({'text': _textController.text}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text sent successfully!')),
        );
        setState(() {
          responseFromGemini = response.body;
          _imageFile = _imageFile;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to send text. Please try again later.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 50, 203, 237),
          title: const Row(
            children: [
              Text(
                style: TextStyle(color: Colors.white),
                'Gemini',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _imageFile != null
                ? Image.network(
                    _imageFile!.path,
                    width: 400,
                    height: 400,
                  )
                : const SizedBox(
                    width: 400,
                    height: 400,
                    child: Center(
                      child: Text(
                        'No Image',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _getImage(ImageSource.gallery),
                  child: const Row(
                    children: [
                      Text('Select Image'),
                      SizedBox(
                        width: 10,
                      ),
                      Icon(Icons.image),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                TextButton(
                  onPressed: _uploadImage,
                  child: const Row(
                    children: [Icon(Icons.upload_sharp)],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                          hintText: 'Ask anything about the image',
                          hintStyle: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  GestureDetector(
                    onTap: sendText,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: responseFromGemini.isEmpty
                    ? const Text(
                        'Response from Gemini goes here',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Text(responseFromGemini))
          ],
        ));
  }
}
