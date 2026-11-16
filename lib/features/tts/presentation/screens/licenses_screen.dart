import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';
import '../../data/pocket_tts_model.dart';

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lisanslar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                'Sesli, açık kaynaklı bileşenler ve izin verici lisanslarla '
                'geliştirilmiştir. Ticari kullanımı kısıtlayan (NC) hiçbir '
                'bileşen kullanılmaz.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 18),
              _LicenseCard(
                icon: Icons.memory_rounded,
                title: 'Ses modeli',
                entries: [
                  _LicenseEntry(
                    name: PocketTtsModel.name,
                    license: PocketTtsModel.license,
                    note:
                        '${PocketTtsModel.source} ağırlıklarının INT8 ONNX '
                        'aktarımı. Atıf gerektirir; ticari kullanıma açıktır.',
                  ),
                  const _LicenseEntry(
                    name: 'Pocket TTS ONNX dışa aktarıcı',
                    license: 'MIT',
                    note:
                        'lomotron/pocket-tts-onnx-export ve MIT lisanslı '
                        'pocket_tts kodu.',
                  ),
                  const _LicenseEntry(
                    name: 'pocket-tts-turkish normalizörü',
                    license: 'Apache-2.0',
                    note:
                        'Telefon, kesir, aralık ve Romen rakamı okuma '
                        'kuralları Dart’a uyarlanmıştır.',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LicenseCard(
                icon: Icons.graphic_eq_rounded,
                title: 'Ses motoru',
                entries: const [
                  _LicenseEntry(
                    name: 'sherpa-onnx',
                    license: 'Apache-2.0',
                    note:
                        'ONNX Runtime tabanlı çıkarım; web için WASM, '
                        'macOS için yerel kütüphane.',
                  ),
                  _LicenseEntry(
                    name: 'ONNX Runtime',
                    license: 'MIT',
                    note: 'Model çıkarım motoru.',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LicenseCard(
                icon: Icons.audio_file_outlined,
                title: 'MP3 kodlama',
                entries: const [
                  _LicenseEntry(
                    name: 'Shine',
                    license: 'LGPL-2.0',
                    note:
                        'Saf Dart portu (shine_dart). Uygulama içinde '
                        'değiştirilmeden kullanılır; kaynak kodu depoda '
                        'bulunur.',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LicenseCard(
                icon: Icons.translate_rounded,
                title: 'Dil verisi',
                entries: const [
                  _LicenseEntry(
                    name: 'CMU Pronouncing Dictionary',
                    license: 'BSD-2-Clause',
                    note:
                        'İngilizce kelimelerin çevrimdışı sesletim sözlüğü. '
                        'Türkçe okunuşa uyarlanmıştır.',
                  ),
                  _LicenseEntry(
                    name: 'FrequencyWords Türkçe',
                    license: 'MIT',
                    note:
                        'Türkçe kelimelerin yanlışlıkla İngilizce okunmasını '
                        'önleyen koruma listesi.',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LicenseCard(
                icon: Icons.text_fields_rounded,
                title: 'Yazı tipi',
                entries: const [
                  _LicenseEntry(
                    name: 'Manrope',
                    license: 'SIL Open Font License 1.1',
                    note:
                        'Mikhail Sharanda tarafından tasarlandı. Uygulama '
                        'ile birlikte gömülüdür.',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LicenseCard(
                icon: Icons.widgets_outlined,
                title: 'Flutter ve paketler',
                entries: const [
                  _LicenseEntry(
                    name: 'Flutter',
                    license: 'BSD-3-Clause',
                    note: 'Google tarafından geliştirilen UI çatısı.',
                  ),
                  _LicenseEntry(
                    name: 'provider',
                    license: 'MIT',
                    note: 'Durum yönetimi.',
                  ),
                  _LicenseEntry(
                    name: 'audioplayers',
                    license: 'MIT',
                    note: 'Ses oynatma.',
                  ),
                  _LicenseEntry(
                    name: 'shared_preferences',
                    license: 'BSD-3-Clause',
                    note: 'Yerel ayar ve geçmiş saklama.',
                  ),
                  _LicenseEntry(
                    name: 'path_provider',
                    license: 'BSD-3-Clause',
                    note: 'Uygulama destek klasörü.',
                  ),
                  _LicenseEntry(
                    name: 'file_selector',
                    license: 'BSD-3-Clause',
                    note: 'MP3 kaydetme iletişim kutusu.',
                  ),
                  _LicenseEntry(
                    name: 'web',
                    license: 'BSD-3-Clause',
                    note: 'Tarayıcı indirmeleri için JS erişimi.',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _LicenseCard(
                icon: Icons.code_rounded,
                title: 'Uygulama',
                entries: [
                  _LicenseEntry(
                    name: 'Sesli kaynak kodu',
                    license: 'MIT',
                    note:
                        'github.com/MehmetIcm/sesli — ticari kullanım '
                        'dahil geniş yetkiler tanır; telif bildirimi korunur.',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tam lisans metinleri',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ayrıntılı lisans ve atıf metinleri depodaki '
                      'LICENSES.md, THIRD_PARTY_NOTICES.md ve licenses/ '
                      'klasöründe yer alır. Uygulama kodu MIT lisanslıdır. '
                      'Sürüm ${AppInfo.version}.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({
    required this.icon,
    required this.title,
    required this.entries,
  });

  final IconData icon;
  final String title;
  final List<_LicenseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
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
            const SizedBox(height: 10),
            for (var i = 0; i < entries.length; i++) ...[
              _LicenseRow(entry: entries[i]),
              if (i != entries.length - 1) const Divider(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _LicenseRow extends StatelessWidget {
  const _LicenseRow({required this.entry});

  final _LicenseEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                entry.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                entry.license,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          entry.note,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _LicenseEntry {
  const _LicenseEntry({
    required this.name,
    required this.license,
    required this.note,
  });

  final String name;
  final String license;
  final String note;
}
