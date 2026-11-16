# Sesli — Değişiklik Günlüğü

Bu dosya [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) biçimini
ve [Anlamsal Sürümleme](https://semver.org/lang/tr/) ilkelerini izler.

## [Yayınlanmadı]

### Eklenecek

- macOS imzalı DMG paketi (Xcode + CocoaPods gerektirir).
- Safari ve Firefox için çalışma zamanı testleri.

## [1.0.0] — 2026-11-16

İlk herkese açık sürüm.

### Eklendi

- **Ses motoru:** `sherpa_onnx` 2.0.1 + Pocket TTS Türkçe (INT8 ONNX),
  WebAssembly (Web Worker) ve macOS yerel isolate.
- **Altı ses:** Elif, Zeynep, Defne (kadın); Emre, Kerem, Mert (erkek).
- **Türkçe normalizasyon:** sayılar, tarihler, saatler, para birimleri,
  yüzdeler, ölçü birimleri, kısaltmalar, telefon numaraları, e-posta,
  kesirler, aralıklar, Romen rakamları, matematik sembolleri ve HTML
  temizliği.
- **İngilizce sesletim:** özel adlar ve teknik terimler Türkçe sesletimle
  okunur (`Cambridge` → “kembriç”, `webcam` → “vebkem”); 121.735 kelimelik
  CMUdict sözlüğü ve kural tabanlı G2P yedeği.
- **Doğal konuşma:** cümle bazlı sentez, noktalama duyarlı duraklamalar
  (cümle 360 ms, soru 430 ms, virgül 160 ms, paragraf 600 ms), ses bazlı EQ,
  de-esser, yumuşak kompresör, −20 LUFS / −1,5 dBTP normalizasyonu.
- **Hız kontrolü:** perdeyi koruyan WSOLA (0,7× – 1,3×).
- **Oynatma:** 48 kHz kayıpsız WAV ile oynat / duraklat / devam / durdur /
  sarma / süre göstergesi.
- **MP3 indirme:** saf Dart Shine kodlayıcı, 48 kHz, mono, 160 kbps.
- **Arayüz:** Türkçe, Material 3, açık/koyu tema, responsive, Manrope yazı
  tipi, geçmiş, ayarlar, gizlilik, hakkında ve lisanslar ekranları.
- **Çevrimdışı:** service worker (`sesli-cache-v11`) ile tam çevrimdışı
  çalışma; model ilk kullanımda önbelleğe alınır.
- **Yayın:** GitHub Actions ile GitHub Pages dağıtımı, CI (analyze + test),
  MIT lisansı, gizlilik/çerez politikası, güvenlik politikası ve katkı
  rehberi.

### Ölçümler

- `flutter analyze`: 0 sorun; `flutter test`: 162 test geçiyor.
- Gerçek model çıktısı: −20,0 LUFS / −1,7 dBTP (üç ses örneği).
- Web: 20,9 sn ses 17,6 sn'de üretildi; MP3 `ffprobe` ile 48 kHz / 160 kbps
  doğrulandı.

[Yayınlanmadı]: https://github.com/MehmetIcm/sesli/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/MehmetIcm/sesli/releases/tag/v1.0.0
