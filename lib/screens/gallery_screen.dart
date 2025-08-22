import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/auth_controller.dart';
import '../controllers/media_controller.dart';
import '../models/media_item.dart';
import '../widgets/media_grid_item.dart';
import '../widgets/camera_fab.dart';
import '../services/share_extension_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final MediaController _mediaController = MediaController();
  final AuthController _authController = AuthController();
  final ShareExtensionService _shareService = ShareExtensionService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Auth kontrolü
    if (!_authController.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
      return;
    }
    _initializeGallery();
  }

  Future<void> _initializeGallery() async {
    await _mediaController.initialize();
    await _shareService.initialize();

    // Paylaşılan içerik bildirim callback'ini ayarla
    _shareService.onSharedContentProcessed = (message) {
      if (mounted) {
        _showSuccessSnackBar(message);
        _refreshGallery(); // Galeriyi yenile
      }
    };

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshGallery() async {
    setState(() {
      _isLoading = true;
    });

    // Media'ları yeniden yükle
    await _mediaController.loadMedia();

    setState(() {
      _isLoading = false;
    });
  }

  void _logout() {
    _authController.logout();
    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _handlePermissionError(String errorMessage) async {
    if (errorMessage.contains('kalıcı olarak reddedildi')) {
      // İzin kalıcı olarak reddedildi, ayarları açma seçeneği sun
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'İzin Gerekli',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '$errorMessage\n\nİzin vermek için ayarları açmak ister misiniz?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text(
                'Ayarları Aç',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    } else {
      // Normal hata mesajını göster
      _showErrorSnackBar(errorMessage);
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMediaDetail(MediaItem mediaItem) {
    Navigator.of(context).pushNamed('/detail', arguments: mediaItem);
  }

  @override
  Widget build(BuildContext context) {
    // Auth kontrolü ScreenProtection'da yapılıyor, burada yapmayalım
    return GestureDetector(
      onTap: () {
        // Kullanıcı aktivitesi - timer'ı sıfırla
        _authController.userActivity();
      },
      onPanUpdate: (_) {
        // Kullanıcı aktivitesi - timer'ı sıfırla
        _authController.userActivity();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text(
            'Private Gallery',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.lock),
              onPressed: _showChangePasswordDialog,
              tooltip: 'Şifre Değiştir',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Çıkış Yap',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _mediaController.mediaItems.isEmpty
            ? _buildEmptyState()
            : _buildGalleryGrid(),
        floatingActionButton: CameraFAB(
          onPhotoPressed: () async {
            try {
              await _mediaController.takePhoto();
              _refreshGallery();
            } catch (e) {
              await _handlePermissionError(e.toString());
            }
          },
          onVideoPressed: () async {
            try {
              await _mediaController.recordVideo();
              _refreshGallery();
            } catch (e) {
              await _handlePermissionError(e.toString());
            }
          },
          onGalleryPressed: () async {
            try {
              await _mediaController.pickFromGallery();
              _refreshGallery();
            } catch (e) {
              await _handlePermissionError(e.toString());
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Henüz medya yok',
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Fotoğraf veya video eklemek için\nsağ alt köşedeki butonu kullanın',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return RefreshIndicator(
      onRefresh: _refreshGallery,
      color: Colors.white,
      backgroundColor: Colors.black,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _mediaController.mediaItems.length,
        itemBuilder: (context, index) {
          final mediaItem = _mediaController.mediaItems[index];
          return MediaGridItem(
            mediaItem: mediaItem,
            onTap: () => _showMediaDetail(mediaItem),
            onLongPress: () => _showDeleteDialog(mediaItem),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(MediaItem mediaItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Medyayı Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bu ${mediaItem.type == MediaType.image ? 'fotoğrafı' : 'videoyu'} silmek istediğinizden emin misiniz?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _mediaController.deleteMedia(mediaItem.id);
                _refreshGallery();
              } catch (e) {
                _showErrorSnackBar('Silme işlemi başarısız: $e');
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
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
}
