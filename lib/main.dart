import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

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
  final translator = GoogleTranslator();

  bool isListening = false;
  String translatedText = 'Waiting for Japanese audio...';

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await Permission.microphone.request();
    await FlutterOverlayWindow.requestPermission();
  }

  Future<void> startListening() async {
    bool available = await speech.initialize();

    if (available) {
      setState(() {
        isListening = true;
      });

      speech.listen(
        localeId: 'ja_JP',
        partialResults: true,
        onResult: (result) async {
          String japanese = result.recognizedWords;

          if (japanese.isNotEmpty) {
            var translation =
                await translator.translate(japanese, from: 'ja', to: 'en');

            translatedText = translation.text;

            await FlutterOverlayWindow.shareData(translatedText);

            setState(() {});
          }
        },
      );

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'Nihongo Lens',
        overlayContent: 'Translation Active',
        height: 160,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.bottomCenter,
      );
    }
  }

  Future<void> stopListening() async {
    await speech.stop();
    await FlutterOverlayWindow.closeOverlay();

    setState(() {
      isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nihongo Lens'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.translate,
              size: 100,
              color: Colors.cyan,
            ),
            const SizedBox(height: 30),
            Text(
              translatedText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isListening
                  ? stopListening
                  : startListening,
              child: Text(
                isListening
                    ? 'STOP TRANSLATION'
                    : 'START LIVE TRANSLATION',
              ),
            )
          ],
        ),
      ),
    );
  }
}
