import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const NihongoLensApp());
}

class NihongoLensApp extends StatelessWidget {
  const NihongoLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText speech = SpeechToText();

  bool isListening = false;
  String detectedText = "Waiting for Japanese speech...";

  Future<void> startListening() async {
    bool available = await speech.initialize();

    if (available) {
      setState(() {
        isListening = true;
      });

      speech.listen(
        localeId: 'ja_JP',
        partialResults: true,
        onResult: (result) {
          setState(() {
            detectedText = result.recognizedWords;
          });
        },
      );
    }
  }

  Future<void> stopListening() async {
    await speech.stop();

    setState(() {
      isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nihongo Lens"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mic,
              size: 100,
              color: Colors.cyan,
            ),
            const SizedBox(height: 30),
            Text(
              detectedText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed:
                  isListening ? stopListening : startListening,
              child: Text(
                isListening
                    ? "STOP LISTENING"
                    : "START LISTENING",
              ),
            )
          ],
        ),
      ),
    );
  }
}
