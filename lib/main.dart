import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'features/live/broadcaster_page.dart';
import 'l10n/l10n.dart';
import 'locale_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/live/video_recorder_page.dart';
import 'routes/app_routes.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  runApp(
    ProviderScope(
      child: legacy.ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = legacy.Provider.of<LocaleProvider>(context).locale;

    return MaterialApp(
      title: 'lu live',
      debugShowCheckedModeBanner: false,
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
    );
  }
}