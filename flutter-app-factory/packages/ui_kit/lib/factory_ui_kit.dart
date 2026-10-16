import 'package:flutter/material.dart';

class FactoryTheme {
  FactoryTheme._();
  static const Color seed = Color(0xFF3867D6);
  static ThemeData theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

/// Reusable constraint-based surface; does not force phone widths on tablets.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({required this.child, super.key});
  final Widget child;
  static const double maxWidth = 840;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
