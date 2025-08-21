import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';

class MediaGridItem extends StatefulWidget {
  final MediaItem mediaItem;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MediaGridItem({
    super.key,
    required this.mediaItem,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<MediaGridItem> createState() => _MediaGridItemState();
}

class _MediaGridItemState extends State<MediaGridItem> {
  VideoPlayerController? _videoController;
  bool _isVideoThumbnailLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaItem.type == MediaType.video) {
      _initializeVideoThumbnail();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoThumbnail() async {
    try {
      _videoController = VideoPlayerController.file(
        File(widget.mediaItem.path),
      );
      await _videoController!.initialize();

      // Video'nun ilk frame'ini al
      await _videoController!.seekTo(Duration.zero);

      if (mounted) {
        setState(() {
          _isVideoThumbnailLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Video thumbnail yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Medya içeriği
              _buildMediaContent(),

              // Video ikonu (eğer video ise)
              if (widget.mediaItem.type == MediaType.video)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),

              // Tarih bilgisi
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDate(widget.mediaItem.createdAt),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    return FutureBuilder<bool>(
      future: File(widget.mediaItem.path).exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          if (widget.mediaItem.type == MediaType.image) {
            return Image.file(
              File(widget.mediaItem.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget();
              },
            );
          } else {
            return _buildVideoThumbnail();
          }
        } else {
          return _buildErrorWidget();
        }
      },
    );
  }

  Widget _buildVideoThumbnail() {
    if (_videoController != null && _isVideoThumbnailLoaded) {
      return VideoPlayer(_videoController!);
    } else {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.video_file, color: Colors.white, size: 32),
        ),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white, size: 32),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
