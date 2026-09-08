import 'package:flutter/material.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/theme/tokens.dart';

class Y01SettingsScreen extends StatelessWidget {
  const Y01SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppCopy.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: const Text(AppCopy.settingsRadius),
            subtitle: Text('${AppConstants.searchRadiusKm.round()}km'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              AppCopy.settingsSoon,
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
