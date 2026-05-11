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

      body: Center(

        child: ElevatedButton(

          onPressed: startCapture,

          child: const Text(
            'START INTERNAL AUDIO CAPTURE',
          ),
        ),
      ),
    );
  }
}
