class ApiEndpoints {
  static const String login = '/api/member/login';
  static const String sendEmailCode = '/api/member/email/send';
  static const String loginEmail = '/api/member/login/email';
  static const String loginAccount = '/api/member/login/pwd';
  static const String resetPassword = '/api/member/pwd/update';
  static const String modifyPassword = '/api/member/pwd/modify';
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
  static const String userRecommend = '/api/member/recommend/user'; // 推薦用戶

  static const String liveCall = '/api/live/call'; // 撥打電話
  static const String liveCallAccept = '/api/live/call/accept'; // 1.接聽電話 2.拒絕電話
  static const String liveCallRenew = '/api/im/call'; // 直播token續期

  static const String messageSend = '/api/im/send'; // 發送聊天消息
  static const String messageHistory = '/api/im/message/history'; // 接收聊天歷史消息
  static const String userMessageList = '/api/im/message/user'; // 接收用戶聊天記錄列表

  static const String moneyCash = '/api/member/cash'; // 獲取金幣

}