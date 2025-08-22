import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/media_item.dart';
import '../services/media_service.dart';

class MediaController {
  static final MediaController _instance = MediaController._internal();
  factory MediaController() => _instance;
  MediaController._internal();

  final MediaService _mediaService = MediaService();
  final ImagePicker _imagePicker = ImagePicker();

  List<MediaItem> _mediaItems = [];
  bool _isLoading = false;
  bool _isInCameraMode = false; // Kamera uygulamasında olup olmadığını takip et

  List<MediaItem> get mediaItems => _mediaItems;
  bool get isLoading => _isLoading;
  bool get isInCameraMode => _isInCameraMode;

  Future<void> initialize() async {
    await _mediaService.initialize();
    await loadMedia();
  }

  Future<void> loadMedia() async {
    _isLoading = true;
    notifyListeners();

    try {
      _mediaItems = await _mediaService.getAllMedia();
    } catch (e) {
      debugPrint('Medya yüklenirken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      throw Exception(
        'Kamera izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
      );
    }
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      throw Exception(
        'Mikrofon izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
      );
    }
    return status.isGranted;
  }

  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    if (status.isPermanentlyDenied) {
      throw Exception(
        'Galeri izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
      );
    }
    return status.isGranted;
  }

  Future<void> takePhoto() async {
    try {
      // Kamera modunu aktif et
      _isInCameraMode = true;
      notifyListeners();

      // Önce kamera iznini kontrol et
      final cameraPermission = await Permission.camera.status;
      if (cameraPermission.isDenied || cameraPermission.isRestricted) {
        final granted = await requestCameraPermission();
        if (!granted) {
          throw Exception(
            'Kamera izni gerekli. Lütfen kamera erişimine izin verin.',
          );
        }
      } else if (cameraPermission.isPermanentlyDenied) {
        throw Exception(
          'Kamera izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
        );
      }

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95, // %95 kalite - artırıldı
      );

      if (photo != null) {
        await _saveMediaItem(File(photo.path), MediaType.image);
      } else {
        throw Exception('Fotoğraf seçilmedi');
      }
    } catch (e) {
      debugPrint('Fotoğraf çekilirken hata: $e');
      rethrow;
    } finally {
      // Kamera modunu 2 saniye sonra kapat (kamera uygulamasından geri dönme süresi için)
      Future.delayed(const Duration(seconds: 2), () {
        _isInCameraMode = false;
        notifyListeners();
      });
    }
  }

  Future<void> recordVideo() async {
    try {
      // Kamera modunu aktif et
      _isInCameraMode = true;
      notifyListeners();

      // Kamera ve mikrofon izinlerini kontrol et
      final cameraPermission = await Permission.camera.status;
      final microphonePermission = await Permission.microphone.status;

      if (cameraPermission.isDenied || cameraPermission.isRestricted) {
        final granted = await requestCameraPermission();
        if (!granted) {
          throw Exception(
            'Kamera izni gerekli. Lütfen kamera erişimine izin verin.',
          );
        }
      } else if (cameraPermission.isPermanentlyDenied) {
        throw Exception(
          'Kamera izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
        );
      }

      if (microphonePermission.isDenied || microphonePermission.isRestricted) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          throw Exception(
            'Mikrofon izni gerekli. Lütfen mikrofon erişimine izin verin.',
          );
        }
      } else if (microphonePermission.isPermanentlyDenied) {
        throw Exception(
          'Mikrofon izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
        );
      }

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
        preferredCameraDevice: CameraDevice.rear, // Arka kamera tercih et
      );

      if (video != null) {
        await _saveMediaItem(File(video.path), MediaType.video);
      } else {
        throw Exception('Video kaydedilmedi');
      }
    } catch (e) {
      debugPrint('Video çekilirken hata: $e');
      rethrow;
    } finally {
      // Kamera modunu 2 saniye sonra kapat (kamera uygulamasından geri dönme süresi için)
      Future.delayed(const Duration(seconds: 2), () {
        _isInCameraMode = false;
        notifyListeners();
      });
    }
  }

  Future<void> pickFromGallery() async {
    try {
      // Galeri iznini kontrol et
      final photosPermission = await Permission.photos.status;
      if (photosPermission.isDenied || photosPermission.isRestricted) {
        final granted = await requestPhotosPermission();
        if (!granted) {
          throw Exception(
            'Galeri izni gerekli. Lütfen galeri erişimine izin verin.',
          );
        }
      } else if (photosPermission.isPermanentlyDenied) {
        throw Exception(
          'Galeri izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
        );
      }

      final XFile? media = await _imagePicker.pickMedia(
        imageQuality: 95,
      ); // %95 kalite - artırıldı

      if (media != null) {
        final MediaType type =
            media.path.toLowerCase().contains('.mp4') ||
                media.path.toLowerCase().contains('.mov')
            ? MediaType.video
            : MediaType.image;

        await _saveMediaItem(File(media.path), type);
      } else {
        throw Exception('Medya seçilmedi');
      }
    } catch (e) {
      debugPrint('Galeriden seçilirken hata: $e');
      rethrow;
    }
  }

  Future<void> _saveMediaItem(File file, MediaType type) async {
    try {
      final savedPath = await _mediaService.saveFile(file, type);

      final mediaItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: savedPath,
        type: type,
        createdAt: DateTime.now(),
      );

      await _mediaService.saveMedia(mediaItem);
      await loadMedia();
    } catch (e) {
      debugPrint('Medya kaydedilirken hata: $e');
      rethrow;
    }
  }

  Future<void> deleteMedia(String id) async {
    try {
      await _mediaService.deleteMedia(id);
      await loadMedia();
    } catch (e) {
      debugPrint('Medya silinirken hata: $e');
      rethrow;
    }
  }

  Future<MediaItem?> getMediaById(String id) async {
    return await _mediaService.getMediaById(id);
  }

  void notifyListeners() {
    // Bu controller'da ChangeNotifier kullanmadığımız için
    // UI güncellemeleri için farklı bir yaklaşım kullanacağız
  }
}
