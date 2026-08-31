import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../core/helpers/ui/dialog_helper.dart';
import '../../core/providers/main/home_provider.dart';
import '../../core/providers/settings/settings_provider.dart';
import '../../core/routes/app_route.dart';
import '../../core/services/i18n/translations.g.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import 'main/home_screen.dart';

const _tabCount = 6;

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) => const CentralContainer();
}

class CentralContainer extends ConsumerStatefulWidget {
  const CentralContainer({super.key});

  @override
  ConsumerState<CentralContainer> createState() => _CentralContainerState();
}

class _CentralContainerState extends ConsumerState<CentralContainer> with SingleTickerProviderStateMixin {
  late final TabController tabController;

  @override
  void initState() {
    super.initState();

    AppTheme.setStatusBarColor();

    tabController = TabController(length: _tabCount, vsync: this, initialIndex: ref.read(homeProvider));
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        ref.read(homeProvider.notifier).tabIndex = tabController.index;
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    tabController.animateTo(index);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      elevation: 0.0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/launcher/logo_reverse.svg',
            width: 90.0,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            const SettingsRoute().push(context);
          },
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
      backgroundColor: AppTheme.getAppbarBgColor(),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: HomeScreen(tabController: tabController),
    drawer: Drawer(
      backgroundColor: AppTheme.pickColor(
        light: Colors.white,
        dark: AppColors.blackRussian,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.pickColor(
                light: AppTheme.primaryColor,
                dark: AppColors.raisinBlack,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  context.t.appNameAlt,
                  style: const TextStyle(fontSize: 21, color: Colors.white),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(context.t.documentation),
            onTap: () => _goToTab(0),
          ),
          ListTile(
            leading: const Icon(Icons.pin),
            title: Text(context.t.discreteVariables),
            onTap: () => _goToTab(1),
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: Text(context.t.continuousVariables),
            onTap: () => _goToTab(2),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(context.t.qualitativeVariables),
            onTap: () => _goToTab(3),
          ),
          ListTile(
            leading: const Icon(Icons.save),
            title: Text(context.t.safeguards),
            onTap: () => _goToTab(4),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: Text(context.t.tutorial),
            onTap: () => _goToTab(5),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(context.t.settings),
            onTap: () {
              Navigator.of(context).pop();
              const SettingsRoute().push(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(context.t.about),
            onTap: () {
              Navigator.of(context).pop();
              DialogHelper.showContent(
                context,
                title: Text(
                  context.t.about,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                content: Text(context.t.appDescription, textAlign: TextAlign.justify),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(context.t.share),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(settingsProvider.notifier).shareApp();
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: Text(context.t.rateApp),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(settingsProvider.notifier).rateApp();
            },
          ),
        ],
      ),
    ),
  );
}
