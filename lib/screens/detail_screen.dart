import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/media_item.dart';
import '../controllers/media_controller.dart';
import '../controllers/auth_controller.dart';

class DetailScreen extends StatefulWidget {
  final MediaItem mediaItem;

  const DetailScreen({super.key, required this.mediaItem});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final MediaController _mediaController = MediaController();
  final AuthController _authController = AuthController();
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
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
    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    if (widget.mediaItem.type == MediaType.video) {
      await _initializeVideo();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _videoPlayerController = VideoPlayerController.file(
        File(widget.mediaItem.path),
      );
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[300]!,
        ),
      );
    } catch (e) {
      debugPrint('Video yüklenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
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
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            widget.mediaItem.type == MediaType.image ? 'Fotoğraf' : 'Video',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDialog,
              tooltip: 'Sil',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _buildMediaContent(),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.mediaItem.type == MediaType.image) {
      return _buildImageViewer();
    } else {
      return _buildVideoPlayer();
    }
  }

  Widget _buildImageViewer() {
    return FutureBuilder<bool>(
      future: File(widget.mediaItem.path).exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.data == true) {
          return PhotoView(
            imageProvider: FileImage(File(widget.mediaItem.path)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        } else {
          return _buildErrorWidget();
        }
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (_chewieController != null) {
      return Center(child: Chewie(controller: _chewieController!));
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.mediaItem.type == MediaType.image
                ? Icons.broken_image
                : Icons.video_file,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Medya yüklenemedi',
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Dosya bulunamadı veya bozuk',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Medyayı Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bu ${widget.mediaItem.type == MediaType.image ? 'fotoğrafı' : 'videoyu'} silmek istediğinizden emin misiniz?',
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
                await _mediaController.deleteMedia(widget.mediaItem.id);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Silme işlemi başarısız: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
