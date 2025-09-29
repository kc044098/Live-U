import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  /// 由 code 取訊息；若字典無此 code → fallback 用 serverMessage → 最終給通用字串
  static String messageFor(int code, {String? serverMessage}) {
    final fromMap = zhTW[code];
    if (fromMap != null && fromMap.trim().isNotEmpty) return fromMap;
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return serverMessage.trim();
    }
    return '發生未知錯誤（$code）';
  }
}

/// 把任何錯誤物件 → 轉為 Toast（統一點）
class AppErrorToast {
  static void show(Object error) {
    if (error is ApiException) {
      Fluttertoast.showToast(msg: error.message);
      return;
    }
    if (error is DioException) {
      Fluttertoast.showToast(msg: _messageOfDio(error));
      return;
    }
    debugPrint("[AppErrorToast] ${error.toString()}");
    Fluttertoast.showToast(msg: '發生未知錯誤');
  }

  static String _messageOfDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '連線逾時，請稍後再試';
      case DioExceptionType.sendTimeout:
        return '傳送逾時，請稍後再試';
      case DioExceptionType.receiveTimeout:
        return '接收逾時，請稍後再試';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 404) return '伺服器資源不存在（HTTP 404）';
        if (status == 500) return '伺服器忙碌，請稍後再試（HTTP 500）';
        return '伺服器回應異常（HTTP $status）';
      case DioExceptionType.cancel:
        return '請求已取消';
      case DioExceptionType.connectionError:
        return '網路連線異常，請檢查網路';
      case DioExceptionType.unknown:
      default:
        return '發生網路錯誤，請稍後再試';
    }
  }
}

/// 小工具：包一層 try/catch，自動 Toast，回傳 fallback
Future<T?> guardToast<T>(Future<T> Function() run, {T? fallback}) async {
  try {
    return await run();
  } catch (e) {
    AppErrorToast.show(e);
    return fallback;
  }
}