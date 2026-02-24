import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/app_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/ai_service.dart';
import 'core/services/apphud_service.dart';
import 'core/services/appsflyer_service.dart';
import 'core/services/history_service.dart';
import 'core/services/tracking_service.dart';
import 'core/services/tts_service.dart';
import 'core/services/favorites_service.dart';
import 'splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  await _initializeServices();

  runApp(const MainApp());
}

Future<void> _initializeServices() async {
  await HistoryService.instance.initialize();
  await FavoritesService.instance.initialize();

  if (AppConfig.geminiApiKey != 'YOUR_GEMINI_API_KEY') {
    AiService.instance.initialize(AppConfig.geminiApiKey);
  }

  await TtsService.instance.initialize(
    voiceRssApiKey: AppConfig.voiceRssApiKey,
  );

  await ApphudService.instance.initialize();
  final trackingStatus = await TrackingService.instance.requestPermission();
  await AppsFlyerService.instance.initialize();
  await AppsFlyerService.instance.setAttStatus(trackingStatus);

  // Apple Search Ads attribution (iOS only)
  if (Platform.isIOS) {
    ApphudService.instance.collectAndForwardAppleSearchAdsAttribution();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      home: const SplashScreen(),
    );
  }
}
