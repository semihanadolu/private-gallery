import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/password_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/detail_screen.dart';
import 'controllers/auth_controller.dart';
import 'widgets/screen_protection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Sadece dikey modda çalışacak
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Tam ekran modu
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Ekran görüntüsü koruması
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Private Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PasswordScreen(),
        '/gallery': (context) => const ScreenProtection(child: GalleryScreen()),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          final mediaItem = settings.arguments as dynamic;
          return MaterialPageRoute(
            builder: (context) => DetailScreen(mediaItem: mediaItem),
          );
        }
        return null;
      },
    );
  }
}
