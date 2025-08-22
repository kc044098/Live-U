class ApiEndpoints {
  static const String login = '/api/member/login';
  static const String sendEmailCode = '/api/member/email/send';
  static const String loginEmail = '/api/member/login/email';
  static const String loginAccount = '/api/member/login/pwd';
  static const String resetPassword = '/api/member/pwd/update';
  static const String logout = '/api/member/logout';
  static const String memberInfo = '/api/member/info';
  static const String memberInfoUpdate = '/api/member/info/update';
  static const String memberVipList = '/api/member/vip/list'; // Vip方案列表

  static const String memberFans = '/api/member/fans';
  static const String memberFocus = '/api/member/focus';  // 關注主播
  static const String isFocusMember = '/api/member/like/is';  // 查詢是否關注對方
  static const String memberTagList = '/api/member/tag/list';
  static const String memberFocusList = '/api/member/focus/list';  // 關注列表

  static const String preUpload = '/api/member/upload/prep';
  static const String momentCreate = '/api/member/dynamic/upload';  // 建立影片/圖片動態
  static const String videoList = '/api/member/video/list';  // 獲取用戶動態列表
  static const String videoUpdate = '/api/member/video/update'; // 更新動態
  static const String videoLike = '/api/member/video/like'; // 喜歡視頻
  static const String videoRecommend = '/api/member/recommend'; // 推薦視頻

  static const String liveCall = '/api/im/call'; // 撥打電話
  static const String liveCallAccept = '/api/im/call/accept'; // 接聽電話
  static const String liveCallReject = '/api/im/call/reject'; // 接聽拒絕
  static const String liveCallCancel = '/api/im/call/reject'; // 接聽拒絕
  static const String liveCallRenew = '/api/im/call'; // 直播token續期







}