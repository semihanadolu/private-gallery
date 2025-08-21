import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/auth_controller.dart';
import '../widgets/password_input.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final AuthController _authController = AuthController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Kısa bir gecikme ekleyerek loading animasyonunu göster
    await Future.delayed(const Duration(milliseconds: 500));

    final password = _passwordController.text;

    if (password.length != 8) {
      setState(() {
        _errorMessage = 'Şifre 8 haneli olmalıdır';
        _isLoading = false;
      });
      return;
    }

    final isValid = await _authController.validatePassword(password);
    if (isValid) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/gallery');
      }
    } else {
      setState(() {
        _errorMessage = 'Yanlış şifre';
        _isLoading = false;
      });

      // Hatalı girişte titreşim
      HapticFeedback.vibrate();
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Şifre Değiştir',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mevcut şifre
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Mevcut Şifre',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Yeni şifre
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (8 haneli)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Şifre tekrar
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre Tekrar',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() {
                        isLoading = true;
                      });

                      final currentPassword = currentPasswordController.text;
                      final newPassword = newPasswordController.text;
                      final confirmPassword = confirmPasswordController.text;

                      // Validasyonlar
                      if (currentPassword.isEmpty ||
                          newPassword.isEmpty ||
                          confirmPassword.isEmpty) {
                        _showErrorSnackBar('Tüm alanları doldurun');
                        setDialogState(() {
                          isLoading = false;
                        });
                        return;
                      }

                      if (newPassword.length != 8) {
                        _showErrorSnackBar('Yeni şifre 8 haneli olmalıdır');
                        setDialogState(() {
                          isLoading = false;
                        });
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        _showErrorSnackBar('Yeni şifreler eşleşmiyor');
                        setDialogState(() {
                          isLoading = false;
                        });
                        return;
                      }

                      // Şifre değiştir
                      final success = await _authController.changePassword(
                        currentPassword,
                        newPassword,
                      );

                      if (success) {
                        Navigator.of(context).pop();
                        _showSuccessSnackBar('Şifre başarıyla değiştirildi');
                      } else {
                        _showErrorSnackBar('Mevcut şifre yanlış');
                      }

                      setDialogState(() {
                        isLoading = false;
                      });
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Değiştir',
                      style: TextStyle(color: Colors.blue),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo veya uygulama adı
                const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Private Gallery',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Güvenli erişim için şifrenizi girin',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Şifre girişi
                PasswordInput(
                  controller: _passwordController,
                  isVisible: _isPasswordVisible,
                  maxLength: 8, // 8 haneli şifre
                  onVisibilityChanged: (visible) {
                    setState(() {
                      _isPasswordVisible = visible;
                    });
                  },
                  onSubmitted: (_) => _validatePassword(),
                ),

                const SizedBox(height: 16),

                // Hata mesajı
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 32),

                // Giriş butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Şifre değiştir butonu
                TextButton(
                  onPressed: _showChangePasswordDialog,
                  child: const Text(
                    'Şifre Değiştir',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
