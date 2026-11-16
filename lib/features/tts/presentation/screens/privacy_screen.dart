import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';
import 'licenses_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _PrivacyHero(),
              const SizedBox(height: 18),
              _PrivacyCard(
                icon: Icons.lock_outline_rounded,
                title: 'Kısa özet',
                child: Text(
                  'Sesli tamamen cihazınızda çalışır. Yazdığınız metinler, '
                  'seslendirme sırasında veya sonrasında hiçbir sunucuya, '
                  'bulut hizmetine ya da üçüncü taraf API’ye gönderilmez. '
                  'Hesap oluşturmanız gerekmez; reklam, izleme veya analiz '
                  'yoktur.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 14),
              _PrivacyCard(
                icon: Icons.storage_outlined,
                title: 'Hangi veriler saklanır?',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bullet(
                      'Metinler: yalnızca siz “Geçmişe kaydet” seçeneğini '
                      'açık bıraktıysanız ve yalnızca bu cihazda saklanır.',
                    ),
                    _Bullet(
                      'Ayarlar: tema, ses, hız, kalite ve oynatma tercihleri '
                      'cihazınızın yerel depolamasında tutulur.',
                    ),
                    _Bullet(
                      'Ses dosyaları: üretilen MP3 yalnızca siz indirene kadar '
                      'bellekte tutulur; geçmişe kaydedilmez.',
                    ),
                    _Bullet(
                      'Model dosyaları: uygulamayla birlikte gelir. macOS’ta '
                      'ilk açılışta uygulama destek klasörüne kopyalanır.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _PrivacyCard(
                icon: Icons.wifi_off_rounded,
                title: 'Ağ erişimi',
                child: Text(
                  'Uygulama, ilk yüklemeden sonra çalışmak için internet '
                  'bağlantısı kullanmaz. Web sürümünde uygulama dosyaları '
                  'barındırıldığı sunucudan bir kez indirilir; bu indirme '
                  'sırasında da metinleriniz gönderilmez. macOS sürümü '
                  'tamamen çevrimdışı kurulabilir.\n\n'
                  'Uygulamada hiçbir ağ isteği, telemetri, çerez veya '
                  'reklam kitaplığı bulunmaz.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 14),
              _PrivacyCard(
                icon: Icons.cloud_outlined,
                title: 'Barındırma',
                child: Text(
                  'Web sürümü GitHub Pages üzerinde barındırılır. GitHub, '
                  'hizmetin güvenliği ve kötüye kullanımın önlenmesi amacıyla '
                  'IP adresi ve tarayıcı bilgisi gibi teknik erişim günlükleri '
                  'tutabilir. Bu günlüklere geliştiricinin erişimi yoktur ve '
                  'metinlerinizle ilişkilendirilemez.\n\n'
                  'macOS sürümü tamamen çevrimdışıdır; hiçbir barındırma '
                  'günlüğü oluşmaz. Ayrıntılar depodaki PRIVACY.md '
                  'dosyasındadır.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 14),
              _PrivacyCard(
                icon: Icons.tune_rounded,
                title: 'Sizin kontrolünüz',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bullet(
                      'Geçmişi istediğiniz zaman tek tek veya tamamen '
                      'silebilirsiniz (Ayarlar → Veriler).',
                    ),
                    _Bullet(
                      'Geçmişe kaydetmeyi kapatarak hiçbir metnin '
                      'saklanmamasını sağlayabilirsiniz.',
                    ),
                    _Bullet(
                      'Tarayıcı verilerini temizlemek, web sürümündeki tüm '
                      'yerel kayıtları da siler.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _PrivacyCard(
                icon: Icons.verified_user_outlined,
                title: 'Açık kaynak ve denetlenebilirlik',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesli’nin kullandığı model, motor ve kodlayıcı açık '
                      'kaynaklıdır. Kaynak kodları ve lisans metinleri '
                      'depoda bulunur; ağ davranışını kendiniz '
                      'inceleyebilirsiniz.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LicensesScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Lisansları görüntüle'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${AppInfo.name} · ${AppInfo.privacySummary}',
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
}

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.65),
            scheme.surfaceContainerLowest,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: scheme.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gizlilik önce gelir',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Metniniz cihazınızdan çıkmaz. Her şey yerel çalışır.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
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
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
