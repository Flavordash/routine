import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/language_service.dart';
import '../../services/notification_permission_service.dart';
import '../dialogs/tutorial_dialog.dart';

class SettingsDialog extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final LanguageService languageService;

  const SettingsDialog({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.languageService,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final NotificationPermissionService _permissionService = NotificationPermissionService.instance;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  Future<void> _openNotificationSettings() async {
    await _permissionService.openNotificationSettings();
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.settings,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Settings content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Toggle Section
                    _buildSettingsSection(
                      title: l10n.appearance,
                      children: [
                        ListTile(
                          leading: Icon(
                            _isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.theme),
                          subtitle: Text(
                            _isDarkMode ? l10n.darkMode : l10n.lightMode,
                          ),
                          trailing: Switch(
                            value: _isDarkMode,
                            onChanged: (value) {
                              setState(() {
                                _isDarkMode = value;
                              });
                              widget.onThemeToggle();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Language Section
                    _buildSettingsSection(
                      title: l10n.language,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.language,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.language),
                          subtitle: Text(
                            '${widget.languageService.getCurrentLanguageName()} (${widget.languageService.locale.languageCode})',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showLanguageSelector(l10n),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Notifications Section
                    _buildSettingsSection(
                      title: l10n.notifications,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openNotificationSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.notifications,
                                size: 20,
                              ),
                              label: Text(
                                l10n.notificationSettings,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            l10n.notificationPermissionDescription,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Help & Support Section
                    _buildSettingsSection(
                      title: l10n.helpAndSupport,
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.help_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.tutorial),
                          subtitle: Text(l10n.learnHowToUse),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showTutorial();
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.email_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.contactSupport),
                          subtitle: Text(l10n.getHelpAndAssistance),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _launchEmail(),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.privacy_tip_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(l10n.privacyPolicy),
                          subtitle: Text(l10n.viewPrivacyPolicy),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _launchPrivacyPolicy(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // About Section
                    _buildSettingsSection(
                      title: l10n.about,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Routine 24',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.developedBy,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                l10n.copyright,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showLanguageSelector(AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: widget.languageService.supportedLocales.length,
            itemBuilder: (context, index) {
              final locale = widget.languageService.supportedLocales[index];
              final languageName = widget.languageService.getLanguageName(
                locale.languageCode,
              );
              final nativeName = widget.languageService.getNativeName(
                locale.languageCode,
              );
              final isSelected = locale == widget.languageService.locale;

              return ListTile(
                title: Text(languageName),
                subtitle: Text(nativeName),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await widget.languageService.changeLanguage(locale);
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Language changed to $languageName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const TutorialDialog();
      },
    );
  }

  Future<void> _launchEmail() async {
    const String email = 'kwanapps2025@gmail.com';

    try {
      await Clipboard.setData(const ClipboardData(text: email));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email copied to clipboard: $email'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy email to clipboard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri privacyUri = Uri.parse('https://flavordash.github.io/routine24-privacy/');

    try {
      if (await canLaunchUrl(privacyUri)) {
        await launchUrl(
          privacyUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open privacy policy in browser'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening privacy policy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}