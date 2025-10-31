import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Facebook'**
  String get loginWithFacebook;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get loginWithApple;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get loginWithEmail;

  /// No description provided for @loginWithAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Account'**
  String get loginWithAccount;

  /// No description provided for @consentLoginPrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing in you confirm you are 18+ and agree to our '**
  String get consentLoginPrefix;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfUse;

  /// No description provided for @anchorAgreement.
  ///
  /// In en, this message translates to:
  /// **'Broadcaster Agreement'**
  String get anchorAgreement;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andWord;

  /// No description provided for @initializingWait.
  ///
  /// In en, this message translates to:
  /// **'Initializing, please try again later'**
  String get initializingWait;

  /// No description provided for @signInFailedGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get signInFailedGoogle;

  /// No description provided for @signInFailedApple.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed'**
  String get signInFailedApple;

  /// No description provided for @signInFailedFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook sign-in failed'**
  String get signInFailedFacebook;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailHint;

  /// No description provided for @codeHint.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get codeHint;

  /// No description provided for @getCode.
  ///
  /// In en, this message translates to:
  /// **'Get Code'**
  String get getCode;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordHint;

  /// No description provided for @passwordRuleTip.
  ///
  /// In en, this message translates to:
  /// **'6–16 characters. Only numbers, letters or special characters.'**
  String get passwordRuleTip;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @secondsSuffix.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondsSuffix;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get pleaseEnterEmail;

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent'**
  String get codeSent;

  /// No description provided for @emailFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get emailFormatError;

  /// No description provided for @enterAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields'**
  String get enterAllFields;

  /// No description provided for @passwordFormatError.
  ///
  /// In en, this message translates to:
  /// **'Password must be 6–16 characters and contain only numbers, letters, or special characters'**
  String get passwordFormatError;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registerSuccess;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetTitle;

  /// No description provided for @pleaseEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter verification code'**
  String get pleaseEnterCode;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter new password'**
  String get pleaseEnterNewPassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password has been reset'**
  String get passwordResetSuccess;

  /// No description provided for @emailLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get emailLoginTitle;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @codeLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with code'**
  String get codeLogin;

  /// No description provided for @accountPasswordLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get accountPasswordLogin;

  /// No description provided for @otherLoginMethods.
  ///
  /// In en, this message translates to:
  /// **'Other sign-in options'**
  String get otherLoginMethods;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountYet;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get registerNow;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get loginSuccess;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @loginFailedWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: wrong account or password'**
  String get loginFailedWrongCredentials;

  /// No description provided for @loginFailedWrongCode.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: invalid code'**
  String get loginFailedWrongCode;

  /// No description provided for @loginFailedEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: invalid email'**
  String get loginFailedEmailFormat;

  /// No description provided for @accountLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Account'**
  String get accountLoginTitle;

  /// No description provided for @accountHint.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountHint;

  /// No description provided for @pleaseEnterAccount.
  ///
  /// In en, this message translates to:
  /// **'Please enter account'**
  String get pleaseEnterAccount;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get errUnknown;

  /// No description provided for @errConnectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please try again.'**
  String get errConnectionTimeout;

  /// No description provided for @errSendTimeout.
  ///
  /// In en, this message translates to:
  /// **'Send timed out. Please try again.'**
  String get errSendTimeout;

  /// No description provided for @errReceiveTimeout.
  ///
  /// In en, this message translates to:
  /// **'Receive timed out. Please try again.'**
  String get errReceiveTimeout;

  /// No description provided for @errHttp404.
  ///
  /// In en, this message translates to:
  /// **'Resource not found (HTTP 404)'**
  String get errHttp404;

  /// No description provided for @errHttp500.
  ///
  /// In en, this message translates to:
  /// **'Server busy (HTTP 500)'**
  String get errHttp500;

  /// No description provided for @errHttpBadResponse.
  ///
  /// In en, this message translates to:
  /// **'Server responded with an error'**
  String get errHttpBadResponse;

  /// No description provided for @errRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request was cancelled'**
  String get errRequestCancelled;

  /// No description provided for @errConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Network connection error. Please check your network.'**
  String get errConnectionError;

  /// No description provided for @errNetworkUnknown.
  ///
  /// In en, this message translates to:
  /// **'A network error occurred. Please try again.'**
  String get errNetworkUnknown;

  /// No description provided for @locationPleaseEnableService.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services'**
  String get locationPleaseEnableService;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Please enable it in Settings.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @locationFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get locationFetchFailed;

  /// No description provided for @callTimeoutNoResponse.
  ///
  /// In en, this message translates to:
  /// **'Call timed out. No response.'**
  String get callTimeoutNoResponse;

  /// No description provided for @calleeBusy.
  ///
  /// In en, this message translates to:
  /// **'User is busy'**
  String get calleeBusy;

  /// No description provided for @calleeOffline.
  ///
  /// In en, this message translates to:
  /// **'User is offline'**
  String get calleeOffline;

  /// No description provided for @calleeDndOn.
  ///
  /// In en, this message translates to:
  /// **'User is in Do Not Disturb'**
  String get calleeDndOn;

  /// No description provided for @needMicCamPermission.
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone/camera first'**
  String get needMicCamPermission;

  /// No description provided for @micCamPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permissions permanently denied. Please enable in Settings.'**
  String get micCamPermissionPermanentlyDenied;

  /// No description provided for @callDialFailed.
  ///
  /// In en, this message translates to:
  /// **'Call failed, please try again later'**
  String get callDialFailed;

  /// No description provided for @peerDeclined.
  ///
  /// In en, this message translates to:
  /// **'The other party declined'**
  String get peerDeclined;

  /// No description provided for @statusBusy.
  ///
  /// In en, this message translates to:
  /// **'User is busy!'**
  String get statusBusy;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'User is offline'**
  String get statusOffline;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get statusConnecting;

  /// No description provided for @minimizeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimizeTooltip;

  /// No description provided for @balanceNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance, please recharge'**
  String get balanceNotEnough;

  /// No description provided for @peerEndedCall.
  ///
  /// In en, this message translates to:
  /// **'The other party ended the call'**
  String get peerEndedCall;

  /// No description provided for @needMicPermission.
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone first'**
  String get needMicPermission;

  /// No description provided for @acceptFailedMissingToken.
  ///
  /// In en, this message translates to:
  /// **'Accept failed: missing call token'**
  String get acceptFailedMissingToken;

  /// No description provided for @incomingCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get incomingCallTitle;

  /// No description provided for @userWord.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userWord;

  /// No description provided for @inviteVideoCall.
  ///
  /// In en, this message translates to:
  /// **'invites you to a video call…'**
  String get inviteVideoCall;

  /// No description provided for @inviteVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'invites you to a voice call…'**
  String get inviteVoiceCall;

  /// No description provided for @callerEndedRequest.
  ///
  /// In en, this message translates to:
  /// **'The caller has ended the call request…'**
  String get callerEndedRequest;

  /// No description provided for @incomingTimeout.
  ///
  /// In en, this message translates to:
  /// **'Missed call (timed out)'**
  String get incomingTimeout;

  /// No description provided for @pleaseGrantMicCam.
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone and camera'**
  String get pleaseGrantMicCam;

  /// No description provided for @pleaseGrantMic.
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone'**
  String get pleaseGrantMic;

  /// No description provided for @minimizeScreen.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimizeScreen;

  /// No description provided for @insufficientBalanceTopup.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance. Please top up.'**
  String get insufficientBalanceTopup;

  /// No description provided for @calleeDnd.
  ///
  /// In en, this message translates to:
  /// **'User is in Do Not Disturb'**
  String get calleeDnd;

  /// No description provided for @homeTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTabTitle;

  /// No description provided for @friendsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTabTitle;

  /// No description provided for @fallbackUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get fallbackUser;

  /// No description provided for @fallbackBroadcaster.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get fallbackBroadcaster;

  /// No description provided for @tagRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get tagRecommended;

  /// No description provided for @tagNewUpload.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get tagNewUpload;

  /// No description provided for @tagImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get tagImage;

  /// No description provided for @ratePerMinuteUnit.
  ///
  /// In en, this message translates to:
  /// **' coins/min'**
  String get ratePerMinuteUnit;

  /// No description provided for @messagesTab.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTab;

  /// No description provided for @callsTab.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get callsTab;

  /// No description provided for @loadFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: '**
  String loadFailedPrefix(Object err);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @networkFetchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch data. Network error.'**
  String get networkFetchError;

  /// No description provided for @whoLikesMeTitleCount.
  ///
  /// In en, this message translates to:
  /// **'Who likes me: {n} new likes'**
  String whoLikesMeTitleCount(int n);

  /// No description provided for @lastUserJustLiked.
  ///
  /// In en, this message translates to:
  /// **'[{name}] just liked you'**
  String lastUserJustLiked(Object name);

  /// No description provided for @noNewLikes.
  ///
  /// In en, this message translates to:
  /// **'No new likes'**
  String get noNewLikes;

  /// No description provided for @totalUnreadMessages.
  ///
  /// In en, this message translates to:
  /// **'{n} unread messages'**
  String totalUnreadMessages(int n);

  /// No description provided for @userWithId.
  ///
  /// In en, this message translates to:
  /// **'User {id}'**
  String userWithId(int id);

  /// No description provided for @callDuration.
  ///
  /// In en, this message translates to:
  /// **'Call duration {mm}:{ss}'**
  String callDuration(Object mm, Object ss);

  /// No description provided for @callCanceled.
  ///
  /// In en, this message translates to:
  /// **'Call canceled'**
  String get callCanceled;

  /// No description provided for @callNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get callNotConnected;

  /// No description provided for @missedToken.
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get missedToken;

  /// No description provided for @canceledToken.
  ///
  /// In en, this message translates to:
  /// **'canceled'**
  String get canceledToken;

  /// No description provided for @giftLabel.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get giftLabel;

  /// No description provided for @voiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceLabel;

  /// No description provided for @imageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageLabel;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{m, plural, one {{m} min ago} other {{m} min ago}}'**
  String minutesAgo(int m);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{h, plural, one {{h} hr ago} other {{h} hr ago}}'**
  String hoursAgo(int h);

  /// No description provided for @dateYmd.
  ///
  /// In en, this message translates to:
  /// **'{year}/{month}/{day}'**
  String dateYmd(int year, int month, int day);

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String idLabel(Object id);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @vipPrivilegeTitle.
  ///
  /// In en, this message translates to:
  /// **'VIP benefits'**
  String get vipPrivilegeTitle;

  /// No description provided for @vipPrivilegeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join VIP'**
  String get vipPrivilegeSubtitle;

  /// No description provided for @vipOpened.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get vipOpened;

  /// No description provided for @vipOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get vipOpenNow;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteFriends;

  /// No description provided for @earnCommission.
  ///
  /// In en, this message translates to:
  /// **'Earn coins'**
  String get earnCommission;

  /// No description provided for @inviteNow.
  ///
  /// In en, this message translates to:
  /// **'Invite now'**
  String get inviteNow;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get myWallet;

  /// No description provided for @recharge.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get recharge;

  /// No description provided for @coinsUnit.
  ///
  /// In en, this message translates to:
  /// **'coins'**
  String get coinsUnit;

  /// No description provided for @priceSetting.
  ///
  /// In en, this message translates to:
  /// **'Price settings'**
  String get priceSetting;

  /// No description provided for @whoLikesMe.
  ///
  /// In en, this message translates to:
  /// **'Likes received'**
  String get whoLikesMe;

  /// No description provided for @iLiked.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get iLiked;

  /// No description provided for @accountManage.
  ///
  /// In en, this message translates to:
  /// **'Account management'**
  String get accountManage;

  /// No description provided for @dndMode.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get dndMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @liveChatHint.
  ///
  /// In en, this message translates to:
  /// **'Say something…'**
  String get liveChatHint;

  /// No description provided for @giftSend.
  ///
  /// In en, this message translates to:
  /// **'Sent a gift to {name}'**
  String giftSend(Object name);

  /// No description provided for @tooltipMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get tooltipMinimize;

  /// No description provided for @tooltipClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tooltipClose;

  /// No description provided for @freeTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free time'**
  String get freeTimeLabel;

  /// No description provided for @rechargeGo.
  ///
  /// In en, this message translates to:
  /// **'Recharge'**
  String get rechargeGo;

  /// No description provided for @callConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Call failed to connect'**
  String get callConnectFailed;

  /// No description provided for @toggleVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle video'**
  String get toggleVideoFailed;

  /// No description provided for @switchCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to switch camera'**
  String get switchCameraFailed;

  /// No description provided for @notConnectedToPeer.
  ///
  /// In en, this message translates to:
  /// **'Not connected to the other side yet'**
  String get notConnectedToPeer;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notLoggedIn;

  /// No description provided for @peerLeftChatroom.
  ///
  /// In en, this message translates to:
  /// **'The other party has left the chat room'**
  String get peerLeftChatroom;

  /// No description provided for @peerLeftLivestream.
  ///
  /// In en, this message translates to:
  /// **'The other party has left the live room'**
  String get peerLeftLivestream;

  /// No description provided for @pleaseGrantMicOnly.
  ///
  /// In en, this message translates to:
  /// **'Please grant microphone permission'**
  String get pleaseGrantMicOnly;

  /// No description provided for @pleaseGrantMicAndCamera.
  ///
  /// In en, this message translates to:
  /// **'Please grant microphone and camera permissions'**
  String get pleaseGrantMicAndCamera;

  /// No description provided for @freeTimeEndedStartBilling.
  ///
  /// In en, this message translates to:
  /// **'Free time ended, charging started'**
  String get freeTimeEndedStartBilling;

  /// No description provided for @countdownRechargeHint.
  ///
  /// In en, this message translates to:
  /// **'Less than {sec} seconds remaining. Please recharge soon.'**
  String countdownRechargeHint(int sec);

  /// No description provided for @chatEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat ended'**
  String get chatEndedTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @settlingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Settling, please wait…'**
  String get settlingPleaseWait;

  /// No description provided for @greatJobKeepItUp.
  ///
  /// In en, this message translates to:
  /// **'Great job—keep it up!'**
  String get greatJobKeepItUp;

  /// No description provided for @videoDurationPrefix.
  ///
  /// In en, this message translates to:
  /// **'Video duration: '**
  String get videoDurationPrefix;

  /// No description provided for @durationZeroSeconds.
  ///
  /// In en, this message translates to:
  /// **'0s'**
  String get durationZeroSeconds;

  /// No description provided for @minuteUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minuteUnit;

  /// No description provided for @secondUnit.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondUnit;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get totalIncome;

  /// No description provided for @giftsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Gift sends'**
  String get giftsCountLabel;

  /// No description provided for @videoIncome.
  ///
  /// In en, this message translates to:
  /// **'Video income'**
  String get videoIncome;

  /// No description provided for @voiceIncome.
  ///
  /// In en, this message translates to:
  /// **'Voice income'**
  String get voiceIncome;

  /// No description provided for @giftIncome.
  ///
  /// In en, this message translates to:
  /// **'Gift income'**
  String get giftIncome;

  /// No description provided for @coinUnit.
  ///
  /// In en, this message translates to:
  /// **'coins'**
  String get coinUnit;

  /// No description provided for @timesUnit.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get timesUnit;

  /// No description provided for @stillNotSettledTapRetry.
  ///
  /// In en, this message translates to:
  /// **'Still not settled? Tap to retry'**
  String get stillNotSettledTapRetry;

  /// No description provided for @onlineStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatusLabel;

  /// No description provided for @busyStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get busyStatusLabel;

  /// No description provided for @offlineStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineStatusLabel;

  /// No description provided for @musicAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Music'**
  String get musicAddTitle;

  /// No description provided for @musicSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search song title'**
  String get musicSearchHint;

  /// No description provided for @musicTabRecommend.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get musicTabRecommend;

  /// No description provided for @musicTabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get musicTabFavorites;

  /// No description provided for @musicTabUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get musicTabUsed;

  /// No description provided for @musicLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get musicLoadFailedTitle;

  /// No description provided for @musicNoContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get musicNoContent;

  /// No description provided for @useAction.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useAction;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @momentHint.
  ///
  /// In en, this message translates to:
  /// **'Say something...'**
  String get momentHint;

  /// No description provided for @momentHint1.
  ///
  /// In en, this message translates to:
  /// **'Say something...'**
  String get momentHint1;

  /// No description provided for @editCover.
  ///
  /// In en, this message translates to:
  /// **'Edit cover'**
  String get editCover;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @categoryFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get categoryFeatured;

  /// No description provided for @categoryDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get categoryDaily;

  /// No description provided for @uploadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Uploading video...'**
  String get uploadingVideo;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Upload successful'**
  String get uploadSuccess;

  /// No description provided for @uploadCanceled.
  ///
  /// In en, this message translates to:
  /// **'Upload canceled'**
  String get uploadCanceled;

  /// No description provided for @loginExpiredRelogin.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get loginExpiredRelogin;

  /// No description provided for @requestTooFrequent.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try later.'**
  String get requestTooFrequent;

  /// No description provided for @invalidParams.
  ///
  /// In en, this message translates to:
  /// **'Invalid or missing parameters'**
  String get invalidParams;

  /// No description provided for @serverBusyTryLater.
  ///
  /// In en, this message translates to:
  /// **'Server busy, please try again later'**
  String get serverBusyTryLater;

  /// No description provided for @videoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Video upload failed'**
  String get videoUploadFailed;

  /// No description provided for @coverUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cover upload failed'**
  String get coverUploadFailed;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get imageUploadFailed;

  /// No description provided for @createMomentFailed.
  ///
  /// In en, this message translates to:
  /// **'Create post failed'**
  String get createMomentFailed;

  /// No description provided for @genericUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get genericUploadFailed;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get genericError;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// No description provided for @flipCamera.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get flipCamera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @modeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get modeVideo;

  /// No description provided for @modeImage.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get modeImage;

  /// No description provided for @toastAddedMusic.
  ///
  /// In en, this message translates to:
  /// **'Music added'**
  String get toastAddedMusic;

  /// No description provided for @toastClearedMusic.
  ///
  /// In en, this message translates to:
  /// **'Music cleared'**
  String get toastClearedMusic;

  /// No description provided for @noOtherCameraToSwitch.
  ///
  /// In en, this message translates to:
  /// **'No other camera to switch'**
  String get noOtherCameraToSwitch;

  /// No description provided for @beautyNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Beauty not implemented'**
  String get beautyNotImplemented;

  /// No description provided for @filterNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Filter not implemented'**
  String get filterNotImplemented;

  /// No description provided for @recordTooLong1Min.
  ///
  /// In en, this message translates to:
  /// **'Recording must be within 1 minute'**
  String get recordTooLong1Min;

  /// No description provided for @pickVideoTooLong1Min.
  ///
  /// In en, this message translates to:
  /// **'Selected video must be within 1 minute'**
  String get pickVideoTooLong1Min;

  /// No description provided for @noGifts.
  ///
  /// In en, this message translates to:
  /// **'No gifts'**
  String get noGifts;

  /// No description provided for @insufficientGoldNow.
  ///
  /// In en, this message translates to:
  /// **'Insufficient coins!'**
  String get insufficientGoldNow;

  /// No description provided for @balancePrefix.
  ///
  /// In en, this message translates to:
  /// **'Balance: '**
  String get balancePrefix;

  /// No description provided for @currentCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins: '**
  String get currentCoins;

  /// No description provided for @packetsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load packages'**
  String get packetsLoadFailed;

  /// No description provided for @limitedTimeBonus.
  ///
  /// In en, this message translates to:
  /// **'Limited-time bonus {n} coins'**
  String limitedTimeBonus(int n);

  /// No description provided for @customAmount.
  ///
  /// In en, this message translates to:
  /// **'Custom amount'**
  String get customAmount;

  /// No description provided for @enterRechargeAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount to top up'**
  String get enterRechargeAmount;

  /// No description provided for @packetsNotReady.
  ///
  /// In en, this message translates to:
  /// **'Packages not loaded yet. Please wait.'**
  String get packetsNotReady;

  /// No description provided for @amountAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 1'**
  String get amountAtLeastOne;

  /// No description provided for @amountMustBeInteger.
  ///
  /// In en, this message translates to:
  /// **'Amount must be an integer'**
  String get amountMustBeInteger;

  /// No description provided for @pleaseChoosePackage.
  ///
  /// In en, this message translates to:
  /// **'Please choose a package'**
  String get pleaseChoosePackage;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get sendFailed;

  /// No description provided for @giftSentShort.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get giftSentShort;

  /// No description provided for @dmPrefix.
  ///
  /// In en, this message translates to:
  /// **'messaged you:'**
  String get dmPrefix;

  /// No description provided for @replyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyAction;

  /// No description provided for @giftShort.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get giftShort;

  /// No description provided for @imageShort.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageShort;

  /// No description provided for @voiceShort.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceShort;

  /// No description provided for @voiceWithSeconds.
  ///
  /// In en, this message translates to:
  /// **'Voice {s}s'**
  String voiceWithSeconds(int s);

  /// No description provided for @incomingGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'sent a message'**
  String get incomingGenericMessage;

  /// No description provided for @xCount.
  ///
  /// In en, this message translates to:
  /// **'x{n}'**
  String xCount(int n);

  /// No description provided for @pullUpToLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Pull up to load more'**
  String get pullUpToLoadMore;

  /// No description provided for @releaseToLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Release to load more'**
  String get releaseToLoadMore;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingEllipsis;

  /// No description provided for @oldestMessagesShown.
  ///
  /// In en, this message translates to:
  /// **'Showing oldest messages'**
  String get oldestMessagesShown;

  /// No description provided for @emojiLabel.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emojiLabel;

  /// No description provided for @callLabel.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callLabel;

  /// No description provided for @videoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// No description provided for @inputMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get inputMessageHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @holdToTalk.
  ///
  /// In en, this message translates to:
  /// **'Hold to talk'**
  String get holdToTalk;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get videoCall;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @dmDailyLimitHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used up today\'s DMs. You can start a video call!'**
  String get dmDailyLimitHint;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @currentlyOnlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get currentlyOnlineLabel;

  /// No description provided for @dnd15m.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get dnd15m;

  /// No description provided for @dnd30m.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get dnd30m;

  /// No description provided for @dnd1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get dnd1h;

  /// No description provided for @dnd6h.
  ///
  /// In en, this message translates to:
  /// **'6 hours'**
  String get dnd6h;

  /// No description provided for @dnd12h.
  ///
  /// In en, this message translates to:
  /// **'12 hours'**
  String get dnd12h;

  /// No description provided for @dnd24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get dnd24h;

  /// No description provided for @dndSetFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed, please try again'**
  String get dndSetFailed;

  /// No description provided for @dndTitle.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get dndTitle;

  /// No description provided for @dndVideoDnd.
  ///
  /// In en, this message translates to:
  /// **'Call DND'**
  String get dndVideoDnd;

  /// No description provided for @dndActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Enabled. During this time your status is set to Busy and others cannot start video chats with you.'**
  String get dndActiveHint;

  /// No description provided for @dndInactiveHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a duration to enable DND. Others cannot start video chats with you while it’s on.'**
  String get dndInactiveHint;

  /// No description provided for @dndOffToast.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb turned off'**
  String get dndOffToast;

  /// No description provided for @dndOnToast.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb on ({label})'**
  String dndOnToast(Object label);

  /// No description provided for @accountInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Account info'**
  String get accountInfoTitle;

  /// No description provided for @changeAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Change account password'**
  String get changeAccountPassword;

  /// No description provided for @changeEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Change email password'**
  String get changeEmailPassword;

  /// No description provided for @accountManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Account management'**
  String get accountManageTitle;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailBindHint.
  ///
  /// In en, this message translates to:
  /// **'Bind an email to receive activity updates, new features, and rewards.'**
  String get emailBindHint;

  /// No description provided for @statusBound.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get statusBound;

  /// No description provided for @statusToBind.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get statusToBind;

  /// No description provided for @addEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Add email'**
  String get addEmailTitle;

  /// No description provided for @addEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you want to associate with your account. It won\'t be shown on your public profile.'**
  String get addEmailSubtitle;

  /// No description provided for @addEmailHintEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get addEmailHintEmail;

  /// No description provided for @addEmailHintCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get addEmailHintCode;

  /// No description provided for @addEmailGetCode.
  ///
  /// In en, this message translates to:
  /// **'Get code'**
  String get addEmailGetCode;

  /// No description provided for @addEmailConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get addEmailConfirm;

  /// No description provided for @addEmailToastInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get addEmailToastInvalid;

  /// No description provided for @addEmailToastNeedCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code'**
  String get addEmailToastNeedCode;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonPublishMoment.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get commonPublishMoment;

  /// No description provided for @commonVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get commonVideo;

  /// No description provided for @commonImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get commonImage;

  /// No description provided for @commonContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get commonContent;

  /// No description provided for @commonFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get commonFeatured;

  /// No description provided for @commonNoContentYet.
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get commonNoContentYet;

  /// No description provided for @commonMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get commonMyProfile;

  /// No description provided for @profileTabInfo.
  ///
  /// In en, this message translates to:
  /// **'My info'**
  String get profileTabInfo;

  /// No description provided for @profileTabMoments.
  ///
  /// In en, this message translates to:
  /// **'Moments'**
  String get profileTabMoments;

  /// No description provided for @profileAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get profileAboutMe;

  /// No description provided for @profileLabelHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileLabelHeight;

  /// No description provided for @profileLabelWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profileLabelWeight;

  /// No description provided for @profileLabelMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get profileLabelMeasurements;

  /// No description provided for @profileLabelCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileLabelCity;

  /// No description provided for @profileLabelJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get profileLabelJob;

  /// No description provided for @profileMyTags.
  ///
  /// In en, this message translates to:
  /// **'My tags'**
  String get profileMyTags;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @unitCentimeter.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCentimeter;

  /// No description provided for @unitPound.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitPound;

  /// No description provided for @unitYearShort.
  ///
  /// In en, this message translates to:
  /// **'yrs'**
  String get unitYearShort;

  /// No description provided for @fieldNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get fieldNickname;

  /// No description provided for @fieldGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get fieldGender;

  /// No description provided for @fieldBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get fieldBirthday;

  /// No description provided for @fieldHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get fieldHeight;

  /// No description provided for @fieldWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get fieldWeight;

  /// No description provided for @fieldMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get fieldMeasurements;

  /// No description provided for @fieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get fieldCity;

  /// No description provided for @fieldJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get fieldJob;

  /// No description provided for @fieldTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get fieldTags;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get genderSecret;

  /// No description provided for @tagsAddNow.
  ///
  /// In en, this message translates to:
  /// **'Add now'**
  String get tagsAddNow;

  /// No description provided for @tagsTitleMyTags.
  ///
  /// In en, this message translates to:
  /// **'My tags'**
  String get tagsTitleMyTags;

  /// No description provided for @toastTagsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Tags updated'**
  String get toastTagsUpdated;

  /// No description provided for @toastMaxFiveTags.
  ///
  /// In en, this message translates to:
  /// **'You can select up to 5 tags'**
  String get toastMaxFiveTags;

  /// No description provided for @toastUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {e}'**
  String toastUpdateFailed(Object e);

  /// No description provided for @toastInvalidImageType.
  ///
  /// In en, this message translates to:
  /// **'Only JPG/JPEG/PNG images are allowed'**
  String get toastInvalidImageType;

  /// No description provided for @sheetTitleEnterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get sheetTitleEnterNickname;

  /// No description provided for @sheetHintEnterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get sheetHintEnterNickname;

  /// No description provided for @toastEnterNickname.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get toastEnterNickname;

  /// No description provided for @toastNicknameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Nickname is too long'**
  String get toastNicknameTooLong;

  /// No description provided for @toastNicknameUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Nickname updated'**
  String get toastNicknameUpdateSuccess;

  /// No description provided for @toastNicknameUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update nickname: {e}'**
  String toastNicknameUpdateFailed(Object e);

  /// No description provided for @sheetTitleEnterHeight.
  ///
  /// In en, this message translates to:
  /// **'Enter height'**
  String get sheetTitleEnterHeight;

  /// No description provided for @toastEnterValidHeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid height'**
  String get toastEnterValidHeight;

  /// No description provided for @toastEnterHeightRange.
  ///
  /// In en, this message translates to:
  /// **'Enter height in 1–999'**
  String get toastEnterHeightRange;

  /// No description provided for @toastHeightUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Height updated'**
  String get toastHeightUpdateSuccess;

  /// No description provided for @toastHeightUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update height: {e}'**
  String toastHeightUpdateFailed(Object e);

  /// No description provided for @sheetTitleEnterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get sheetTitleEnterWeight;

  /// No description provided for @toastEnterValidWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight'**
  String get toastEnterValidWeight;

  /// No description provided for @toastEnterWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Enter weight in 1–999'**
  String get toastEnterWeightRange;

  /// No description provided for @toastWeightUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Weight updated'**
  String get toastWeightUpdateSuccess;

  /// No description provided for @toastWeightUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update weight: {e}'**
  String toastWeightUpdateFailed(Object e);

  /// No description provided for @toastAgeMustBe18.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18'**
  String get toastAgeMustBe18;

  /// No description provided for @toastAgeUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Age updated'**
  String get toastAgeUpdateSuccess;

  /// No description provided for @toastAgeUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update age: {e}'**
  String toastAgeUpdateFailed(Object e);

  /// No description provided for @sheetTitleEnterMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Enter measurements'**
  String get sheetTitleEnterMeasurements;

  /// No description provided for @bodyBust.
  ///
  /// In en, this message translates to:
  /// **'Bust'**
  String get bodyBust;

  /// No description provided for @bodyWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get bodyWaist;

  /// No description provided for @bodyHip.
  ///
  /// In en, this message translates to:
  /// **'Hip'**
  String get bodyHip;

  /// No description provided for @toastMeasurementsEachRange.
  ///
  /// In en, this message translates to:
  /// **'Each measurement must be 1–999'**
  String get toastMeasurementsEachRange;

  /// No description provided for @toastMeasurementsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Measurements updated'**
  String get toastMeasurementsUpdated;

  /// No description provided for @toastMeasurementsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update measurements: {e}'**
  String toastMeasurementsUpdateFailed(Object e);

  /// No description provided for @sheetTitleEnterJob.
  ///
  /// In en, this message translates to:
  /// **'Enter job'**
  String get sheetTitleEnterJob;

  /// No description provided for @sheetHintEnterJob.
  ///
  /// In en, this message translates to:
  /// **'Enter job'**
  String get sheetHintEnterJob;

  /// No description provided for @toastJobMax12.
  ///
  /// In en, this message translates to:
  /// **'Job can be up to 12 characters'**
  String get toastJobMax12;

  /// No description provided for @toastJobUpdated.
  ///
  /// In en, this message translates to:
  /// **'Job updated'**
  String get toastJobUpdated;

  /// No description provided for @toastJobUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update job: {e}'**
  String toastJobUpdateFailed(Object e);

  /// No description provided for @monthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// No description provided for @monthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// No description provided for @monthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// No description provided for @monthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// No description provided for @monthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// No description provided for @monthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// No description provided for @monthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// No description provided for @monthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// No description provided for @monthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// No description provided for @monthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// No description provided for @inviteScanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code to download'**
  String get inviteScanQrTitle;

  /// No description provided for @inviteScanQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your sweet journey now'**
  String get inviteScanQrSubtitle;

  /// No description provided for @inviteSharePoster.
  ///
  /// In en, this message translates to:
  /// **'Share poster'**
  String get inviteSharePoster;

  /// No description provided for @inviteCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get inviteCopyLink;

  /// No description provided for @inviteSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get inviteSaveImage;

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get inviteCopied;

  /// No description provided for @inviteLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get inviteLoadFailed;

  /// No description provided for @inviteInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid link'**
  String get inviteInvalidLink;

  /// No description provided for @inviteGetLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get invite link'**
  String get inviteGetLinkFailed;

  /// No description provided for @inviteSavingNotReady.
  ///
  /// In en, this message translates to:
  /// **'Screen is not ready yet'**
  String get inviteSavingNotReady;

  /// No description provided for @inviteSavedToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos!'**
  String get inviteSavedToAlbum;

  /// No description provided for @inviteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get inviteSaveFailed;

  /// No description provided for @shareTo.
  ///
  /// In en, this message translates to:
  /// **'Share to'**
  String get shareTo;

  /// No description provided for @commonPermissionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Permission disabled'**
  String get commonPermissionDisabled;

  /// No description provided for @commonPermissionRationaleOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Storage/Photos permission is disabled. Please enable it in Settings.'**
  String get commonPermissionRationaleOpenSettings;

  /// No description provided for @commonGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get commonGoToSettings;

  /// No description provided for @messengerNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Messenger is not installed'**
  String get messengerNotInstalled;

  /// No description provided for @inviteEarnCashShort.
  ///
  /// In en, this message translates to:
  /// **'Earn cash'**
  String get inviteEarnCashShort;

  /// No description provided for @inviteOnceLifetime.
  ///
  /// In en, this message translates to:
  /// **'- Invite once, earn for life -'**
  String get inviteOnceLifetime;

  /// No description provided for @inviteCommissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn {percent} of each friend’s top-up amount'**
  String inviteCommissionDesc(Object percent);

  /// No description provided for @myInvites.
  ///
  /// In en, this message translates to:
  /// **'My invites'**
  String get myInvites;

  /// No description provided for @inviteEasyEarn.
  ///
  /// In en, this message translates to:
  /// **'·Earn with ease·'**
  String get inviteEasyEarn;

  /// No description provided for @likedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No liked users yet'**
  String get likedEmptyHint;

  /// No description provided for @toastGiftSent.
  ///
  /// In en, this message translates to:
  /// **'Gift sent!'**
  String get toastGiftSent;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// No description provided for @myInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'My invites'**
  String get myInvitesTitle;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @totalCommissionReward.
  ///
  /// In en, this message translates to:
  /// **'Total commission rewards'**
  String get totalCommissionReward;

  /// No description provided for @withdrawableAmount.
  ///
  /// In en, this message translates to:
  /// **'Withdrawable amount'**
  String get withdrawableAmount;

  /// No description provided for @tabMyRewards.
  ///
  /// In en, this message translates to:
  /// **'My rewards'**
  String get tabMyRewards;

  /// No description provided for @tabInvitees.
  ///
  /// In en, this message translates to:
  /// **'Invitees'**
  String get tabInvitees;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @commissionRewards.
  ///
  /// In en, this message translates to:
  /// **'Commission rewards'**
  String get commissionRewards;

  /// No description provided for @rewardsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Rewards count'**
  String get rewardsCountLabel;

  /// No description provided for @rechargeRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'Top-up reward'**
  String get rechargeRewardLabel;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @inviteesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitees'**
  String get inviteesCountLabel;

  /// No description provided for @registeredAt.
  ///
  /// In en, this message translates to:
  /// **'Registered at'**
  String get registeredAt;

  /// No description provided for @oldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Old password'**
  String get oldPasswordHint;

  /// No description provided for @newPasswordCannotBeSame.
  ///
  /// In en, this message translates to:
  /// **'New password must differ from old password'**
  String get newPasswordCannotBeSame;

  /// No description provided for @passwordChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordChangeSuccess;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password'**
  String get passwordChangeFailed;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processing;

  /// No description provided for @videoPriceSettings.
  ///
  /// In en, this message translates to:
  /// **'Video price settings'**
  String get videoPriceSettings;

  /// No description provided for @voicePriceSettings.
  ///
  /// In en, this message translates to:
  /// **'Voice price settings'**
  String get voicePriceSettings;

  /// No description provided for @loadPriceFailedUsingDefaults.
  ///
  /// In en, this message translates to:
  /// **'Failed to load prices; using defaults'**
  String get loadPriceFailedUsingDefaults;

  /// No description provided for @priceMustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'Price must be between {min} and {max}'**
  String priceMustBeBetween(int min, int max);

  /// No description provided for @enterPriceRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter {min}–{max}'**
  String enterPriceRangeHint(int min, int max);

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saveSuccess;

  /// No description provided for @saveFailedTryLater.
  ///
  /// In en, this message translates to:
  /// **'Save failed, please try again later'**
  String get saveFailedTryLater;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @likeDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See who\'s into you—message instantly'**
  String get likeDialogSubtitle;

  /// No description provided for @noPlansAvailable.
  ///
  /// In en, this message translates to:
  /// **'No plans available'**
  String get noPlansAvailable;

  /// No description provided for @usdPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} USD/month'**
  String usdPerMonth(Object amount);

  /// No description provided for @purchaseVip.
  ///
  /// In en, this message translates to:
  /// **'Buy VIP'**
  String get purchaseVip;

  /// No description provided for @dataFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid data format'**
  String get dataFormatError;

  /// No description provided for @uploadFailedCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'Upload failed, please check your network'**
  String get uploadFailedCheckNetwork;

  /// No description provided for @inviteLinkEmpty.
  ///
  /// In en, this message translates to:
  /// **'Invite link is empty'**
  String get inviteLinkEmpty;

  /// No description provided for @updateFailedCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'Update failed, please check your network connection'**
  String get updateFailedCheckNetwork;

  /// No description provided for @videoPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Video price'**
  String get videoPriceTitle;

  /// No description provided for @voicePriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice price'**
  String get voicePriceTitle;

  /// No description provided for @vipAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get vipAppBarTitle;

  /// No description provided for @vipCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership perks'**
  String get vipCardTitle;

  /// No description provided for @vipCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock perks for a premium experience'**
  String get vipCardSubtitle;

  /// No description provided for @vipNotActivated.
  ///
  /// In en, this message translates to:
  /// **'Not activated'**
  String get vipNotActivated;

  /// No description provided for @vipBestChoice.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get vipBestChoice;

  /// No description provided for @vipPrivilegesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exclusive perks'**
  String get vipPrivilegesTitle;

  /// No description provided for @vipOriginalPrice.
  ///
  /// In en, this message translates to:
  /// **'Was {price}'**
  String vipOriginalPrice(Object price);

  /// No description provided for @vipPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} / mo'**
  String vipPerMonth(Object amount);

  /// No description provided for @vipBuyCta.
  ///
  /// In en, this message translates to:
  /// **'{price} USD / Activate {planTitle}'**
  String vipBuyCta(Object price, Object planTitle);

  /// No description provided for @iapWarnNoProducts.
  ///
  /// In en, this message translates to:
  /// **'App Store product info not available. Please try again later.'**
  String get iapWarnNoProducts;

  /// No description provided for @iapWarnNoProductId.
  ///
  /// In en, this message translates to:
  /// **'iOS productId not configured; IAP unavailable'**
  String get iapWarnNoProductId;

  /// No description provided for @iapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'App Store unavailable, please try again later'**
  String get iapUnavailable;

  /// No description provided for @iapProductIdMissing.
  ///
  /// In en, this message translates to:
  /// **'No iOS productId configured for this plan'**
  String get iapProductIdMissing;

  /// No description provided for @iapProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'App Store product not found'**
  String get iapProductNotFound;

  /// No description provided for @vipOpenSuccess.
  ///
  /// In en, this message translates to:
  /// **'Activated successfully'**
  String get vipOpenSuccess;

  /// No description provided for @vipOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Activation failed: {err}'**
  String vipOpenFailed(Object err);

  /// No description provided for @androidSubComing.
  ///
  /// In en, this message translates to:
  /// **'Android subscription coming soon'**
  String get androidSubComing;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {err}'**
  String loadFailed(Object err);

  /// No description provided for @vipExpireSuffix.
  ///
  /// In en, this message translates to:
  /// **'expires'**
  String get vipExpireSuffix;

  /// No description provided for @privBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'VIP Badge'**
  String get privBadgeTitle;

  /// No description provided for @privBadgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Stand out with a VIP badge'**
  String get privBadgeDesc;

  /// No description provided for @privVisitsTitle.
  ///
  /// In en, this message translates to:
  /// **'All visit history'**
  String get privVisitsTitle;

  /// No description provided for @privVisitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Never miss who liked you'**
  String get privVisitsDesc;

  /// No description provided for @privUnlimitedCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited calls'**
  String get privUnlimitedCallTitle;

  /// No description provided for @privUnlimitedCallDesc.
  ///
  /// In en, this message translates to:
  /// **'Endless connections, more chances'**
  String get privUnlimitedCallDesc;

  /// No description provided for @privDirectDmTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct messaging'**
  String get privDirectDmTitle;

  /// No description provided for @privDirectDmDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlimited private chat anytime'**
  String get privDirectDmDesc;

  /// No description provided for @privBeautyTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced beauty effects'**
  String get privBeautyTitle;

  /// No description provided for @privBeautyDesc.
  ///
  /// In en, this message translates to:
  /// **'More effects, better looks'**
  String get privBeautyDesc;

  /// No description provided for @whoLikesMeTitle.
  ///
  /// In en, this message translates to:
  /// **'Who liked me'**
  String get whoLikesMeTitle;

  /// No description provided for @whoLikesMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See who’s into you—reach out instantly'**
  String get whoLikesMeSubtitle;

  /// No description provided for @buyVipWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Buy VIP ({price})'**
  String buyVipWithPrice(Object price);

  /// No description provided for @planLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load plans'**
  String get planLoadFailed;

  /// No description provided for @noAvailablePlans.
  ///
  /// In en, this message translates to:
  /// **'No plans available'**
  String get noAvailablePlans;

  /// No description provided for @userFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallback;

  /// No description provided for @setupPleaseChoose.
  ///
  /// In en, this message translates to:
  /// **'Please choose'**
  String get setupPleaseChoose;

  /// No description provided for @setupYourGender.
  ///
  /// In en, this message translates to:
  /// **'Your gender'**
  String get setupYourGender;

  /// No description provided for @setupGenderImmutable.
  ///
  /// In en, this message translates to:
  /// **'Once set, gender cannot be changed'**
  String get setupGenderImmutable;

  /// No description provided for @setupNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupNext;

  /// No description provided for @setupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get setupSkip;

  /// No description provided for @setupToastSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender first'**
  String get setupToastSelectGender;

  /// No description provided for @setupToastSetProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile first'**
  String get setupToastSetProfileFirst;

  /// No description provided for @setupPleaseFill.
  ///
  /// In en, this message translates to:
  /// **'Please fill in'**
  String get setupPleaseFill;

  /// No description provided for @setupYourAge.
  ///
  /// In en, this message translates to:
  /// **'Your age'**
  String get setupYourAge;

  /// No description provided for @setupAgeRequirement.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 to use this app'**
  String get setupAgeRequirement;

  /// No description provided for @setupAgePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get setupAgePlaceholder;

  /// No description provided for @setupAgeUnitYear.
  ///
  /// In en, this message translates to:
  /// **'yr'**
  String get setupAgeUnitYear;

  /// No description provided for @setupAgeToastEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age'**
  String get setupAgeToastEmpty;

  /// No description provided for @setupAgeToastMin18.
  ///
  /// In en, this message translates to:
  /// **'Age must be 18 or older'**
  String get setupAgeToastMin18;

  /// No description provided for @setupYourNickname.
  ///
  /// In en, this message translates to:
  /// **'Your nickname'**
  String get setupYourNickname;

  /// No description provided for @setupNicknameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a nickname so others know you'**
  String get setupNicknameSubtitle;

  /// No description provided for @setupNicknamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get setupNicknamePlaceholder;

  /// No description provided for @setupNicknameToastEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your nickname'**
  String get setupNicknameToastEmpty;

  /// No description provided for @setupNicknameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be ≤ {max} chars'**
  String setupNicknameTooLong(Object max);

  /// No description provided for @setupBlockBack.
  ///
  /// In en, this message translates to:
  /// **'Please finish your profile first'**
  String get setupBlockBack;

  /// No description provided for @setupLastStep.
  ///
  /// In en, this message translates to:
  /// **'Final step'**
  String get setupLastStep;

  /// No description provided for @setupYourPhoto.
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get setupYourPhoto;

  /// No description provided for @setupPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear, front-facing photo of yourself'**
  String get setupPhotoSubtitle;

  /// No description provided for @photoSampleClear.
  ///
  /// In en, this message translates to:
  /// **'No obstruction'**
  String get photoSampleClear;

  /// No description provided for @photoSampleSmile.
  ///
  /// In en, this message translates to:
  /// **'Remember to smile'**
  String get photoSampleSmile;

  /// No description provided for @photoSampleClearFeatures.
  ///
  /// In en, this message translates to:
  /// **'Clear facial features'**
  String get photoSampleClearFeatures;

  /// No description provided for @setupFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get setupFinish;

  /// No description provided for @pickPhotoFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a photo first'**
  String get pickPhotoFirst;

  /// No description provided for @uploadImagesOnly.
  ///
  /// In en, this message translates to:
  /// **'Images only'**
  String get uploadImagesOnly;

  /// No description provided for @uploadLimitMaxSize.
  ///
  /// In en, this message translates to:
  /// **'Files must be under {size}'**
  String uploadLimitMaxSize(Object size);

  /// No description provided for @pickFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Selection failed, please retry'**
  String get pickFailedRetry;

  /// No description provided for @netIssueRetryLater.
  ///
  /// In en, this message translates to:
  /// **'Network error, please try again later'**
  String get netIssueRetryLater;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get userNotLoggedIn;

  /// No description provided for @apiErrLoginExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired, please sign in again'**
  String get apiErrLoginExpired;

  /// No description provided for @apiErrPayloadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Payload too large'**
  String get apiErrPayloadTooLarge;

  /// No description provided for @apiErrUnprocessable.
  ///
  /// In en, this message translates to:
  /// **'Invalid or incomplete parameters'**
  String get apiErrUnprocessable;

  /// No description provided for @apiErrTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests, try again later'**
  String get apiErrTooManyRequests;

  /// No description provided for @apiErrServiceGeneric.
  ///
  /// In en, this message translates to:
  /// **'Service error, please try again later'**
  String get apiErrServiceGeneric;

  /// No description provided for @profileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeight;

  /// No description provided for @profileWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profileWeight;

  /// No description provided for @profileMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get profileMeasurements;

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

  /// No description provided for @profileJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get profileJob;

  /// No description provided for @sectionFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get sectionFeatured;

  /// No description provided for @badgeFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get badgeFeatured;

  /// No description provided for @actionMessageTa.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get actionMessageTa;

  /// No description provided for @actionStartVideo.
  ///
  /// In en, this message translates to:
  /// **'Start video call'**
  String get actionStartVideo;

  /// No description provided for @unitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitLb.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitLb;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minute;

  /// No description provided for @coin.
  ///
  /// In en, this message translates to:
  /// **'coins'**
  String get coin;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @likesCount.
  ///
  /// In en, this message translates to:
  /// **'{n} Likes'**
  String likesCount(Object n);

  /// No description provided for @coinsPerMinute.
  ///
  /// In en, this message translates to:
  /// **'{n} coins/min'**
  String coinsPerMinute(Object n);

  /// No description provided for @userGeneric.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userGeneric;

  /// No description provided for @roleBroadcaster.
  ///
  /// In en, this message translates to:
  /// **'Broadcaster'**
  String get roleBroadcaster;

  /// No description provided for @tabMyInfo.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabMyInfo;

  /// No description provided for @tabPersonalFeed.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get tabPersonalFeed;

  /// No description provided for @emptyNoContent.
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get emptyNoContent;

  /// No description provided for @loadFailedWith.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {e}'**
  String loadFailedWith(Object e);

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get walletTitle;

  /// No description provided for @walletDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get walletDetails;

  /// No description provided for @walletReadFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wallet'**
  String get walletReadFail;

  /// No description provided for @walletPacketsLoadFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to load packs'**
  String get walletPacketsLoadFail;

  /// No description provided for @walletPacketsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Packs not loaded yet'**
  String get walletPacketsNotLoaded;

  /// No description provided for @walletEnterIntAmountAtLeast1.
  ///
  /// In en, this message translates to:
  /// **'Enter an integer (min 1)'**
  String get walletEnterIntAmountAtLeast1;

  /// No description provided for @walletChoosePacketFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a pack'**
  String get walletChoosePacketFirst;

  /// No description provided for @walletBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Coin balance'**
  String get walletBalanceLabel;

  /// No description provided for @walletCustomAmount.
  ///
  /// In en, this message translates to:
  /// **'Custom amount'**
  String get walletCustomAmount;

  /// No description provided for @walletCustomTopup.
  ///
  /// In en, this message translates to:
  /// **'Custom top-up'**
  String get walletCustomTopup;

  /// No description provided for @walletCustomHintAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter your top-up amount'**
  String get walletCustomHintAmount;

  /// No description provided for @walletBtnTopupNow.
  ///
  /// In en, this message translates to:
  /// **'Top up now'**
  String get walletBtnTopupNow;

  /// No description provided for @walletBonusGift.
  ///
  /// In en, this message translates to:
  /// **'Limited bonus +{n} coins'**
  String walletBonusGift(Object n);

  /// No description provided for @billDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill details'**
  String get billDetailTitle;

  /// No description provided for @rechargeWord.
  ///
  /// In en, this message translates to:
  /// **'Top-up'**
  String get rechargeWord;

  /// No description provided for @coinWord.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coinWord;

  /// No description provided for @rechargeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Top-up successful'**
  String get rechargeSuccess;

  /// No description provided for @rechargeDetails.
  ///
  /// In en, this message translates to:
  /// **'Top-up details'**
  String get rechargeDetails;

  /// No description provided for @rechargeCoinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Top-up coins'**
  String get rechargeCoinsLabel;

  /// No description provided for @rechargeMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Top-up method'**
  String get rechargeMethodLabel;

  /// No description provided for @paymentAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment account'**
  String get paymentAccountLabel;

  /// No description provided for @rechargeTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Top-up time'**
  String get rechargeTimeLabel;

  /// No description provided for @rechargeOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Top-up order ID'**
  String get rechargeOrderIdLabel;

  /// No description provided for @rechargeFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Top-up failed'**
  String get rechargeFailedShort;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get unknownStatus;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @selectTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Choose transaction type'**
  String get selectTransactionType;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterRecharge.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get filterRecharge;

  /// No description provided for @filterSendGift.
  ///
  /// In en, this message translates to:
  /// **'Send gift'**
  String get filterSendGift;

  /// No description provided for @filterReceiveGift.
  ///
  /// In en, this message translates to:
  /// **'Receive gift'**
  String get filterReceiveGift;

  /// No description provided for @filterVideoPaid.
  ///
  /// In en, this message translates to:
  /// **'Video call cost'**
  String get filterVideoPaid;

  /// No description provided for @filterVoicePaid.
  ///
  /// In en, this message translates to:
  /// **'Voice call cost'**
  String get filterVoicePaid;

  /// No description provided for @filterCampaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign reward'**
  String get filterCampaign;

  /// No description provided for @loadFailedTapRetry.
  ///
  /// In en, this message translates to:
  /// **'Load failed, tap to retry'**
  String get loadFailedTapRetry;

  /// No description provided for @walletNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get walletNoRecords;

  /// No description provided for @giftToName.
  ///
  /// In en, this message translates to:
  /// **'Gift to {name}'**
  String giftToName(Object name);

  /// No description provided for @giftSent.
  ///
  /// In en, this message translates to:
  /// **'Gift sent'**
  String get giftSent;

  /// No description provided for @titleReceiveGift.
  ///
  /// In en, this message translates to:
  /// **'Received gift'**
  String get titleReceiveGift;

  /// No description provided for @withdrawDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal details'**
  String get withdrawDetailsTitle;

  /// No description provided for @withdrawNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No withdrawal records yet'**
  String get withdrawNoRecords;

  /// No description provided for @noMoreData.
  ///
  /// In en, this message translates to:
  /// **'No more'**
  String get noMoreData;

  /// No description provided for @withdrawToMethod.
  ///
  /// In en, this message translates to:
  /// **'Withdraw to {method}'**
  String withdrawToMethod(Object method);

  /// No description provided for @unknownMethod.
  ///
  /// In en, this message translates to:
  /// **'Unknown method'**
  String get unknownMethod;

  /// No description provided for @withdrawTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal time'**
  String get withdrawTimeLabel;

  /// No description provided for @withdrawMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal method'**
  String get withdrawMethodLabel;

  /// No description provided for @withdrawAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal account'**
  String get withdrawAccountLabel;

  /// No description provided for @withdrawAccountNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get withdrawAccountNameLabel;

  /// No description provided for @withdrawOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal ID'**
  String get withdrawOrderIdLabel;

  /// No description provided for @statusReviewing.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get statusReviewing;

  /// No description provided for @statusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get statusSuccess;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @withdrawAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdraw amount'**
  String get withdrawAmountLabel;

  /// No description provided for @withdrawAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter withdrawal amount'**
  String get withdrawAmountHint;

  /// No description provided for @feeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee: '**
  String get feeLabel;

  /// No description provided for @withdrawAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawable: '**
  String get withdrawAvailableLabel;

  /// No description provided for @withdrawAccountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get withdrawAccountTypeLabel;

  /// No description provided for @withdrawAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter payout account (e.g., PayPal email)'**
  String get withdrawAccountHint;

  /// No description provided for @withdrawAccountNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter account name'**
  String get withdrawAccountNameHint;

  /// No description provided for @withdrawSubmitSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request submitted'**
  String get withdrawSubmitSuccessTitle;

  /// No description provided for @withdrawSubmitSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'We’ll review within 3 business days. Please wait.'**
  String get withdrawSubmitSuccessDesc;

  /// No description provided for @withdrawEmptyAccountOrName.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal account and name cannot be empty'**
  String get withdrawEmptyAccountOrName;

  /// No description provided for @withdrawMinAmount1.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal is 1'**
  String get withdrawMinAmount1;

  /// No description provided for @withdrawExceedsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal amount exceeds available amount'**
  String get withdrawExceedsAvailable;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethodTitle;

  /// No description provided for @payAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment amount'**
  String get payAmountTitle;

  /// No description provided for @approxCoins.
  ///
  /// In en, this message translates to:
  /// **'≈ {n} coins'**
  String approxCoins(Object n);

  /// No description provided for @commissionAccount.
  ///
  /// In en, this message translates to:
  /// **'Commission account'**
  String get commissionAccount;

  /// No description provided for @availableUsd.
  ///
  /// In en, this message translates to:
  /// **'Available {amount} USD'**
  String availableUsd(Object amount);

  /// No description provided for @appStoreBilling.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get appStoreBilling;

  /// No description provided for @googlePlayBilling.
  ///
  /// In en, this message translates to:
  /// **'Google Play Billing'**
  String get googlePlayBilling;

  /// No description provided for @rechargeFailed.
  ///
  /// In en, this message translates to:
  /// **'Top-up failed: {err}'**
  String rechargeFailed(Object err);

  /// No description provided for @paymentMethodUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported payment method'**
  String get paymentMethodUnsupported;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
