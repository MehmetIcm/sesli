import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../tts_controller.dart';
import '../widgets/history_section.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TtsController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = controller.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş'),
        actions: [
          if (entries.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context, controller),
              icon: const Icon(Icons.delete_sweep_outlined, size: 19),
              label: const Text('Temizle'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 34,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz seslendirme yok',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Seslendirdiğiniz metinler burada listelenir. '
                      'Ses dosyaları değil, yalnızca metin ve ayarlar saklanır.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      child: HistoryTile(
                        entry: entry,
                        onTap: () {
                          controller.loadHistoryEntry(entry);
                          Navigator.of(context).pop();
                        },
                        onDelete: () => controller.deleteHistoryEntry(entry.id),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    TtsController controller,
  ) async {
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
    }
  }
}
