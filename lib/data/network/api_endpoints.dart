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
  static const String memberVipList = '/api/finance/vip/list'; // Vip方案列表

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
  static const String videoView = '/api/member/video/view';    // 紀錄觀看視頻時長

  static const String liveCall = '/api/live/call'; // 撥打電話
  static const String liveCallAccept = '/api/live/call/accept'; // 1.接聽電話 2.拒絕電話
  static const String liveCallRenew = '/api/im/call'; // 直播token續期

  static const String messageSend = '/api/im/send'; // 發送聊天消息
  static const String messageRead = '/api/im/message/read'; // 已讀聊天消息

  static const String messageHistory = '/api/im/message/history'; // 接收聊天歷史消息
  static const String userMessageList = '/api/im/message/user'; // 接收用戶聊天記錄列表
  static const String userCallRecordList = '/api/live/list'; // 接收用戶撥打電話記錄列表

  static const String moneyCash = '/api/member/cash'; // 獲取金幣
  static const String coinPacketList = '/api/finance/gold/list'; // 金幣禮包列表
  static const String giftList = '/api/live/gift/list'; // 禮物列表
  static const String musicList = '/api/member/music/list'; // 音樂列表
  static const String recharge = '/api/finance/recharge'; // 充值金幣 （測試用）
  static const String withdraw = '/api/finance/withdraw'; // 提現金幣 （測試用）
  static const String rechargeList = '/api/finance/recharge/list'; // 充值明細
  static const String withdrawList = '/api/finance/withdraw/list'; // 提現明細
  static const String rechargeDetail = '/api/finance/recharge/info'; // 充值詳情
  static const String financeList = '/api/finance/list'; // 帳變紀錄
  static const String buyVip = '/api/finance/vip/buy'; // 購買vip
  static const String configSet = '/api/member/config/set'; // 用於主播視頻或語音價格配置
  static const String config = '/api/member/config/list'; // 用於讀取主播視頻或語音價格配置

  static const String inviteUrl = '/api/member/share'; // 邀請碼
  static const String inviteList = '/api/member/invite/list'; // 我邀請的人的列表
  static const String rewordList = '/api/finance/log'; // 用來獲取我的獎勵

  static const String dndSet = '/api/member/mode/set'; // 用於用戶勿擾模式配置
  static const String dndRead = '/api/member/mode'; // 用於查詢用戶勿擾模式配置
  static const String renewRtcToken = '/api/live/token/renew';

  static const String liveEnd = '/api/live/report';
  static const String iapVerify = '/api/finance/pay/apple';

  static const String tokenRegister = '/api/member/register'; // FCM 註冊token
  static const String setPresence = '/api/member/status/set'; // 上報在線狀態


}