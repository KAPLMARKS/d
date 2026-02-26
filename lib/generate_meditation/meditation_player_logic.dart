part of 'meditation_player_screen.dart';

extension _MeditationPlayerLogic on _MeditationPlayerScreenState {
  String _detectLang() {
    final style = widget.voiceStyle;
    const ruStyles = [
      '\u041c\u044f\u0433\u043a\u0438\u0439',
      '\u041d\u0435\u0439\u0442\u0440\u0430\u043b\u044c\u043d\u044b\u0439',
      '\u0413\u043b\u0443\u0431\u043e\u043a\u0438\u0439',
    ];
    if (ruStyles.contains(style)) {
      return 'ru';
    }

    final locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (locale == 'ru') {
      return 'ru';
    }

    return 'en';
  }

  String _localizedSound(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (_currentSound) {
      'None' => l10n.t('none'),
      'Nature' => l10n.t('nature'),
      'Ambient music' => l10n.t('ambient_music'),
      'Rain' => l10n.t('rain'),
      _ => _currentSound,
    };
  }

  void _prepareTts() async {
    if (widget.script.isEmpty || !TtsService.instance.isInitialized) return;

    setState(() => _ttsLoading = true);

    final lang = _detectLang();
    final path = await TtsService.instance.generateAudio(
      widget.script,
      widget.voiceStyle,
      lang,
    );

    if (!mounted) return;

    if (path != null) {
      setState(() {
        _ttsFilePath = path;
        _ttsLoading = false;
      });
    } else {
      await TtsService.instance.configureVoice(widget.voiceStyle, lang);
      if (!mounted) return;
      setState(() {
        _fallbackTts = true;
        _ttsLoading = false;
      });
    }
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      if (!_savedToHistory) {
        _savedToHistory = true;
        _saveToHistory();
      }

      if (_ttsFilePath != null) {
        if (!_voiceStarted) {
          _voiceStarted = true;
          AudioService.instance.playVoice(_ttsFilePath!);
        } else {
          AudioService.instance.resumeVoice();
        }
      } else if (_fallbackTts && !_fallbackStarted) {
        _fallbackStarted = true;
        TtsService.instance.speak(widget.script);
      }

      if (_currentSound != 'None') {
        if (!_bgSoundStarted) {
          _bgSoundStarted = true;
          AudioService.instance.playSound(_currentSound);
        } else {
          AudioService.instance.resume();
        }
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_currentSeconds < _totalSeconds) {
          setState(() => _currentSeconds++);
        } else {
          _timer?.cancel();
          setState(() => _isPlaying = false);
          AudioService.instance.stopAll();
          TtsService.instance.stop();
        }
      });
    } else {
      _timer?.cancel();
      if (_ttsFilePath != null) {
        AudioService.instance.pauseAll();
      } else {
        TtsService.instance.stop();
        _fallbackStarted = false;
        AudioService.instance.pause();
      }
    }
  }

  void _seekForward() {
    setState(() {
      _currentSeconds = (_currentSeconds + 15).clamp(0, _totalSeconds);
    });
    if (_ttsFilePath != null) {
      AudioService.instance.seekVoice(Duration(seconds: _currentSeconds));
    }
  }

  void _seekBackward() {
    setState(() {
      _currentSeconds = (_currentSeconds - 15).clamp(0, _totalSeconds);
    });
    if (_ttsFilePath != null) {
      AudioService.instance.seekVoice(Duration(seconds: _currentSeconds));
    }
  }

  void _saveToHistory() {
    final digits = widget.duration.replaceAll(RegExp(r'[^0-9]'), '');
    final minutes = int.tryParse(digits) ?? 3;
    HistoryService.instance.addMeditationEntry(HistoryEntry(
      id: _meditationId,
      title: widget.title,
      goal: widget.goal,
      durationMinutes: minutes,
      date: DateTime.now(),
      type: 'meditation',
    ));
    AppsFlyerService.instance.logMeditationCompleted(
      goal: widget.goal,
      duration: widget.duration,
    );
  }

  void _changeSound() async {
    final result = await PlayerBackgroundSoundsSheet.show(
      context,
      currentSound: _currentSound,
    );
    if (result != null) {
      setState(() => _currentSound = result);
      if (result == 'None') {
        AudioService.instance.stop();
        _bgSoundStarted = false;
      } else if (_isPlaying) {
        AudioService.instance.playSound(result);
        _bgSoundStarted = true;
      } else {
        _bgSoundStarted = false;
      }
    }
  }

  void _toggleFavorite() {
    final fav = FavoriteMeditation(
      id: _meditationId,
      title: widget.title,
      description: widget.description,
      script: widget.script,
      duration: widget.duration,
      goal: widget.goal,
      sound: widget.sound,
      voiceStyle: widget.voiceStyle,
      date: DateTime.now(),
    );
    FavoritesService.instance.toggleFavorite(fav);
    setState(() => _isFavorite = !_isFavorite);
  }

  void _shareScreenshot() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/meditation_share.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final text = '${widget.title} - ${widget.description}\n'
          'AI Meditation Guide';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: text,
        ),
      );
    } catch (_) {}
  }

  void _cleanupPlayback() {
    _timer?.cancel();
    AudioService.instance.stopAll();
    TtsService.instance.stop();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
