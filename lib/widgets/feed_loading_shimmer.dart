import 'package:flutter/material.dart';
import 'package:social_app/widgets/custom_shimmer.dart';

class FeedLoadingShimmer extends StatelessWidget {
  const FeedLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // تأثير تحميل القصص
              CustomShimmer(
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 15),

              // تأثير تحميل المنشورات
              for (int i = 0; i < 2; i++) ...[
                CustomShimmer(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
