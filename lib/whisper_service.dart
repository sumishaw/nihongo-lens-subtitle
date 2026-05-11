import 'dart:convert';
import 'package:http/http.dart' as http;

class WhisperService {

  static const apiKey =
      "YOUR_OPENAI_API_KEY";

  static Future<String> transcribeAudio(
      List<int> audioBytes) async {

    try {

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://api.openai.com/v1/audio/transcriptions',
        ),
      );

      request.headers['Authorization'] =
          'Bearer $apiKey';

      request.fields['model'] = 'whisper-1';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: 'audio.wav',
        ),
      );

      var response =
          await request.send();

      var body =
          await response.stream.bytesToString();

      var jsonData =
          jsonDecode(body);

      return jsonData['text'] ?? '';

    } catch (e) {

      return 'Transcription failed';
    }
  }
}
