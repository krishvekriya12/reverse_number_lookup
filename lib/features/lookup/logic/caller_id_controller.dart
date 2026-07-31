import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CallerIdState { setupRequired, enableRequired, healthy }

class CallerIdController extends ChangeNotifier {
  static final CallerIdController instance = CallerIdController();
  static const String _prefKeyEnabled = 'caller_id_enabled';

  CallerIdState state = CallerIdState.setupRequired;
  bool isInitialized = false;

  Future<void> refresh() async {
    final isHealthy = await isCallerIdFullyConfigured();
    final isEnabled = await _isEnabled();

    if (!isHealthy) {
      state = CallerIdState.setupRequired;
    } else if (!isEnabled) {
      state = CallerIdState.enableRequired;
    } else {
      state = CallerIdState.healthy;
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, enabled);
    await refresh();
  }

  Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyEnabled) ?? false;
  }

  Future<bool> isCallerIdFullyConfigured() async {
    final phoneState = await Permission.phone.isGranted;
    final contacts = await Permission.contacts.isGranted;
    final overlay = await Permission.systemAlertWindow.isGranted;

    if (!phoneState || !contacts || !overlay) return false;

    return true;
  }

  Future<bool> isPhoneContactGranted() async {
    final phoneState = await Permission.phone.isGranted;
    final contacts = await Permission.contacts.isGranted;
    return phoneState && contacts;
  }

  Future<bool> isOverlayGranted() async {
    return Permission.systemAlertWindow.isGranted;
  }

  Future<bool> isNotificationGranted() async {
    return Permission.notification.isGranted;
  }

  Future<void> requestPhoneContacts() async {
    await [Permission.phone, Permission.contacts].request();
    await refresh();
  }

  Future<void> requestNotifications() async {
    await Permission.notification.request();
    await refresh();
  }

  Future<void> requestOverlay() async {
    await Permission.systemAlertWindow.request();
    await refresh();
  }
}
