import 'dart:async';
import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_non_renewing_purchase.dart';
import 'package:apphud/models/apphud_models/apphud_paywall.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_placements.dart';
import 'package:apphud/models/apphud_models/apphud_error.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/apphud_subscription.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_provider.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_data.dart';
import 'package:apphud/models/apphud_models/apphud_user.dart';
import 'package:apphud/models/apphud_models/android/android_purchase_wrapper.dart';
import 'package:apphud/models/apphud_models/composite/apphud_product_composite.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';

/// Returns localized price string from ApphudProduct.
/// iOS: uses skProduct.price and skProduct.priceLocale with device locale.
/// Android: uses ProductDetails formattedPrice (already localized).
String formatApphudProductPrice(ApphudProduct product) {
  final sk = product.skProduct;
  if (sk != null) {
    final price = sk.price;
    final currencyCode = sk.priceLocale.currencyCode ?? 'USD';
    final currencySymbol = sk.priceLocale.currencySymbol;
    final locale = ui.PlatformDispatcher.instance.locale;
    final localeString = (locale.countryCode?.isNotEmpty ?? false)
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    try {
      final format = currencySymbol != null && currencySymbol.isNotEmpty
          ? NumberFormat.currency(
              locale: localeString,
              name: currencyCode,
              symbol: currencySymbol,
            )
          : NumberFormat.currency(
              locale: localeString,
              name: currencyCode,
            );
      return format.format(price);
    } catch (_) {
      return NumberFormat.currency(name: currencyCode).format(price);
    }
  }
  final details = product.productDetails;
  if (details != null) {
    final subOffers = details.subscriptionOfferDetails;
    final phases = (subOffers != null && subOffers.isNotEmpty)
        ? subOffers.first.pricingPhases
        : null;
    final formatted = (phases != null && phases.isNotEmpty)
        ? phases.first.formattedPrice
        : null;
    if (formatted != null && formatted.isNotEmpty) return formatted;
    final oneTime = details.oneTimePurchaseOfferDetails?.formattedPrice;
    if (oneTime != null && oneTime.isNotEmpty) return oneTime;
  }
  return '—';
}

/// Returns price and currencyCode from ApphudProduct for custom formatting.
({double price, String currencyCode})? getApphudProductPriceInfo(ApphudProduct product) {
  final sk = product.skProduct;
  if (sk != null) {
    return (
      price: sk.price,
      currencyCode: sk.priceLocale.currencyCode ?? 'USD',
    );
  }
  return null;
}

class ApphudService {
  static const _paywallId = 'paywall_main';
  static const _placementId = 'placement_main';

  static const weeklyProductId = 'sonicforge_weekly';
  static const monthlyProductId = 'sonicforge_monthly';
  static const yearlyProductId = 'sonicforge_yearly';

  static ApphudService? _instance;
  bool _initialized = false;
  bool _forbidden = false;
  String? _lastErrorMessage;

  final _subscriptionStatusController = StreamController<bool>.broadcast();
  final _paywallsController = StreamController<ApphudPaywalls>.broadcast();
  final _placementsController = StreamController<List<ApphudPlacement>>.broadcast();

  ApphudService._();

  static ApphudService get instance {
    _instance ??= ApphudService._();
    return _instance!;
  }

  /// Stream of premium access status changes (subscriptions, non-renewing purchases)
  Stream<bool> get subscriptionStatusStream => _subscriptionStatusController.stream;

  /// Stream of paywall updates when fully loaded
  Stream<ApphudPaywalls> get paywallsStream => _paywallsController.stream;

  /// Stream of placement updates when fully loaded
  Stream<List<ApphudPlacement>> get placementsStream => _placementsController.stream;

