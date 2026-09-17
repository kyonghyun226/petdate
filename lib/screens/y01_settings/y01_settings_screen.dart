import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/location/location_providers.dart';
import 'package:petdate/push/push_providers.dart';
import 'package:petdate/theme/tokens.dart';

const settingsEnableNotificationsKey = ValueKey<String>(
  'settings-enable-notifications',
);
const settingsEnableLocationKey = ValueKey<String>('settings-enable-location');

class Y01SettingsScreen extends ConsumerStatefulWidget {
  const Y01SettingsScreen({super.key});

  @override
  ConsumerState<Y01SettingsScreen> createState() => _Y01SettingsScreenState();
}

class _Y01SettingsScreenState extends ConsumerState<Y01SettingsScreen>
    with WidgetsBindingObserver {
  bool _locationOn = false;
  bool _notificationsOn = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final locationOn =
        await ref.read(locationCoordinatorProvider).isEnabled();
    final notificationsOn =
        await ref.read(pushCoordinatorProvider).isEnabled();
    if (!mounted) return;
    setState(() {
      _locationOn = locationOn;
      _notificationsOn = notificationsOn;
    });
  }

  Future<void> _setLocation(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (value) {
        final ok =
            await ref.read(locationCoordinatorProvider).enableFromSettings();
        if (!mounted) return;
        setState(() => _locationOn = ok);
      } else {
        setState(() => _locationOn = false);
        await ref.read(locationCoordinatorProvider).disableFromSettings();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<void> _setNotifications(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (value) {
        final ok =
            await ref.read(pushCoordinatorProvider).enableFromSettings();
        if (!mounted) return;
        setState(() => _notificationsOn = ok);
      } else {
        setState(() => _notificationsOn = false);
        await ref.read(pushCoordinatorProvider).disableFromSettings();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppCopy.settingsTitle)),
      body: ListView(
        children: [
          SwitchListTile(
            key: settingsEnableLocationKey,
            secondary: const Icon(Icons.location_on_outlined),
            title: const Text(AppCopy.settingsLocation),
            subtitle: const Text(AppCopy.settingsLocationHint),
            value: _locationOn,
            onChanged: _busy ? null : _setLocation,
          ),
          const Divider(),
          SwitchListTile(
            key: settingsEnableNotificationsKey,
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text(AppCopy.settingsNotifications),
            subtitle: const Text(AppCopy.settingsNotificationsHint),
            value: _notificationsOn,
            onChanged: _busy ? null : _setNotifications,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
          ),
        ],
      ),
    );
  }
}
