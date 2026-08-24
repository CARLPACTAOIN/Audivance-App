import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 48,
    this.decorative = false,
    this.semanticLabel = 'Audivance logo',
  });

  static const assetPath = 'assets/images/logo/audivance_logo.png';

  final double size;
  final bool decorative;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (decorative) {
      return ExcludeSemantics(child: image);
    }

    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(child: image),
    );
  }
}
