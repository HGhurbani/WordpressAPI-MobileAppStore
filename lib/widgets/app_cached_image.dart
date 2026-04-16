import 'dart:math' as math;

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
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final devicePixelRatio =
            MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
        final resolvedWidth = _finiteDimension(width ?? constraints.maxWidth) ??
            MediaQuery.sizeOf(context).width;
        final resolvedHeight =
            _finiteDimension(height ?? constraints.maxHeight);
        final cacheWidth = _cacheDimension(resolvedWidth, devicePixelRatio);
        final cacheHeight = _cacheDimension(resolvedHeight, devicePixelRatio);

        if (u.isEmpty) {
          return _fallback();
        }

        return CachedNetworkImage(
          imageUrl: u,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 80),
          placeholderFadeInDuration: const Duration(milliseconds: 40),
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          maxWidthDiskCache: cacheWidth,
          maxHeightDiskCache: cacheHeight,
          placeholder: (context, _) => _placeholder(context),
          errorWidget: (context, _, __) => errorWidget ?? _fallback(),
        );
      },
    );

    final br = borderRadius;
    if (br == null) return content;
    return ClipRRect(borderRadius: br, child: content);
  }

  double? _finiteDimension(double value) {
    if (!value.isFinite || value <= 0) {
      return null;
    }
    return value;
  }

  int? _cacheDimension(double? logicalDimension, double devicePixelRatio) {
    if (logicalDimension == null || !logicalDimension.isFinite || logicalDimension <= 0) {
      return null;
    }

    final scaled = (logicalDimension * devicePixelRatio).round();
    return math.max(64, math.min(scaled, 2048));
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

