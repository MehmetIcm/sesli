import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/pocket_tts_model.dart';
import '../tts_controller.dart';
import 'about_screen.dart';
import 'licenses_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TtsController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _SettingsCard(
                icon: Icons.palette_outlined,
                title: 'Görünüm',
                subtitle: 'Tema tercihi cihazınızda saklanır.',
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('Sistem'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Açık'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Koyu'),
                    ),
                  ],
                  selected: {controller.themeMode},
                  onSelectionChanged: (value) {
                    controller.setThemeMode(value.first);
                  },
                ),
              ),
              const SizedBox(height: 14),
              _SettingsCard(
                icon: Icons.play_circle_outline_rounded,
                title: 'Oynatma',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: controller.autoPlay,
                      onChanged: controller.setAutoPlay,
                      title: const Text('Seslendirme bitince otomatik oynat'),
                      subtitle: const Text(
                        'Kapalıysa MP3 hazır olduğunda oynatıcıyı siz başlatırsınız.',
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: controller.saveHistory,
                      onChanged: controller.setSaveHistory,
                      title: const Text('Geçmişe kaydet'),
                      subtitle: const Text(
                        'Yalnızca metin ve ayarlar saklanır; ses dosyası saklanmaz.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SettingsCard(
                icon: Icons.tune_rounded,
                title: 'Seslendirme',
                subtitle: 'Varsayılan hız ve kalite.',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hız',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${controller.speed.toStringAsFixed(1)}×',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: controller.speed,
                      min: 0.7,
                      max: 1.3,
                      divisions: 12,
                      label: '${controller.speed.toStringAsFixed(1)}×',
                      onChanged: controller.setSpeed,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Kalite (difüzyon adımı)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${controller.numSteps}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: controller.numSteps.toDouble(),
                      min: 2,
                      max: 8,
                      divisions: 6,
                      label: '${controller.numSteps} adım',
                      onChanged: (value) =>
                          controller.setNumSteps(value.round()),
                    ),
                    Text(
                      'Daha yüksek değer daha temiz ses üretir, ancak daha '
                      'yavaştır. Önerilen: 8.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SettingsCard(
                icon: Icons.memory_rounded,
                title: 'Model',
                subtitle: 'Cihaz üzerinde çalışan Türkçe ses modeli.',
                child: Column(
                  children: [
                    _InfoRow(label: 'Model', value: PocketTtsModel.name),
                    _InfoRow(label: 'Sürüm', value: PocketTtsModel.version),
                    _InfoRow(
                      label: 'Yaklaşık boyut',
                      value: formatBytes(PocketTtsModel.approximateTotalBytes),
                    ),
                    _InfoRow(label: 'Lisans', value: PocketTtsModel.license),
                    _InfoRow(
                      label: 'Motor',
                      value: 'sherpa-onnx · ONNX Runtime',
                    ),
                    _InfoRow(
                      label: 'Örnekleme',
                      value: '24 kHz kaynak · 48 kHz çıkış',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SettingsCard(
                icon: Icons.storage_outlined,
                title: 'Veriler',
                subtitle: 'Geçmiş ve model önbelleği.',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_sweep_outlined),
                      title: const Text('Geçmişi temizle'),
                      subtitle: Text('${controller.history.length} kayıt'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: controller.history.isEmpty
                          ? null
                          : () => _clearHistory(context, controller),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.shield_outlined),
                      title: const Text('Gizlilik'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _push(context, const PrivacyScreen()),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Lisanslar ve kaynaklar'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _push(context, const LicensesScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SettingsCard(
                icon: Icons.info_outline_rounded,
                title: 'Uygulama',
                child: Column(
                  children: [
                    _InfoRow(label: 'Ad', value: AppInfo.name),
                    _InfoRow(label: 'Sürüm', value: AppInfo.version),
                    _InfoRow(label: 'Paket', value: AppInfo.bundleId),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _push(context, const AboutScreen()),
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: const Text('Hakkında'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppInfo.privacySummary,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _clearHistory(
    BuildContext context,
    TtsController controller,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geçmiş temizlensin mi?'),
        content: const Text(
          'Tüm seslendirme kayıtları silinir. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearHistory();
      messenger.showSnackBar(
        const SnackBar(content: Text('Geçmiş temizlendi.')),
      );
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
