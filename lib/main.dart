import 'dart:async';
import 'dart:io';

import 'package:djs_live_stream/push/app_lifecycle.dart';
import 'package:djs_live_stream/push/presence_reporter.dart';
import 'package:djs_live_stream/push/push_service.dart';
import 'package:djs_live_stream/push/push_token_registrar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'config/providers/app_config_provider.dart';
import 'core/ws/ws_provider.dart';
import 'data/models/user_model.dart';
import 'features/call/call_signal_listener.dart';
import 'features/call/rtc_engine_manager.dart';
import 'features/live/broadcaster_page.dart';
import 'features/live/live_end_page.dart';
import 'features/live/pip_system_ui.dart';
import 'features/profile/profile_controller.dart';
import 'firebase_options.dart';
import 'globals.dart';
import 'l10n/l10n.dart';
import 'locale_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/live/video_recorder_page.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  debugPrint('main() start~');
  Future<void> logFirebaseConfig() async {
    try {
      final app = Firebase.app();
      final o = app.options;
      debugPrint('### Firebase Runtime Options');
      debugPrint('### platform=${Platform.isIOS ? "iOS" : Platform.operatingSystem}');
      debugPrint('### appId=${o.appId}');
      debugPrint('### projectId=${o.projectId}');
      debugPrint('### gcmSenderId=${o.messagingSenderId}');
      debugPrint('### storageBucket=${o.storageBucket}');
      debugPrint('### apiKey(head)=${o.apiKey.substring(0, 8)}...');
    } catch (e) {
      debugPrint('### Firebase not initialized: $e');
    }
  }

  WidgetsFlutterBinding.ensureInitialized();

  AppLifecycle.I.init();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushService.I.maybeShowPendingIncomingUI();
  });

  await Firebase.initializeApp();
  await logFirebaseConfig();

  const env   = String.fromEnvironment('ENV', defaultValue: '<MISSING>');
  const api   = String.fromEnvironment('API_BASE', defaultValue: '<MISSING>');
  const ws    = String.fromEnvironment('WS_URL', defaultValue: '<MISSING>');
  // 也順便印出你原本的判斷
  debugPrint('### DART_DEFINES => ENV=$env, API_BASE=$api, WS_URL=$ws, kReleaseMode=$kReleaseMode');


  FirebaseMessaging.onBackgroundMessage(firebaseBgHandler);


  // 2) 再做你其他初始化
  final mgr = RtcEngineManager();
  final logPath = await mgr.prepareRtcLogPath();
  await mgr.init(appId: AppConfig.agoraAppId, logPath: logPath);

  PipSystemUi.init(navigatorKey: rootNavigatorKey);

  await PushService.I.init();

  // 3) 最后再 runApp
  runApp(
    ProviderScope(
      child: legacy.ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = legacy.Provider.of<LocaleProvider>(context).locale;
    ref.watch(wsProvider);

    // 啟動後收集 token（FCM / VoIP），不會打後端
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushTokenRegistrar.I.initCollectors(ref);
      // 若一打開就已登入，也上報一次
      final u = ref.read(userProfileProvider);
      if (u != null) {
        PushTokenRegistrar.I.onLogin(ref);
      }
    });

    // 監聽登入狀態：登入後上報一次（之後 token 變更會自動上報）
    ref.listen<UserModel?>(userProfileProvider, (prev, next) {
      if (next != null) {
        unawaited(PushTokenRegistrar.I.onLogin(ref));
        unawaited(PresenceReporter.I.start(ref));
      } else {
        unawaited(PresenceReporter.I.stop());
      }
    });

    return MaterialApp(
      title: 'lu live',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      locale: locale,
      localeResolutionCallback: (Locale? device, Iterable<Locale> supported) {
        if (device == null) return const Locale('en');
        if (device.languageCode.toLowerCase() == 'zh') {
          return const Locale('zh');
        }
        return const Locale('en');
      },
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.videoRecorder: (context) => const VideoRecorderPage(),
        AppRoutes.live_end: (_) => const LiveEndPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.broadcaster) {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => const BroadcasterPage(),
              settings: RouteSettings(arguments: args),
            );
          } else {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('')),
              ),
            );
          }
        }
        return null;
      },
      navigatorObservers: [routeObserver],
      builder: (context, child) => CallSignalListener(child: child ?? const SizedBox()),
    );
  }
}