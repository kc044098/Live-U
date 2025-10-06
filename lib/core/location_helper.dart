
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/l10n.dart';

class LocationHelper {
  /// 取得目前 GPS 城市名稱，若失敗回傳 null
  static Future<String?> getCurrentCity({BuildContext? context}) async {
    final S? t = _maybeTexts(context);

    // 1) 服務是否開啟
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(
        msg: t?.locationPleaseEnableService ??
            _fallback('請開啟手機定位服務', 'Please enable location services'),
      );
      return null;
    }

    // 2) 權限檢查 / 請求
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg: t?.locationPermissionPermanentlyDenied ??
            _fallback('定位權限被永久拒絕，請至系統設定開啟',
                'Location permission permanently denied. Please enable it in Settings.'),
      );
      return null;
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine
    ) {
      Fluttertoast.showToast(
        msg: t?.locationPermissionDenied ??
            _fallback('無法取得定位權限', 'Location permission denied'),
      );
      return null;
    }

    // 3) 取座標 + 反向地理
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // 依常見語意回傳：城市(locality) > 區/縣(subAdministrativeArea) > 省/州(administrativeArea)
        final city = _firstNonEmpty([
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
        ]);
        return city;
      }
    } catch (e) {
      debugPrint('❌ GPS 定位失敗: $e');
      Fluttertoast.showToast(
        msg: t?.locationFetchFailed ??
            _fallback('GPS 定位失敗', 'Failed to get location'),
      );
    }

    return null;
  }

  static S? _maybeTexts(BuildContext? context) {
    try {
      if (context == null) return null;
      return S.of(context);
    } catch (_) {
      return null;
    }
  }

  // 沒有 S 可用時，依系統主要語言中/英做簡單後備
  static String _fallback(String zh, String en) {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final isZh = code.toLowerCase().startsWith('zh');
    return isZh ? zh : en;
  }

  static String? _firstNonEmpty(List<String?> items) {
    for (final s in items) {
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    return null;
  }
}
