import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  List<MediaItem> get mediaItems => _mediaItems;
  bool get isLoading => _isLoading;

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
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<void> takePhoto() async {
    try {
      // Önce kamera iznini kontrol et
      final cameraPermission = await Permission.camera.status;
      if (cameraPermission.isDenied) {
        final granted = await requestCameraPermission();
        if (!granted) {
          throw Exception('Kamera izni gerekli');
        }
      }

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        await _saveMediaItem(File(photo.path), MediaType.image);
      }
    } catch (e) {
      debugPrint('Fotoğraf çekilirken hata: $e');
      rethrow;
    }
  }

  Future<void> recordVideo() async {
    try {
      // Kamera ve mikrofon izinlerini kontrol et
      final cameraPermission = await Permission.camera.status;
      final microphonePermission = await Permission.microphone.status;

      if (cameraPermission.isDenied) {
        final granted = await requestCameraPermission();
        if (!granted) {
          throw Exception('Kamera izni gerekli');
        }
      }

      if (microphonePermission.isDenied) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          throw Exception('Mikrofon izni gerekli');
        }
      }

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        await _saveMediaItem(File(video.path), MediaType.video);
      }
    } catch (e) {
      debugPrint('Video çekilirken hata: $e');
      rethrow;
    }
  }

  Future<void> pickFromGallery() async {
    try {
      // Galeri iznini kontrol et
      final photosPermission = await Permission.photos.status;
      if (photosPermission.isDenied) {
        final granted = await requestPhotosPermission();
        if (!granted) {
          throw Exception('Galeri izni gerekli');
        }
      }

      final XFile? media = await _imagePicker.pickMedia(imageQuality: 80);

      if (media != null) {
        final MediaType type =
            media.path.toLowerCase().contains('.mp4') ||
                media.path.toLowerCase().contains('.mov')
            ? MediaType.video
            : MediaType.image;

        await _saveMediaItem(File(media.path), type);
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
