import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import '../config/app_config.dart';
import 'apphud_service.dart';

class AppsFlyerService {

  static AppsFlyerService? _instance;
  AppsflyerSdk? _sdk;
  bool _initialized = false;
  Map<String, dynamic>? _conversionData;

  AppsFlyerService._();

  static AppsFlyerService get instance {
    _instance ??= AppsFlyerService._();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      final options = AppsFlyerOptions(
        afDevKey: AppConfig.appsFlyerDevKey,
        appId: AppConfig.appsFlyerAppleAppId,
        showDebug: false,
        timeToWaitForATTUserAuthorization: 60,
      );

      _sdk = AppsflyerSdk(options);

      _sdk!.onInstallConversionData((data) async {
        _conversionData = Map<String, dynamic>.from(data);
        await _forwardAttributionToApphud(_conversionData!);
      });

      _sdk!.onAppOpenAttribution((data) async {
        final payload = Map<String, dynamic>.from(data);
        await _forwardAttributionToApphud(payload);
      });

      await _sdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
      );

      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  bool get isInitialized => _initialized;

  Map<String, dynamic>? get conversionData => _conversionData;

  Future<void> logEvent(String eventName, Map<String, dynamic> values) async {
    if (!_initialized || _sdk == null) return;
    try {
      await _sdk!.logEvent(eventName, values);
    } catch (_) {}
  }

  Future<void> logMeditationCompleted({
    required String goal,
    required String duration,
  }) async {
    await logEvent('meditation_completed', {
      'goal': goal,
      'duration': duration,
    });
  }

  Future<void> logBreathingCompleted({
    required String mood,
    required String duration,
  }) async {
    await logEvent('breathing_completed', {
      'mood': mood,
      'duration': duration,
    });
  }

  Future<void> logSubscriptionStarted(String productId) async {
    await logEvent('subscription_started', {
      'product_id': productId,
    });
  }

  Future<void> setAttStatus(TrackingStatus status) async {
    if (!_initialized || _sdk == null || !Platform.isIOS) return;
    try {
      _sdk!.setAdditionalData({
        'att_status': status.name,
      });
    } catch (_) {}
  }

  Future<void> _forwardAttributionToApphud(Map<String, dynamic> data) async {
    try {
      final identifier = await _sdk?.getAppsFlyerUID();
      await ApphudService.instance.setAttribution(
        data: data,
        identifier: identifier,
      );
    } catch (_) {}
  }
}
