import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  try {
    cameras = await availableCameras();
  } catch (_) {
    cameras = [];
  }
  runApp(const NihongoLensApp());
}

class NihongoLensApp extends StatelessWidget {
  const NihongoLensApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nihongo Lens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Color(0xFFFF3B3B)),
      ),
      home: const TranslatorScreen(),
    );
  }
}

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});
  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  int _cameraIndex = 0;
  bool _cameraReady = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  OnDeviceTranslator? _translator;
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  bool _modelReady = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _statusMessage = 'Initializing...';
  String _japaneseText = '';
  String _displayCaption = 'Press START to begin listening...';
  bool _audioOnly = false;
  bool _micDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _initAll();
  }

  Future<void> _initAll() async {
    await _requestPermissions();
    await _initTranslator();
    if (!_audioOnly) await _initCamera(_cameraIndex);
    await _initSpeech();
    if (mounted) setState(() => _statusMessage = '');
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera] != PermissionStatus.granted) {
      _audioOnly = true;
    }
    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      _micDenied = true;
      if (mounted) {
        setState(() {
          _displayCaption =
              '⚠️ Microphone permission denied.\nTap FIX button below → Settings → Allow Microphone.';
        });
      }
    }
  }

  Future<void> _initTranslator() async {
    _translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.japanese,
      targetLanguage: TranslateLanguage.english,
    );
    final jaOk = await _modelManager.isModelDownloaded(TranslateLanguage.japanese);
    final enOk = await _modelManager.isModelDownloaded(TranslateLanguage.english);
    if (!jaOk || !enOk) {
      if (mounted) setState(() { _isDownloading = true; _statusMessage = 'Downloading language pack...'; });
      try {
        if (!jaOk) {
          await _modelManager.downloadModel(TranslateLanguage.japanese, isWifiRequired: false);
          if (mounted) setState(() => _downloadProgress = 0.6);
        }
        if (!enOk) {
          await _modelManager.downloadModel(TranslateLanguage.english, isWifiRequired: false);
          if (mounted) setState(() => _downloadProgress = 1.0);
        }
        if (mounted) setState(() { _modelReady = true; _isDownloading = false; _statusMessage = ''; });
      } catch (e) {
        if (mounted) setState(() { _isDownloading = false; _statusMessage = 'Download failed – need internet first time'; });
      }
    } else {
      _modelReady = true;
    }
  }

  Future<void> _initCamera(int index) async {
    if (cameras.isEmpty) { _audioOnly = true; return; }
    _cameraController?.dispose();
    _cameraController = CameraController(
      cameras[index % cameras.length],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {
      _audioOnly = true;
    }
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) {
        if (mounted) setState(() {
          _isListening = false;
          if (e.errorMsg.contains('permission')) {
            _micDenied = true;
            _displayCaption = '⚠️ Mic denied. Tap FIX to open Settings.';
          } else {
            _displayCaption = 'Speech error: ${e.errorMsg}. Tap START to retry.';
          }
        });
      },
      onStatus: (s) {
        if (s == 'done' && _isListening) _restartListening();
      },
    );
  }

  void _restartListening() {
    if (!_isListening || !_speechAvailable) return;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_isListening && mounted) {
        _speech.listen(
          localeId: 'ja-JP',
          onResult: _onResult,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_micDenied) { await openAppSettings(); return; }
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() {
        _isListening = false;
        _displayCaption = 'Press START to begin listening...';
        _japaneseText = '';
      });
    } else {
      if (!_speechAvailable) await _initSpeech();
      if (_speechAvailable) {
        setState(() { _isListening = true; _displayCaption = '🎤 Listening for Japanese...'; });
        await _speech.listen(
          localeId: 'ja-JP',
          onResult: _onResult,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        );
      } else {
        setState(() => _displayCaption = '⚠️ Speech unavailable. Install Google app.');
      }
    }
  }

  Future<void> _onResult(SpeechRecognitionResult result) async {
    if (!mounted) return;
    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;
    setState(() => _japaneseText = words);
    if (result.finalResult && _modelReady && _translator != null) {
      try {
        final en = await _translator!.translateText(words);
        if (mounted && en.isNotEmpty) setState(() => _displayCaption = en);
      } catch (_) {
        if (mounted) setState(() => _displayCaption = 'Translation error. Retry.');
      }
    }
  }

  Future<void> _flipCamera() async {
    if (cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % cameras.length;
    setState(() => _cameraReady = false);
    await _initCamera(_cameraIndex);
  }

  void _toggleAudioOnly() {
    setState(() { _audioOnly = !_audioOnly; _cameraReady = false; });
    if (!_audioOnly) {
      _initCamera(_cameraIndex);
    } else {
      _cameraController?.dispose();
      _cameraController = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) _cameraController?.dispose();
    else if (state == AppLifecycleState.resumed && !_audioOnly) _initCamera(_cameraIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _cameraController?.dispose();
    _speech.stop();
    _translator?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        _buildBg(),
        _buildTopBar(),
        if (_isDownloading) _buildDownloadOverlay(),
        if (!_isDownloading) _buildCaptions(),
        _buildControls(),
        if (_micDenied) _buildMicBanner(),
      ]),
    );
  }

  Widget _buildBg() {
    if (!_audioOnly && _cameraReady &&
        _cameraController != null && _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF1a1a2e), Colors.black],
          radius: 1.2,
        ),
      ),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎌', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 12),
        Text(_audioOnly ? 'Audio Only Mode' : _statusMessage.isEmpty ? 'Starting camera...' : _statusMessage,
            style: const TextStyle(color: Colors.white54, fontSize: 16)),
      ])),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(children: [
          const Text('🎌 ', style: TextStyle(fontSize: 18)),
          const Expanded(child: Text('Nihongo Lens  •  Japanese → English',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFF3B3B), borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.mic, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _buildDownloadOverlay() {
    return Center(child: Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black87, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF3B3B)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.download, color: Color(0xFFFF3B3B), size: 40),
        const SizedBox(height: 16),
        const Text('Downloading Offline\nLanguage Pack',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Japanese ML Kit model\n(one-time, ~30MB)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: _downloadProgress > 0 ? _downloadProgress : null,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF3B3B)),
        ),
        const SizedBox(height: 10),
        Text(_downloadProgress > 0 ? '${(_downloadProgress * 100).toInt()}%' : 'Connecting...',
            style: const TextStyle(color: Colors.white54)),
      ]),
    ));
  }

  Widget _buildCaptions() {
    return Positioned(
      bottom: 110, left: 16, right: 16,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (_japaneseText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
            child: Text(_japaneseText, style: const TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 1.2)),
          ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
            border: Border(left: BorderSide(color: Color(0xFFFF3B3B), width: 4)),
          ),
          child: Text(_displayCaption,
              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold, height: 1.3)),
        ),
      ]),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 32, left: 0, right: 0,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        GestureDetector(
          onTap: _toggleListening,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
            decoration: BoxDecoration(
              color: _isListening ? const Color(0xFF333333) : const Color(0xFFFF3B3B),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [BoxShadow(
                color: (_isListening ? Colors.grey : const Color(0xFFFF3B3B)).withOpacity(0.4),
                blurRadius: 12, offset: const Offset(0, 4),
              )],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(_isListening ? 'STOP' : 'START',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        _iconBtn(_audioOnly ? Icons.videocam : Icons.videocam_off, _toggleAudioOnly),
        if (!_audioOnly && cameras.length > 1) ...[
          const SizedBox(width: 12),
          _iconBtn(Icons.flip_camera_android, _flipCamera),
        ],
      ]),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(40)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildMicBanner() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 64, left: 12, right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red),
        ),
        child: Row(children: [
          const Icon(Icons.mic_off, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(child: Text('Microphone denied.\nTap FIX → Settings → allow Mic.',
              style: TextStyle(color: Colors.white, fontSize: 13))),
          GestureDetector(
            onTap: openAppSettings,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              child: const Text('FIX', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}
