import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../tts_controller.dart';
import 'emotion_selector.dart';
import 'voice_tile.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TtsController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: scheme.secondary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ses ve ton', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Altı gerçek Türkçe konuşmacı',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _VoiceGrid(controller: controller),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 16),
            _SectionLabel(
              title: 'Ton',
              subtitle: 'Duygu etiketi ilk cümlenin başına eklenir.',
            ),
            const SizedBox(height: 10),
            EmotionSelector(
              selected: controller.emotion,
              onSelected: controller.setEmotion,
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                _SectionLabel(
                  title: 'Hız',
                  subtitle: 'Doğal aralık: 0,7× – 1,3×',
                ),
                const Spacer(),
                _ValueBadge(text: '${controller.speed.toStringAsFixed(1)}×'),
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
            const SizedBox(height: 4),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                leading: Icon(
                  Icons.tune_rounded,
                  size: 19,
                  color: scheme.onSurfaceVariant,
                ),
                title: Text(
                  'Kalite ayarı',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${controller.numSteps} adım · daha yüksek = daha doğal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  Slider(
                    value: controller.numSteps.toDouble(),
                    min: 2,
                    max: 8,
                    divisions: 6,
                    label: '${controller.numSteps} adım',
                    onChanged: (value) => controller.setNumSteps(value.round()),
                  ),
                  Text(
                    'Difüzyon adım sayısı arttıkça ses daha temiz olur; '
                    'üretim süresi de uzar. Önerilen değer: 4.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SynthesizeArea(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _VoiceGrid extends StatelessWidget {
  const _VoiceGrid({required this.controller});

  final TtsController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final voice in controller.voices)
              SizedBox(
                width: width,
                child: VoiceTile(
                  voice: voice,
                  selected: controller.selectedVoice.id == voice.id,
                  previewing: controller.previewingVoiceId == voice.id,
                  onTap: () => controller.selectVoice(voice),
                  onPreview: () => controller.togglePreview(voice),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SynthesizeArea extends StatelessWidget {
  const _SynthesizeArea({required this.controller});

  final TtsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (controller.engineStatus == EngineStatus.error) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: scheme.error,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Model yüklenemedi',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              controller.engineError ?? 'Bilinmeyen hata.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: controller.retryEngine,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (controller.engineStatus == EngineStatus.loading) {
      final percent = (controller.engineProgress * 100).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  value: controller.engineProgress > 0
                      ? controller.engineProgress
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Model hazırlanıyor… %$percent',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: controller.engineProgress > 0
                  ? controller.engineProgress
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk açılışta model tarayıcıya/cache’e yüklenir. Sonrasında '
            'tamamen çevrimdışı çalışır.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final synthesizing = controller.isSynthesizing;
    final progress = controller.synthesisProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.canSynthesize ? controller.synthesize : null,
            icon: synthesizing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.graphic_eq_rounded),
            label: Text(
              synthesizing
                  ? 'Seslendiriliyor… %${(progress * 100).round()}'
                  : 'Seslendir',
            ),
          ),
        ),
        if (synthesizing) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress > 0 ? progress : null,
            ),
          ),
        ],
        if (controller.synthesisStatus == SynthesisStatus.error &&
            controller.synthesisError != null) ...[
          const SizedBox(height: 10),
          Text(
            controller.synthesisError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.offline_bolt_outlined, size: 15, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tamamen çevrimdışı · Sunucu yok · MP3 çıktı',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
