// What is this file for?
// A short, honest help screen that opens the Android pages which keep the
// offline wake listener running: notifications, battery and auto-start.
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/wake_constants.dart';
import '../services/keep_alive_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_text.dart';
import '../widgets/responsive_body.dart';
import '../widgets/section_title.dart';

/// Shows the three phone settings that help the wake listener stay alive.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Checks the battery setting and opens the matching Android pages.
class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final KeepAliveService _service = KeepAliveService();
  bool _batteryIgnored = false;
  bool _isBusy = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshBattery());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Refreshes the battery answer when the user comes back from a page.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshBattery());
    }
  }

  /// Builds the help cards and the done button.
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: onboardingTitle,
      body: ResponsiveBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppSpacing.small,
            bottom: AppSpacing.extraLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppText(onboardingIntro, role: AppTextRole.body),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              _buildNotificationCard(),
              const SizedBox(height: AppSpacing.large),
              _buildBatteryCard(),
              const SizedBox(height: AppSpacing.large),
              _buildAutoStartCard(),
              const SizedBox(height: AppSpacing.large),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      onboardingHonestNote,
                      role: AppTextRole.caption,
                      useMutedColor: true,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    AppButton(
                      label: onboardingOpenAppInfoButton,
                      isSecondary: true,
                      onPressed: _isBusy ? null : _openAppInfo,
                    ),
                  ],
                ),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.medium),
                AppText(
                  _status,
                  role: AppTextRole.caption,
                  useMutedColor: true,
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              AppButton(
                label: onboardingDoneButton,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Notification permission card.
  Widget _buildNotificationCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: onboardingNotificationsTitle),
          const SizedBox(height: AppSpacing.small),
          const AppText(
            onboardingNotificationsNote,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
          const SizedBox(height: AppSpacing.medium),
          AppButton(
            label: onboardingAllowNotificationsButton,
            isSecondary: true,
            onPressed: _isBusy ? null : _allowNotifications,
          ),
        ],
      ),
    );
  }

  /// Battery optimisation card.
  Widget _buildBatteryCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: onboardingBatteryTitle),
          const SizedBox(height: AppSpacing.small),
          const AppText(
            onboardingBatteryNote,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
          const SizedBox(height: AppSpacing.small),
          AppText(
            _batteryIgnored
                ? onboardingBatteryAlreadyAllowed
                : onboardingBatteryStillOn,
            role: AppTextRole.caption,
            useMutedColor: !_batteryIgnored,
          ),
          const SizedBox(height: AppSpacing.medium),
          AppButton(
            label: onboardingOpenBatteryButton,
            isSecondary: true,
            onPressed: _isBusy ? null : _openBattery,
          ),
        ],
      ),
    );
  }

  /// Manufacturer auto-start card.
  Widget _buildAutoStartCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: onboardingAutoStartTitle),
          const SizedBox(height: AppSpacing.small),
          const AppText(
            onboardingAutoStartNote,
            role: AppTextRole.caption,
            useMutedColor: true,
          ),
          const SizedBox(height: AppSpacing.medium),
          AppButton(
            label: onboardingOpenAutoStartButton,
            isSecondary: true,
            onPressed: _isBusy ? null : _openAutoStart,
          ),
        ],
      ),
    );
  }

  /// Asks Android for notification access.
  Future<void> _allowNotifications() async {
    setState(() => _isBusy = true);
    final allowed = await _service.requestNotificationPermission();
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _status = allowed
          ? onboardingNotificationAllowed
          : onboardingNotificationBlocked;
    });
  }

  /// Opens the battery exemption page.
  Future<void> _openBattery() async {
    final opened = await _service.openPage('battery');
    if (!mounted) return;
    setState(
      () => _status = opened ? onboardingActionOpened : onboardingActionFailed,
    );
  }

  /// Opens the manufacturer auto-start page.
  Future<void> _openAutoStart() async {
    final opened = await _service.openPage('autoStart');
    if (!mounted) return;
    setState(
      () => _status = opened ? onboardingActionOpened : onboardingActionFailed,
    );
  }

  /// Opens this app's information page as a safe fallback.
  Future<void> _openAppInfo() async {
    final opened = await _service.openPage('appDetails');
    if (!mounted) return;
    setState(
      () => _status = opened ? onboardingActionOpened : onboardingActionFailed,
    );
  }

  /// Reads whether battery optimisation is already off.
  Future<void> _refreshBattery() async {
    final ignored = await _service.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() => _batteryIgnored = ignored);
  }
}
