import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';
import '../widgets/brand_mark.dart';
import 'licenses_screen.dart';
import 'privacy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Column(
                  children: [
                    const BrandMark(size: 88, showShadow: true),
                    const SizedBox(height: 16),
                    Text(
                      AppInfo.name,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppInfo.tagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text(
                        'Sürüm ${AppInfo.version} · Tamamen çevrimdışı',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _FeatureGrid(),
              const SizedBox(height: 18),
              _AboutCard(
                icon: Icons.settings_suggest_outlined,
                title: 'Nasıl çalışır?',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _NumberedStep(
                      number: '1',
                      title: 'Metin normalize edilir',
                      text:
                          'Sayılar, tarihler, saatler, para birimleri, '
                          'yüzdeler, kısaltmalar ve telefon numaraları '
                          'Türkçe okunuşa çevrilir. Özgün metniniz korunur.',
                    ),
                    SizedBox(height: 12),
                    _NumberedStep(
                      number: '2',
                      title: 'Cihazdaki model seslendirir',
                      text:
                          'Pocket TTS Türkçe modeli, seçtiğiniz referans sesle '
                          'ONNX Runtime üzerinde çalışır. Web’de Web Worker, '
                          'macOS’ta arka plan isolate kullanılır.',
                    ),
                    SizedBox(height: 12),
                    _NumberedStep(
                      number: '3',
                      title: 'Gerçek MP3 hazırlanır',
                      text:
                          '24 kHz ses, 48 kHz’e yeniden örneklenir ve Shine '
                          'kodlayıcısıyla 160 kbps mono MP3 olarak paketlenir. '
                          'Dosya cihazınızdan çıkmaz.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _AboutCard(
                icon: Icons.hub_outlined,
                title: 'Teknoloji ve teşekkürler',
                child: Column(
                  children: const [
                    _TechRow(
                      name: 'Pocket TTS Türkçe',
                      detail: 'wite-tech · CC-BY-4.0',
                    ),
                    _TechRow(
                      name: 'sherpa-onnx',
                      detail: 'k2-fsa · Apache-2.0',
                    ),
                    _TechRow(
                      name: 'Shine MP3 kodlayıcı',
                      detail: 'shine_dart · LGPL-2.0',
                    ),
                    _TechRow(name: 'Flutter', detail: 'Google · BSD-3-Clause'),
                    _TechRow(
                      name: 'Manrope yazı tipi',
                      detail: 'Mikhail Sharanda · OFL-1.1',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: const Text('Gizlilik'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LicensesScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Lisanslar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SelectableText(
                'Kaynak kodu ve tam lisans metinleri: '
                '${AppInfo.repositoryUrl}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Türkçe için, cihazınızda. Sevgiyle geliştirildi.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final features = [
      (
        Icons.wifi_off_rounded,
        'Tamamen çevrimdışı',
        'İlk yüklemeden sonra internet gerekmez. Metin sunucuya gönderilmez.',
      ),
      (
        Icons.record_voice_over_outlined,
        'Altı gerçek ses',
        'Üç kadın, üç erkek konuşmacı. Perde kaydırma ile üretilmiş yapay ses yok.',
      ),
      (
        Icons.audio_file_outlined,
        'Gerçek MP3',
        'Yeniden adlandırılmış WAV değil; Shine ile kodlanmış MP3 dosyası.',
      ),
      (
        Icons.translate_rounded,
        'Türkçe normalizasyon',
        'Sayı, tarih, saat, para, yüzde, birim ve kısaltmalar doğru okunur.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final feature in features)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(
                            alpha: 0.55,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          feature.$1,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        feature.$2,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature.$3,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
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
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechRow extends StatelessWidget {
  const _TechRow({required this.name, required this.detail});

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            detail,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
