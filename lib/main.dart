import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      theme: ThemeData.dark(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver {

  static const platform =
      MethodChannel('nihongo_lens/audio');

  bool waitingForPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> startCapture() async {
    waitingForPermission = true;

    try {
      await platform.invokeMethod('startCapture');
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (
        state == AppLifecycleState.resumed &&
        waitingForPermission
    ) {

      waitingForPermission = false;

      Future.delayed(
        const Duration(milliseconds: 500),
            () async {
          try {
            await platform.invokeMethod('startCapture');
          } catch (e) {
            debugPrint(e.toString());
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: startCapture,
          child: const Text(
            'START LIVE TRANSLATION',
          ),
        ),
      ),
    );
  }
}
