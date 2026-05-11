
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const platform =
      MethodChannel('nihongo_lens/audio');

  Future<void> startCapture() async {

    try {

      await platform.invokeMethod(
        'startCapture',
      );

    } catch (e) {

      debugPrint(
        "Capture Error: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Nihongo Lens',
        ),
      ),

      body: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.translate,
              size: 120,
              color: Colors.cyan,
            ),

            const SizedBox(height: 40),

            const Text(

              'Live Japanese Subtitle Translator',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(

              'Captures Japanese video audio and shows floating English subtitles.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 60),

            ElevatedButton(

              onPressed: startCapture,

              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
              ),

              child: const Text(

                'START LIVE TRANSLATION',

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(

              'Best Results:\n\n• Use speaker audio\n• Keep volume medium-high\n• Use YouTube/VLC/browser videos\n• Allow overlay permission',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.white54,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
