// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get login => '登入';

  @override
  String get loginWelcomeTitle => '歡迎您的登入';

  @override
  String get loginWithFacebook => '透過 Facebook 登入';

  @override
  String get loginWithGoogle => '透過 Google 登入';

  @override
  String get loginWithApple => '透過 Apple 登入';

  @override
  String get loginWithEmail => '透過郵箱登入';

  @override
  String get loginWithAccount => '透過帳號密碼登入';

  @override
  String get consentLoginPrefix => '登入即代表您已年滿 18 歲，並同意我們的 ';

  @override
  String get termsOfUse => '社区协议';

  @override
  String get anchorAgreement => '服务协议';

  @override
  String get privacyPolicy => '隐私协议';

  @override
  String get andWord => ' 和 ';

  @override
  String get initializingWait => '初始化中，請稍後再試';

  @override
  String get signInFailedGoogle => 'Google 登入失敗';

  @override
  String get signInFailedApple => 'Apple 登入失敗';

  @override
  String get signInFailedFacebook => 'Facebook 登入失敗';

  @override
  String get registerTitle => '帳號註冊';

  @override
  String get emailHint => '請輸入郵箱帳號';

  @override
  String get codeHint => '請輸入驗證碼';

  @override
  String get getCode => '獲取驗證碼';

  @override
  String get newPasswordHint => '請輸入新密碼';

  @override
  String get passwordRuleTip => '密碼 6–16 字元，只能包括數字、字母或特殊字元';

  @override
  String get confirm => '確定';

  @override
  String get secondsSuffix => '秒';

  @override
  String get pleaseEnterEmail => '請輸入郵箱';

  @override
  String get codeSent => '驗證碼已發送';

  @override
  String get emailFormatError => 'Email 格式錯誤';

  @override
  String get enterAllFields => '請完整輸入所有欄位';

  @override
  String get passwordFormatError => '密碼需為 6–16 位且只包含數字、字母或特殊字元';

  @override
  String get registerSuccess => '註冊成功';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get hidePassword => '隱藏密碼';

  @override
  String get resetTitle => '忘記密碼';

  @override
  String get pleaseEnterCode => '請輸入驗證碼';

  @override
  String get pleaseEnterNewPassword => '請輸入新密碼';

  @override
  String get passwordResetSuccess => '密碼已重置';

  @override
  String get emailLoginTitle => '通過郵箱登入';

  @override
  String get passwordHint => '密碼';

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get codeLogin => '驗證碼登入';

  @override
  String get accountPasswordLogin => '帳號密碼登入';

  @override
  String get otherLoginMethods => '其他方式登入';

  @override
  String get noAccountYet => '還沒有帳號？';

  @override
  String get registerNow => '立即註冊';

  @override
  String get loginSuccess => '登入成功';

  @override
  String get pleaseEnterPassword => '請輸入密碼';

  @override
  String get loginFailedWrongCredentials => '登入失敗：帳號或密碼錯誤';

  @override
  String get loginFailedWrongCode => '登入失敗：驗證碼錯誤';

  @override
  String get loginFailedEmailFormat => '登入失敗：信箱格式錯誤';

  @override
  String get accountLoginTitle => '通過帳號登入';

  @override
  String get accountHint => '帳號';

  @override
  String get pleaseEnterAccount => '請輸入帳號';

  @override
  String get errUnknown => '發生未知錯誤';

  @override
  String get errConnectionTimeout => '連線逾時，請稍後再試';

  @override
  String get errSendTimeout => '傳送逾時，請稍後再試';

  @override
  String get errReceiveTimeout => '接收逾時，請稍後再試';

  @override
  String get errHttp404 => '伺服器資源不存在（HTTP 404）';

  @override
  String get errHttp500 => '伺服器忙碌，請稍後再試（HTTP 500）';

  @override
  String get errHttpBadResponse => '伺服器回應異常';

  @override
  String get errRequestCancelled => '請求已取消';

  @override
  String get errConnectionError => '網路連線異常，請檢查網路';

  @override
  String get errNetworkUnknown => '發生網路錯誤，請稍後再試';

  @override
  String get locationPleaseEnableService => '請開啟手機定位服務';

  @override
  String get locationPermissionDenied => '無法取得定位權限';

  @override
  String get locationPermissionPermanentlyDenied => '定位權限被永久拒絕，請至系統設定開啟';

  @override
  String get locationFetchFailed => 'GPS 定位失敗';

  @override
  String get callTimeoutNoResponse => '電話撥打超時，對方無回應';

  @override
  String get calleeBusy => '對方忙線中';

  @override
  String get calleeOffline => '對方不在線';

  @override
  String get calleeDndOn => '對方開啟免擾';

  @override
  String get needMicCamPermission => '請先授權相機與麥克風';

  @override
  String get micCamPermissionPermanentlyDenied => '相機/麥克風權限被永久拒絕，請至系統設定開啟';

  @override
  String get callDialFailed => '電話撥打失敗，請稍後再撥';

  @override
  String get peerDeclined => '對方已拒絕';

  @override
  String get statusBusy => '對方忙線中！';

  @override
  String get statusOffline => '對方不在線';

  @override
  String get statusConnecting => '正在接通中…';

  @override
  String get minimizeTooltip => '縮小畫面';

  @override
  String get balanceNotEnough => '餘額不足，請前往充值';

  @override
  String get peerEndedCall => '對方已結束通話';

  @override
  String get needMicPermission => '請先授權麥克風';

  @override
  String get acceptFailedMissingToken => '接聽失敗：缺少通話憑證';

  @override
  String get incomingCallTitle => '來電';

  @override
  String get userWord => '用戶';

  @override
  String get inviteVideoCall => '邀請你進行視頻通話…';

  @override
  String get inviteVoiceCall => '邀請你進行語音通話…';

  @override
  String get callerEndedRequest => '對方已結束通話請求…';

  @override
  String get incomingTimeout => '來電超時未接';

  @override
  String get pleaseGrantMicCam => '請先授權相機與麥克風';

  @override
  String get pleaseGrantMic => '請先授權麥克風';

  @override
  String get minimizeScreen => '縮小畫面';

  @override
  String get insufficientBalanceTopup => '餘額不足，請前往充值～';

  @override
  String get calleeDnd => '對方開啟免擾';

  @override
  String get homeTabTitle => '首頁';

  @override
  String get friendsTabTitle => '交友';

  @override
  String get fallbackUser => '用戶';

  @override
  String get fallbackBroadcaster => '主播';

  @override
  String get tagRecommended => '推薦';

  @override
  String get tagNewUpload => '新上傳';

  @override
  String get tagImage => '圖片';

  @override
  String get ratePerMinuteUnit => ' 金幣/分鐘';

  @override
  String get messagesTab => '消息';

  @override
  String get callsTab => '通話';

  @override
  String loadFailedPrefix(Object err) {
    return '載入失敗：';
  }

  @override
  String get retry => '重試';

  @override
  String get networkFetchError => '資料獲取失敗，網路連接異常';

  @override
  String whoLikesMeTitleCount(int n) {
    return '誰喜歡我：有 $n 個人新喜歡';
  }

  @override
  String lastUserJustLiked(Object name) {
    return '[$name] 剛喜歡你';
  }

  @override
  String get noNewLikes => '暫無新喜歡';

  @override
  String totalUnreadMessages(int n) {
    return '共 $n 條消息未讀';
  }

  @override
  String userWithId(int id) {
    return '用戶 $id';
  }

  @override
  String callDuration(Object mm, Object ss) {
    return '通話時長 $mm:$ss';
  }

  @override
  String get callCanceled => '已取消通話';

  @override
  String get callNotConnected => '未接通';

  @override
  String get missedToken => '未接';

  @override
  String get canceledToken => '取消';

  @override
  String get giftLabel => '禮物';

  @override
  String get voiceLabel => '語音';

  @override
  String get imageLabel => '圖片';

  @override
  String get justNow => '剛剛';

  @override
  String minutesAgo(int m) {
    return '$m 分鐘前';
  }

  @override
  String hoursAgo(int h) {
    return '$h 小時前';
  }

  @override
  String dateYmd(int year, int month, int day) {
    return '$year/$month/$day';
  }

  @override
  String idLabel(Object id) {
    return 'ID: $id';
  }

  @override
  String get unknown => '未知';

  @override
  String get vipPrivilegeTitle => 'VIP 特權';

  @override
  String get vipPrivilegeSubtitle => '開通專屬特權';

  @override
  String get vipOpened => '已開通';

  @override
  String get vipOpenNow => '立即開通';

  @override
  String get inviteFriends => '邀請好友';

  @override
  String get earnCommission => '賺取永久傭金';

  @override
  String get inviteNow => '立即邀請';

  @override
  String get myWallet => '我的錢包';

  @override
  String get recharge => '充值';

  @override
  String get coinsUnit => '金幣';

  @override
  String get priceSetting => '價格設定';

  @override
  String get whoLikesMe => '誰喜歡我';

  @override
  String get iLiked => '我喜歡的';

  @override
  String get accountManage => '帳號管理';

  @override
  String get dndMode => '勿擾模式';

  @override
  String get logout => '退出登入';

  @override
  String get liveChatHint => '說點什麼⋯';

  @override
  String giftSend(Object name) {
    return '送出禮物給 $name';
  }

  @override
  String get tooltipMinimize => '縮小畫面';

  @override
  String get tooltipClose => '關閉';

  @override
  String get freeTimeLabel => '免費時長';

  @override
  String get rechargeGo => '去充值';

  @override
  String get callConnectFailed => '通話連線接通失敗';

  @override
  String get toggleVideoFailed => '切換影像失敗';

  @override
  String get switchCameraFailed => '切換鏡頭失敗';

  @override
  String get notConnectedToPeer => '尚未連線到對方';

  @override
  String get notLoggedIn => '尚未登入';

  @override
  String get peerLeftChatroom => '對方已離開聊天室';

  @override
  String get peerLeftLivestream => '對方已離開直播間';

  @override
  String get pleaseGrantMicOnly => '請先授權麥克風';

  @override
  String get pleaseGrantMicAndCamera => '請先授權麥克風與相機';

  @override
  String get freeTimeEndedStartBilling => '免費時長已結束，開始計費';

  @override
  String countdownRechargeHint(int sec) {
    return '當前剩餘時間不足 $sec 秒，請盡快充值。';
  }

  @override
  String get chatEndedTitle => '聊天結束';

  @override
  String get refresh => '重新整理';

  @override
  String get settlingPleaseWait => '結算中，請稍候…';

  @override
  String get greatJobKeepItUp => '太棒了，努力就會有收穫！';

  @override
  String get videoDurationPrefix => '視頻時長：';

  @override
  String get durationZeroSeconds => '0 秒';

  @override
  String get minuteUnit => '分';

  @override
  String get secondUnit => '秒';

  @override
  String get totalIncome => '總收入';

  @override
  String get giftsCountLabel => '送禮次數';

  @override
  String get videoIncome => '視頻收入';

  @override
  String get voiceIncome => '語音收入';

  @override
  String get giftIncome => '禮物收入';

  @override
  String get coinUnit => '金幣';

  @override
  String get timesUnit => '次';

  @override
  String get stillNotSettledTapRetry => '仍未結算？點此重試';

  @override
  String get onlineStatusLabel => '在線';

  @override
  String get busyStatusLabel => '忙線中';

  @override
  String get offlineStatusLabel => '離線';

  @override
  String get musicAddTitle => '添加音樂';

  @override
  String get musicSearchHint => '搜尋歌名';

  @override
  String get musicTabRecommend => '推薦';

  @override
  String get musicTabFavorites => '收藏';

  @override
  String get musicTabUsed => '用過';

  @override
  String get musicLoadFailedTitle => '載入失敗';

  @override
  String get musicNoContent => '暫無內容';

  @override
  String get useAction => '使用';

  @override
  String get publish => '發佈';

  @override
  String get momentHint => '記錄這一刻…';

  @override
  String get momentHint1 => '請輸入內容...';

  @override
  String get editCover => '編輯封面';

  @override
  String get selectCategory => '選擇分類';

  @override
  String get categoryFeatured => '精選';

  @override
  String get categoryDaily => '日常';

  @override
  String get uploadingVideo => '上傳視頻中…';

  @override
  String get uploadSuccess => '上傳成功～';

  @override
  String get uploadCanceled => '已取消上傳';

  @override
  String get loginExpiredRelogin => '登入已失效，請重新登入';

  @override
  String get requestTooFrequent => '操作太頻繁，稍後再試';

  @override
  String get invalidParams => '參數不完整或不合法';

  @override
  String get serverBusyTryLater => '伺服器忙碌，請稍後再試';

  @override
  String get videoUploadFailed => '影片上傳失敗';

  @override
  String get coverUploadFailed => '封面上傳失敗';

  @override
  String get imageUploadFailed => '圖片上傳失敗';

  @override
  String get createMomentFailed => '建立動態失敗';

  @override
  String get genericUploadFailed => '資料上傳失敗';

  @override
  String get genericError => '發生錯誤';

  @override
  String get nextStep => '下一步';

  @override
  String get flipCamera => '翻轉';

  @override
  String get gallery => '相簿';

  @override
  String get modeVideo => '視頻';

  @override
  String get modeImage => '圖片';

  @override
  String get toastAddedMusic => '已添加音樂';

  @override
  String get toastClearedMusic => '已清除音樂';

  @override
  String get noOtherCameraToSwitch => '沒有其他鏡頭可切換';

  @override
  String get beautyNotImplemented => '美顏功能尚未實現';

  @override
  String get filterNotImplemented => '濾鏡功能尚未實現';

  @override
  String get recordTooLong1Min => '錄製視頻需在一分鐘以內';

  @override
  String get pickVideoTooLong1Min => '選取視頻需要在一分鐘以內';

  @override
  String get noGifts => '暫無禮物';

  @override
  String get insufficientGoldNow => '當前金幣不足！';

  @override
  String get balancePrefix => '餘額：';

  @override
  String get currentCoins => '當前金幣：';

  @override
  String get packetsLoadFailed => '禮包載入失敗';

  @override
  String limitedTimeBonus(int n) {
    return '限時贈送 $n 幣';
  }

  @override
  String get customAmount => '自定義金額';

  @override
  String get enterRechargeAmount => '請輸入您的充值金額';

  @override
  String get packetsNotReady => '禮包尚未載入，請稍候';

  @override
  String get amountAtLeastOne => '至少輸入 1 元';

  @override
  String get amountMustBeInteger => '金額必須是整數';

  @override
  String get pleaseChoosePackage => '請先選擇禮包';

  @override
  String get sendFailed => '發送失敗';

  @override
  String get giftSentShort => '贈送';

  @override
  String get dmPrefix => '私信了你：';

  @override
  String get replyAction => '回覆';

  @override
  String get giftShort => '禮物';

  @override
  String get imageShort => '圖片';

  @override
  String get voiceShort => '語音';

  @override
  String voiceWithSeconds(int s) {
    return '語音 ${s}s';
  }

  @override
  String get incomingGenericMessage => '發來一條消息';

  @override
  String xCount(int n) {
    return 'x$n';
  }

  @override
  String get pullUpToLoadMore => '上拉載入更多';

  @override
  String get releaseToLoadMore => '釋放以載入更多';

  @override
  String get loadingEllipsis => '載入中…';

  @override
  String get oldestMessagesShown => '已顯示最舊的消息';

  @override
  String get emojiLabel => '表情';

  @override
  String get callLabel => '通話';

  @override
  String get videoLabel => '視頻';

  @override
  String get inputMessageHint => '請輸入消息…';

  @override
  String get send => '發送';

  @override
  String get holdToTalk => '按住說話';

  @override
  String get videoCall => '視頻通話';

  @override
  String get cancel => '取消';

  @override
  String get dmDailyLimitHint => '當天私信次數已用完，您可以直接視頻通話哦！';

  @override
  String get yesterdayLabel => '昨日';

  @override
  String get currentlyOnlineLabel => '當前在線';

  @override
  String get dnd15m => '15 分鐘';

  @override
  String get dnd30m => '30 分鐘';

  @override
  String get dnd1h => '1 小時';

  @override
  String get dnd6h => '6 小時';

  @override
  String get dnd12h => '12 小時';

  @override
  String get dnd24h => '24 小時';

  @override
  String get dndSetFailed => '設定失敗，請稍後再試';

  @override
  String get dndTitle => '勿擾模式';

  @override
  String get dndVideoDnd => '視頻勿擾';

  @override
  String get dndActiveHint => '已開啟。在此期間，後台會將你的狀態設為忙碌，別人無法發起視頻聊天';

  @override
  String get dndInactiveHint => '選擇一個時長開啟免擾。開啟後期間別人無法和你進行視頻聊天';

  @override
  String get dndOffToast => '已關閉免擾';

  @override
  String dndOnToast(Object label) {
    return '已開啟免擾（$label）';
  }

  @override
  String get accountInfoTitle => '賬號資訊';

  @override
  String get changeAccountPassword => '修改帳號密碼';

  @override
  String get changeEmailPassword => '修改郵箱密碼';

  @override
  String get accountManageTitle => '賬號管理';

  @override
  String get accountLabel => '賬號';

  @override
  String get emailLabel => '郵箱';

  @override
  String get emailBindHint => '綁定郵箱，隨時接收有趣的活動、新功能升級、推薦獎勵等資訊';

  @override
  String get statusBound => '已綁定';

  @override
  String get statusToBind => '待綁定';

  @override
  String get addEmailTitle => '添加郵箱';

  @override
  String get addEmailSubtitle => '輸入您想要與您的帳號關聯的郵箱地址，您的郵箱不會顯示在公開資料中';

  @override
  String get addEmailHintEmail => '請輸入郵箱賬號';

  @override
  String get addEmailHintCode => '請輸入驗證碼';

  @override
  String get addEmailGetCode => '獲取驗證碼';

  @override
  String get addEmailConfirm => '確定';

  @override
  String get addEmailToastInvalid => '請輸入有效郵箱';

  @override
  String get addEmailToastNeedCode => '請輸入驗證碼';

  @override
  String get commonUnknown => '未知';

  @override
  String get commonEdit => '編輯';

  @override
  String get commonPublishMoment => '發佈動態';

  @override
  String get commonVideo => '影片';

  @override
  String get commonImage => '圖片';

  @override
  String get commonContent => '內容';

  @override
  String get commonFeatured => '精選';

  @override
  String get commonNoContentYet => '還沒有內容';

  @override
  String get commonMyProfile => '個人資料';

  @override
  String get profileTabInfo => '我的資料';

  @override
  String get profileTabMoments => '個人動態';

  @override
  String get profileAboutMe => '關於我';

  @override
  String get profileLabelHeight => '身高';

  @override
  String get profileLabelWeight => '體重';

  @override
  String get profileLabelMeasurements => '三圍';

  @override
  String get profileLabelCity => '城市';

  @override
  String get profileLabelJob => '工作';

  @override
  String get profileMyTags => '我的標籤';

  @override
  String get editProfileTitle => '編輯個人資料';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDone => '完成';

  @override
  String get commonSave => '保存';

  @override
  String get commonConfirm => '確定';

  @override
  String get unitCentimeter => 'cm';

  @override
  String get unitPound => 'lb';

  @override
  String get unitYearShort => '歲';

  @override
  String get fieldNickname => '暱稱';

  @override
  String get fieldGender => '性別';

  @override
  String get fieldBirthday => '生日';

  @override
  String get fieldHeight => '身高';

  @override
  String get fieldWeight => '體重';

  @override
  String get fieldMeasurements => '三圍';

  @override
  String get fieldCity => '城市';

  @override
  String get fieldJob => '工作';

  @override
  String get fieldTags => '個人標籤';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get genderSecret => '保密';

  @override
  String get tagsAddNow => '立即添加';

  @override
  String get tagsTitleMyTags => '我的標籤';

  @override
  String get toastTagsUpdated => '標籤已更新';

  @override
  String get toastMaxFiveTags => '最多只能選擇 5 個標籤';

  @override
  String toastUpdateFailed(Object e) {
    return '更新失敗：$e';
  }

  @override
  String get toastInvalidImageType => '只允許上傳 JPG / JPEG / PNG 圖片';

  @override
  String get sheetTitleEnterNickname => '填寫暱稱';

  @override
  String get sheetHintEnterNickname => '請輸入暱稱';

  @override
  String get toastEnterNickname => '請輸入暱稱';

  @override
  String get toastNicknameTooLong => '暱稱長度過長，請重新輸入';

  @override
  String get toastNicknameUpdateSuccess => '暱稱更新成功';

  @override
  String toastNicknameUpdateFailed(Object e) {
    return '暱稱更新失敗：$e';
  }

  @override
  String get sheetTitleEnterHeight => '填寫身高';

  @override
  String get toastEnterValidHeight => '請輸入正確的身高';

  @override
  String get toastEnterHeightRange => '請輸入 1–999 的身高';

  @override
  String get toastHeightUpdateSuccess => '身高更新成功';

  @override
  String toastHeightUpdateFailed(Object e) {
    return '身高更新失敗：$e';
  }

  @override
  String get sheetTitleEnterWeight => '填寫體重';

  @override
  String get toastEnterValidWeight => '請輸入正確的體重';

  @override
  String get toastEnterWeightRange => '請輸入 1–999 的體重';

  @override
  String get toastWeightUpdateSuccess => '體重更新成功';

  @override
  String toastWeightUpdateFailed(Object e) {
    return '體重更新失敗：$e';
  }

  @override
  String get toastAgeMustBe18 => '需年滿 18 歲';

  @override
  String get toastAgeUpdateSuccess => '年齡已更新';

  @override
  String toastAgeUpdateFailed(Object e) {
    return '年齡更新失敗：$e';
  }

  @override
  String get sheetTitleEnterMeasurements => '填寫三圍';

  @override
  String get bodyBust => '胸圍';

  @override
  String get bodyWaist => '腰圍';

  @override
  String get bodyHip => '臀圍';

  @override
  String get toastMeasurementsEachRange => '三圍每一項請輸入 1–999 的數值';

  @override
  String get toastMeasurementsUpdated => '三圍已更新';

  @override
  String toastMeasurementsUpdateFailed(Object e) {
    return '三圍更新失敗：$e';
  }

  @override
  String get sheetTitleEnterJob => '填寫職業';

  @override
  String get sheetHintEnterJob => '請輸入職業';

  @override
  String get toastJobMax12 => '職業最多輸入 12 個字元';

  @override
  String get toastJobUpdated => '職業已更新';

  @override
  String toastJobUpdateFailed(Object e) {
    return '職業更新失敗：$e';
  }

  @override
  String get monthJanuary => '一月';

  @override
  String get monthFebruary => '二月';

  @override
  String get monthMarch => '三月';

  @override
  String get monthApril => '四月';

  @override
  String get monthMay => '五月';

  @override
  String get monthJune => '六月';

  @override
  String get monthJuly => '七月';

  @override
  String get monthAugust => '八月';

  @override
  String get monthSeptember => '九月';

  @override
  String get monthOctober => '十月';

  @override
  String get monthNovember => '十一月';

  @override
  String get monthDecember => '十二月';

  @override
  String get inviteScanQrTitle => '識別二維碼下載';

  @override
  String get inviteScanQrSubtitle => '即可開啟甜蜜交友之旅';

  @override
  String get inviteSharePoster => '分享海報';

  @override
  String get inviteCopyLink => '複製連結';

  @override
  String get inviteSaveImage => '保存圖片';

  @override
  String get inviteCopied => '已複製連結';

  @override
  String get inviteLoadFailed => '載入失敗';

  @override
  String get inviteInvalidLink => '無效的連結';

  @override
  String get inviteGetLinkFailed => '取得邀請連結失敗';

  @override
  String get inviteSavingNotReady => '畫面尚未準備完成';

  @override
  String get inviteSavedToAlbum => '已保存至相簿！';

  @override
  String get inviteSaveFailed => '保存失敗';

  @override
  String get shareTo => '分享到';

  @override
  String get commonPermissionDisabled => '權限被停用';

  @override
  String get commonPermissionRationaleOpenSettings =>
      '您已關閉儲存/相簿權限，請前往系統設定手動開啟。';

  @override
  String get commonGoToSettings => '去設定';

  @override
  String get messengerNotInstalled => '未檢測到安裝 Messenger，無法分享';

  @override
  String get inviteEarnCashShort => '賺現金';

  @override
  String get inviteOnceLifetime => '- 邀請一次，享終身收益 -';

  @override
  String inviteCommissionDesc(Object percent) {
    return '好友每次充值餘額，即可享受好友充值總金額 $percent 的提成';
  }

  @override
  String get myInvites => '我的邀請';

  @override
  String get inviteEasyEarn => '·輕鬆躺賺·';

  @override
  String get likedEmptyHint => '還沒有喜歡的人～';

  @override
  String get toastGiftSent => '你已贈送出禮物～';

  @override
  String get logoutConfirmMessage => '確認退出當前帳號？';

  @override
  String get myInvitesTitle => '我的邀請';

  @override
  String get withdraw => '提現';

  @override
  String get totalCommissionReward => '累計佣金獎勵';

  @override
  String get withdrawableAmount => '可提現金額';

  @override
  String get tabMyRewards => '我的獎勵';

  @override
  String get tabInvitees => '我邀請的人';

  @override
  String get todayLabel => '今日';

  @override
  String get totalLabel => '累計';

  @override
  String get commissionRewards => '佣金獎勵';

  @override
  String get rewardsCountLabel => '獎勵次數';

  @override
  String get rechargeRewardLabel => '充值獎勵';

  @override
  String get noData => '暫無資料';

  @override
  String get inviteesCountLabel => '邀請人數（人）';

  @override
  String get registeredAt => '註冊時間';

  @override
  String get oldPasswordHint => '請輸入舊密碼';

  @override
  String get newPasswordCannotBeSame => '新密碼不可與舊密碼相同';

  @override
  String get passwordChangeSuccess => '密碼修改成功';

  @override
  String get passwordChangeFailed => '密碼修改失敗';

  @override
  String get processing => '處理中…';

  @override
  String get videoPriceSettings => '視頻價格設定';

  @override
  String get voicePriceSettings => '語音價格設定';

  @override
  String get loadPriceFailedUsingDefaults => '讀取價格失敗，已使用預設值';

  @override
  String priceMustBeBetween(int min, int max) {
    return '價格需介於 $min ~ $max';
  }

  @override
  String enterPriceRangeHint(int min, int max) {
    return '請輸入 $min ~ $max';
  }

  @override
  String get saveSuccess => '保存成功';

  @override
  String get saveFailedTryLater => '保存失敗，請稍後再試';

  @override
  String get pleaseEnterValidNumber => '請輸入有效數字';

  @override
  String get likeDialogSubtitle => '查看對你心動的 Ta，立即聯繫不再等待';

  @override
  String get noPlansAvailable => '暫無可用方案';

  @override
  String usdPerMonth(Object amount) {
    return '$amount 美元/月';
  }

  @override
  String get purchaseVip => '購買 VIP';

  @override
  String get dataFormatError => '資料格式錯誤';

  @override
  String get uploadFailedCheckNetwork => '資料上傳失敗，請檢查網路';

  @override
  String get inviteLinkEmpty => '邀請連結為空';

  @override
  String get updateFailedCheckNetwork => '更新失敗，請確認網路連線';

  @override
  String get videoPriceTitle => '視頻價格';

  @override
  String get voicePriceTitle => '語音價格';

  @override
  String get vipAppBarTitle => 'VIP';

  @override
  String get vipCardTitle => '會員特權';

  @override
  String get vipCardSubtitle => '解鎖特權，享頂級體驗';

  @override
  String get vipNotActivated => '暫未開通';

  @override
  String get vipBestChoice => '最佳選擇';

  @override
  String get vipPrivilegesTitle => '專屬特權';

  @override
  String vipOriginalPrice(Object price) {
    return '原價 $price';
  }

  @override
  String vipPerMonth(Object amount) {
    return '$amount / 月';
  }

  @override
  String vipBuyCta(Object price, Object planTitle) {
    return '$price 美元 / 開通 $planTitle';
  }

  @override
  String get iapWarnNoProducts => 'App Store 產品資訊抓不到，請稍後再試';

  @override
  String get iapWarnNoProductId => '尚未配置 iOS productId，暫無法內購';

  @override
  String get iapUnavailable => 'App Store 不可用，請稍後再試';

  @override
  String get iapProductIdMissing => '此方案未配置 iOS productId';

  @override
  String get iapProductNotFound => '找不到 App Store 商品資訊';

  @override
  String get vipOpenSuccess => '開通成功';

  @override
  String vipOpenFailed(Object err) {
    return '開通失敗：$err';
  }

  @override
  String get androidSubComing => 'Android 訂閱即將開放';

  @override
  String loadFailed(Object err) {
    return '載入失敗：$err';
  }

  @override
  String get vipExpireSuffix => '到期';

  @override
  String get privBadgeTitle => 'VIP 尊享標識';

  @override
  String get privBadgeDesc => '點亮特權，讓你成為與眾不同的那顆心';

  @override
  String get privVisitsTitle => '訪問記錄全解鎖';

  @override
  String get privVisitsDesc => '不錯過每個喜歡你的人';

  @override
  String get privUnlimitedCallTitle => '無限制連線';

  @override
  String get privUnlimitedCallDesc => '無限連線，給你更多可能';

  @override
  String get privDirectDmTitle => '直接私聊';

  @override
  String get privDirectDmDesc => '免費無限私聊，隨時發起';

  @override
  String get privBeautyTitle => '高級美顏';

  @override
  String get privBeautyDesc => '特效更多，妝造更精緻';

  @override
  String get whoLikesMeTitle => '誰喜歡我';

  @override
  String get whoLikesMeSubtitle => '查看對你心動的 Ta，立即聯繫不再等待';

  @override
  String buyVipWithPrice(Object price) {
    return '購買 VIP（$price）';
  }

  @override
  String get planLoadFailed => '方案載入失敗';

  @override
  String get noAvailablePlans => '目前沒有可用方案';

  @override
  String get userFallback => '用戶';

  @override
  String get setupPleaseChoose => '請選擇';

  @override
  String get setupYourGender => '你的性別';

  @override
  String get setupGenderImmutable => '性別一旦設置，不可更改';

  @override
  String get setupNext => '下一步';

  @override
  String get setupSkip => '跳過';

  @override
  String get setupToastSelectGender => '請先選擇性別';

  @override
  String get setupToastSetProfileFirst => '請先設定個人資料';

  @override
  String get setupPleaseFill => '請填寫';

  @override
  String get setupYourAge => '你的年齡';

  @override
  String get setupAgeRequirement => '年齡需達到 18 歲以上，才能使用';

  @override
  String get setupAgePlaceholder => '請輸入你的年齡';

  @override
  String get setupAgeUnitYear => '歲';

  @override
  String get setupAgeToastEmpty => '請輸入你的年齡';

  @override
  String get setupAgeToastMin18 => '年齡必須大於等於 18 歲';

  @override
  String get setupYourNickname => '你的暱稱';

  @override
  String get setupNicknameSubtitle => '給自己起個暱稱吧，讓大家認識你';

  @override
  String get setupNicknamePlaceholder => '請輸入你的暱稱';

  @override
  String get setupNicknameToastEmpty => '請輸入你的暱稱';

  @override
  String setupNicknameTooLong(Object max) {
    return '暱稱長度不可超過 $max 字';
  }

  @override
  String get setupBlockBack => '請先設定個人資料';

  @override
  String get setupLastStep => '最後一步';

  @override
  String get setupYourPhoto => '你的照片';

  @override
  String get setupPhotoSubtitle => '上傳一張本人五官清晰的正面照';

  @override
  String get photoSampleClear => '無遮擋';

  @override
  String get photoSampleSmile => '記得微笑';

  @override
  String get photoSampleClearFeatures => '五官清晰';

  @override
  String get setupFinish => '完成';

  @override
  String get pickPhotoFirst => '請先選擇照片';

  @override
  String get uploadImagesOnly => '只能上傳圖片檔案';

  @override
  String uploadLimitMaxSize(Object size) {
    return '只能上傳 $size 以下的檔案';
  }

  @override
  String get pickFailedRetry => '選取失敗，請重試';

  @override
  String get netIssueRetryLater => '網路連線異常，請稍後重試';

  @override
  String get uploadFailed => '上傳失敗';

  @override
  String get userNotLoggedIn => '使用者未登入';

  @override
  String get apiErrLoginExpired => '登入已失效，請重新登入';

  @override
  String get apiErrPayloadTooLarge => '請求資料過大';

  @override
  String get apiErrUnprocessable => '參數不完整或不合法';

  @override
  String get apiErrTooManyRequests => '操作太頻繁，稍後再試';

  @override
  String get apiErrServiceGeneric => '服務異常，請稍後再試';

  @override
  String get profileHeight => '身高';

  @override
  String get profileWeight => '體重';

  @override
  String get profileMeasurements => '三圍';

  @override
  String get profileCity => '城市';

  @override
  String get profileJob => '工作';

  @override
  String get sectionFeatured => '精選';

  @override
  String get badgeFeatured => '精選';

  @override
  String get actionMessageTa => '私信TA';

  @override
  String get actionStartVideo => '發起視頻';

  @override
  String get unitCm => 'cm';

  @override
  String get unitKg => 'kg';

  @override
  String get unitLb => '磅';

  @override
  String get minute => '分鐘';

  @override
  String get coin => '金幣';

  @override
  String get free => '免費';

  @override
  String likesCount(Object n) {
    return '$n 喜歡';
  }

  @override
  String coinsPerMinute(Object n) {
    return '$n 金幣/分鐘';
  }

  @override
  String get userGeneric => '用戶';

  @override
  String get roleBroadcaster => '主播';

  @override
  String get tabMyInfo => '我的資料';

  @override
  String get tabPersonalFeed => '個人動態';

  @override
  String get emptyNoContent => '還沒有內容';

  @override
  String loadFailedWith(Object e) {
    return '載入失敗：$e';
  }

  @override
  String get walletTitle => '我的錢包';

  @override
  String get walletDetails => '明細';

  @override
  String get walletReadFail => '讀取錢包失敗';

  @override
  String get walletPacketsLoadFail => '禮包載入失敗';

  @override
  String get walletPacketsNotLoaded => '禮包尚未載入，請稍候';

  @override
  String get walletEnterIntAmountAtLeast1 => '請輸入整數金額（至少 1）';

  @override
  String get walletChoosePacketFirst => '請先選擇禮包';

  @override
  String get walletBalanceLabel => '金幣餘額';

  @override
  String get walletCustomAmount => '自定義金額';

  @override
  String get walletCustomTopup => '自定義充值';

  @override
  String get walletCustomHintAmount => '請輸入您的充值金額';

  @override
  String get walletBtnTopupNow => '立即充值';

  @override
  String walletBonusGift(Object n) {
    return '限時贈送 +$n 幣';
  }

  @override
  String get billDetailTitle => '帳單詳情';

  @override
  String get rechargeWord => '充值';

  @override
  String get coinWord => '金幣';

  @override
  String get rechargeSuccess => '充值成功';

  @override
  String get rechargeDetails => '充值詳情';

  @override
  String get rechargeCoinsLabel => '充值金幣';

  @override
  String get rechargeMethodLabel => '充值方式';

  @override
  String get paymentAccountLabel => '付款帳戶';

  @override
  String get rechargeTimeLabel => '充值時間';

  @override
  String get rechargeOrderIdLabel => '充值單號';

  @override
  String get rechargeFailedShort => '充值失敗';

  @override
  String get unknownStatus => '未知狀態';

  @override
  String get filter => '篩選';

  @override
  String get selectTransactionType => '選擇交易類型';

  @override
  String get filterAll => '全部';

  @override
  String get filterRecharge => '充值';

  @override
  String get filterSendGift => '送禮';

  @override
  String get filterReceiveGift => '收禮';

  @override
  String get filterVideoPaid => '視頻消費';

  @override
  String get filterVoicePaid => '語音消費';

  @override
  String get filterCampaign => '活動獎勵';

  @override
  String get loadFailedTapRetry => '載入失敗，點擊重試';

  @override
  String get walletNoRecords => '尚無紀錄';

  @override
  String giftToName(Object name) {
    return '贈送禮物給 $name';
  }

  @override
  String get giftSent => '贈送禮物';

  @override
  String get titleReceiveGift => '收到禮物';

  @override
  String get withdrawDetailsTitle => '提現明細';

  @override
  String get withdrawNoRecords => '目前沒有提現紀錄';

  @override
  String get noMoreData => '沒有更多';

  @override
  String withdrawToMethod(Object method) {
    return '提現到$method';
  }

  @override
  String get unknownMethod => '未知方式';

  @override
  String get withdrawTimeLabel => '提現時間';

  @override
  String get withdrawMethodLabel => '提現方式';

  @override
  String get withdrawAccountLabel => '提現帳戶';

  @override
  String get withdrawAccountNameLabel => '提現戶名';

  @override
  String get withdrawOrderIdLabel => '提現單號';

  @override
  String get statusReviewing => '審核中';

  @override
  String get statusSuccess => '成功';

  @override
  String get statusRejected => '審核拒絕';

  @override
  String get statusApproved => '審核通過';

  @override
  String get withdrawAmountLabel => '提現金額';

  @override
  String get withdrawAmountHint => '請輸入提現金額';

  @override
  String get feeLabel => '手續費：';

  @override
  String get withdrawAvailableLabel => '可提現金額：';

  @override
  String get withdrawAccountTypeLabel => '帳戶類型';

  @override
  String get withdrawAccountHint => '請輸入提現帳戶（如 PayPal Email）';

  @override
  String get withdrawAccountNameHint => '請輸入提現戶名';

  @override
  String get withdrawSubmitSuccessTitle => '提現申請已提交';

  @override
  String get withdrawSubmitSuccessDesc => '我們將在三個工作日進行審核，請耐心等待';

  @override
  String get withdrawEmptyAccountOrName => '提現帳戶與提現戶名不可為空';

  @override
  String get withdrawMinAmount1 => '提現金額最低為1元';

  @override
  String get withdrawExceedsAvailable => '提現金額大於可提現金額';

  @override
  String get paymentMethodTitle => '支付方式';

  @override
  String get payAmountTitle => '支付金額';

  @override
  String approxCoins(Object n) {
    return '≈ $n 金幣';
  }

  @override
  String get commissionAccount => '佣金帳戶';

  @override
  String availableUsd(Object amount) {
    return '可用 $amount美元';
  }

  @override
  String get appStoreBilling => 'App Store';

  @override
  String get googlePlayBilling => 'Google Play Billing';

  @override
  String rechargeFailed(Object err) {
    return '充值失敗：$err';
  }

  @override
  String get paymentMethodUnsupported => '未支援的支付方式';
}
