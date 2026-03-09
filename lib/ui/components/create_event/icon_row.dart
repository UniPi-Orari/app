import 'package:flutter/material.dart';

class IconRow extends StatelessWidget {
  const IconRow({
    super.key,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: Icon(
              icon,
              size: 22,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: trailing != null ? 0 : 16),
              child: child,
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
