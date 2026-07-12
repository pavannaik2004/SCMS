import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/server_url_override.dart';
import '../../../core/theme/app_colors.dart';

/// Renders a complaint media image from a server-relative (`/Storage/..`) or
/// absolute URL.
///
/// Resolves the effective backend base URL at runtime so images are fetched
/// from the same server the API calls go to. Media URLs from the backend are
/// relative (e.g. `/Storage/xyz.jpg`); prefixing them with the build-time
/// `.env` base URL breaks whenever a tester points the app at a different
/// server via [ServerUrlOverride] (LAN IP / tunnel) — the API works but the
/// images 404 against an unreachable `localhost`. This widget mirrors the
/// override so both stay in sync.
class MediaImage extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;

  const MediaImage({
    super.key,
    required this.url,
    this.width = 120,
    this.height = 120,
    this.fit = BoxFit.cover,
  });

  @override
  State<MediaImage> createState() => _MediaImageState();
}

class _MediaImageState extends State<MediaImage> {
  late Future<String> _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = _resolve();
  }

  @override
  void didUpdateWidget(covariant MediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _resolvedUrl = _resolve();
    }
  }

  Future<String> _resolve() async {
    if (widget.url.startsWith('http')) return widget.url;
    final override = await ServerUrlOverride.get();
    final base = (override != null && override.isNotEmpty)
        ? override
        : ApiConstants.baseUrl;
    return '$base${widget.url}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolvedUrl,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _placeholder(
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return Image.network(
          snapshot.data!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _placeholder(
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          errorBuilder: (_, __, ___) =>
              _placeholder(const Icon(Icons.broken_image_outlined)),
        );
      },
    );
  }

  Widget _placeholder(Widget child) => Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.surfaceVariant,
        child: child,
      );
}
