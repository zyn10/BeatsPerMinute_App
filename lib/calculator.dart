import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

class BPMCalculator extends StatefulWidget {
  const BPMCalculator({Key? key}) : super(key: key);

  @override
  State<BPMCalculator> createState() => _BPMCalculatorState();
}

class _BPMCalculatorState extends State<BPMCalculator> {
  String bpmResult = '';
  late Record audioRecord;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String audioPath = '';

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    audioRecord = Record();
    super.initState();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

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

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      setState(() {
        isRecording = false;
        audioPath = path!;
        print(audioPath);
        calculateBPM(audioPath);
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start();
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      print("Error in recording");
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      await audioPlayer.play(urlSource);
    } catch (e) {
      print("Error playing audio");
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
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton(
              onPressed: pickAndCalculateBPM,
              child: const Text(
                "Pick and calculate",
              ),
            ),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: isRecording
                  ? const Text('Stop Recording')
                  : const Text('Start Recording'),
            ),
            const SizedBox(
              height: 25,
            ),
            if (!isRecording && audioPath != null)
              ElevatedButton(
                onPressed: playRecording,
                child: const Text(
                  "Play Recording",
                  // style: TextStyle(
                  //   fontSize: 18,
                  //   fontWeight: FontWeight.w500,
                  // ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
