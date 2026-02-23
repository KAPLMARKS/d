import 'dart:async';
import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_paywall.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_provider.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_data.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ApphudService {
  static const _paywallId = 'paywall_main';
  static const _placementId = 'placement_main';

  static const weeklyProductId = 'sonicforge_weekly';
  static const monthlyProductId = 'sonicforge_monthly';

  static ApphudService? _instance;
  bool _initialized = false;
  bool _forbidden = false;
  String? _lastErrorMessage;

  ApphudService._();

  static ApphudService get instance {
    _instance ??= ApphudService._();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      await Apphud.start(apiKey: AppConfig.apphudApiKey).timeout(const Duration(seconds: 8));
      _initialized = true;
      _forbidden = false;
      _lastErrorMessage = null;
      debugPrint('[Apphud] Initialized successfully');
    } catch (e) {
      _initialized = false;
      _handleInitError(e);
    }
  }

  bool get isInitialized => _initialized;
  bool get isAvailable => _initialized && !_forbidden;
  bool get isForbidden => _forbidden;
  String? get lastErrorMessage => _lastErrorMessage;

  Future<bool> hasActiveSubscription() async {
    if (!isAvailable) return false;
    try {
      return await Apphud.hasActiveSubscription();
    } catch (e) {
      _logRuntimeError('hasActiveSubscription', e);
      return false;
    }
  }

  Future<bool> hasPremiumAccess() async {
    if (!isAvailable) return false;
    try {
      return await Apphud.hasPremiumAccess();
    } catch (e) {
      _logRuntimeError('hasPremiumAccess', e);
      return false;
    }
  }

  Future<List<ApphudPaywall>> getPaywalls() async {
    if (!isAvailable) return [];
    try {
      final ApphudPaywalls result = await Apphud.paywallsDidLoadCallback();
      return result.paywalls;
    } catch (e) {
      _logRuntimeError('getPaywalls', e);
      return [];
    }
  }

  Future<ApphudPaywall?> getMainPaywall() async {
    final paywalls = await getPaywalls();
    try {
      return paywalls.firstWhere((p) =>
          p.identifier == _paywallId ||
          p.identifier == _placementId);
    } catch (_) {
      return paywalls.isNotEmpty ? paywalls.first : null;
    }
  }

  Future<List<ApphudProduct>> getProducts() async {
    final paywall = await getMainPaywall();
    return paywall?.products ?? [];
  }

  Future<bool> purchase(ApphudProduct product) async {
    if (!isAvailable) return false;
    try {
      final result = await Apphud.purchase(product: product);
      return result.error == null;
    } catch (e) {
      _logRuntimeError('purchase', e);
      return false;
    }
  }

  Future<bool> purchaseById(String productId) async {
    if (!isAvailable) return false;
    try {
      final result = await Apphud.purchase(productId: productId);
      return result.error == null;
    } catch (e) {
      _logRuntimeError('purchaseById', e);
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (!isAvailable) return false;
    try {
      await Apphud.restorePurchases();
      return await hasActiveSubscription();
    } catch (e) {
      _logRuntimeError('restorePurchases', e);
      return false;
    }
  }

  Future<void> setAttribution({
    required Map<String, dynamic> data,
    String? identifier,
  }) async {
    if (!isAvailable) return;
    try {
      await Apphud.setAttribution(
        provider: ApphudAttributionProvider.appsFlyer,
        data: ApphudAttributionData(rawData: data),
        identifier: identifier,
      );
    } catch (e) {
      _logRuntimeError('setAttribution', e);
    }
  }

  void _handleInitError(Object error) {
    final text = error.toString();
    _lastErrorMessage = text;
    _forbidden = text.contains('403') ||
        text.toLowerCase().contains('access forbidden') ||
        text.toLowerCase().contains('authorization');

    if (_forbidden) {
      debugPrint(
        '[Apphud] Initialization skipped (403/authorization). '
        'App continues without subscriptions. Details: $text',
      );
    } else {
      debugPrint(
        '[Apphud] Initialization failed, fallback mode enabled. '
        'App continues without subscriptions. Details: $text',
      );
    }
  }

  void _logRuntimeError(String method, Object error) {
    debugPrint(
      '[Apphud] $method failed. Using safe fallback. Error: $error',
    );
  }
}
