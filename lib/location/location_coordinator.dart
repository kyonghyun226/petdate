import 'dart:async';

import 'package:flutter/material.dart';
import 'package:petdate/location/geo.dart';
import 'package:petdate/location/location_permission_gate.dart';
import 'package:petdate/location/location_preprompt.dart';
import 'package:petdate/location/location_prompt_store.dart';
import 'package:petdate/location/location_service.dart';

typedef LocationBoolCheck = bool Function();
typedef LocationUidProvider = String? Function();
typedef LocationPersist = Future<void> Function({
  required String uid,
  required ApproxLatLng point,
});

/// Permission timing, GPS read, and pet geo write. Auth missing is a no-op.
class LocationCoordinator {
  LocationCoordinator({
    required this.store,
    required this.service,
    required this.hasAuth,
    required this.onMain,
    required this.uid,
    required this.persistLocation,
    this.navigatorKey,
    this.onLocationChanged,
  });

  final LocationPromptStore store;
  final LocationService service;
  final LocationBoolCheck hasAuth;
  final LocationBoolCheck onMain;
  final LocationUidProvider uid;
  final LocationPersist persistLocation;
  final GlobalKey<NavigatorState>? navigatorKey;
  final ValueChanged<ApproxLatLng?>? onLocationChanged;

  bool _attached = false;
  bool _promptInFlight = false;
  ApproxLatLng? _lastKnown;

  ApproxLatLng? get lastKnown => _lastKnown;

  LocationPermissionGate gate() => LocationPermissionGate(
        hasAuth: hasAuth(),
        onMain: onMain(),
        alreadyAsked: store.hasAsked,
      );

  bool get shouldOfferEnableInSettings => store.shouldOfferEnableInSettings;

  Future<void> attach() async {
    if (_attached) return;
    _attached = true;
    await store.hydrate();
    await syncIfAllowed();
  }

  /// First main entry. Pre-prompt → OS. Deny never blocks browsing.
  Future<void> maybeAskOnMain(BuildContext context) async {
    if (_promptInFlight) return;
    await store.hydrate();
    if (!gate().canShowPreprompt) {
      await syncIfAllowed();
      return;
    }
    if (!context.mounted) return;

    _promptInFlight = true;
    try {
      final allow = await showLocationPreprompt(context);
      if (allow) {
        await store.markAsked();
        final granted = await _requestOs();
        if (granted) {
          await store.markGranted();
          await syncIfAllowed();
        } else {
          await store.markOsDenied();
        }
      } else {
        await store.markDeclinedPreprompt();
      }
    } finally {
      _promptInFlight = false;
    }
  }

  Future<bool> _requestOs() async {
    final enabled = await service.isServiceEnabled();
    if (!enabled) {
      await service.openLocationSettings();
      return false;
    }
    var status = await service.checkPermission();
    if (!status.isGranted) {
      status = await service.requestPermission();
    }
    return status.isGranted;
  }

  /// Refresh GPS + pet doc when OS already allows.
  Future<void> syncIfAllowed() async {
    if (!hasAuth() || !onMain()) return;
    final myUid = uid();
    if (myUid == null) return;

    final status = await service.checkPermission();
    if (!status.isGranted) return;
    if (!await service.isServiceEnabled()) return;

    await store.markGranted();
    final point = await service.currentPosition();
    if (point == null) return;

    _lastKnown = point;
    onLocationChanged?.call(point);
    try {
      await persistLocation(uid: myUid, point: point);
    } on Object {
      // Offline / rules — keep local origin for distance UI.
    }
  }

  Future<void> openOsLocationSettings() async {
    await service.openAppSettings();
  }

  /// OS location permission currently granted (and services on).
  Future<bool> isEnabled() async {
    try {
      if (!await service.isServiceEnabled()) return false;
      return (await service.checkPermission()).isGranted;
    } on Object {
      return false;
    }
  }

  /// Settings toggle ON: request OS permission and sync.
  Future<bool> enableFromSettings() async {
    await store.markAsked();
    final granted = await _requestOs();
    if (granted) {
      await store.markGranted();
      await syncIfAllowed();
      return true;
    }
    await store.markOsDenied();
    await openOsLocationSettings();
    return false;
  }

  /// Settings toggle OFF: stop using location in-app and open OS settings.
  Future<void> disableFromSettings() async {
    _lastKnown = null;
    onLocationChanged?.call(null);
    await store.markDeclinedPreprompt();
    await openOsLocationSettings();
  }

  void onSignedOut() {
    _lastKnown = null;
    onLocationChanged?.call(null);
    _attached = false;
  }

  void dispose() {}
}
