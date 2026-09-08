import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/push/push_providers.dart';
import 'package:petdate/theme/tokens.dart';

const settingsEnableNotificationsKey = ValueKey<String>(
  'settings-enable-notifications',
);

class Y01SettingsScreen extends ConsumerWidget {
  const Y01SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerEnable = ref
        .watch(pushCoordinatorProvider)
        .shouldOfferEnableInSettings;

    return Scaffold(
      appBar: AppBar(title: const Text(AppCopy.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: const Text(AppCopy.settingsRadius),
            subtitle: Text('${AppConstants.searchRadiusKm.round()}km'),
          ),
          if (offerEnable) ...[
            const Divider(),
            ListTile(
              key: settingsEnableNotificationsKey,
              leading: const Icon(Icons.notifications_outlined),
              title: const Text(AppCopy.settingsEnableNotifications),
              subtitle: const Text(AppCopy.settingsNotificationsHint),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                ref.read(pushCoordinatorProvider).openOsNotificationSettings();
              },
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(AppCopy.settingsSoon, style: AppTypography.caption),
          ),
        ],
      ),
    );
  }
}
