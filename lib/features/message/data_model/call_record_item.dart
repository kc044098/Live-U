import 'package:flutter/material.dart';

@immutable
class CallRecordItem {
  final int uid;                 // 對方 uid
  final String nickname;         // 對方暱稱
  final List<String> avatars;    // 頭像（相對）
  final int status;              // 狀態（1/4…）
  final int startAt;             // 通話開始秒（unix）
  final int endAt;               // 通話結束秒（unix）
  final int flag;                // 1=語音 2=視頻（依你現有圖示）
  final int updateAt;
  final int createAt;

  const CallRecordItem({
    required this.uid,
    required this.nickname,
    required this.avatars,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.flag,
    required this.updateAt,
    required this.createAt,
  });

  factory CallRecordItem.fromJson(Map<String, dynamic> j) {
    List<String> _toList(dynamic v) =>
        (v is List) ? v.map((e) => '$e').toList() : const <String>[];
    int _i(dynamic v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);

    return CallRecordItem(
      uid: _i(j['uid']),
      nickname: (j['nick_name'] ?? '').toString(),
      avatars: _toList(j['avatar']),
      status: _i(j['status']),
      startAt: _i(j['start_at']),
      endAt: _i(j['end_at']),
      flag: _i(j['flag']),
      updateAt: _i(j['update_at']),
      createAt: _i(j['create_at']),
    );
  }
}
