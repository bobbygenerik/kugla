import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app/theme.dart';

/// Full-screen cinematic splash: plays [assets/splash/splash_reveal.mp4] once,
/// then calls [onVideoComplete] if provided.
class StartupSplashScreen extends StatefulWidget {
  const StartupSplashScreen({
    super.key,
    this.onVideoComplete,
  });

  final VoidCallback? onVideoComplete;

  @override
  State<StartupSplashScreen> createState() => _StartupSplashScreenState();
}

class _StartupSplashScreenState extends State<StartupSplashScreen> {
  VideoPlayerController? _controller;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(
      'assets/splash/splash_reveal.mp4',
    );
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onTick);
      setState(() => _controller = controller);
      // Start playback after the first frame so [VideoPlayer] is attached (avoids
      // silent no-op [play] on some Android/iOS builds).
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _notified) return;
        final c = _controller;
        if (c == null) return;
        await c.setVolume(1.0);
        await c.play();
      });
    } catch (_) {
      await controller.dispose();
      _finish();
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _notified) return;
    final d = c.value.duration;
    if (d == Duration.zero) return;
    if (c.value.position >= d - const Duration(milliseconds: 120)) {
      _finish();
    }
  }

  void _finish() {
    if (_notified) return;
    _notified = true;
    widget.onVideoComplete?.call();
  }

  void _skip() {
    _controller?.pause();
    _finish();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: KuglaColors.deepSpace,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: KuglaColors.deepSpace),
          if (c != null && c.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: KuglaColors.cyan),
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: TextButton(
              onPressed: _skip,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: KuglaColors.textMuted.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
