// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get loginWelcomeTitle => 'Welcome';

  @override
  String get loginWithFacebook => 'Sign in with Facebook';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginWithApple => 'Sign in with Apple';

  @override
  String get loginWithEmail => 'Sign in with Email';

  @override
  String get loginWithAccount => 'Sign in with Live U';

  @override
  String get consentLoginPrefix =>
      'By signing in you confirm you are 18+ and agree to our ';

  @override
  String get termsOfUse => 'Terms of Service';

  @override
  String get anchorAgreement => 'Broadcaster Agreement';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get andWord => ' and ';

  @override
  String get initializingWait => 'Initializing, please try again later';

  @override
  String get signInFailedGoogle => 'Google sign-in failed';

  @override
  String get signInFailedApple => 'Apple sign-in failed';

  @override
  String get signInFailedFacebook => 'Facebook sign-in failed';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get emailHint => 'Email address';

  @override
  String get codeHint => 'Verification code';

  @override
  String get getCode => 'Get Code';

  @override
  String get newPasswordHint => 'New password';

  @override
  String get passwordRuleTip =>
      '6–16 characters. Only numbers, letters or special characters.';

  @override
  String get confirm => 'Confirm';

  @override
  String get secondsSuffix => 's';

  @override
  String get pleaseEnterEmail => 'Please enter email';

  @override
  String get codeSent => 'Verification code sent';

  @override
  String get emailFormatError => 'Invalid email format';

  @override
  String get enterAllFields => 'Please complete all fields';

  @override
  String get passwordFormatError =>
      'Password must be 6–16 characters and contain only numbers, letters, or special characters';

  @override
  String get registerSuccess => 'Registration successful';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get resetTitle => 'Reset Password';

  @override
  String get pleaseEnterCode => 'Please enter verification code';

  @override
  String get pleaseEnterNewPassword => 'Please enter new password';

  @override
  String get passwordResetSuccess => 'Password has been reset';

  @override
  String get emailLoginTitle => 'Sign in with Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get codeLogin => 'Sign in with code';

  @override
  String get accountPasswordLogin => 'Sign in with password';

  @override
  String get otherLoginMethods => 'Other sign-in options';

  @override
  String get noAccountYet => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register now';

  @override
  String get loginSuccess => 'Signed in';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get loginFailedWrongCredentials =>
      'Sign-in failed: wrong account or password';

  @override
  String get loginFailedWrongCode => 'Sign-in failed: invalid code';

  @override
  String get loginFailedEmailFormat => 'Sign-in failed: invalid email';

  @override
  String get accountLoginTitle => 'Sign in with Account';

  @override
  String get accountHint => 'Account';

  @override
  String get pleaseEnterAccount => 'Please enter account';

  @override
  String get errUnknown => 'An unknown error occurred';

  @override
  String get errConnectionTimeout => 'Connection timed out. Please try again.';

  @override
  String get errSendTimeout => 'Send timed out. Please try again.';

  @override
  String get errReceiveTimeout => 'Receive timed out. Please try again.';

  @override
  String get errHttp404 => 'Resource not found (HTTP 404)';

  @override
  String get errHttp500 => 'Server busy (HTTP 500)';

  @override
  String get errHttpBadResponse => 'Server responded with an error';

  @override
  String get errRequestCancelled => 'Request was cancelled';

  @override
  String get errConnectionError =>
      'Network connection error. Please check your network.';

  @override
  String get errNetworkUnknown => 'A network error occurred. Please try again.';

  @override
  String get locationPleaseEnableService => 'Please enable location services';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permission permanently denied. Please enable it in Settings.';

  @override
  String get locationFetchFailed => 'Failed to get location';

  @override
  String get callTimeoutNoResponse => 'Call timed out. No response.';

  @override
  String get calleeBusy => 'User is busy';

  @override
  String get calleeOffline => 'User is offline';

  @override
  String get calleeDndOn => 'User is in Do Not Disturb';

  @override
  String get needMicCamPermission => 'Please allow microphone/camera first';

  @override
  String get micCamPermissionPermanentlyDenied =>
      'Permissions permanently denied. Please enable in Settings.';

  @override
  String get callDialFailed => 'Call failed, please try again later';

  @override
  String get peerDeclined => 'The other party declined';

  @override
  String get statusBusy => 'User is busy!';

  @override
  String get statusOffline => 'User is offline';

  @override
  String get statusConnecting => 'Connecting...';

  @override
  String get minimizeTooltip => 'Minimize';

  @override
  String get balanceNotEnough => 'Insufficient balance, please recharge';

  @override
  String get peerEndedCall => 'The other party ended the call';

  @override
  String get needMicPermission => 'Please allow microphone first';

  @override
  String get acceptFailedMissingToken => 'Accept failed: missing call token';

  @override
  String get incomingCallTitle => 'Incoming call';

  @override
  String get userWord => 'User';

  @override
  String get inviteVideoCall => 'invites you to a video call…';

  @override
  String get inviteVoiceCall => 'invites you to a voice call…';

  @override
  String get callerEndedRequest => 'The caller has ended the call request…';

  @override
  String get incomingTimeout => 'Missed call (timed out)';

  @override
  String get pleaseGrantMicCam => 'Please allow microphone and camera';

  @override
  String get pleaseGrantMic => 'Please allow microphone';

  @override
  String get minimizeScreen => 'Minimize';

  @override
  String get insufficientBalanceTopup => 'Insufficient balance. Please top up.';

  @override
  String get calleeDnd => 'User is in Do Not Disturb';

  @override
  String get homeTabTitle => 'Home';

  @override
  String get friendsTabTitle => 'Friends';

  @override
  String get publishDynamic => 'Post';

  @override
  String get fallbackUser => 'User';

  @override
  String get fallbackBroadcaster => 'Host';

  @override
  String get tagRecommended => 'Recommended';

  @override
  String get tagNewUpload => 'New';

  @override
  String get tagImage => 'Image';

  @override
  String get ratePerMinuteUnit => ' coins/min';

  @override
  String get messagesTab => 'Messages';

  @override
  String get callsTab => 'Calls';

  @override
  String loadFailedPrefix(Object err) {
    return 'Failed to load: ';
  }

  @override
  String get retry => 'Retry';

  @override
  String get networkFetchError => 'Failed to fetch data. Network error.';

  @override
  String whoLikesMeTitleCount(int n) {
    return 'Who likes me: $n new likes';
  }

  @override
  String lastUserJustLiked(Object name) {
    return '[$name] just liked you';
  }

  @override
  String get noNewLikes => 'No new likes';

  @override
  String totalUnreadMessages(int n) {
    return '$n unread messages';
  }

  @override
  String userWithId(int id) {
    return 'User $id';
  }

  @override
  String callDuration(Object mm, Object ss) {
    return 'Call duration $mm:$ss';
  }

  @override
  String get callCanceled => 'Call canceled';

  @override
  String get callNotConnected => 'Missed';

  @override
  String get missedToken => 'missed';

  @override
  String get canceledToken => 'canceled';

  @override
  String get giftLabel => 'Gift';

  @override
  String get voiceLabel => 'Voice';

  @override
  String get imageLabel => 'Image';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m min ago',
      one: '$m min ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int h) {
    String _temp0 = intl.Intl.pluralLogic(
      h,
      locale: localeName,
      other: '$h hr ago',
      one: '$h hr ago',
    );
    return '$_temp0';
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
  String get unknown => 'Unknown';

  @override
  String get vipPrivilegeTitle => 'VIP benefits';

  @override
  String get vipPrivilegeSubtitle => 'Join VIP';

  @override
  String get vipOpened => 'Subscribe';

  @override
  String get vipOpenNow => 'Open now';

  @override
  String get inviteFriends => 'Invite friends';

  @override
  String get earnCommission => 'Earn coins';

  @override
  String get inviteNow => 'Invite now';

  @override
  String get myWallet => 'Wallet';

  @override
  String get recharge => 'Top up';

  @override
  String get coinsUnit => 'coins';

  @override
  String get priceSetting => 'Price settings';

  @override
  String get whoLikesMe => 'Likes received';

  @override
  String get iLiked => 'Favorites';

  @override
  String get accountManage => 'Account management';

  @override
  String get dndMode => 'Do Not Disturb';

  @override
  String get logout => 'Log out';

  @override
  String get liveChatHint => 'Say something…';

  @override
  String giftSend(Object name) {
    return 'Sent a gift to $name';
  }

  @override
  String get tooltipMinimize => 'Minimize';

  @override
  String get tooltipClose => 'Close';

  @override
  String get freeTimeLabel => 'Free time';

  @override
  String get rechargeGo => 'Recharge';

  @override
  String get callConnectFailed => 'Call failed to connect';

  @override
  String get toggleVideoFailed => 'Failed to toggle video';

  @override
  String get switchCameraFailed => 'Failed to switch camera';

  @override
  String get notConnectedToPeer => 'Not connected to the other side yet';

  @override
  String get notLoggedIn => 'Not signed in';

  @override
  String get peerLeftChatroom => 'The other party has left the chat room';

  @override
  String get peerLeftLivestream => 'The other party has left the live room';

  @override
  String get pleaseGrantMicOnly => 'Please grant microphone permission';

  @override
  String get pleaseGrantMicAndCamera =>
      'Please grant microphone and camera permissions';

  @override
  String get freeTimeEndedStartBilling => 'Free time ended, charging started';

  @override
  String get chatEndedTitle => 'Chat ended';

  @override
  String get refresh => 'Refresh';

  @override
  String get settlingPleaseWait => 'Settling, please wait…';

  @override
  String get greatJobKeepItUp => 'Great job—keep it up!';

  @override
  String get videoDurationPrefix => 'Video duration: ';

  @override
  String get durationZeroSeconds => '0s';

  @override
  String get minuteUnit => 'min';

  @override
  String get secondUnit => 's';

  @override
  String get totalIncome => 'Total income';

  @override
  String get giftsCountLabel => 'Gift sends';

  @override
  String get videoIncome => 'Video income';

  @override
  String get voiceIncome => 'Voice income';

  @override
  String get giftIncome => 'Gift income';

  @override
  String get coinUnit => 'coins';

  @override
  String get timesUnit => 'times';

  @override
  String get stillNotSettledTapRetry => 'Still not settled? Tap to retry';

  @override
  String get onlineStatusLabel => 'Online';

  @override
  String get busyStatusLabel => 'Busy';

  @override
  String get offlineStatusLabel => 'Offline';

  @override
  String get musicAddTitle => 'Add Music';

  @override
  String get musicSearchHint => 'Search song title';

  @override
  String get musicTabRecommend => 'Recommended';

  @override
  String get musicTabFavorites => 'Favorites';

  @override
  String get musicTabUsed => 'Used';

  @override
  String get musicLoadFailedTitle => 'Load failed';

  @override
  String get musicNoContent => 'No content';

  @override
  String get useAction => 'Use';

  @override
  String get publish => 'Publish';

  @override
  String get momentHint => 'Say something...';

  @override
  String get momentHint1 => 'Say something...';

  @override
  String get editCover => 'Edit cover';

  @override
  String get selectCategory => 'Select category';

  @override
  String get categoryFeatured => 'Featured';

  @override
  String get categoryDaily => 'Daily';

  @override
  String get uploadingVideo => 'Uploading video...';

  @override
  String get uploadSuccess => 'Upload successful';

  @override
  String get uploadCanceled => 'Upload canceled';

  @override
  String get loginExpiredRelogin => 'Session expired. Please sign in again.';

  @override
  String get requestTooFrequent => 'Too many requests. Try later.';

  @override
  String get invalidParams => 'Invalid or missing parameters';

  @override
  String get serverBusyTryLater => 'Server busy, please try again later';

  @override
  String get videoUploadFailed => 'Video upload failed';

  @override
  String get coverUploadFailed => 'Cover upload failed';

  @override
  String get imageUploadFailed => 'Image upload failed';

  @override
  String get createMomentFailed => 'Create post failed';

  @override
  String get genericUploadFailed => 'Upload failed';

  @override
  String get genericError => 'An error occurred';

  @override
  String get nextStep => 'Next step';

  @override
  String get flipCamera => 'Flip';

  @override
  String get gallery => 'Gallery';

  @override
  String get modeVideo => 'Video';

  @override
  String get modeImage => 'Photo';

  @override
  String get toastAddedMusic => 'Music added';

  @override
  String get toastClearedMusic => 'Music cleared';

  @override
  String get noOtherCameraToSwitch => 'No other camera to switch';

  @override
  String get beautyNotImplemented => 'Beauty not implemented';

  @override
  String get filterNotImplemented => 'Filter not implemented';

  @override
  String get recordTooLong1Min => 'Recording must be within 1 minute';

  @override
  String get pickVideoTooLong1Min => 'Selected video must be within 1 minute';

  @override
  String get noGifts => 'No gifts';

  @override
  String get insufficientGoldNow => 'Insufficient coins!';

  @override
  String get balancePrefix => 'Balance: ';

  @override
  String get currentCoins => 'Coins: ';

  @override
  String get packetsLoadFailed => 'Failed to load packages';

  @override
  String limitedTimeBonus(int n) {
    return 'Limited-time bonus $n coins';
  }

  @override
  String get customAmount => 'Custom amount';

  @override
  String get enterRechargeAmount => 'Enter amount to top up';

  @override
  String get packetsNotReady => 'Packages not loaded yet. Please wait.';

  @override
  String get amountAtLeastOne => 'Enter at least 1';

  @override
  String get amountMustBeInteger => 'Amount must be an integer';

  @override
  String get pleaseChoosePackage => 'Please choose a package';

  @override
  String get sendFailed => 'Send failed';

  @override
  String get giftSentShort => 'Sent';

  @override
  String get dmPrefix => 'messaged you:';

  @override
  String get replyAction => 'Reply';

  @override
  String get giftShort => 'Gift';

  @override
  String get imageShort => 'Image';

  @override
  String get voiceShort => 'Voice';

  @override
  String voiceWithSeconds(int s) {
    return 'Voice ${s}s';
  }

  @override
  String get incomingGenericMessage => 'sent a message';

  @override
  String xCount(int n) {
    return 'x$n';
  }

  @override
  String get pullUpToLoadMore => 'Pull up to load more';

  @override
  String get releaseToLoadMore => 'Release to load more';

  @override
  String get loadingEllipsis => 'Loading…';

  @override
  String get oldestMessagesShown => 'Showing oldest messages';

  @override
  String get emojiLabel => 'Emoji';

  @override
  String get callLabel => 'Call';

  @override
  String get videoLabel => 'Video';

  @override
  String get inputMessageHint => 'Type a message…';

  @override
  String get send => 'Send';

  @override
  String get holdToTalk => 'Hold to talk';

  @override
  String get videoCall => 'Video call';

  @override
  String get cancel => 'Cancel';

  @override
  String get dmDailyLimitHint =>
      'You\'ve used up today\'s DMs. You can start a video call!';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get currentlyOnlineLabel => 'Online now';

  @override
  String get dnd15m => '15 min';

  @override
  String get dnd30m => '30 min';

  @override
  String get dnd1h => '1 hour';

  @override
  String get dnd6h => '6 hours';

  @override
  String get dnd12h => '12 hours';

  @override
  String get dnd24h => '24 hours';

  @override
  String get dndSetFailed => 'Update failed, please try again';

  @override
  String get dndTitle => 'Do Not Disturb';

  @override
  String get dndVideoDnd => 'Call DND';

  @override
  String get dndActiveHint =>
      'Enabled. During this time your status is set to Busy and others cannot start video chats with you.';

  @override
  String get dndInactiveHint =>
      'Pick a duration to enable DND. Others cannot start video chats with you while it’s on.';

  @override
  String get dndOffToast => 'Do Not Disturb turned off';

  @override
  String dndOnToast(Object label) {
    return 'Do Not Disturb on ($label)';
  }

  @override
  String get accountInfoTitle => 'Account info';

  @override
  String get changeAccountPassword => 'Change account password';

  @override
  String get changeEmailPassword => 'Change email password';

  @override
  String get accountManageTitle => 'Account management';

  @override
  String get accountLabel => 'Account';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailBindHint =>
      'Bind an email to receive activity updates, new features, and rewards.';

  @override
  String get statusBound => 'Linked';

  @override
  String get statusToBind => 'Not linked';

  @override
  String get addEmailTitle => 'Add email';

  @override
  String get addEmailSubtitle =>
      'Enter the email you want to associate with your account. It won\'t be shown on your public profile.';

  @override
  String get addEmailHintEmail => 'Enter email address';

  @override
  String get addEmailHintCode => 'Enter verification code';

  @override
  String get addEmailGetCode => 'Get code';

  @override
  String get addEmailConfirm => 'Confirm';

  @override
  String get addEmailToastInvalid => 'Please enter a valid email';

  @override
  String get addEmailToastNeedCode => 'Please enter the code';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonPublishMoment => 'Post';

  @override
  String get commonVideo => 'Video';

  @override
  String get commonImage => 'Image';

  @override
  String get commonContent => 'Content';

  @override
  String get commonFeatured => 'Featured';

  @override
  String get commonNoContentYet => 'No content yet';

  @override
  String get commonMyProfile => 'Profile';

  @override
  String get profileTabInfo => 'My info';

  @override
  String get profileTabMoments => 'Moments';

  @override
  String get profileAboutMe => 'About me';

  @override
  String get profileLabelHeight => 'Height';

  @override
  String get profileLabelWeight => 'Weight';

  @override
  String get profileLabelMeasurements => 'Measurements';

  @override
  String get profileLabelCity => 'City';

  @override
  String get profileLabelJob => 'Job';

  @override
  String get profileMyTags => 'My tags';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSave => 'Save';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get unitCentimeter => 'cm';

  @override
  String get unitPound => 'lb';

  @override
  String get unitYearShort => 'yrs';

  @override
  String get fieldNickname => 'Nickname';

  @override
  String get fieldGender => 'Gender';

  @override
  String get fieldBirthday => 'Birthday';

  @override
  String get fieldHeight => 'Height';

  @override
  String get fieldWeight => 'Weight';

  @override
  String get fieldMeasurements => 'Measurements';

  @override
  String get fieldCity => 'City';

  @override
  String get fieldJob => 'Job';

  @override
  String get fieldTags => 'Tags';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderSecret => 'Secret';

  @override
  String get tagsAddNow => 'Add now';

  @override
  String get tagsTitleMyTags => 'My tags';

  @override
  String get toastTagsUpdated => 'Tags updated';

  @override
  String get toastMaxFiveTags => 'You can select up to 5 tags';

  @override
  String toastUpdateFailed(Object e) {
    return 'Update failed: $e';
  }

  @override
  String get toastInvalidImageType => 'Only JPG/JPEG/PNG images are allowed';

  @override
  String get sheetTitleEnterNickname => 'Enter nickname';

  @override
  String get sheetHintEnterNickname => 'Enter nickname';

  @override
  String get toastEnterNickname => 'Please enter a nickname';

  @override
  String get toastNicknameTooLong => 'Nickname is too long';

  @override
  String get toastNicknameUpdateSuccess => 'Nickname updated';

  @override
  String toastNicknameUpdateFailed(Object e) {
    return 'Failed to update nickname: $e';
  }

  @override
  String get sheetTitleEnterHeight => 'Enter height';

  @override
  String get toastEnterValidHeight => 'Please enter a valid height';

  @override
  String get toastEnterHeightRange => 'Enter height in 1–999';

  @override
  String get toastHeightUpdateSuccess => 'Height updated';

  @override
  String toastHeightUpdateFailed(Object e) {
    return 'Failed to update height: $e';
  }

  @override
  String get sheetTitleEnterWeight => 'Enter weight';

  @override
  String get toastEnterValidWeight => 'Please enter a valid weight';

  @override
  String get toastEnterWeightRange => 'Enter weight in 1–999';

  @override
  String get toastWeightUpdateSuccess => 'Weight updated';

  @override
  String toastWeightUpdateFailed(Object e) {
    return 'Failed to update weight: $e';
  }

  @override
  String get toastAgeMustBe18 => 'You must be at least 18';

  @override
  String get toastAgeUpdateSuccess => 'Age updated';

  @override
  String toastAgeUpdateFailed(Object e) {
    return 'Failed to update age: $e';
  }

  @override
  String get sheetTitleEnterMeasurements => 'Enter measurements';

  @override
  String get bodyBust => 'Bust';

  @override
  String get bodyWaist => 'Waist';

  @override
  String get bodyHip => 'Hip';

  @override
  String get toastMeasurementsEachRange => 'Each measurement must be 1–999';

  @override
  String get toastMeasurementsUpdated => 'Measurements updated';

  @override
  String toastMeasurementsUpdateFailed(Object e) {
    return 'Failed to update measurements: $e';
  }

  @override
  String get sheetTitleEnterJob => 'Enter job';

  @override
  String get sheetHintEnterJob => 'Enter job';

  @override
  String get toastJobMax12 => 'Job can be up to 12 characters';

  @override
  String get toastJobUpdated => 'Job updated';

  @override
  String toastJobUpdateFailed(Object e) {
    return 'Failed to update job: $e';
  }

  @override
  String get monthJanuary => 'January';

  @override
  String get monthFebruary => 'February';

  @override
  String get monthMarch => 'March';

  @override
  String get monthApril => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJune => 'June';

  @override
  String get monthJuly => 'July';

  @override
  String get monthAugust => 'August';

  @override
  String get monthSeptember => 'September';

  @override
  String get monthOctober => 'October';

  @override
  String get monthNovember => 'November';

  @override
  String get monthDecember => 'December';

  @override
  String get inviteScanQrTitle => 'Scan the QR code to download';

  @override
  String get inviteScanQrSubtitle => 'Start your sweet journey now';

  @override
  String get inviteSharePoster => 'Share poster';

  @override
  String get inviteCopyLink => 'Copy link';

  @override
  String get inviteSaveImage => 'Save image';

  @override
  String get inviteCopied => 'Link copied';

  @override
  String get inviteLoadFailed => 'Load failed';

  @override
  String get inviteInvalidLink => 'Invalid link';

  @override
  String get inviteGetLinkFailed => 'Failed to get invite link';

  @override
  String get inviteSavingNotReady => 'Screen is not ready yet';

  @override
  String get inviteSavedToAlbum => 'Saved to Photos!';

  @override
  String get inviteSaveFailed => 'Save failed';

  @override
  String get shareTo => 'Share to';

  @override
  String get commonPermissionDisabled => 'Permission disabled';

  @override
  String get commonPermissionRationaleOpenSettings =>
      'Storage/Photos permission is disabled. Please enable it in Settings.';

  @override
  String get commonGoToSettings => 'Open Settings';

  @override
  String get messengerNotInstalled => 'Messenger is not installed';

  @override
  String get inviteEarnCashShort => 'Earn cash';

  @override
  String get inviteOnceLifetime => '- Invite once, earn for life -';

  @override
  String inviteCommissionDesc(Object percent) {
    return 'Earn $percent of each friend’s top-up amount';
  }

  @override
  String get myInvites => 'My invites';

  @override
  String get inviteEasyEarn => '·Earn with ease·';

  @override
  String get likedEmptyHint => 'No liked users yet';

  @override
  String get toastGiftSent => 'Gift sent!';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get myInvitesTitle => 'My invites';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get totalCommissionReward => 'Total commission rewards';

  @override
  String get withdrawableAmount => 'Withdrawable amount';

  @override
  String get tabMyRewards => 'My rewards';

  @override
  String get tabInvitees => 'Invitees';

  @override
  String get todayLabel => 'Today';

  @override
  String get totalLabel => 'Total';

  @override
  String get commissionRewards => 'Commission rewards';

  @override
  String get rewardsCountLabel => 'Rewards count';

  @override
  String get rechargeRewardLabel => 'Top-up reward';

  @override
  String get noData => 'No data';

  @override
  String get inviteesCountLabel => 'Invitees';

  @override
  String get registeredAt => 'Registered at';

  @override
  String get oldPasswordHint => 'Old password';

  @override
  String get newPasswordCannotBeSame =>
      'New password must differ from old password';

  @override
  String get passwordChangeSuccess => 'Password updated';

  @override
  String get passwordChangeFailed => 'Failed to update password';

  @override
  String get processing => 'Processing…';

  @override
  String get videoPriceSettings => 'Video price settings';

  @override
  String get voicePriceSettings => 'Voice price settings';

  @override
  String get loadPriceFailedUsingDefaults =>
      'Failed to load prices; using defaults';

  @override
  String priceMustBeBetween(int min, int max) {
    return 'Price must be between $min and $max';
  }

  @override
  String enterPriceRangeHint(int min, int max) {
    return 'Enter $min–$max';
  }

  @override
  String get saveSuccess => 'Saved';

  @override
  String get saveFailedTryLater => 'Save failed, please try again later';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get likeDialogSubtitle => 'See who\'s into you—message instantly';

  @override
  String get noPlansAvailable => 'No plans available';

  @override
  String usdPerMonth(Object amount) {
    return '$amount USD/month';
  }

  @override
  String get purchaseVip => 'Buy VIP';

  @override
  String get dataFormatError => 'Invalid data format';

  @override
  String get uploadFailedCheckNetwork =>
      'Upload failed, please check your network';

  @override
  String get inviteLinkEmpty => 'Invite link is empty';

  @override
  String get updateFailedCheckNetwork =>
      'Update failed, please check your network connection';

  @override
  String get videoPriceTitle => 'Video price';

  @override
  String get voicePriceTitle => 'Voice price';

  @override
  String get vipAppBarTitle => 'VIP';

  @override
  String get vipCardTitle => 'Membership perks';

  @override
  String get vipCardSubtitle => 'Unlock perks for a premium experience';

  @override
  String get vipNotActivated => 'Not activated';

  @override
  String get vipBestChoice => 'Best value';

  @override
  String get vipPrivilegesTitle => 'Exclusive perks';

  @override
  String vipOriginalPrice(Object price) {
    return 'Was $price';
  }

  @override
  String vipPerMonth(Object amount) {
    return '$amount / mo';
  }

  @override
  String vipBuyCta(Object price, Object planTitle) {
    return '$price USD / Activate $planTitle';
  }

  @override
  String get iapWarnNoProducts =>
      'App Store product info not available. Please try again later.';

  @override
  String get iapWarnNoProductId =>
      'iOS productId not configured; IAP unavailable';

  @override
  String get iapUnavailable => 'App Store unavailable, please try again later';

  @override
  String get iapProductIdMissing => 'No iOS productId configured for this plan';

  @override
  String get iapProductNotFound => 'App Store product not found';

  @override
  String get vipOpenSuccess => 'Activated successfully';

  @override
  String vipOpenFailed(Object err) {
    return 'Activation failed: $err';
  }

  @override
  String get androidSubComing => 'Android subscription coming soon';

  @override
  String loadFailed(Object err) {
    return 'Failed to load: $err';
  }

  @override
  String get vipExpireSuffix => 'expires';

  @override
  String get privBadgeTitle => 'VIP Badge';

  @override
  String get privBadgeDesc => 'Stand out with a VIP badge';

  @override
  String get privVisitsTitle => 'All visit history';

  @override
  String get privVisitsDesc => 'Never miss who liked you';

  @override
  String get privUnlimitedCallTitle => 'Unlimited calls';

  @override
  String get privUnlimitedCallDesc => 'Endless connections, more chances';

  @override
  String get privDirectDmTitle => 'Direct messaging';

  @override
  String get privDirectDmDesc => 'Unlimited private chat anytime';

  @override
  String get privBeautyTitle => 'Advanced beauty effects';

  @override
  String get privBeautyDesc => 'More effects, better looks';

  @override
  String get whoLikesMeTitle => 'Who liked me';

  @override
  String get whoLikesMeSubtitle => 'See who’s into you—reach out instantly';

  @override
  String buyVipWithPrice(Object price) {
    return 'Buy VIP ($price)';
  }

  @override
  String get planLoadFailed => 'Failed to load plans';

  @override
  String get noAvailablePlans => 'No plans available';

  @override
  String get userFallback => 'User';

  @override
  String get setupPleaseChoose => 'Please choose';

  @override
  String get setupYourGender => 'Your gender';

  @override
  String get setupGenderImmutable => 'Once set, gender cannot be changed';

  @override
  String get setupNext => 'Next';

  @override
  String get setupSkip => 'Skip';

  @override
  String get setupToastSelectGender => 'Please select a gender first';

  @override
  String get setupToastSetProfileFirst => 'Please complete your profile first';

  @override
  String get setupPleaseFill => 'Please fill in';

  @override
  String get setupYourAge => 'Your age';

  @override
  String get setupAgeRequirement => 'You must be at least 18 to use this app';

  @override
  String get setupAgePlaceholder => 'Enter your age';

  @override
  String get setupAgeUnitYear => 'yr';

  @override
  String get setupAgeToastEmpty => 'Please enter your age';

  @override
  String get setupAgeToastMin18 => 'Age must be 18 or older';

  @override
  String get setupYourNickname => 'Your nickname';

  @override
  String get setupNicknameSubtitle => 'Pick a nickname so others know you';

  @override
  String get setupNicknamePlaceholder => 'Enter your nickname';

  @override
  String get setupNicknameToastEmpty => 'Please enter your nickname';

  @override
  String setupNicknameTooLong(Object max) {
    return 'Nickname must be ≤ $max chars';
  }

  @override
  String get setupBlockBack => 'Please finish your profile first';

  @override
  String get setupLastStep => 'Final step';

  @override
  String get setupYourPhoto => 'Your photo';

  @override
  String get setupPhotoSubtitle =>
      'Upload a clear, front-facing photo of yourself';

  @override
  String get photoSampleClear => 'No obstruction';

  @override
  String get photoSampleSmile => 'Remember to smile';

  @override
  String get photoSampleClearFeatures => 'Clear facial features';

  @override
  String get setupFinish => 'Finish';

  @override
  String get pickPhotoFirst => 'Please select a photo first';

  @override
  String get uploadImagesOnly => 'Images only';

  @override
  String uploadLimitMaxSize(Object size) {
    return 'Files must be under $size';
  }

  @override
  String get pickFailedRetry => 'Selection failed, please retry';

  @override
  String get netIssueRetryLater => 'Network error, please try again later';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get userNotLoggedIn => 'User not logged in';

  @override
  String get apiErrLoginExpired => 'Session expired, please sign in again';

  @override
  String get apiErrPayloadTooLarge => 'Payload too large';

  @override
  String get apiErrUnprocessable => 'Invalid or incomplete parameters';

  @override
  String get apiErrTooManyRequests => 'Too many requests, try again later';

  @override
  String get apiErrServiceGeneric => 'Service error, please try again later';

  @override
  String get profileHeight => 'Height';

  @override
  String get profileWeight => 'Weight';

  @override
  String get profileMeasurements => 'Measurements';

  @override
  String get profileCity => 'City';

  @override
  String get profileJob => 'Job';

  @override
  String get sectionFeatured => 'Featured';

  @override
  String get badgeFeatured => 'Featured';

  @override
  String get actionMessageTa => 'Message';

  @override
  String get actionStartVideo => 'Start video call';

  @override
  String get unitCm => 'cm';

  @override
  String get unitKg => 'kg';

  @override
  String get unitLb => 'lb';

  @override
  String get minute => 'min';

  @override
  String get coin => 'coins';

  @override
  String get free => 'Free';

  @override
  String likesCount(Object n) {
    return '$n Likes';
  }

  @override
  String coinsPerMinute(Object n) {
    return '$n coins/min';
  }

  @override
  String get userGeneric => 'User';

  @override
  String get roleBroadcaster => 'Broadcaster';

  @override
  String get tabMyInfo => 'Profile';

  @override
  String get tabPersonalFeed => 'Posts';

  @override
  String get emptyNoContent => 'No content yet';

  @override
  String loadFailedWith(Object e) {
    return 'Load failed: $e';
  }

  @override
  String get walletTitle => 'My Wallet';

  @override
  String get walletDetails => 'Details';

  @override
  String get walletReadFail => 'Failed to load wallet';

  @override
  String get walletPacketsLoadFail => 'Failed to load packs';

  @override
  String get walletPacketsNotLoaded => 'Packs not loaded yet';

  @override
  String get walletEnterIntAmountAtLeast1 => 'Enter an integer (min 1)';

  @override
  String get walletChoosePacketFirst => 'Please select a pack';

  @override
  String get walletBalanceLabel => 'Coin balance';

  @override
  String get walletCustomAmount => 'Custom amount';

  @override
  String get walletCustomTopup => 'Custom top-up';

  @override
  String get walletCustomHintAmount => 'Enter your top-up amount';

  @override
  String get walletBtnTopupNow => 'Top up now';

  @override
  String walletBonusGift(Object n) {
    return 'Limited bonus +$n coins';
  }

  @override
  String get billDetailTitle => 'Bill details';

  @override
  String get rechargeWord => 'Top-up';

  @override
  String get coinWord => 'Coins';

  @override
  String get rechargeSuccess => 'Top-up successful';

  @override
  String get rechargeDetails => 'Top-up details';

  @override
  String get rechargeCoinsLabel => 'Top-up coins';

  @override
  String get rechargeMethodLabel => 'Top-up method';

  @override
  String get paymentAccountLabel => 'Payment account';

  @override
  String get rechargeTimeLabel => 'Top-up time';

  @override
  String get rechargeOrderIdLabel => 'Top-up order ID';

  @override
  String get rechargeFailedShort => 'Top-up failed';

  @override
  String get unknownStatus => 'Unknown status';

  @override
  String get filter => 'Filter';

  @override
  String get selectTransactionType => 'Choose transaction type';

  @override
  String get filterAll => 'All';

  @override
  String get filterRecharge => 'Top up';

  @override
  String get filterSendGift => 'Send gift';

  @override
  String get filterReceiveGift => 'Receive gift';

  @override
  String get filterVideoPaid => 'Video call cost';

  @override
  String get filterVoicePaid => 'Voice call cost';

  @override
  String get filterCampaign => 'Campaign reward';

  @override
  String get loadFailedTapRetry => 'Load failed, tap to retry';

  @override
  String get walletNoRecords => 'No records yet';

  @override
  String giftToName(Object name) {
    return 'Gift to $name';
  }

  @override
  String get giftSent => 'Gift sent';

  @override
  String get titleReceiveGift => 'Received gift';

  @override
  String get withdrawDetailsTitle => 'Withdrawal details';

  @override
  String get withdrawNoRecords => 'No withdrawal records yet';

  @override
  String get noMoreData => 'No more';

  @override
  String withdrawToMethod(Object method) {
    return 'Withdraw to $method';
  }

  @override
  String get unknownMethod => 'Unknown method';

  @override
  String get withdrawTimeLabel => 'Withdrawal time';

  @override
  String get withdrawMethodLabel => 'Withdrawal method';

  @override
  String get withdrawAccountLabel => 'Withdrawal account';

  @override
  String get withdrawAccountNameLabel => 'Account name';

  @override
  String get withdrawOrderIdLabel => 'Withdrawal ID';

  @override
  String get statusReviewing => 'Under review';

  @override
  String get statusSuccess => 'Successful';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusApproved => 'Approved';

  @override
  String get withdrawAmountLabel => 'Withdraw amount';

  @override
  String get withdrawAmountHint => 'Enter withdrawal amount';

  @override
  String get feeLabel => 'Fee: ';

  @override
  String get withdrawAvailableLabel => 'Withdrawable: ';

  @override
  String get withdrawAccountTypeLabel => 'Account type';

  @override
  String get withdrawAccountHint => 'Enter payout account (e.g., PayPal email)';

  @override
  String get withdrawAccountNameHint => 'Enter account name';

  @override
  String get withdrawSubmitSuccessTitle => 'Withdrawal request submitted';

  @override
  String get withdrawSubmitSuccessDesc =>
      'We’ll review within 3 business days. Please wait.';

  @override
  String get withdrawEmptyAccountOrName =>
      'Withdrawal account and name cannot be empty';

  @override
  String get withdrawMinAmount1 => 'Minimum withdrawal is 1';

  @override
  String get withdrawExceedsAvailable =>
      'Withdrawal amount exceeds available amount';

  @override
  String get paymentMethodTitle => 'Payment method';

  @override
  String get payAmountTitle => 'Payment amount';

  @override
  String approxCoins(Object n) {
    return '≈ $n coins';
  }

  @override
  String get commissionAccount => 'Commission account';

  @override
  String availableUsd(Object amount) {
    return 'Available $amount USD';
  }

  @override
  String get appStoreBilling => 'App Store';

  @override
  String get googlePlayBilling => 'Google Play Billing';

  @override
  String rechargeFailed(Object err) {
    return 'Top-up failed: $err';
  }

  @override
  String get paymentMethodUnsupported => 'Unsupported payment method';
}
