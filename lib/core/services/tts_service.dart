import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class TtsService {
  static TtsService? _instance;
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  String _voiceRssKey = '';

  VoidCallback? onComplete;

  TtsService._();

  static TtsService get instance {
    _instance ??= TtsService._();
    return _instance!;
  }

  bool get isInitialized => _initialized;

  // ==================== Init ====================

  Future<void> initialize({String voiceRssApiKey = ''}) async {
    _voiceRssKey = voiceRssApiKey;
    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setPitch(1.0);
      _flutterTts.setCompletionHandler(() => onComplete?.call());
      _flutterTts.setErrorHandler((msg) => debugPrint('flutter_tts: $msg'));
      _initialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  // ==================== Main API ====================

  /// Returns MP3 file path on success, null on failure.
  /// Tries: VoiceRSS → Edge TTS → null (caller uses flutter_tts).
  Future<String?> generateAudio(
    String script,
    String voiceStyle,
    String languageCode,
  ) async {
    if (script.isEmpty) return null;

    if (_voiceRssKey.isNotEmpty) {
      try {
        final path = await _voiceRssTts(script, voiceStyle, languageCode)
            .timeout(const Duration(seconds: 120));
        if (path != null) {
          debugPrint('TTS: VoiceRSS OK');
          return path;
        }
      } catch (e) {
        debugPrint('TTS: VoiceRSS failed — $e');
      }
    }

    try {
      final path = await _edgeTts(script, voiceStyle, languageCode)
          .timeout(const Duration(seconds: 90));
      if (path != null) {
        debugPrint('TTS: Edge fallback OK');
        return path;
      }
    } catch (e) {
      debugPrint('TTS: Edge fallback failed — $e');
    }

    return null;
  }

  // ==================== VoiceRSS ====================

  Future<String?> _voiceRssTts(
    String script,
    String voiceStyle,
    String lang,
  ) async {
    final cleaned = _cleanForSpeech(script);
    final hlCode = lang == 'ru' ? 'ru-ru' : 'en-us';
    final voice = _voiceRssVoice(voiceStyle, lang);
    final rate = _voiceRssRate(voiceStyle);

    final params = {
      'key': _voiceRssKey,
      'hl': hlCode,
      'v': voice,
      'r': rate.toString(),
      'c': 'MP3',
      'f': '24khz_16bit_mono',
      'src': cleaned,
    };

    final body = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final client = HttpClient();
    try {
      final request =
          await client.postUrl(Uri.parse('https://api.voicerss.org/'));
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.write(body);
      final response = await request.close();

      final audioBuilder = BytesBuilder();
      await response.forEach((chunk) => audioBuilder.add(chunk));
      final audioBytes = audioBuilder.toBytes();

      if (audioBytes.length < 500) {
        final text = utf8.decode(audioBytes, allowMalformed: true);
        if (text.contains('ERROR:')) {
          debugPrint('VoiceRSS: $text');
          return null;
        }
      }

      if (audioBytes.isEmpty) return null;
      return _saveToFile(audioBytes);
    } finally {
      client.close();
    }
  }

  String _voiceRssVoice(String style, String lang) {
    if (lang == 'ru') {
      switch (style) {
        case 'Soft':
        case 'Мягкий':
          return 'Marina';
        case 'Deep':
        case 'Глубокий':
          return 'Peter';
        default:
          return 'Olga';
      }
    } else {
      switch (style) {
        case 'Soft':
        case 'Мягкий':
          return 'Amy';
        case 'Deep':
        case 'Глубокий':
          return 'John';
        default:
          return 'Linda';
      }
    }
  }

  int _voiceRssRate(String style) {
    switch (style) {
      case 'Soft':
      case 'Мягкий':
        return -3;
      case 'Deep':
      case 'Глубокий':
        return -2;
      default:
        return -1;
    }
  }

  String _cleanForSpeech(String script) {
    return script
        .replaceAllMapped(
          RegExp(r'\[PAUSE\s*(\d+)s?\]', caseSensitive: false),
          (m) {
            final secs = int.tryParse(m.group(1) ?? '3') ?? 3;
            return '. ' * secs;
          },
        )
        .replaceAll(RegExp(r'\s{3,}'), ' ')
        .trim();
  }

  // ==================== Edge TTS (fallback) ====================

  static const _edgeToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  static const _edgeWsBase =
      'wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1';

  static const Map<String, String> _edgeVoices = {
    'Soft_en': 'en-US-JennyNeural',
    'Neutra_en': 'en-US-AriaNeural',
    'Deep_en': 'en-US-GuyNeural',
    'Soft_ru': 'ru-RU-SvetlanaNeural',
    'Neutra_ru': 'ru-RU-SvetlanaNeural',
    'Deep_ru': 'ru-RU-DmitryNeural',
    'Мягкий_en': 'en-US-JennyNeural',
    'Нейтральный_en': 'en-US-AriaNeural',
    'Глубокий_en': 'en-US-GuyNeural',
    'Мягкий_ru': 'ru-RU-SvetlanaNeural',
    'Нейтральный_ru': 'ru-RU-SvetlanaNeural',
    'Глубокий_ru': 'ru-RU-DmitryNeural',
  };

  Future<String?> _edgeTts(
    String script,
    String voiceStyle,
    String lang,
  ) async {
    final voice = _edgeVoices['${voiceStyle}_$lang'] ??
        (lang == 'ru' ? 'ru-RU-SvetlanaNeural' : 'en-US-AriaNeural');
    final xmlLang = voice.startsWith('ru') ? 'ru-RU' : 'en-US';
    final reqId = _hex32();

    final ws = await WebSocket.connect(
      '$_edgeWsBase?TrustedClientToken=$_edgeToken&ConnectionId=$reqId',
      headers: {
        'Origin': 'chrome-extension://jdiccldimpdaibmpdmdnlbipcdgkmpnb',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0',
      },
    );

    final ts = DateTime.now().toUtc().toIso8601String();
    ws.add(
      'X-Timestamp:$ts\r\n'
      'Content-Type:application/json; charset=utf-8\r\n'
      'Path:speech.config\r\n\r\n'
      '{"context":{"synthesis":{"audio":{"metadataoptions":'
      '{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"true"},'
      '"outputFormat":"audio-24khz-96kbitrate-mono-mp3"}}}}',
    );

    final ssml = _buildEdgeSsml(script, voice, voiceStyle, xmlLang);
    ws.add(
      'X-RequestId:$reqId\r\n'
      'Content-Type:application/ssml+xml\r\n'
      'X-Timestamp:${DateTime.now().toUtc().toIso8601String()}\r\n'
      'Path:ssml\r\n\r\n'
      '$ssml',
    );

    final audio = BytesBuilder();
    await for (final msg in ws) {
      if (msg is List<int> && msg.length > 2) {
        final hLen = (msg[0] << 8) | msg[1];
        if (2 + hLen < msg.length) {
          final header =
              utf8.decode(msg.sublist(2, 2 + hLen), allowMalformed: true);
          if (header.contains('Path:audio')) {
            audio.add(msg.sublist(2 + hLen));
          }
        }
      } else if (msg is String && msg.contains('Path:turn.end')) {
        break;
      }
    }
    await ws.close();

    final bytes = audio.toBytes();
    if (bytes.isEmpty) return null;
    return _saveToFile(bytes);
  }

  String _buildEdgeSsml(
    String script,
    String voice,
    String voiceStyle,
    String xmlLang,
  ) {
    final pauseRe = RegExp(r'\[PAUSE\s*(\d+)s?\]', caseSensitive: false);
    final segments = script.split(pauseRe);
    final pauses = pauseRe.allMatches(script).toList();

    final (rate, pitch, vol) = _edgeProsody(voiceStyle);

    final buf = StringBuffer()
      ..write(
          '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="$xmlLang">')
      ..write('<voice name="$voice">')
      ..write('<prosody rate="$rate" pitch="$pitch" volume="$vol">');

    for (int i = 0; i < segments.length; i++) {
      final t = segments[i].trim();
      if (t.isNotEmpty) buf.write(_escapeXml(t));
      if (i < pauses.length) {
        final sec = int.tryParse(pauses[i].group(1) ?? '3') ?? 3;
        buf.write(' <break time="${sec}s"/> ');
      }
    }

    buf.write('</prosody></voice></speak>');
    return buf.toString();
  }

  (String, String, String) _edgeProsody(String style) {
    switch (style) {
      case 'Soft':
      case 'Мягкий':
        return ('-22%', '+3Hz', '-8%');
      case 'Deep':
      case 'Глубокий':
        return ('-18%', '-8Hz', '+0%');
      default:
        return ('-12%', '+0Hz', '+0%');
    }
  }

  // ==================== flutter_tts (offline fallback) ====================

  Future<void> configureVoice(String voiceStyle, String languageCode) async {
    await _flutterTts.setLanguage(languageCode == 'ru' ? 'ru-RU' : 'en-US');
    switch (voiceStyle) {
      case 'Soft':
      case 'Мягкий':
        await _flutterTts.setSpeechRate(0.35);
        await _flutterTts.setPitch(1.15);
        break;
      case 'Deep':
      case 'Глубокий':
        await _flutterTts.setSpeechRate(0.32);
        await _flutterTts.setPitch(0.8);
        break;
      default:
        await _flutterTts.setSpeechRate(0.38);
        await _flutterTts.setPitch(1.0);
        break;
    }
  }

  Future<void> speak(String script) async {
    if (!_initialized) return;
    final cleaned = _cleanForSpeech(script);
    await _flutterTts.speak(cleaned);
  }

  Future<void> stop() async => _flutterTts.stop();
  Future<void> pause() async => _flutterTts.pause();

  Future<void> setVolume(double vol) async {
    await _flutterTts.setVolume(vol.clamp(0.0, 1.0));
  }

  // ==================== Helpers ====================

  String _escapeXml(String t) => t
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  String _hex32() {
    final ms = DateTime.now().microsecondsSinceEpoch;
    return ms.toRadixString(16).padLeft(32, 'a').substring(0, 32);
  }

  Future<String> _saveToFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/meditation_tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );
    await file.writeAsBytes(bytes);
    debugPrint('TTS: saved ${file.lengthSync()} bytes');
    return file.path;
  }

  Future<void> clearCache() async {
    try {
      final dir = await getTemporaryDirectory();
      for (final f in dir.listSync()) {
        if (f.path.contains('meditation_tts_') && f.path.endsWith('.mp3')) {
          await f.delete();
        }
      }
    } catch (_) {}
  }
}
