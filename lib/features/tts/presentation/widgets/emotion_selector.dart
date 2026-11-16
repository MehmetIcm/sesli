import 'package:flutter/material.dart';

import '../../domain/speech_emotion.dart';

class EmotionSelector extends StatelessWidget {
  const EmotionSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SpeechEmotion selected;
  final ValueChanged<SpeechEmotion> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final emotion in SpeechEmotion.values)
          ChoiceChip(
            selected: emotion == selected,
            onSelected: (_) => onSelected(emotion),
            showCheckmark: false,
            avatar: Icon(
              emotion.icon,
              size: 16,
              color: emotion == selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            label: Text(emotion.label),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: emotion == selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: scheme.primaryContainer,
            backgroundColor: scheme.surfaceContainerLow,
            side: BorderSide(
              color: emotion == selected
                  ? scheme.primary.withValues(alpha: 0.5)
                  : scheme.outlineVariant,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          ),
      ],
    );
  }
}