  Future<void> initialize() async {
    try {
      await Apphud.setListener(listener: _ApphudListenerImpl(this));
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

  Future<void> _onSubscriptionsUpdated(List<ApphudSubscriptionWrapper> subscriptions) async {
    await _emitPremiumStatus();
  }

  Future<void> _onNonRenewingPurchasesUpdated(List<ApphudNonRenewingPurchase> purchases) async {
    await _emitPremiumStatus();
  }

  Future<void> _emitPremiumStatus() async {
    if (!isAvailable) return;
    try {
      final hasAccess = await Apphud.hasPremiumAccess();
      _subscriptionStatusController.add(hasAccess);
    } catch (_) {}
  }

  void _onPaywallsDidFullyLoad(ApphudPaywalls paywalls) {
    _paywallsController.add(paywalls);
  }

  void _onPlacementsDidFullyLoad(List<ApphudPlacement> placements) {
    _placementsController.add(placements);
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
      if (result.error != null) return [];
      return result.paywalls;
    } catch (e) {
      _logRuntimeError('getPaywalls', e);
      return [];
    }
  }

  /// Call when your custom paywall is shown (for A/B testing analytics)
  Future<void> paywallShown(ApphudPaywall paywall) async {
    if (!isAvailable) return;
    try {
      await Apphud.paywallShown(paywall);
    } catch (e) {
      _logRuntimeError('paywallShown', e);
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

  /// Placements with paywalls and products (awaits Store products)
  Future<List<ApphudPlacement>> getPlacements() async {
    if (!isAvailable) return [];
    try {
      return await Apphud.placements();
    } catch (e) {
      _logRuntimeError('getPlacements', e);
      return [];
    }
  }

  /// Single placement by identifier
  Future<ApphudPlacement?> getPlacement(String identifier) async {
    if (!isAvailable) return null;
    try {
      return await Apphud.placement(identifier);
    } catch (e) {
      _logRuntimeError('getPlacement', e);
      return null;
    }
  }

  /// Fetch placements (force refresh for audience/A-B updates)
  Future<ApphudPlacements> fetchPlacements({bool forceRefresh = false}) async {
    if (!isAvailable) {
      return ApphudPlacements(placements: [], error: ApphudError(message: 'Apphud not available'));
    }
    try {
      return await Apphud.fetchPlacements(forceRefresh: forceRefresh);
    } catch (e) {
      _logRuntimeError('fetchPlacements', e);
      return ApphudPlacements(placements: [], error: ApphudError(message: e.toString()));
    }
  }

  /// Products via paywall.products from main paywall
  Future<List<ApphudProduct>> getProducts() async {
    final paywall = await getMainPaywall();
    return paywall?.products ?? [];
  }

  /// Products from a specific placement's paywall
  Future<List<ApphudProduct>> getProductsFromPlacement(String placementId) async {
    final placement = await getPlacement(placementId);
    return placement?.paywall?.products ?? [];
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

  /// Set attribution data. Use provider-specific methods for convenience.
  Future<void> setAttribution({
    required ApphudAttributionProvider provider,
    required Map<String, dynamic> data,
    String? identifier,
  }) async {
    if (!isAvailable) return;
    try {
      await Apphud.setAttribution(
        provider: provider,
        data: ApphudAttributionData(rawData: data),
        identifier: identifier,
      );
    } catch (e) {
      _logRuntimeError('setAttribution', e);
    }
  }

  /// AppsFlyer attribution (identifier = AppsFlyer UID)
  Future<void> setAppsFlyerAttribution({
    required Map<String, dynamic> data,
    String? identifier,
  }) async {
    await setAttribution(
      provider: ApphudAttributionProvider.appsFlyer,
      data: data,
      identifier: identifier,
    );
  }

  /// Firebase attribution
  Future<void> setFirebaseAttribution(Map<String, dynamic> data) async {
    await setAttribution(
      provider: ApphudAttributionProvider.firebase,
      data: data,
    );
  }

  /// Apple Search Ads attribution (iOS only). Collects and forwards to Apphud.
  Future<void> collectAndForwardAppleSearchAdsAttribution() async {
    if (!isAvailable) return;
    try {
      final data = await Apphud.collectSearchAdsAttribution();
      if (data != null && data.isNotEmpty) {
        await setAttribution(
          provider: ApphudAttributionProvider.appleAdsAttribution,
          data: data,
        );
        debugPrint('[Apphud] Apple Search Ads attribution forwarded');
      }
    } catch (e) {
      _logRuntimeError('collectAndForwardAppleSearchAdsAttribution', e);
    }
  }

  /// Submit IDFA to Apphud (e.g. after ATT permission). Required for attribution matching.
  Future<void> setAdvertisingIdentifier(String idfa) async {
    if (!isAvailable) return;
    try {
      await Apphud.setAdvertisingIdentifier(idfa);
    } catch (e) {
      _logRuntimeError('setAdvertisingIdentifier', e);
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

class _ApphudListenerImpl extends ApphudListener {
  _ApphudListenerImpl(this._service);

  final ApphudService _service;

  @override
  Future<void> apphudDidChangeUserID(String userId) async {
    debugPrint('[Apphud] User ID changed: $userId');
  }

  @override
  Future<void> apphudDidFecthProducts(List<ApphudProductComposite> products) async {
    debugPrint('[Apphud] Products fetched: ${products.length}');
  }

  @override
  Future<void> paywallsDidFullyLoad(ApphudPaywalls paywalls) async {
    _service._onPaywallsDidFullyLoad(paywalls);
    debugPrint('[Apphud] Paywalls loaded: ${paywalls.paywalls.length}');
  }

  @override
  Future<void> userDidLoad(ApphudUser user) async {
    debugPrint('[Apphud] User loaded');
  }

  @override
  Future<void> apphudSubscriptionsUpdated(
    List<ApphudSubscriptionWrapper> subscriptions,
  ) async {
    await _service._onSubscriptionsUpdated(subscriptions);
    debugPrint('[Apphud] Subscriptions updated: ${subscriptions.length}');
  }

  @override
  Future<void> apphudNonRenewingPurchasesUpdated(
    List<ApphudNonRenewingPurchase> purchases,
  ) async {
    await _service._onNonRenewingPurchasesUpdated(purchases);
    debugPrint('[Apphud] Non-renewing purchases updated: ${purchases.length}');
  }

  @override
  Future<void> placementsDidFullyLoad(List<ApphudPlacement> placements) async {
    _service._onPlacementsDidFullyLoad(placements);
    debugPrint('[Apphud] Placements loaded: ${placements.length}');
  }

  @override
  Future<void> apphudDidReceivePurchase(AndroidPurchaseWrapper purchase) async {
    debugPrint('[Apphud] Purchase received');
  }
}
