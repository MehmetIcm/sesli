import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_info.dart';
import '../tts_controller.dart';
import '../widgets/brand_mark.dart';
import '../widgets/control_panel.dart';
import '../widgets/editor_card.dart';
import '../widgets/history_section.dart';
import '../widgets/player_card.dart';
import 'about_screen.dart';
import 'history_screen.dart';
import 'licenses_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TtsController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            controller.synthesize,
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            controller.synthesize,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 34),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppInfo.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (MediaQuery.sizeOf(context).width > 720)
                      Text(
                        AppInfo.tagline,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: isDark ? 'Açık temaya geç' : 'Koyu temaya geç',
                onPressed: () {
                  controller.setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Geçmiş',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HistoryScreen(),
                    ),
                  );
                },
                icon: controller.history.isEmpty
                    ? const Icon(Icons.history_rounded)
                    : Badge.count(
                        count: controller.history.length,
                        child: const Icon(Icons.history_rounded),
                      ),
              ),
              IconButton(
                tooltip: 'Ayarlar',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
              ),
              PopupMenuButton<String>(
                tooltip: 'Daha fazla',
                onSelected: (value) {
                  final page = switch (value) {
                    'about' => const AboutScreen(),
                    'privacy' => const PrivacyScreen(),
                    _ => const LicensesScreen(),
                  };
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => page));
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'about',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('Hakkında'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'privacy',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.shield_outlined),
                      title: Text('Gizlilik'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'licenses',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.description_outlined),
                      title: Text('Lisanslar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.surface,
                  scheme.surfaceContainerLow.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final horizontal = wide ? 32.0 : 16.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Hero(compact: !wide),
                            const SizedBox(height: 18),
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(flex: 7, child: EditorCard()),
                                  const SizedBox(width: 18),
                                  const Expanded(
                                    flex: 5,
                                    child: ControlPanel(),
                                  ),
                                ],
                              )
                            else ...[
                              const EditorCard(),
                              const SizedBox(height: 16),
                              const ControlPanel(),
                            ],
                            if (controller.hasResult) ...[
                              const SizedBox(height: 18),
                              const PlayerCard(),
                            ],
                            if (controller.history.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const HistorySection(),
                            ],
                            const SizedBox(height: 28),
                            _Footer(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metniniz, doğal Türkçe sesle.',
            style:
                (compact
                        ? theme.textTheme.headlineLarge
                        : theme.textTheme.displaySmall)
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: compact ? -0.8 : -1.4,
                      height: 1.08,
                    ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Altı gerçek Türkçe konuşmacı, akıllı metin normalizasyonu ve '
              'gerçek MP3 çıktısı. Her şey cihazınızda çalışır.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroChip(
                icon: Icons.wifi_off_rounded,
                label: 'Tamamen çevrimdışı',
              ),
              _HeroChip(
                icon: Icons.record_voice_over_outlined,
                label: '6 doğal ses',
              ),
              _HeroChip(icon: Icons.audio_file_outlined, label: 'Gerçek MP3'),
              _HeroChip(
                icon: Icons.translate_rounded,
                label: 'Türkçe normalizasyon',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 22),
                const SizedBox(width: 8),
                Text(
                  '${AppInfo.name} · Sürüm ${AppInfo.version}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => _push(context, const PrivacyScreen()),
              child: const Text('Gizlilik'),
            ),
            TextButton(
              onPressed: () => _push(context, const LicensesScreen()),
              child: const Text('Lisanslar'),
            ),
            TextButton(
              onPressed: () => _push(context, const AboutScreen()),
              child: const Text('Hakkında'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Metinleriniz cihazınızdan çıkmaz. Sunucu, hesap, reklam veya analiz yok.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
