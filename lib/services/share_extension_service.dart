import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../models/media_item.dart';
import 'media_service.dart';

class ShareExtensionService {
  static final ShareExtensionService _instance =
      ShareExtensionService._internal();
  factory ShareExtensionService() => _instance;
  ShareExtensionService._internal();

  final MediaService _mediaService = MediaService();
  late StreamSubscription _intentDataStreamSubscription;
  bool _isProcessingInitialMedia = false;

  // Callback function for shared content notifications
  Function(String)? onSharedContentProcessed;

  Future<void> initialize() async {
    try {
      await _mediaService.initialize();
      _setupSharingListener();
      print('ShareExtensionService başarıyla başlatıldı');
    } catch (e) {
      print('ShareExtensionService başlatılırken hata: $e');
    }
  }

  void _setupSharingListener() {
    try {
      // For sharing images coming from outside the app while the app is in the memory
      _intentDataStreamSubscription = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen(
            (List<SharedMediaFile> value) {
              // Initial media işlenirken stream'den gelen verileri görmezden gel
              if (!_isProcessingInitialMedia) {
                print(
                  'Paylaşım stream\'den veri alındı: ${value.length} dosya',
                );
                _processSharedFiles(value);
              }
            },
            onError: (err) {
              print("getIntentDataStream error: $err");
              // Hata durumunda kullanıcıya bilgi ver
              onSharedContentProcessed?.call('Paylaşım işlenirken hata oluştu');
            },
          );

      // For sharing images coming from outside the app while the app is closed
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((List<SharedMediaFile> value) {
            if (value.isNotEmpty && !_isProcessingInitialMedia) {
              _isProcessingInitialMedia = true;
              print('Başlangıç paylaşım verisi alındı: ${value.length} dosya');
              _processSharedFiles(value);
            }
            // Tell the library that we are done processing the intent.
            ReceiveSharingIntent.instance.reset();
          })
          .catchError((error) {
            print("getInitialMedia error: $error");
            onSharedContentProcessed?.call('Paylaşım işlenirken hata oluştu');
          });
    } catch (e) {
      print('Paylaşım listener kurulurken hata: $e');
    }
  }

  Future<void> _processSharedFiles(List<SharedMediaFile> sharedFiles) async {
    print('${sharedFiles.length} dosya işleniyor...');

    for (int i = 0; i < sharedFiles.length; i++) {
      final sharedFile = sharedFiles[i];
      try {
        print('Dosya ${i + 1}/${sharedFiles.length} işleniyor...');

        // Dosya verilerini güvenli bir şekilde kontrol et
        final filePath = sharedFile.path;
        if (filePath.isEmpty) {
          print('Geçersiz dosya yolu: $filePath');
          continue;
        }

        // URL'yi dosya yoluna çevir
        String actualPath = filePath;
        if (filePath.startsWith('file://')) {
          actualPath = filePath.substring(7);
        }

        print('Dosya yolu: $actualPath');

        // Dosyanın var olup olmadığını kontrol et
        final file = File(actualPath);
        if (!await file.exists()) {
          print('Dosya bulunamadı: $actualPath');
          continue;
        }

        // Dosya boyutunu kontrol et
        final fileSize = await file.length();
        print('Dosya boyutu: $fileSize bytes');

        final fileType = _getMediaTypeFromSharedFile(sharedFile);

        if (fileType != null) {
          print(
            'Dosya türü: ${fileType == MediaType.image ? 'Resim' : 'Video'}',
          );

          final savedPath = await _mediaService.saveFile(file, fileType);

          await _mediaService.saveMedia(
            MediaItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              path: savedPath,
              type: fileType,
              createdAt: DateTime.now(),
            ),
          );

          print('Paylaşılan dosya kaydedildi: $savedPath');
          onSharedContentProcessed?.call(
            '${fileType == MediaType.image ? 'Fotoğraf' : 'Video'} başarıyla aktarıldı',
          );
        } else {
          print('Desteklenmeyen dosya türü: ${sharedFile.type}');
          onSharedContentProcessed?.call('Desteklenmeyen dosya türü');
        }
      } catch (e) {
        print('Paylaşılan dosya işlenirken hata: $e');
        onSharedContentProcessed?.call('Dosya işlenirken hata oluştu');
      }
    }
  }

  MediaType? _getMediaTypeFromSharedFile(SharedMediaFile file) {
    try {
      print('Dosya türü kontrol ediliyor: ${file.type}');
      print('Dosya detayları: ${file.toMap()}');

      if (file.type.toString().contains('image')) {
        return MediaType.image;
      } else if (file.type.toString().contains('video')) {
        return MediaType.video;
      } else {
        print('Desteklenmeyen dosya türü: ${file.type}');
        return null;
      }
    } catch (e) {
      print('Dosya türü belirlenirken hata: $e');
      return null;
    }
  }

  // Periyodik kontrol için timer başlat (artık gerekli değil, stream kullanıyoruz)
  void startPeriodicCheck() {
    // receive_sharing_intent stream kullandığı için periyodik kontrol gerekmiyor
  }

  void dispose() {
    try {
      _intentDataStreamSubscription.cancel();
      print('ShareExtensionService dispose edildi');
    } catch (e) {
      print('ShareExtensionService dispose edilirken hata: $e');
    }
  }
}
