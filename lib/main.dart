import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'config/app_config.dart';
import 'core/ws/ws_provider.dart';
import 'features/call/call_signal_listener.dart';
import 'features/call/rtc_engine_manager.dart';
import 'features/live/broadcaster_page.dart';
import 'features/live/live_end_page.dart';
import 'features/live/pip_system_ui.dart';
import 'firebase_options.dart';
import 'globals.dart';
import 'l10n/l10n.dart';
import 'locale_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/live/video_recorder_page.dart';
import 'routes/app_routes.dart';

import 'package:firebase_core/firebase_core.dart';
// 如果你有用 flutterfire cli 生成的 options：
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) 先把 Firebase 初始化完成
  // 如果有 firebase_options.dart：
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  // 2) 再做你其他初始化
  final mgr = RtcEngineManager();
  final logPath = await mgr.prepareRtcLogPath();
  await mgr.init(appId: AppConfig.agoraAppId, logPath: logPath);

  PipSystemUi.init(navigatorKey: rootNavigatorKey);

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

    return MaterialApp(
      title: 'lu live',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      locale: locale,
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
                body: Center(child: Text('無效參數，無法進入直播')),
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