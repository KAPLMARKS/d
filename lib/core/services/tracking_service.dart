import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class TrackingService {
  static TrackingService? _instance;

  TrackingService._();

  static TrackingService get instance {
    _instance ??= TrackingService._();
    return _instance!;
  }

  Future<TrackingStatus> requestPermission() async {
    if (!Platform.isIOS) return TrackingStatus.notSupported;

    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;

      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(seconds: 1));
        return await AppTrackingTransparency
            .requestTrackingAuthorization();
      }

      return status;
    } catch (_) {
      return TrackingStatus.denied;
    }
  }

  Future<bool> isAuthorized() async {
    if (!Platform.isIOS) return true;
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      return status == TrackingStatus.authorized;
    } catch (_) {
      return false;
    }
  }
}
