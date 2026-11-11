import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UnauthenticatedPromptView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;

  const UnauthenticatedPromptView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Chế độ Khách · Chưa đăng nhập trên app',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

