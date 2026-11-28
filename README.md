# Sesli

**Metniniz, doğal Türkçe sesle.**

[![Web yayını](https://github.com/MehmetIcm/sesli/actions/workflows/web.yml/badge.svg)](https://github.com/MehmetIcm/sesli/actions/workflows/web.yml)
[![Lisans: MIT](https://img.shields.io/badge/kod-MIT-0F766E.svg)](LICENSE)
[![Model: CC-BY-4.0](https://img.shields.io/badge/model-CC--BY--4.0-E9C46A.svg)](THIRD_PARTY_NOTICES.md)
[![Flutter 3.47](https://img.shields.io/badge/Flutter-3.47-02569B.svg)](https://flutter.dev)

**Canlı demo:** https://mehmeticm.github.io/sesli/

Sesli, tamamen çevrimdışı çalışan bir Türkçe metin seslendirme uygulamasıdır.
Metni yazarsınız, altı farklı Türkçe konuşmacıdan biriyle dinlersiniz ve
sonucu gerçek MP3 olarak indirirsiniz. Uygulama; tarayıcı `SpeechSynthesis`
API'sini, işletim sistemi seslerini veya bulut servislerini kullanmaz.
Seslendirme, uygulamayla birlikte gelen ONNX modeliyle cihaz üzerinde
üretilir.

- Web (Chrome / Edge / Safari) ve macOS hedeflenir.
- Altı ses: **Elif, Zeynep, Defne** (kadın), **Emre, Kerem, Mert** (erkek).
- Türkçe metin normalizasyonu: sayılar, tarihler, saatler, para birimleri,
  yüzdeler, ölçü birimleri, kısaltmalar, telefon ve e-posta.
- İngilizce kelimeler Türkçe sesletimle okunur (`webcam` → “vebkem”,
  `download` → “daunloud”).
- Gerçek MP3 çıktısı (48 kHz, mono, 160 kbps).
- Perdeyi koruyan gerçek hız kontrolü (0,7× – 1,3×) ve doğal duraklamalar.
- Oynat / duraklat / devam et / durdur / konum değiştir / indir.
- Açık–koyu tema, Türkçe arayüz, Material 3, responsive tasarım.
- Hesap, reklam, analiz veya sunucu yoktur. Metinler cihazdan çıkmaz.

## Durum

| Alan | Durum |
| --- | --- |
| `flutter analyze` | Temiz (0 sorun) |
| `flutter test` | 170 test geçiyor |
| Web release derlemesi | Başarılı (`build/web`, ~219 MB) |
| GitHub deposu | Herkese açık: https://github.com/MehmetIcm/sesli |
| GitHub Pages yayını | Yayında ve doğrulandı: https://mehmeticm.github.io/sesli/ |
| Sürüm | v1.2.1 (GitHub Release + etiket) |
| Chrome'da gerçek seslendirme | Doğrulandı (Elif, Emre ve Teknik örnek metni; 17,6 sn'de 20,9 sn ses) |
| Oynatma biçimi | Doğrulandı (`data:audio/wav`, 48 kHz, mono, 16-bit, 20,9 sn) |
| Oynat / duraklat / devam / sarma | Doğrulandı (tarayıcıda gerçek tıklamalarla) |
| Gerçek MP3 indirme | Doğrulandı (`ffprobe`: MP3, 48 kHz, mono, 160 kbps) |
| İngilizce kelime sesletimi | Doğrulandı (`webcam` → “vebkem”, `Cambridge` → “kembriç”) |
| Çevrimdışı açılış | Doğrulandı (service worker `sesli-cache-v15`) |
| Çevrimdışı seslendirme | Doğrulandı (model + WASM + referans ses önbellekten) |
| macOS derlemesi | **Yapılamadı** — bu makinede tam Xcode ve CocoaPods yok |

Ayrıntılı doğrulama kayıtları için [Progress.md](Progress.md). Sesin
doğallaştırılması, netleştirilmesi ve yükseklik tutarlılığı için yapılan
ölçümlü araştırma ve öncelikli plan
[docs/SES_KALITESI_ARASTIRMASI.md](docs/SES_KALITESI_ARASTIRMASI.md)
dosyasındadır.

## Gereksinimler

- Flutter 3.47.x (stable) ve Dart 3.13.x
- Web için modern bir tarayıcı (service worker ve WebAssembly desteği)
- macOS derlemesi için tam Xcode ve CocoaPods (aşağıya bakın)

## Hızlı başlangıç (web)

```bash
git clone https://github.com/MehmetIcm/sesli.git
cd sesli
flutter pub get

# Geliştirme
flutter run -d chrome

# Release
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 -d build/web
# Tarayıcıda http://localhost:8080/ açın
```

> `--no-web-resources-cdn` **zorunludur**. Bu bayrak olmadan CanvasKit ve
> Roboto fontu Google CDN'inden yüklenir ve uygulama çevrimdışı açılmaz.

### Web yayınlama (GitHub Pages)

Depo, `.github/workflows/web.yml` ile **GitHub Pages**'e otomatik dağıtılır.
`main` dalına yapılan her push; `flutter analyze`, `flutter test`, release
derlemesi ve dağıtım adımlarını çalıştırır.

- Alt yol desteği: derleme `--base-href "/sesli/"` ile alınır; uygulama
  `https://mehmeticm.github.io/sesli/` altında sorunsuz çalışır.
- Service worker yalnızca güvenli bağlamlarda çalışır; GitHub Pages HTTPS
  sunduğu için sorun yoktur.
- `.wasm` dosyaları `application/wasm` olarak sunulur.
- Uygulama kabuğu her açılışta ağdan doğrulanır; model, WASM, font ve ses
  dosyaları önbellekten gelir. Ağ yoksa tamamı önbellekten gelir.
- `sw.js` sürümü (`CACHE_NAME`) her yayında artırılmalıdır; aksi hâlde eski
  kabuk önbellekte kalabilir.

Kendiniz yayınlamak için:

```bash
flutter build web --release --no-web-resources-cdn --base-href /sesli/
cp web/privacy.html web/terms.html web/robots.txt build/web/
touch build/web/.nojekyll
```

İlk açılışta model (~157 MB) motor başlatılırken indirilip önbelleğe alınır.
İlk yükleme tamamlandıktan sonra uygulama tamamen çevrimdışı çalışır.

> **Bant genişliği notu:** GitHub Pages'in aylık ~100 GB yumuşak sınırı
> vardır ve her yeni ziyaretçi ~165 MB indirir. Bu, aylık yaklaşık 600 yeni
> ziyarete karşılık gelir. Trafik artarsa modeli ayrı bir CDN'e/Release
> varlığına taşımak gerekir.

## macOS derlemesi

Bu proje macOS için hazırdır ancak bu geliştirme makinesinde yalnızca
Command Line Tools bulunduğu için derleme ve DMG üretimi yapılamamıştır.
Tam Xcode ve CocoaPods kurulduktan sonra:

```bash
# 1) Xcode'u App Store'dan kurun, bir kez açıp lisansı kabul edin.
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch

# 2) CocoaPods
sudo gem install cocoapods
# alternatif: brew install cocoapods

# 3) Derleme (depo klasöründe)
flutter clean
flutter pub get
flutter build macos --release

# 4) Çalıştırma
open build/macos/Build/Products/Release/Sesli.app
```

İsteğe bağlı DMG:

```bash
hdiutil create \
  -volname "Sesli" \
  -srcfolder build/macos/Build/Products/Release/Sesli.app \
  -ov -format UDZO \
  Sesli-1.2.1.dmg
```

Dağıtım için uygulamanın imzalanması ve noterden geçirilmesi gerekir
(`codesign`, `notarytool`). Bunlar Apple Developer hesabı gerektirir.

macOS'ta model ilk çalıştırmada uygulama varlıklarından
`~/Library/Application Support/.../models/pocket_tts_tr/` klasörüne
kopyalanır. Sonraki açılışlarda kopyalama atlanır.

## Mimari

```
lib/
  app.dart                     MaterialApp, tema, yerelleştirme
  main.dart                    Giriş noktası
  core/                        Sabitler, tema, biçimlendiriciler
  features/tts/
    data/                      Ses kataloğu, örnek metinler, ayarlar, geçmiş
    domain/                    Normalizasyon, parçalama, duygu, sonuç modeli
    infrastructure/            Motor (web/native), MP3, WAV, oynatma, kayıt
    presentation/              Denetleyici, ekranlar, widget'lar
```

- **Motor soyutlaması:** `TtsEngine` arayüzü; web'de `WebTtsEngine`
  (Web Worker + WASM), macOS'ta `NativeTtsEngine` (kalıcı Dart isolate).
- **Web:** `web/tts-worker.js` ağır ONNX çıkarımını ana iş parçacığından
  ayırır. Model dosyaları Emscripten MEMFS'e yazılır.
- **MP3:** `shine_dart` ile saf Dart Shine kodlayıcı. 24 kHz kaynak ses
  pencereleştirilmiş sinc ile 48 kHz'e (tam 2×) yeniden örneklenir, 160 kbps
  mono olarak kodlanır.
- **Ses işleme:** Metin cümle bazında sentezlenir; her cümle ayrı üretilir ve
  noktalama işaretine göre değişen doğal duraklamalarla birleştirilir (cümle
  sonu 300 ms, soru 360 ms, ünlem 340 ms, virgül 130 ms, paragraf 480 ms).
  Ardından 60 Hz rumble temizliği, 220 Hz altında −1,5 dB hafif bas kesme,
  550 Hz'de +0,8 dB gövde, 2,8 kHz'de +0,8 dB varlık, **ses bazlı EQ**,
  ölçülü de-esser ve **−18 LUFS / −1,5 dBTP** normalizasyonu uygulanır.
  Agresif kompresör varsayılan olarak kapalıdır. Hız WSOLA ile perde
  korunarak değiştirilir.
- **Oynatma:** Kayıpsız 48 kHz WAV ile yapılır; MP3 yalnızca indirme
  içindir. Önizlemeler de WAV olarak çalınır.
- **İngilizce sesletim:** `EnglishTransliterator`; özel kelime haritası,
  CMUdict tabanlı çevrimdışı sözlük, kural tabanlı G2P ve Türkçe kelime koruma
  listesi kullanır. Böylece `webcam` harf harf değil “vebkem”, `Cambridge`
  “kembriç” okunur.
- **Durum:** `provider` + `ChangeNotifier`; tercihler `shared_preferences`.

## Model ve sesler

- Model: **Pocket TTS Türkçe** (`wite-tech/pocket-tts-turkish`),
  **CC-BY-4.0**, ONNX aktarımı; dil modeli INT8, Mimi kod çözücüsü fp32,
  ~157 MB, 24 kHz.
- ONNX dışa aktarma: `lomotron/pocket-tts-onnx-export` (MIT).
- Altı konuşmacı, referans kaydıyla ses klonlama yoluyla elde edilir;
  perde kaydırma (pitch shifting) kullanılmaz. Elif, Kerem ve Mert modelin
  kendi kayıtlarını kullanır. Zeynep ve Emre referansları **Canora Turkish**
  (`elif`, `emre`), Defne referansı **Clarvia TTS tiny** (`female_4`) ile
  üretilmiştir; iki model de **Apache-2.0** lisanslıdır ve ağırlıkları
  uygulamaya dahil edilmez.
- Doğallık (UTMOS22, aynı metin, 3 tohum ortalaması): Zeynep 3,36 → **3,78**;
  Defne 3,52 → **3,73**; Emre 2,92 → **3,61**. Elif 3,75; Kerem 3,01;
  Mert 3,03.
- Duygu etiketleri: `[sakin]`, `[mutlu]`, `[üzgün]`, `[kızgın]`, `[şaşkın]`.

Lisans ayrıntıları: [LICENSES.md](LICENSES.md) ve
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Testler

```bash
flutter analyze
flutter test
```

Kapsam: Türkçe normalizasyon, İngilizce sesletim (harita, CMUdict, G2P,
Türkçe kelime koruması), metin parçalama, pencereleştirilmiş sinc yeniden
örnekleme, ses sonrası işleme (sessizlik kırpma, duraklama, EQ, WSOLA),
WAV çözme, MP3 kodlama, denetleyici (sentez/MP3/geçmiş/oynatma/önizleme),
ekranlar ve ana akış widget testleri.

## Bilinen sınırlamalar

- macOS derlemesi ve gerçek cihaz performansı bu ortamda test edilemedi.
- Web'de ilk açılış ~219 MB indirir; sonrası çevrimdışıdır. Depo ~165 MB
  (model ~157 MB) olduğu için ilk `git clone` uzun sürebilir.
- Seslendirme hızı cihaza göre değişir; bu makinede ~11 saniyelik ses
  yaklaşık 11 saniyede üretildi (yaklaşık gerçek zamanlı).
- Tarayıcı sekmesi arka plandayken veya pencere gizliyken kare üretimi
  yavaşlayabilir; seslendirme Web Worker'da devam eder.
- Model sözlüğünde rakam, `q/w/x` ve bazı semboller yoktur. Normalizasyon
  bunları Türkçe okunuşa çevirir; yine de desteklenmeyen bir karakter kalırsa
  uygulama anlaşılır bir hata gösterir.
- İngilizce sesletim kural tabanlıdır. Sözlükte bulunmayan çok nadir
  kelimelerde (özellikle özel adlar) yaklaşık bir okunuş üretilir.
- Yalnızca Chromium tabanlı tarayıcıda çalışma zamanı doğrulaması yapıldı;
  Safari ve Firefox denenmedi.
- Model, CC-BY-4.0 gereği atıf gerektirir. Uygulama içindeki **Lisanslar**
  ekranı ve bu depodaki bildirimler bu atfı sağlar.

## Lisans

- **Uygulama kodu:** [MIT](LICENSE) — ticari kullanım dahil geniş yetkiler;
  telif bildirimi korunmalıdır.
- **Ses modeli:** Pocket TTS Türkçe, **CC-BY-4.0**; atıf zorunludur.
- **Diğer bileşenler:** sherpa-onnx (Apache-2.0), shine_dart (LGPL-2.0),
  CMUdict (BSD-2-Clause), Manrope (OFL-1.1), Flutter (BSD-3-Clause).

Özet tablo: [LICENSES.md](LICENSES.md) · Atıf metinleri:
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) · Tam lisans metinleri:
[`licenses/`](licenses/). Ticari kullanımı kısıtlayan (NC) hiçbir bileşen
kullanılmamıştır.

## Gizlilik ve hukuki

- [Gizlilik ve Çerez Politikası](PRIVACY.md) — çerez yok, analiz yok,
  metinler cihazdan çıkmaz; yalnızca zorunlu yerel depolama.
- [Kullanım Koşulları](TERMS.md) — “olduğu gibi” sunum, sorumluluk sınırı,
  kabul edilebilir kullanım.
- [Güvenlik Politikası](SECURITY.md) · [Katkı Rehberi](CONTRIBUTING.md) ·
  [Davranış Kuralları](CODE_OF_CONDUCT.md)
- Web'de ayrıca: [`/privacy.html`](https://mehmeticm.github.io/sesli/privacy.html)
  ve [`/terms.html`](https://mehmeticm.github.io/sesli/terms.html).

Uygulama hiçbir çerez, analitik, reklam veya üçüncü taraf isteği
kullanmadığı için çerez onay bandı gerekmez; bu durum politikada ve
uygulama içindeki **Gizlilik** ekranında açıklanır.
