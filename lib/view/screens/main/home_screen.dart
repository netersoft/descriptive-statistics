import 'package:flutter/material.dart';

import '../../../core/services/i18n/translations.g.dart';
import '../../themes/app_theme.dart';
import '../backups/backups_screen.dart';
import '../calculators/continuous_screen.dart';
import '../calculators/discrete_screen.dart';
import '../calculators/qualitative_screen.dart';
import '../documentation/documentation_screen.dart';
import '../tutorial/tutorial_screen.dart';

class HomeScreen extends StatelessWidget {
  final TabController tabController;

  const HomeScreen({required this.tabController, super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Material(
        color: AppTheme.getAppbarBgColor(),
        child: TabBar(
          controller: tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: context.t.documentation),
            Tab(text: context.t.discreteVariables),
            Tab(text: context.t.continuousVariables),
            Tab(text: context.t.qualitativeVariables),
            Tab(text: context.t.safeguards),
            Tab(text: context.t.tutorial),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: tabController,
          children: const [
            DocumentationScreen(),
            DiscreteScreen(),
            ContinuousScreen(),
            QualitativeScreen(),
            BackupsScreen(),
            TutorialScreen(),
          ],
        ),
      ),
    ],
  );
}
