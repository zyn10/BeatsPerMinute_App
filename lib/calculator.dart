import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class BPMCalculator extends StatefulWidget {
  const BPMCalculator({Key? key}) : super(key: key);

  @override
  State<BPMCalculator> createState() => _BPMCalculatorState();
}

class _BPMCalculatorState extends State<BPMCalculator> {
  String bpmResult = '';

  Future<void> calculateBPM(String filePath) async {
    var url = Uri.parse('http://192.168.0.100:8080/calculate_bpm');
    var request = http.MultipartRequest('POST', url);

    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        filePath,
      ),
    );

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          bpmResult = 'BPM Result: ${data['bpm']}';
        });
      } else {
        setState(() {
          bpmResult = 'Error: ${response.statusCode}';
          print('Error: ${response.statusCode}');
        });
      }
    } catch (e) {
      setState(() {
        bpmResult = 'Error: $e';
      });
    }
  }

  Future<void> pickAndCalculateBPM() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.isNotEmpty) {
      String filePath = result.files.first.path!;
      calculateBPM(filePath);
    } else {
      setState(() {
        bpmResult = 'No file selected';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "BPM Calculator",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              bpmResult,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton(
              onPressed: pickAndCalculateBPM,
              child: const Text('Select and Calculate BPM'),
            ),
          ],
        ),
      ),
    );
  }
}
