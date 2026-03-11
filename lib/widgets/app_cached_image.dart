import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppCachedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? placeholderBackground;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderBackground,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final u = (url ?? '').trim();
    final content = u.isEmpty
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: u,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholderFadeInDuration: const Duration(milliseconds: 80),
            placeholder: (context, _) => _placeholder(context),
            errorWidget: (context, _, __) => errorWidget ?? _fallback(),
          );

    final br = borderRadius;
    if (br == null) return content;
    return ClipRRect(borderRadius: br, child: content);
  }

  Widget _placeholder(BuildContext context) {
    final bg = placeholderBackground ?? Colors.grey.shade200;
    return Container(
      width: width,
      height: height,
      color: bg,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: placeholderBackground ?? Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}

