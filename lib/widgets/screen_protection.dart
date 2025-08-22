import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/auth_controller.dart';
import '../controllers/media_controller.dart';

class ScreenProtection extends StatefulWidget {
  final Widget child;

  const ScreenProtection({super.key, required this.child});

  @override
  State<ScreenProtection> createState() => _ScreenProtectionState();
}

class _ScreenProtectionState extends State<ScreenProtection>
    with WidgetsBindingObserver {
  final AuthController _authController = AuthController();
  final MediaController _mediaController = MediaController();
  bool _isScreenProtected = false;
  bool _needsReauthentication = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // İlk açılışta ekran korumasını aktif etme
    // Sadece arkaplandan geri geldiğinde aktif et
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _enableScreenProtection();
        // Sadece ekran koruması, logout yapmıyoruz
        break;
      case AppLifecycleState.resumed:
        // MediaController'ın kamera flag'ini kontrol etmek için bekle
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;

          // Kamera uygulamasından geri dönüyorsak şifre isteme
          if (_mediaController.isInCameraMode) {
            // Kamera modunda sadece ekran korumasını kaldır
            _disableScreenProtection();
          } else {
            // Auth durumunu kontrol et
            if (!_authController.isAuthenticated) {
              // Logout olmuş, şifre ekranına yönlendir
              _needsReauthentication = true;
              _enableScreenProtection();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_needsReauthentication && mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              });
            } else {
              // Authenticated, sadece ekran korumasını kaldır
              _disableScreenProtection();
            }
          }
        });
        break;
      default:
        break;
    }
  }

  void _enableScreenProtection() {
    setState(() {
      _isScreenProtected = true;
    });
    // Ekran görüntüsü alınmasını engelle
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  void _disableScreenProtection() {
    setState(() {
      _isScreenProtected = false;
      _needsReauthentication = false;
    });
    // Normal moda dön
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Kullanıcı aktivitesi - timer'ı sıfırla
        _authController.userActivity();
      },
      onPanUpdate: (_) {
        // Kullanıcı aktivitesi - timer'ı sıfırla
        _authController.userActivity();
      },
      child: Stack(
        children: [
          widget.child,
          if (_isScreenProtected)
            Container(
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.lock, size: 80, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
