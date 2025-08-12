class ApiEndpoints {
  static const String login = '/api/member/login';
  static const String sendEmailCode = '/api/member/email/send';
  static const String loginEmail = '/api/member/login/email';
  static const String loginAccount = '/api/member/login/pwd';
  static const String resetPassword = '/api/member/pwd/update';

  static const String memberInfo = '/api/member/info';
  static const String memberInfoUpdate = '/api/member/info/update';
  static const String memberFocus = '/api/member/focus';
  static const String memberTagList = '/api/member/tag/list';

  static const String preUpload = '/api/member/upload/prep';
  static const String momentCreate = '/api/member/dynamic/upload';  // 建立影片/圖片動態
  static const String videoList = '/api/member/video/list';  // 獲取用戶動態列表
  static const String videoUpdate = '/api/member/video/update'; // 更新動態
  static const String videoLike = '/api/member/video/like'; // 喜歡視頻

}