import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static AiService? _instance;
  late final GenerativeModel _model;
  bool _initialized = false;

  AiService._();

  static AiService get instance {
    _instance ??= AiService._();
    return _instance!;
  }

  void initialize(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  Future<String> generateDailyRecommendation({String languageCode = 'en'}) async {
    if (!_initialized) return _fallbackRecommendation(languageCode);
    try {
      final response = await _model.generateContent([
        Content.text(
          'Generate a short, calming one-sentence meditation recommendation '
          'for today. Keep it under 50 characters. No quotes, no emojis. '
          'Examples: "A calm mind leads to better sleep tonight", '
          '"Focus on your breath to find inner peace". '
          'Just return the sentence, nothing else. '
          '${_languageInstruction(languageCode)}',
        ),
      ]);
      return response.text?.trim() ?? _fallbackRecommendation(languageCode);
    } catch (_) {
      return _fallbackRecommendation(languageCode);
    }
  }

  Future<MeditationResult> generateMeditation({
    required String goal,
    required String duration,
    required String voiceStyle,
    required String backgroundSound,
    String languageCode = 'en',
  }) async {
    if (!_initialized) return _fallbackMeditation(goal, duration, languageCode);
    try {
      final wordCount = _wordCountForDuration(duration);
      final goalTechnique = _techniqueForGoal(goal, languageCode);
      final styleTone = _toneForVoiceStyle(voiceStyle, languageCode);

      final response = await _model.generateContent([
        Content.text(
          'You are an expert meditation guide. Write a complete meditation '
          'narration script that will be read aloud by a text-to-speech engine.\n\n'
          'Parameters:\n'
          '- Goal: $goal\n'
          '- Duration: $duration\n'
          '- Tone: $styleTone\n\n'
          'STRUCTURE (follow strictly):\n'
          '1. OPENING (10%): Warm greeting, invite to find comfort, close eyes\n'
          '2. GROUNDING (15%): Body awareness, breathing rhythm setup\n'
          '3. CORE PRACTICE (55%): $goalTechnique\n'
          '4. INTEGRATION (10%): Bring awareness back, notice feelings\n'
          '5. CLOSING (10%): Gentle return, gratitude, open eyes\n\n'
          'RULES:\n'
          '- Write exactly $wordCount words of narration\n'
          '- Use second person: "you", "your"\n'
          '- Use short, flowing sentences (max 15 words each)\n'
          '- Insert [PAUSE 3s] after breathing instructions\n'
          '- Insert [PAUSE 5s] between major sections\n'
          '- Insert [PAUSE 2s] between sentences for natural rhythm\n'
          '- Include breathing cues: "Breathe in deeply" [PAUSE 3s] "And slowly let it go" [PAUSE 3s]\n'
          '- NO special characters, emojis, bullet points, numbers, or headers\n'
          '- NO meta-commentary like "(pause here)" — only use [PAUSE Xs] format\n'
          '- Write as continuous spoken text, like a live meditation guide\n'
          '- Use vivid sensory language: warmth, light, softness, weight\n\n'
          'Return EXACTLY in this format (no markdown, no extra formatting):\n'
          'TITLE: [creative short title, max 4 words]\n'
          'DESCRIPTION: [one evocative sentence, max 60 chars]\n'
          'SCRIPT: [the full narration text]\n\n'
          'Keep keys TITLE/DESCRIPTION/SCRIPT in English. '
          '${_languageInstruction(languageCode)}',
        ),
      ]);
      final text = response.text ?? '';
      return _parseMeditationResult(text, goal, duration, languageCode);
    } catch (_) {
      return _fallbackMeditation(goal, duration, languageCode);
    }
  }

  int _wordCountForDuration(String duration) {
    final digits = duration.replaceAll(RegExp(r'[^0-9]'), '');
    final minutes = int.tryParse(digits) ?? 5;
    return (minutes * 100).clamp(300, 1800);
  }

  String _techniqueForGoal(String goal, String lang) {
    final techniques = {
      'Reduce stress': lang == 'ru'
          ? 'Прогрессивная мышечная релаксация: напряжение и расслабление каждой группы мышц от ног к голове, визуализация безопасного тихого места, отпускание тревог с каждым выдохом'
          : 'Progressive muscle relaxation: tension and release from feet to head, visualization of a safe peaceful place, releasing worries with each exhale',
      'Improve sleep': lang == 'ru'
          ? 'Техника тяжёлого тела: ощущение тяжести в конечностях, подсчёт дыханий от 10 до 1, визуализация тёплого мягкого света, окутывающего тело, погружение в глубокий покой'
          : 'Heavy body technique: feeling heaviness in limbs, counting breaths from 10 to 1, visualization of warm soft light enveloping the body, sinking into deep rest',
      'Increase focus': lang == 'ru'
          ? 'Однонаправленное внимание: концентрация на одной точке, подсчёт дыханий, визуализация яркого кристально чистого луча света в центре сознания, возвращение к точке фокуса'
          : 'Single-point attention: focus on one spot, counting breaths, visualization of a bright crystal-clear beam of light in the center of awareness, returning to the focus point',
      'Boost energy': lang == 'ru'
          ? 'Энергетическое дыхание: активные глубокие вдохи, визуализация золотого солнечного света наполняющего тело энергией, пробуждение каждой клетки, ощущение бодрости и силы'
          : 'Energizing breath: active deep inhales, visualization of golden sunlight filling the body with energy, awakening every cell, feeling vitality and strength',
      'Calm anxiety': lang == 'ru'
          ? 'Заземление 5-4-3-2-1: пять вещей которые видишь, четыре звука, три ощущения, два запаха, один вкус. Медленное дыхание 4-7-8, визуализация безопасной тихой гавани'
          : 'Grounding 5-4-3-2-1: five things you see, four sounds, three textures, two smells, one taste. Slow 4-7-8 breathing, visualization of a safe quiet harbor',
    };
    return techniques[goal] ??
        (lang == 'ru'
            ? 'Осознанное дыхание и визуализация покоя'
            : 'Mindful breathing and peaceful visualization');
  }

  String _toneForVoiceStyle(String voiceStyle, String lang) {
    final tones = {
      'Soft': lang == 'ru'
          ? 'Очень мягкий, нежный, заботливый. Длинные паузы. Как тёплое одеяло'
          : 'Very gentle, nurturing, warm. Longer pauses. Like a warm blanket',
      'Neutra': lang == 'ru'
          ? 'Спокойный, ровный, уверенный. Сбалансированный ритм'
          : 'Calm, even, confident. Balanced rhythm',
      'Deep': lang == 'ru'
          ? 'Глубокий, основательный, как голос мудреца. Размеренный, весомый'
          : 'Deep, grounding, like a wise sage. Measured, weighty',
      'Мягкий': 'Очень мягкий, нежный, заботливый. Длинные паузы. Как тёплое одеяло',
      'Нейтральный': 'Спокойный, ровный, уверенный. Сбалансированный ритм',
      'Глубокий': 'Глубокий, основательный, как голос мудреца. Размеренный, весомый',
    };
    return tones[voiceStyle] ??
        (lang == 'ru' ? 'Спокойный и ровный' : 'Calm and balanced');
  }

  Future<BreathingResult> generateBreathingExercise({
    required String mood,
    required String duration,
    String languageCode = 'en',
  }) async {
    if (!_initialized) return _fallbackBreathing(mood, duration, languageCode);
    try {
      final technique = _breathingTechniqueForMood(mood);
      final response = await _model.generateContent([
        Content.text(
          'Generate a breathing exercise for someone feeling "$mood".\n'
          'Duration: $duration.\n\n'
          'Recommended technique for this mood: $technique\n'
          'You may adjust the pattern slightly to fit the duration, but keep '
          'the core technique appropriate for the mood.\n\n'
          'RULES:\n'
          '- Calm mood → slow, deep breaths with long holds (e.g. 4-7-8)\n'
          '- Neutral mood → balanced box breathing (e.g. 4-4-4-4)\n'
          '- Stressed mood → extended exhale, short/no hold (e.g. 4-2-6-0)\n'
          '- Anxious mood → short inhale, NO hold, long exhale (e.g. 3-0-6-0)\n\n'
          'Return EXACTLY in this format (no markdown):\n'
          'PATTERN: [inhale_seconds]-[hold_seconds]-[exhale_seconds]-[hold_seconds]\n'
          'CYCLES: [number of cycles to fill the duration]\n'
          'TIP: [one short calming tip, max 50 chars]\n\n'
          'Important: Keep keys PATTERN/CYCLES/TIP in English exactly as shown. '
          '${_languageInstruction(languageCode)}',
        ),
      ]);
      final text = response.text ?? '';
      return _parseBreathingResult(text, mood, duration, languageCode);
    } catch (_) {
      return _fallbackBreathing(mood, duration, languageCode);
    }
  }

  String _breathingTechniqueForMood(String mood) {
    final m = mood.toLowerCase();
    if (m.contains('calm') || m.contains('споко')) {
      return '4-7-8 Relaxing Breath: long hold and extended exhale for deep relaxation';
    } else if (m.contains('stress') || m.contains('стресс')) {
      return '4-2-6 Extended Exhale: short hold, long exhale activates parasympathetic system';
    } else if (m.contains('anxi') || m.contains('тревож')) {
      return '3-0-6 Calming Breath: no hold (holding increases anxiety), long slow exhale';
    }
    return '4-4-4-4 Box Breathing: balanced technique for centering and focus';
  }

  Future<DailyRoutineResult> generateDailyRoutine({String languageCode = 'en'}) async {
    if (!_initialized) return _fallbackRoutine(languageCode);
    try {
      final response = await _model.generateContent([
        Content.text(
          'Generate a daily meditation routine with 3 practices.\n\n'
          'Return EXACTLY in this format (no markdown):\n'
          'MORNING: [title] | [description, max 40 chars] | [duration like 5 min]\n'
          'AFTERNOON: [title] | [description, max 40 chars] | [duration like 3 min]\n'
          'EVENING: [title] | [description, max 40 chars] | [duration like 10 min]\n\n'
          'Important: Keep keys MORNING/AFTERNOON/EVENING in English exactly as shown. '
          '${_languageInstruction(languageCode)}',
        ),
      ]);
      final text = response.text ?? '';
      return _parseRoutineResult(text, languageCode);
    } catch (_) {
      return _fallbackRoutine(languageCode);
    }
  }

  MeditationResult _parseMeditationResult(
      String text, String goal, String duration, String languageCode) {
    String title = languageCode == 'ru' ? 'Момент осознанности' : 'Mindful Moment';
    String description = languageCode == 'ru'
        ? 'Мягкая медитация для вашего состояния'
        : 'A guided meditation for your wellbeing';
    String script = '';

    for (final line in text.split('\n')) {
      if (line.startsWith('TITLE:')) {
        title = line.substring(6).trim();
      } else if (line.startsWith('DESCRIPTION:')) {
        description = line.substring(12).trim();
      } else if (line.startsWith('SCRIPT:')) {
        script = line.substring(7).trim();
      }
    }

    if (script.isEmpty) {
      final scriptStart = text.indexOf('SCRIPT:');
      if (scriptStart != -1) {
        script = text.substring(scriptStart + 7).trim();
      }
    }

    return MeditationResult(
      title: title,
      description: description,
      script: script,
      duration: duration,
    );
  }

  BreathingResult _parseBreathingResult(
      String text, String mood, String duration, String languageCode) {
    int inhale = 4, hold1 = 4, exhale = 4, hold2 = 4;
    int cycles = 6;
    String tip = languageCode == 'ru' ? 'Сконцентрируйся на дыхании' : 'Focus on your breath';

    for (final line in text.split('\n')) {
      if (line.startsWith('PATTERN:')) {
        final parts = line.substring(8).trim().split('-');
        if (parts.length >= 3) {
          inhale = int.tryParse(parts[0].trim()) ?? 4;
          hold1 = int.tryParse(parts[1].trim()) ?? 4;
          exhale = int.tryParse(parts[2].trim()) ?? 4;
          hold2 = parts.length > 3
              ? (int.tryParse(parts[3].trim()) ?? 0)
              : 0;
        }
      } else if (line.startsWith('CYCLES:')) {
        cycles = int.tryParse(line.substring(7).trim()) ?? 6;
      } else if (line.startsWith('TIP:')) {
        tip = line.substring(4).trim();
      }
    }

    return BreathingResult(
      inhaleSeconds: inhale,
      hold1Seconds: hold1,
      exhaleSeconds: exhale,
      hold2Seconds: hold2,
      cycles: cycles,
      tip: tip,
    );
  }

  DailyRoutineResult _parseRoutineResult(String text, String languageCode) {
    final practices = <RoutinePractice>[];

    for (final line in text.split('\n')) {
      String? timeOfDay;
      if (line.startsWith('MORNING:')) {
        timeOfDay = 'Morning';
      } else if (line.startsWith('AFTERNOON:')) {
        timeOfDay = 'Afternoon';
      } else if (line.startsWith('EVENING:')) {
        timeOfDay = 'Evening';
      }

      if (timeOfDay != null) {
        final content = line.substring(line.indexOf(':') + 1).trim();
        final parts = content.split('|').map((s) => s.trim()).toList();
        practices.add(RoutinePractice(
          timeOfDay: timeOfDay,
          title: parts.isNotEmpty ? parts[0] : '$timeOfDay meditation',
          description:
              parts.length > 1 ? parts[1] : 'A calming practice',
          duration: parts.length > 2 ? parts[2] : '5 min',
        ));
      }
    }

    if (practices.isEmpty) return _fallbackRoutine(languageCode);

    return DailyRoutineResult(practices: practices);
  }

  String _fallbackRecommendation(String languageCode) {
    final tips = languageCode == 'ru'
        ? [
            'Спокойный ум помогает лучше спать',
            'Сделай паузу и глубоко вдохни',
            'Отпусти напряжение через медитацию',
            'Начни день с осознанного дыхания',
            'Найди тишину в текущем моменте',
          ]
        : [
            'A calm mind leads to better sleep tonight',
            'Take a moment to breathe and reset',
            'Let go of tension with a quick meditation',
            'Start your day with mindful awareness',
            'Find peace in the present moment',
          ];
    tips.shuffle();
    return tips.first;
  }

  MeditationResult _fallbackMeditation(
      String goal, String duration, String languageCode) {
    final title = languageCode == 'ru' ? 'Момент покоя' : 'Peaceful Moment';
    final description = languageCode == 'ru'
        ? 'Мягкая медитация для внутреннего покоя'
        : 'A gentle meditation for inner peace';
    final script = languageCode == 'ru'
        ? 'Добро пожаловать. Найдите удобное положение и мягко закройте глаза. '
            '[PAUSE 3s] '
            'Позвольте своему телу расслабиться. Отпустите напряжение в плечах, в челюсти, во лбу. '
            '[PAUSE 2s] '
            'Сделайте глубокий вдох через нос. [PAUSE 3s] '
            'И медленно выдохните через рот. [PAUSE 3s] '
            'Ещё раз. Вдохните покой и спокойствие. [PAUSE 3s] '
            'Выдохните всё, что вас тревожит. [PAUSE 3s] '
            'С каждым вдохом вы наполняетесь теплом и светом. '
            'С каждым выдохом уходит напряжение. '
            '[PAUSE 5s] '
            'Представьте тёплый мягкий свет, который окутывает ваше тело. '
            'Он начинается от макушки и медленно спускается вниз. '
            '[PAUSE 2s] '
            'Этот свет расслабляет каждую мышцу, каждую клеточку. '
            '[PAUSE 3s] '
            'Вы в безопасности. Вы в покое. '
            '[PAUSE 5s] '
            'Когда будете готовы, сделайте глубокий вдох. [PAUSE 3s] '
            'Пошевелите пальцами рук и ног. [PAUSE 2s] '
            'И мягко откройте глаза. Спасибо за практику.'
        : 'Welcome. Find a comfortable position and gently close your eyes. '
            '[PAUSE 3s] '
            'Allow your body to soften. Release any tension in your shoulders, your jaw, your forehead. '
            '[PAUSE 2s] '
            'Take a deep breath in through your nose. [PAUSE 3s] '
            'And slowly exhale through your mouth. [PAUSE 3s] '
            'Once more. Breathe in calm and stillness. [PAUSE 3s] '
            'Breathe out anything that no longer serves you. [PAUSE 3s] '
            'With each inhale, you are filling with warmth and light. '
            'With each exhale, tension melts away. '
            '[PAUSE 5s] '
            'Imagine a warm, soft glow surrounding your body. '
            'It begins at the top of your head and slowly moves downward. '
            '[PAUSE 2s] '
            'This light relaxes every muscle, every cell. '
            '[PAUSE 3s] '
            'You are safe. You are at peace. '
            '[PAUSE 5s] '
            'When you are ready, take one deep breath. [PAUSE 3s] '
            'Gently wiggle your fingers and toes. [PAUSE 2s] '
            'And softly open your eyes. Thank you for this practice.';
    return MeditationResult(
      title: title,
      description: description,
      script: script,
      duration: duration,
    );
  }

  BreathingResult _fallbackBreathing(
      String mood, String duration, String languageCode) {
    final m = mood.toLowerCase();
    final digits = duration.replaceAll(RegExp(r'[^0-9]'), '');
    final totalSeconds = (int.tryParse(digits) ?? 3) * 60;

    int inhale, hold1, exhale, hold2;
    String tipEn, tipRu;

    if (m.contains('calm') || m.contains('споко')) {
      // 4-7-8 Relaxing Breath
      inhale = 4; hold1 = 7; exhale = 8; hold2 = 0;
      tipEn = 'Let your exhale be twice your inhale';
      tipRu = 'Выдох в два раза длиннее вдоха';
    } else if (m.contains('stress') || m.contains('стресс')) {
      // 4-2-6 Extended Exhale
      inhale = 4; hold1 = 2; exhale = 6; hold2 = 0;
      tipEn = 'Long exhale activates your calm response';
      tipRu = 'Длинный выдох активирует расслабление';
    } else if (m.contains('anxi') || m.contains('тревож')) {
      // 3-0-6 Calming Breath (no hold)
      inhale = 3; hold1 = 0; exhale = 6; hold2 = 0;
      tipEn = 'Breathe out slowly, no need to hold';
      tipRu = 'Выдыхай медленно, задержка не нужна';
    } else {
      // 4-4-4-4 Box Breathing
      inhale = 4; hold1 = 4; exhale = 4; hold2 = 4;
      tipEn = 'Equal rhythm brings balance to your mind';
      tipRu = 'Равномерный ритм приносит баланс';
    }

    final cycleLen = inhale + hold1 + exhale + hold2;
    final cycles = (totalSeconds / cycleLen).ceil().clamp(3, 30);

    return BreathingResult(
      inhaleSeconds: inhale,
      hold1Seconds: hold1,
      exhaleSeconds: exhale,
      hold2Seconds: hold2,
      cycles: cycles,
      tip: languageCode == 'ru' ? tipRu : tipEn,
    );
  }

  DailyRoutineResult _fallbackRoutine(String languageCode) {
    if (languageCode == 'ru') {
      return DailyRoutineResult(practices: [
        RoutinePractice(
          timeOfDay: 'Утро',
          title: 'Утренняя медитация',
          description: 'Начните день в ясности',
          duration: '5 мин',
        ),
        RoutinePractice(
          timeOfDay: 'День',
          title: 'Дневное дыхание',
          description: 'Перезагрузка и фокус',
          duration: '3 мин',
        ),
        RoutinePractice(
          timeOfDay: 'Вечер',
          title: 'Вечернее расслабление',
          description: 'Отпустите напряжение перед сном',
          duration: '10 мин',
        ),
      ]);
    }
    return DailyRoutineResult(practices: [
      RoutinePractice(
        timeOfDay: 'Morning',
        title: 'Morning meditation',
        description: 'Start your day with clarity',
        duration: '5 min',
      ),
      RoutinePractice(
        timeOfDay: 'Afternoon',
        title: 'Afternoon breathing',
        description: 'Reset and recharge',
        duration: '3 min',
      ),
      RoutinePractice(
        timeOfDay: 'Evening',
        title: 'Evening relaxation',
        description: 'Unwind and prepare for rest',
        duration: '10 min',
      ),
    ]);
  }

  String _languageInstruction(String languageCode) {
    return languageCode == 'ru'
        ? 'Write user-facing content in Russian.'
        : 'Write user-facing content in English.';
  }
}

class MeditationResult {
  final String title;
  final String description;
  final String script;
  final String duration;

  MeditationResult({
    required this.title,
    required this.description,
    required this.script,
    required this.duration,
  });
}

class BreathingResult {
  final int inhaleSeconds;
  final int hold1Seconds;
  final int exhaleSeconds;
  final int hold2Seconds;
  final int cycles;
  final String tip;

  BreathingResult({
    required this.inhaleSeconds,
    required this.hold1Seconds,
    required this.exhaleSeconds,
    required this.hold2Seconds,
    required this.cycles,
    required this.tip,
  });
}

class DailyRoutineResult {
  final List<RoutinePractice> practices;

  DailyRoutineResult({required this.practices});
}

class RoutinePractice {
  final String timeOfDay;
  final String title;
  final String description;
  final String duration;

  RoutinePractice({
    required this.timeOfDay,
    required this.title,
    required this.description,
    required this.duration,
  });
}
