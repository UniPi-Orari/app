import 'package:flutter/material.dart';

class TappableText extends StatelessWidget {
  const TappableText({
    super.key,
    required this.text,
    required this.onTapWithContext,
    this.muted = false,
  });

  final String text;
  final void Function(BuildContext context) onTapWithContext;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Builder(
      builder: (ctx) => InkWell(
        onTap: () => onTapWithContext(ctx),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: muted ? theme.colorScheme.onSurface.withOpacity(0.55) : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
