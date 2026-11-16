import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/voice_catalog.dart';
import '../../infrastructure/mp3_encoder.dart';
import '../tts_controller.dart';
import 'waveform_painter.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TtsController>();
    final result = controller.result;
    if (result == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = controller.duration > Duration.zero
        ? controller.duration
        : result.duration;
    final progress = duration.inMilliseconds > 0
        ? (controller.position.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.headphones_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oynatıcı', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '${VoiceCatalog.byId(result.voiceId).name} · '
                        '${result.emotion.label} · '
                        '${formatDuration(duration)} · '
                        '${formatBytes(controller.mp3?.length ?? 0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (controller.isEncodingMp3)
                  _EncodingBadge()
                else
                  FilledButton.tonalIcon(
                    onPressed: () => _download(context, controller),
                    icon: const Icon(Icons.download_rounded, size: 19),
                    label: const Text('MP3 indir'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
              ],
            ),
            if (controller.isEncodingMp3) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(minHeight: 5),
              ),
            ],
            if (controller.isResultStale) ...[
              const SizedBox(height: 12),
              _StaleBanner(onSynthesize: controller.synthesize),
            ],
            const SizedBox(height: 14),
            _Waveform(controller: controller, progress: progress),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton.filled(
                  onPressed: controller.togglePlay,
                  tooltip: controller.isPlaying ? 'Duraklat' : 'Oynat',
                  style: IconButton.styleFrom(
                    fixedSize: const Size(54, 54),
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  icon: controller.isBuffering
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: scheme.onPrimary,
                          ),
                        )
                      : Icon(
                          controller.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatDuration(controller.position),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: progress,
                    onChanged: (value) => controller.seekFraction(value),
                  ),
                ),
                Text(
                  formatDuration(duration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Durdur',
                  onPressed: controller.stopPlayback,
                  icon: const Icon(Icons.stop_rounded, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                leading: Icon(
                  Icons.subject_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                title: Text(
                  'Okunan metin',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Normalize metni kopyala',
                  onPressed: controller.copyNormalizedText,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      result.normalizedText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.55,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.bolt_rounded, size: 15, color: scheme.secondary),
                const SizedBox(width: 5),
                Text(
                  '${result.elapsed.inMilliseconds / 1000 < 0.1 ? '<0,1' : (result.elapsed.inMilliseconds / 1000).toStringAsFixed(1)} sn’de üretildi',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${result.sampleRate ~/ 1000} kHz kaynak · '
                  '${Mp3Encoder.defaultBitrate} kbps MP3',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, TtsController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = await controller.downloadMp3();
    if (!context.mounted) return;
    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('İndirme iptal edildi.')),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('MP3 hazır: $path'),
        action: SnackBarAction(label: 'Tamam', onPressed: () {}),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.controller, required this.progress});

  final TtsController controller;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final samples = controller.result?.samples;

    return LayoutBuilder(
      builder: (context, constraints) {
        void seek(Offset position) {
          if (constraints.maxWidth <= 0) return;
          controller.seekFraction(
            (position.dx / constraints.maxWidth).clamp(0.0, 1.0),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => seek(details.localPosition),
          onHorizontalDragUpdate: (details) => seek(details.localPosition),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: samples == null
                ? const SizedBox.shrink()
                : CustomPaint(
                    size: Size(constraints.maxWidth, 64),
                    painter: WaveformPainter(
                      samples: samples,
                      progress: progress,
                      activeColor: scheme.primary,
                      inactiveColor: scheme.outlineVariant,
                      barCount: (constraints.maxWidth / 6)
                          .floor()
                          .clamp(24, 140)
                          .toInt(),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.onSynthesize});

  final VoidCallback onSynthesize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: scheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Metin değişti. Yeni hâli seslendirmek için tekrar dokunun.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
          TextButton(onPressed: onSynthesize, child: const Text('Yeniden')),
        ],
      ),
    );
  }
}

class _EncodingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'MP3 hazırlanıyor…',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
