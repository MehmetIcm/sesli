import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../tts_controller.dart';

class EditorCard extends StatelessWidget {
  const EditorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TtsController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tooLong = controller.characterCount > TtsController.maxTextLength;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBadge(
                  icon: Icons.edit_note_rounded,
                  color: scheme.primary,
                  background: scheme.primaryContainer.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Metniniz', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Yazın, dinleyin, MP3 olarak indirin.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tooLong
                        ? scheme.errorContainer
                        : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${controller.characterCount} / ${TtsController.maxTextLength}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tooLong
                          ? scheme.onErrorContainer
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<int>(
                  tooltip: 'Örnek metinler',
                  icon: const Icon(Icons.auto_stories_outlined),
                  onSelected: (index) {
                    controller.loadSample(controller.samples[index]);
                  },
                  itemBuilder: (context) => [
                    for (var i = 0; i < controller.samples.length; i++)
                      PopupMenuItem(
                        value: i,
                        child: Row(
                          children: [
                            const Icon(Icons.notes_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(controller.samples[i].label),
                          ],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: 'Metni temizle',
                  onPressed: controller.textController.text.isEmpty
                      ? null
                      : controller.clearText,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.textController,
              minLines: 9,
              maxLines: 18,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
              decoration: InputDecoration(
                hintText:
                    'Seslendirmek istediğiniz metni buraya yazın…\n\n'
                    'Örnek: “Toplantı 14.30’da başlayacak. Katılım ücreti 250 TL.”',
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: scheme.primary, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Metniniz cihazınızdan çıkmaz; sunucuya gönderilmez.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (MediaQuery.sizeOf(context).width > 720)
                  Text(
                    '⌘ / Ctrl + Enter ile seslendir',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
            if (tooLong) ...[
              const SizedBox(height: 8),
              Text(
                'Metin ${TtsController.maxTextLength} karakter sınırını aşıyor.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _NormalizedHint(
              text: controller.result?.normalizedText,
              visible: controller.result != null,
            ),
          ],
        ),
      ),
    );
  }
}

class _NormalizedHint extends StatelessWidget {
  const _NormalizedHint({required this.text, required this.visible});

  final String? text;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible || text == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Icon(
          Icons.text_fields_rounded,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        title: Text(
          'Seslendirilen metin (normalize edilmiş)',
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
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
              text!,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.55,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}
