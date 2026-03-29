import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_strings.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF252438), const Color(0xFF2E2C45)]
                      : [const Color(0xFFEEECFF), const Color(0xFFE4E2FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.checklist_rounded,
                  size: 52,
                  color: AppTheme.primaryColor.withValues(alpha: 0.85),
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                    end: 1.06,
                    duration: 2000.ms,
                    curve: Curves.easeInOut),
            const Gap(28),
            Text(
              AppStrings.emptyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const Gap(10),
            Text(
              AppStrings.emptySubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const Gap(32),
            // Decorative dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                    (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == 1 ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == 1
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor
                        .withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 600.ms),
          ],
        ),
      ),
    );
  }
}