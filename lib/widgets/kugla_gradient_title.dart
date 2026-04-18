import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Static foil gradient on headline text — matches [KuglaShell] app bar title.
class KuglaGradientTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const KuglaGradientTitle(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = style ??
        Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white,
            );
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          KuglaColors.cyanSoft,
          KuglaColors.cyan,
          KuglaColors.fog.withValues(alpha: 0.92),
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(bounds),
      child: Text(text, style: base),
    );
  }
}
