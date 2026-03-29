import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_dimens.dart';

class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor      = isDark ? const Color(0xFF252438) : const Color(0xFFEEECFF);
    final highlightColor = isDark ? const Color(0xFF2E2C45) : const Color(0xFFFFFFFF);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1400),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.pagePadH, AppDimens.spaceMd,
            AppDimens.pagePadH, AppDimens.pagePadH),
        itemCount: 5,
        itemBuilder: (_, i) => _ShimmerCard(index: i),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final int index;
  const _ShimmerCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final height = index % 2 == 0 ? AppDimens.shimmerCardH1 : AppDimens.shimmerCardH2;
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: AppDimens.spaceXl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.cardPad),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: AppDimens.thumbnailCard,
              height: AppDimens.thumbnailCard,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.thumbnailCardRad),
              ),
            ),
            const SizedBox(width: AppDimens.spaceXl),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: AppDimens.shimmerTitleH,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceMd),
                  Container(
                    height: AppDimens.shimmerSubtitleH,
                    width: AppDimens.shimmerSubtitleW,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm - 1),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceLg),
                  // Progress bar placeholder
                  Container(
                    height: AppDimens.shimmerBarH,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.spaceXs),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}