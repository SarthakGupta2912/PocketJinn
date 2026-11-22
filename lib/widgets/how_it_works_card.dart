// What is this file for?
// A small card that explains the three steps of a command, so a new user
// understands what will happen after they speak.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import 'app_card.dart';
import 'app_text.dart';
import 'section_title.dart';

/// Shows the three simple steps that describe how Pocket Jinn works.
class HowItWorksCard extends StatelessWidget {
  const HowItWorksCard({super.key});

  /// Builds the title and the three numbered steps.
  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: howItWorksTitle),
          SizedBox(height: AppSpacing.medium),
          AppText(howItWorksStepOne),
          SizedBox(height: AppSpacing.small),
          AppText(howItWorksStepTwo),
          SizedBox(height: AppSpacing.small),
          AppText(howItWorksStepThree),
        ],
      ),
    );
  }
}
