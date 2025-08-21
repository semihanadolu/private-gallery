import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  static const String _storageKey = 'media_items';
  late Directory _appDir;

  Future<void> initialize() async {
    _appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${_appDir.path}/media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
  }

  Future<List<MediaItem>> getAllMedia() async {
    final prefs = await SharedPreferences.getInstance();
    final mediaJson = prefs.getStringList(_storageKey) ?? [];
    
    return mediaJson
        .map((json) => MediaItem.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveMedia(MediaItem media) async {
    final prefs = await SharedPreferences.getInstance();
    final mediaList = await getAllMedia();
    mediaList.add(media);
    
    final mediaJson = mediaList
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    await prefs.setStringList(_storageKey, mediaJson);
  }

  Future<void> deleteMedia(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final mediaList = await getAllMedia();
    final mediaToDelete = mediaList.firstWhere((item) => item.id == id);
    
    // Dosyayı fiziksel olarak sil
    final file = File(mediaToDelete.path);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Thumbnail varsa onu da sil
    if (mediaToDelete.thumbnailPath != null) {
      final thumbnailFile = File(mediaToDelete.thumbnailPath!);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
    }
    
    // Listeden kaldır
    mediaList.removeWhere((item) => item.id == id);
    
    final mediaJson = mediaList
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    await prefs.setStringList(_storageKey, mediaJson);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  Future<String> saveFile(File file, MediaType type) async {
    final fileName = '${_generateId()}.${type == MediaType.image ? 'jpg' : 'mp4'}';
    final savedFile = await file.copy('${_appDir.path}/media/$fileName');
    return savedFile.path;
  }

  Future<MediaItem?> getMediaById(String id) async {
    final mediaList = await getAllMedia();
    try {
      return mediaList.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
