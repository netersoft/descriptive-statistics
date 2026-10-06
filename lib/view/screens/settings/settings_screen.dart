import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../../core/enums/app_brightness.dart';
import '../../../core/helpers/ui/dialog_helper.dart';
import '../../../core/providers/settings/settings_provider.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/services/i18n/config.dart';
import '../../../core/services/i18n/translations.g.dart';
import '../../../core/tools/constants/chart_options.dart';
import '../../components/misc/floating_modal.dart';
import '../../themes/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      elevation: 0.0,
      title: Text(
        context.t.settings,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: AppTheme.getAppbarBgColor(),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () {
          context.pop();
        },
      ),
    ),
    body: const SettingsListWrapper(),
  );
}

class SettingsListWrapper extends ConsumerWidget {
  const SettingsListWrapper({super.key});

  SettingsTile _chartTypesTile<T extends Enum>({
    required BuildContext context,
    required String title,
    required String summary,
    required List<T> allTypes,
    required String Function(BuildContext, T) label,
    required Set<T> Function(SettingsState) getSelected,
    required void Function(Set<T>) setSelected,
  }) => SettingsTile.navigation(
    leading: const Icon(Icons.bar_chart),
    trailing: const Icon(Icons.chevron_right),
    title: Text(title),
    description: Text(summary),
    onPressed: (context) => showFloatingModalBottomSheet(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, ref, _) {
          final selected = getSelected(ref.watch(settingsProvider));
          return Material(
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final type in allTypes)
                    CheckboxListTile(
                      title: Text(label(sheetContext, type)),
                      value: selected.contains(type),
                      onChanged: (checked) => setSelected({
                        ...selected.where((t) => t != type),
                        if (checked ?? false) type,
                      }),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider.notifier);
    final state = ref.watch(settingsProvider);

    var currentLang = I18nConfig.langItems.firstWhereOrNull(
      (item) => item.code == LocaleSettings.instance.currentLocale.languageCode,
    );

    return SettingsList(
      sections: [
        SettingsSection(
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: const Icon(Icons.language),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentLang?.label[currentLang.code] ?? ''),
                  const Icon(Icons.chevron_right),
                ],
              ),
              title: Text(context.t.language),
              onPressed: (context) => {
                showFloatingModalBottomSheet(
                  context: context,
                  builder: (context) => Material(
                    child: SafeArea(
                      top: false,
                      child: RadioGroup<String>(
                        groupValue: LocaleSettings.instance.currentLocale.languageCode,
                        onChanged: (value) {
                          if (value != LocaleSettings.instance.currentLocale.languageCode) {
                            settings.changeLanguage(value!);
                            context.pop();
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: I18nConfig.langItems
                              .map<Widget>(
                                (item) => RadioListTile(
                                  title: Text(item.label[currentLang?.code]!),
                                  value: item.code,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              },
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.pin),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${state.decimalPrecision}'),
                  const Icon(Icons.chevron_right),
                ],
              ),
              title: Text(context.t.numberOfDecimals),
              onPressed: (context) => {
                showFloatingModalBottomSheet(
                  context: context,
                  builder: (context) => Material(
                    child: SafeArea(
                      top: false,
                      child: RadioGroup<int>(
                        groupValue: state.decimalPrecision,
                        onChanged: (value) {
                          if (value != state.decimalPrecision) {
                            settings.setDecimalPrecision(value!);
                          }
                          context.pop();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var precision = 0; precision <= 6; precision++)
                              RadioListTile(
                                title: Text('$precision'),
                                value: precision,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              },
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.format_paint),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.appBrightness == AppBrightness.system.name
                        ? context.t.system
                        : state.appBrightness == AppBrightness.light.name
                        ? context.t.light
                        : context.t.dark,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              title: Text(context.t.theme),
              onPressed: (context) => {
                showFloatingModalBottomSheet(
                  context: context,
                  builder: (context) => Material(
                    child: SafeArea(
                      top: false,
                      child: RadioGroup<String>(
                        groupValue: state.appBrightness,
                        onChanged: (value) {
                          if (value != state.appBrightness) {
                            settings.setAppBrightness(value!);
                            context.pop();
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile(
                              title: Text(context.t.light),
                              value: AppBrightness.light.name,
                            ),
                            RadioListTile(
                              title: Text(context.t.dark),
                              value: AppBrightness.dark.name,
                            ),
                            RadioListTile(
                              title: Text(context.t.system),
                              value: AppBrightness.system.name,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              },
            ),
          ],
        ),
        SettingsSection(
          title: Text(context.t.chartsSectionTitle),
          tiles: <SettingsTile>[
            _chartTypesTile<QuantitativeChartType>(
              context: context,
              title: context.t.discreteChartTypesTitle,
              summary: context.t.discreteChartTypesSummary,
              allTypes: QuantitativeChartType.values,
              label: quantitativeChartTypeLabel,
              getSelected: (state) => state.discreteChartTypes,
              setSelected: settings.setDiscreteChartTypes,
            ),
            _chartTypesTile<QuantitativeChartType>(
              context: context,
              title: context.t.continuousChartTypesTitle,
              summary: context.t.continuousChartTypesSummary,
              allTypes: QuantitativeChartType.values,
              label: quantitativeChartTypeLabel,
              getSelected: (state) => state.continuousChartTypes,
              setSelected: settings.setContinuousChartTypes,
            ),
            _chartTypesTile<QualitativeChartType>(
              context: context,
              title: context.t.qualitativeChartTypesTitle,
              summary: context.t.qualitativeChartTypesSummary,
              allTypes: QualitativeChartType.values,
              label: qualitativeChartTypeLabel,
              getSelected: (state) => state.qualitativeChartTypes,
              setSelected: settings.setQualitativeChartTypes,
            ),
          ],
        ),
        SettingsSection(
          title: Text(context.t.applicationSectionTitle),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: const Icon(Icons.info),
              trailing: const Icon(Icons.chevron_right),
              title: Text(context.t.about),
              onPressed: (context) => {
                DialogHelper.showContent(
                  context,
                  title: Text(
                    context.t.about,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('assets/images/launcher/icon.png', width: 96.0, height: 96.0),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.t.appNameAlt,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (ctx, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              'Version ${snapshot.data!.version}',
                              style: const TextStyle(fontSize: 14.0),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 25),
                      Text(
                        context.t.appDescription,
                        style: const TextStyle(fontSize: 16.0),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t.licenseNotice,
                        style: const TextStyle(fontSize: 12.0),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              },
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.privacy_tip),
              trailing: const Icon(Icons.chevron_right),
              title: Text(context.t.privacyPolicy),
              onPressed: (context) => const PrivacyPolicyRoute().push<void>(context),
            ),
            SettingsTile.navigation(
              leading: const Icon(Icons.share),
              trailing: const Icon(Icons.chevron_right),
              title: Text(context.t.recommandApp),
              onPressed: (context) => settings.shareApp(),
            ),
          ],
        ),
      ],
    );
  }
}
