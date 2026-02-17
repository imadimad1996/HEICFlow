import 'package:flutter/material.dart';

class PulsePlaceholder extends StatefulWidget {
  const PulsePlaceholder({
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final BorderRadius borderRadius;

  @override
  State<PulsePlaceholder> createState() => _PulsePlaceholderState();
}

class _PulsePlaceholderState extends State<PulsePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: Color.lerp(
              scheme.surfaceContainerHighest,
              scheme.surfaceContainer,
              t,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
