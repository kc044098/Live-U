import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../l10n/l10n.dart';
import '../l10n/l10n_en.dart';
import '../l10n/l10n_zh.dart';

class ApiException implements Exception {
  final int code;
  final String message; // 可能是後端回傳的 message 或我們映射後的字串
  ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException($code): $message';
}

/// 統一的錯誤字典（繁中）

class AppErrorCatalog {
  static const Map<int, String> zhTW = {
    100: '使用者不存在',
    101: '聊天次數用完',
    102: '額度不足',
    103: '使用者登入失敗',
    104: '使用者上傳失敗',
    105: '檔案格式不允許',
    106: 'ID 不可為空',
    107: '更新失敗',
    108: '未找到直播資料',
    109: '參數錯誤',
    110: '帳號或密碼錯誤',
    111: '登入失敗',
    112: '驗證碼錯誤',
    113: '信箱格式錯誤',
    114: '系統繁忙，請稍候再試',
    115: '找不到信箱',
    116: '帳號已被綁定',
    117: '格式轉換失敗',
    118: '使用者已登入',
    119: '請求失敗',
    120: '不能關注自己',
    121: '使用者通話中',
    122: '密碼錯誤',
    123: '使用者離線',
    124: '使用者不在通話中',
    125: '使用者勿擾模式',
    126: '當前使用者不在直播中',
    127: '訊息通知失敗',
    128: '只能撥打給主播',
    129: '設定錯誤',
    130: '新增記錄失敗',
    131: '取得 Token 失敗',
    132: '使用者資訊已過期',
    133: '連線失敗',
    134: 'JSON 解析錯誤',
    135: '使用者資訊已過期',
    136: '設定不存在',
    404: '暫無資料',
  };

  static const Map<int, String> enUS = {
    100: 'User does not exist',
    101: 'Chat quota used up',
    102: 'Insufficient balance',
    103: 'User sign-in failed',
    104: 'Upload failed',
    105: 'File type not allowed',
    106: 'ID cannot be empty',
    107: 'Update failed',
    108: 'Live session not found',
    109: 'Invalid parameters',
    110: 'Wrong account or password',
    111: 'Sign-in failed',
    112: 'Invalid verification code',
    113: 'Invalid email format',
    114: 'System busy. Please try later.',
    115: 'Email not found',
    116: 'Account already bound',
    117: 'Format conversion failed',
    118: 'User already signed in',
    119: 'Request failed',
    120: 'Cannot follow yourself',
    121: 'User is in a call',
    122: 'Incorrect password',
    123: 'User is offline',
    124: 'User is not in a call',
    125: 'Do-not-disturb mode',
    126: 'User is not live',
    127: 'Notification failed',
    128: 'Can only call broadcasters',
    129: 'Invalid settings',
    130: 'Failed to add record',
    131: 'Failed to obtain token',
    132: 'User info expired',
    133: 'Connection failed',
    134: 'JSON parse error',
    135: 'User info expired',
    136: 'Setting does not exist',
    404: 'No data',
  };

  /// 語系可選：
  /// - 有 `t` → 依 App 當前語言
  /// - 無 `t` 但有 `localeName` → 依其決定
  /// - 都沒有 → 以系統平台語言（Flutter 的 platformDispatcher.locale）為準
  static String messageFor(
      int code, {
        String? serverMessage,
        S? t,
        String? localeName,
      }) {
    final ln = _resolveLocaleName(t, localeName);
    final isZh = ln.toLowerCase().startsWith('zh');
    final map = isZh ? zhTW : enUS;

    final fromMap = map[code];
    if (fromMap != null && fromMap.trim().isNotEmpty) return fromMap;

    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return serverMessage.trim();
    }

    final base = (t != null)
        ? t.errUnknown
        : (isZh ? '發生未知錯誤' : 'An unknown error occurred');
    return '$base ($code)';
  }


  static String _resolveLocaleName(S? t, String? provided) {
    if (t != null) return t.localeName;
    if (provided != null && provided.isNotEmpty) return provided;
    try {
      final loc = WidgetsBinding.instance.platformDispatcher.locale;
      // e.g. 'zh_Hant_TW' / 'en_US'
      return loc.toLanguageTag().replaceAll('-', '_');
    } catch (_) {
      return 'en';
    }
  }
}

class AppErrorToast {
  /// 建議 UI 層呼叫時帶上 context：AppErrorToast.show(e, context: context)
  /// Repo 層也可用：AppErrorToast.show(e)（會依系統語言 fallback）
  static void show(Object error, {BuildContext? context}) {
    final t = resolveT(context);

    if (error is ApiException) {
      // 以 code 為主做本地字典對應；serverMessage 當備援
      final msg = AppErrorCatalog.messageFor(
        error.code,
        serverMessage: error.message,
        t: t,
      );
      Fluttertoast.showToast(msg: msg);
      return;
    }

    if (error is DioException) {
      Fluttertoast.showToast(msg: _messageOfDio(error, t));
      return;
    }

    debugPrint("[AppErrorToast] ${error.toString()}");
    Fluttertoast.showToast(msg: t.errUnknown);
  }

  static S resolveT(BuildContext? context) {
    if (context != null) {
      // 以 App 目前語言為準（支援你在 MyApp.locale 的切換）
      return S.of(context);
    }
    // 沒有 context 時，退回系統語系
    final sys = Platform.localeName.toLowerCase();
    return sys.startsWith('zh') ? SZh() : SEn();
  }

  static String _messageOfDio(DioException e, S t) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return t.errConnectionTimeout;
      case DioExceptionType.sendTimeout:
        return t.errSendTimeout;
      case DioExceptionType.receiveTimeout:
        return t.errReceiveTimeout;
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 404) return t.errHttp404;
        if (status == 500) return t.errHttp500;
        // 其它 HTTP 狀態碼：通用訊息 + 附上碼
        return '${t.errHttpBadResponse} (HTTP $status)';
      case DioExceptionType.cancel:
        return t.errRequestCancelled;
      case DioExceptionType.connectionError:
        return t.errConnectionError;
      case DioExceptionType.unknown:
      default:
        return t.errNetworkUnknown;
    }
  }
}

/// 包裝一個動作，發生例外時自動用多語 Toast，並回傳 fallback
Future<T?> guardToast<T>(
    Future<T> Function() run, {
      T? fallback,
      BuildContext? context,
    }) async {
  try {
    return await run();
  } catch (e) {
    AppErrorToast.show(e, context: context);
    return fallback;
  }
}