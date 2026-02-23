import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  static AudioService? _instance;
  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();

  AudioService._();

  static AudioService get instance {
    _instance ??= AudioService._();
    return _instance!;
  }

  static const Map<String, String> _soundAssets = {
    'Nature': 'assets/music/nature.mp3',
    'Rain': 'assets/music/rain.mp3',
    'Ambient music': 'assets/music/ambient.mp3',
  };

  String? _currentSound;
  double _volume = 0.3;
  double _voiceVolume = 1.0;

  String? get currentSound => _currentSound;
  double get volume => _volume;
  double get voiceVolume => _voiceVolume;
  bool get isPlaying => _bgPlayer.playing;

  Stream<PlayerState> get voicePlayerStateStream =>
      _voicePlayer.playerStateStream;
  Duration get voicePosition => _voicePlayer.position;

  // --------------- Background sound ---------------

  Future<void> playSound(String soundName) async {
    if (soundName == 'None' || soundName.isEmpty) {
      await stop();
      return;
    }
    final asset = _soundAssets[soundName];
    if (asset == null) return;
    try {
      if (_currentSound == soundName && _bgPlayer.playing) return;
      _currentSound = soundName;
      await _bgPlayer.setAsset(asset);
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.setVolume(_volume);
      await _bgPlayer.play();
    } catch (e) {
      debugPrint('AudioService bg: $e');
      _currentSound = null;
    }
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      await _bgPlayer.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> stop() async {
    _currentSound = null;
    try {
      await _bgPlayer.stop();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _bgPlayer.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (_currentSound != null) {
      try {
        await _bgPlayer.play();
      } catch (_) {}
    }
  }

  // --------------- Voice file playback ---------------

  Future<void> playVoice(String filePath) async {
    try {
      await _voicePlayer.setFilePath(filePath);
      await _voicePlayer.setVolume(_voiceVolume);
      await _voicePlayer.play();
    } catch (e) {
      debugPrint('AudioService voice: $e');
    }
  }

  Future<void> setVoiceVolume(double vol) async {
    _voiceVolume = vol.clamp(0.0, 1.0);
    try {
      await _voicePlayer.setVolume(_voiceVolume);
    } catch (_) {}
  }

  Future<void> pauseVoice() async {
    try {
      await _voicePlayer.pause();
    } catch (_) {}
  }

  Future<void> resumeVoice() async {
    try {
      await _voicePlayer.play();
    } catch (_) {}
  }

  Future<void> stopVoice() async {
    try {
      await _voicePlayer.stop();
    } catch (_) {}
  }

  Future<void> seekVoice(Duration position) async {
    try {
      await _voicePlayer.seek(position);
    } catch (_) {}
  }

  // --------------- Combined ---------------

  Future<void> pauseAll() async {
    await pause();
    await pauseVoice();
  }

  Future<void> resumeAll() async {
    await resume();
    await resumeVoice();
  }

  Future<void> stopAll() async {
    await stop();
    await stopVoice();
  }

  void dispose() {
    _bgPlayer.dispose();
    _voicePlayer.dispose();
  }
}
