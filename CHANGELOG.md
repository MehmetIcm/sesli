# Sesli — Değişiklik Günlüğü

Bu dosya [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/) biçimini
ve [Anlamsal Sürümleme](https://semver.org/lang/tr/) ilkelerini izler.

## [Yayınlanmadı]

### Eklenecek

- macOS imzalı DMG paketi (Xcode + CocoaPods gerektirir).
- Safari ve Firefox için çalışma zamanı testleri.

## [1.2.1] — 2026-11-28

Uzun ve zor cümlelerde kelime yutulmasını gideren okuma düzeltmeleri.

### Düzeltildi

- **Para birimi eki:** `1.234.567,89 TL'lik` artık
  "... lira, seksen dokuz kuruşluk" olarak okunuyor. Önceki sürümde cümlede
  `kuruş 'lik` kalıntısı kalıyor, model "lira" ile eki yutuyordu.
- **Kuruştan önce virgül:** Uzun tutarlarda modelin ana birimi atlamasını
  engellemek için kuruş kısmı virgülle ayrılıyor.
- **Parçalama sınırı 260 → 200 karakter.** Sherpa'nın 240 karakterlik iç
  cümle sınırı artık tetiklenmiyor; uzun cümleler modelin içinde değil,
  uygulamada bölünüyor.
- **Noktalama önceliği:** Uzun cümleler önce virgül, noktalı virgül, iki nokta
  ve tireden bölünüyor. Cümle ortasında anlamsız kesilme ve çok kısa artık
  parçalar azaldı.
- **Noktalı virgül cümle sınırı sayılıyor.**
- **Okunuş sözlüğü:** Modelin Türkçe sözlüğünde bulunmayan kelimeler için
  anlamı koruyan karşılıklar kullanılıyor: `Québec` → `Kebek`,
  `senkronizasyon` → `eşgüdüm`,
  `sonuçlanabilecek miydi` → `sonuçlanır mıydı`.

### Doğrulama

- Kullanıcı stres metni üç parçaya ayrılıyor (166 / 102 / 168 karakter);
  Vosk Türkçe ASR'de "lira", "seksen dokuz kuruşluk",
  "oradan da ... mühendis" ve "sonuçlanır mıydı" eksiksiz çıkıyor.
- `flutter analyze`: 0 sorun; `flutter test`: 170 test geçiyor.
- Service worker önbelleği: `sesli-cache-v15`.

## [1.2.0] — 2026-11-26

Referans ses kalitesi sürümü.

### Değişti

- **Zeynep, Defne ve Emre için yeni referans kayıtları.** Pocket TTS çıktısı,
  referans kaydın kalitesini izlediği için düşük doğallıklı erkek
  referansları ve iki kadın referansı değiştirildi:
  - Zeynep → **Canora Turkish** `elif` (Apache-2.0)
  - Defne → **Clarvia TTS tiny** `female_4` (Apache-2.0)
  - Emre → **Canora Turkish** `emre` (Apache-2.0)
  Referanslar 3,7–4,7 saniyelik, sessizlikleri kırpılmış, tepe noktası
  hizalanmış 24 kHz WAV dosyalarıdır. Model ağırlıkları uygulamaya dahil
  edilmez; yalnızca üretilen kısa referans sesleri paketlenir.
- **Ses bazlı EQ:** yeni referanslar dengeli geldiği için Zeynep, Defne ve
  Emre'de ek EQ kaldırıldı. Elif, Kerem ve Mert'in ayarları korundu.
- **Önizlemeler:** üç sesin tanıtım kayıtları yeni tınıyla yeniden üretildi.

### Ölçümler

Aynı metin, 3 tohum ortalaması, UTMOS22 (1–5):

| Ses | Önce | Sonra |
| --- | ---: | ---: |
| Elif | 3,75 | 3,75 |
| Zeynep | 3,36 | **3,78** |
| Defne | 3,52 | **3,73** |
| Emre | 2,92 | **3,61** |
| Kerem | 3,01 | 3,01 |
| Mert | 3,03 | 3,03 |

Altı sesin ortalaması 3,27 → **3,49**. Ölçümler her iki sürümde de ham
24 kHz model çıktısı üzerinde, aynı metin ve tohumlarla yapıldığı için
karşılaştırma doğrudan geçerlidir.

### Değişti (altyapı)

- Web service worker önbelleği `sesli-cache-v14`.
- Sürüm 1.2.0.

## [1.1.0] — 2026-11-25

Doğallık ve konuşma akışı sürümü.

### Düzeltildi

- **Yeniden örnekleyici:** 24 → 48 kHz dönüşümünde kesim frekansı
  Nyquist'in %47'sinde (5,6 kHz) kalıyordu; 6 kHz −14 dB, 8 kHz −38 dB,
  10 kHz −73 dB zayıflıyordu. Kesim %94'e çıkarıldı, 32 tap ve Kaiser
  β=8,6 kullanıldı. 6–10 kHz artık −1 dB içinde; görüntüler −40 dB altında.
  Boğuk/tiz kaybı hissinin ana nedeni buydu.
- **Ses sonrası işleme:** Eski agresif zincir (250 Hz altında −4 dB,
  3,4 kHz'de +5 dB, 6,5 kHz üstünde +3,5 dB, kompresör, −20 LUFS) yerine
  `DspProfile.natural` geldi: 60 Hz high-pass, 220 Hz'de −1,5 dB low shelf,
  550 Hz'de +0,8 dB gövde, 2,8 kHz'de +0,8 dB varlık, 0,6 ölçekli de-esser,
  kompresör kapalı, −18 LUFS / −1,5 dBTP.
- **Ses bazlı EQ** altı sesin ölçülen spektrumuna göre yeniden ayarlandı.
- **Mimi kod çözücüsü** INT8 yerine fp32 kullanılıyor; kuantizasyon
  gürültüsü azaldı. Model paketi ~157 MB.
- **Duraklamalar** kısaltıldı: cümle 300 ms, soru 360 ms, ünlem 340 ms,
  üç nokta 520 ms, virgül 130 ms, paragraf 480 ms; başlangıç 120 ms,
  bitiş 260 ms.
- **Tohumlar:** Her cümle için deterministik tohum (42, 104729 adım)
  kullanılıyor; aynı metin aynı sesi üretiyor.

### Ölçümler

- SQUIM_OBJECTIVE PESQ (natural): Elif 3,609; Zeynep 3,238; Defne 3,226;
  Emre 2,437; Kerem 2,353; Mert 2,422. Altısı da eski profili geçti.
- `flutter analyze`: 0 sorun; `flutter test`: 164 test geçiyor.
- WebKit uçtan uca: 48 kHz mono 16-bit WAV, 15,624 sn, 1,43 MB; MP3
  312.960 bayt; çevrimdışı yeniden yükleme ve oynatma doğrulandı.

### Değişti

- Web service worker önbelleği `sesli-cache-v13`; yazı tipi istekleri
  yerel kalmaya zorlanıyor.
- Sürüm 1.1.0.

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

[Yayınlanmadı]: https://github.com/MehmetIcm/sesli/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/MehmetIcm/sesli/releases/tag/v1.2.1
[1.2.0]: https://github.com/MehmetIcm/sesli/releases/tag/v1.2.0
[1.1.0]: https://github.com/MehmetIcm/sesli/releases/tag/v1.1.0
[1.0.0]: https://github.com/MehmetIcm/sesli/releases/tag/v1.0.0
