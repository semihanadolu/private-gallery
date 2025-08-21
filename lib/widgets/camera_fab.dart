import 'package:flutter/material.dart';

class CameraFAB extends StatefulWidget {
  final VoidCallback onPhotoPressed;
  final VoidCallback onVideoPressed;
  final VoidCallback onGalleryPressed;

  const CameraFAB({
    super.key,
    required this.onPhotoPressed,
    required this.onVideoPressed,
    required this.onGalleryPressed,
  });

  @override
  State<CameraFAB> createState() => _CameraFABState();
}

class _CameraFABState extends State<CameraFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Genişletilmiş butonlar
        if (_isExpanded) ...[
          _buildActionButton(
            icon: Icons.photo_library,
            label: 'Galeri',
            onPressed: () {
              _toggleExpanded();
              widget.onGalleryPressed();
            },
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.videocam,
            label: 'Video',
            onPressed: () {
              _toggleExpanded();
              widget.onVideoPressed();
            },
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Fotoğraf',
            onPressed: () {
              _toggleExpanded();
              widget.onPhotoPressed();
            },
          ),
          const SizedBox(height: 16),
        ],
        
        // Ana FAB
        FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: Colors.blue,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: Colors.grey[800],
            mini: true,
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
