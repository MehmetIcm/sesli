# Progress

Sesli — tamamen çevrimdışı Türkçe metin seslendirme uygulaması.
Bu dosya, yapılan işi ve doğrulama sonuçlarını dürüstçe kaydeder.

Son güncelleme: 25 Kasım 2026

## 1. Kapsam ve hedefler

- Web öncelikli, ardından macOS; mimari Windows/Android'e genişletilebilir.
- Tarayıcı `SpeechSynthesis`, işletim sistemi TTS'i veya bulut servisi
  kullanmadan, cihaz üzerinde çalışan gerçek bir Türkçe ses modeli.
- Aynı model ve sesler Web ile macOS'ta.
- En az dört farklı Türkçe konuşmacı (2 kadın, 2 erkek); perde kaydırma yok.
- İlk yüklemeden sonra tamamen çevrimdışı; sunucu, hesap, reklam, analiz yok.
- Gerçek MP3 (WAV yeniden adlandırma değil), oynatma/duraklatma/durdurma,
  konum değiştirme, süre ve indirme.
- Türkçe arayüz, Material 3, responsive, açık/koyu tema, logo, gizlilik ve
  hakkında ekranları.
- Türkçe normalizasyon (sayı, tarih, saat, para, %, ondalık, birim,
  kısaltma, telefon, e-posta); özgün metin ayrı tutulur.
- Yalnızca izin verici lisanslar; `LICENSES.md`, `THIRD_PARTY_NOTICES.md`.

## 2. Seçilen teknoloji

| Konu | Karar |
| --- | --- |
| Ses motoru | `sherpa_onnx` 2.0.1 (Web: WASM + Web Worker, macOS: yerel + isolate) |
| Model | Pocket TTS Türkçe, `wite-tech/pocket-tts-turkish`, CC-BY-4.0, INT8 LM + fp32 Mimi kod çözücü |
| Sesler | `female_1..3`, `male_1..3` — Elif, Zeynep, Defne, Emre, Kerem, Mert |
| MP3 | `shine_dart` 0.1.1 (LGPL-2.0), 24 kHz → 48 kHz, 160 kbps mono |
| Ses işleme | Cümle bazlı sentez, 32 tap sinc yeniden örnekleme, WSOLA hız kontrolü, ses bazlı EQ + ölçülü de-esser, −18 LUFS / −1,5 dBTP |
| İngilizce sesletim | Özel harita + CMUdict sözlüğü + kural tabanlı G2P + Türkçe kelime koruması |
| Oynatma | `audioplayers` 6.8.1, `BytesSource`; önizlemeler WAV |
| Durum | `provider` + `ChangeNotifier`; `shared_preferences` |
| Web önbellek | Özel `web/sw.js` + özel `web/flutter_bootstrap.js` |
| Yazı tipi | Manrope (OFL-1.1) |

Piper reddedildi: kullanılan Türkçe ses veri kümelerinin bir kısmı NC
lisanslıydı. Kikiri yedek olarak değerlendirildi; Pocket TTS Türkçe'nin
CC-BY-4.0 olması ve altı konuşmacı sunması nedeniyle Pocket TTS seçildi.

## 3. Tamamlanan işler

### Model ve varlıklar
- Model ağırlıkları indirildi, ONNX'e aktarıldı ve
  `assets/models/pocket_tts_tr/` altına yerleştirildi (~157 MB):
  `lm_flow.int8.onnx`, `lm_main.int8.onnx`, `encoder.onnx`,
  `decoder.onnx` (fp32 Mimi), `text_conditioner.onnx`, `vocab.json`,
  `token_scores.json`.
- Python `sherpa-onnx` ile `female_1` ve `male_1` için sessiz olmayan ses
  üretimi doğrulandı.
- Altı referans WAV (`assets/voices/`) ve altı önizleme WAV
  (`assets/previews/`) eklendi.
- Manrope yazı tipi ve uygulama simgesi eklendi; web/macOS simgeleri
  `flutter_launcher_icons` ile üretildi.

### Uygulama
- `core/`, `data/`, `domain/`, `infrastructure/`, `presentation/`
  katmanlarıyla tam uygulama yazıldı.
- Türkçe normalizasyon: tam sayı, ondalık/binlik ayırıcı, tarih, saat, para,
  yüzde, telefon, e-posta, ölçü birimi, kısaltma, sıra sayısı, kesme
  işaretli ekler.
- Metin parçalama: cümle sınırları korunur, uzun cümle kelime sınırından
  bölünür.
- Sentez akışı: normalizasyon → parçalama → model → PCM birleştirme → MP3 →
  otomatik oynatma → geçmiş.
- Oynatma: oynat/duraklat/devam/durdur/konum; süre ve boyut gösterimi.
- MP3 indirme: web'de Blob + `<a download>`, macOS'ta `file_selector`.
- Altı ses kartı, önizleme, duygu seçici, hız (0,7–1,3) ve kalite (2–8 adım).
- Ayarlar, geçmiş, hakkında, gizlilik, lisanslar ekranları.
- Açık/koyu tema, responsive yerleşim, Türkçe yerelleştirme.

### İngilizce sesletim ve doğallık
- Türkçe metne karışan İngilizce kelimeler artık harf harf değil, Türkçe
  sesletimle okunur: `webcam` → “vebkem”, `download` → “daunloud”,
  `browser` → “brauzır”, `WhatsApp` → “vatsap”, `MP3` → “em pi üç”.
- Katmanlar: ~610 girdilik özel kelime haritası, CMUdict'ten türetilmiş
  121.735 kelimelik çevrimdışı sözlük, kural tabanlı G2P yedeği, ek soyma ve
  20.000 kelimelik Türkçe koruma listesi.
- Türkçe kelimeler yanlışlıkla İngilizce okunmaz (`site`, `ithal`, `müthiş`,
  `model`, `normal`, `test` doğrulanmıştır).
- Tek harfli sözcükler yalnızca cümlenin tamamı İngilizceyse çevrilir;
  “A planı” gibi Türkçe kullanımlar korunur.
- Model parametreleri `PocketTtsParams` içinde tek yerden yönetilir:
  `silenceScale 1.12`, `numSteps 8`, `temperature 0.5`,
  `min_char_in_sentence 20`.
- Marka ve yer adları için özel karşılıklar eklendi: `Cambridge → kembriç`,
  `Oxford → oksford`, `Google → gugıl`, `Amazon → amazın`,
  `LinkedIn → linkdın`, `Netflix → netfliks` vb. Büyük “I” harfi Türkçe
  küçültmede “ı” olduğu için sözlük araması “ı → i” dönüşümüyle de yapılır.

### Ses kalitesi ve hız
- `AudioResampler`: 16 kademeli, 256 fazlı, Kaiser (β=7) pencereli sinc
  yeniden örnekleme. Kübik interpolasyona göre daha temiz yukarı örnekleme.
- `AudioPostProcessor`:
  - Parça kenarlarındaki sessizlik kırpılır; parçalar arasına noktalama
    işaretine göre değişen doğal pay eklenir: cümle sonu 380 ms, soru 450 ms,
    ünlem 420 ms, iki nokta 280 ms, noktalı virgül 230 ms, virgül 180 ms,
    üç nokta 620 ms. Başa 120 ms, sona 260 ms pay konur.
  - `timeStretch` (WSOLA) ile perde korunarak 0,7×–1,3× gerçek hız kontrolü.
    Pocket TTS'in `speed` parametresi C++ tarafında yok sayıldığı için bu
    şarttı.
  - `enhance`: 80 Hz yüksek geçiren; 250 Hz altında −4 dB bas kesme;
    500 Hz'de −1,5 dB; 2 kHz'de +2,5 dB; 3,4 kHz'de +5 dB varlık;
    6,5 kHz üstünde +3,5 dB raf; hafif kompresör ve 0,91 tepe
    normalizasyonu. Modelin çıkışı bas ağırlıklı olduğu için bu zincir
    boğukluğu belirgin biçimde azaltır.
- MP3 bit hızı 128 → **160 kbps**'e çıkarıldı; tüm arayüz ve belgeler
  güncellendi.
- Oynatma artık kayıpsız 44,1 kHz WAV ile yapılır; MP3 yalnızca indirme
  içindir. Böylece Shine kodlayıcısının olası bozulmaları dinlerken
  duyulmaz.

### Web çevrimdışı altyapısı
- `web/index.html`: Türkçe meta, açılış ekranı, service worker kaydı,
  ilk karede açılış ekranının kaldırılması.
- `web/manifest.json`: PWA meta verileri ve maskelenebilir simgeler.
- `web/sw.js`: uygulama kabuğu + ses/WASM/model önbelleği; gezinmede
  network-first, ağ yoksa önbellek; 502 yanıtlarında da önbelleğe düşer.
- `web/flutter_bootstrap.js`: Flutter'ın kendi service worker'ını kaydetmeyen
  özel yükleyici (Flutter 3.47'nin oluşturduğu SW kendini iptal ediyordu).
- `WebTtsEngine`, model dosyalarını yüklemeden önce service worker'ın
  sayfayı kontrol etmesini bekler; böylece ilk açılışta hiçbir model dosyası
  önbellek dışında kalmaz.

### macOS
- `PRODUCT_NAME = Sesli`, telif metni ve kullanıcı seçimli dosya izinleri
  (`com.apple.security.files.user-selected.read-write`) ayarlandı.
- Model, ilk çalıştırmada uygulama desteği klasörüne kopyalanır; sonraki
  açılışlarda kurulum işaretiyle atlanır.

## 4. Doğrulama sonuçları

### Statik analiz ve testler
```
flutter analyze  → No issues found!
flutter test     → 146 test geçti
```
Kapsam: normalizasyon, İngilizce sesletim, parçalama, pencereleştirilmiş sinc
yeniden örnekleme, ses sonrası işleme (sessizlik/duraklama/EQ/WSOLA), WAV,
MP3, denetleyici, ekranlar, ana akış.

### Web release derlemesi
```
flutter build web --release --no-web-resources-cdn
→ ✓ Built build/web  (~201 MB)
```

### Chrome'da gerçek çalışma (uygulama içi tarayıcı)
- Uygulama açıldı; altı ses ve örnek metinler göründü.
- "Günlük" örnek metni yüklendi.
- **Elif** ile sentez: 12,2 s ses, 191 KB MP3, 11,1 s üretim.
- **Emre** ile sentez: 11 s ses, 173 KB MP3, 10,9 s üretim.
- Otomatik oynatma çalıştı; konum ilerledi; duraklat/devam çalıştı.
- MP3 indirme: `sesli-elif-20261107-1035.mp3`, 195.184 bayt.
  `ffprobe`: MP3, 44,1 kHz, mono, 160 kbps, 12,199 s. Tam çözme başarılı.
- Service worker; model, WASM, worker, fontlar, altı ses ve altı önizleme
  WAV'ını önbelleğe aldı.

### İngilizce kelime ve ses işleme doğrulaması (13 Kasım 2026)
- Chrome'da “webcam” metni Elif sesiyle seslendirildi; oynatıcı 0:01 süre ve
  24 KB MP3 gösterdi; normalize metin alanında **“vebkem”** göründü.
- Normalizasyon testleri: `webcam→vebkem`, `update→apdeyt`, `online→onlayn`,
  `download→daunloud`, `browser→brauzır`, `WhatsApp→vatsap`,
  `YouTube→yutub`, `software→softveır`, `keyboard→kibord`, `message→mesic`,
  `image→imic`, `package→pekic`, `language→lenguic`, `manage→menic`,
  `computer→kompyutır`, `cache→keş`, `file→fayl`, `backend→bekend`,
  `frontend→frantend`, `blockchain→blokçeyn`, `ethereum→eteryum`,
  `startup→startap`, `MP3→em pi üç`, `B12→be on iki`, `5G→beş ge`,
  `3D→üç di`.
- Türkçe yanlış pozitifler değişmedi: `site`, `ithal`, `müthiş`, `ishal`,
  `reaksiyon`, `koalisyon`, `organize`, `realite`, `teatral`, `kooperatif`,
  `model`, `normal`, `test`.
- Hız testi: 0,8× çıktı süresi 1,2× çıktıdan belirgin biçimde uzun.
- 20 saniyelik ses için işlem süreleri (Dart JIT, bu makine):
  birleştirme 1 ms, WSOLA 63 ms, EQ/normalizasyon 52 ms, 44,1 kHz'e
  yeniden örnekleme 36 ms, MP3 kodlama 530 ms.

### Cambridge, duraklama ve kalite doğrulaması (14 Kasım 2026)
- Release derlemesi (service worker v9) headless Chromium'da uçtan uca
  çalıştırıldı.
- Girdi: “Cambridge Üniversitesi çok eski. Yeni webcam sürücüsünü indirip
  test ettim.”
- Normalize metin (arayüzdeki kopyalama düğmesinden): **“kembriç
  üniversitesi çok eski. yeni vebkem sürücüsünü indirip test ettim.”**
  Böylece `Cambridge` artık Türkçe harflerle değil, “kembriç” sesletimiyle
  okunur.
- Oynatma kaynağı: `data:audio/wav`, 44,1 kHz, mono, 16-bit, 5,009 s.
  Tepe 0,906; RMS 0,091.
- Spektrum (oynatılan WAV): 80–300 Hz **%35,6**, 300–1000 Hz %20,5,
  1–3 kHz **%38,5**, 3–6 kHz %5,4. EQ öncesi model çıkışında 80–300 Hz
  kadın seste %61, erkek seste %75'e çıkıyordu; yeni zincir bası azaltıp
  netlik bandını belirgin biçimde güçlendirdi.
- Duraklamalar: iki cümle arasında **600 ms**, cümle içi virgül/kelime
  sınırlarında 90–170 ms ölçüldü. Konuşma aceleye gelmiyor.
- MP3 indirme: `sesli-elif-20261114-1153.mp3`, 100.832 bayt.
  `ffprobe`: MP3, 44,1 kHz, mono, **160 kbps**, 5,0416 s.
- Son derleme (service worker v10) taze bir Chrome profilinde yeniden
  doğrulandı; normalizasyon çıktısı yine “kembriç … vebkem …” oldu ve
  sentez 8 s içinde tamamlandı.
- `flutter analyze` temiz; `flutter test` **146 test** geçti.


- Yerel sunucu durdurulduktan sonra sayfa yeniden yüklendi; service worker
  uygulama kabuğunu önbellekten sundu (`flutter-view` oluştu).
- Son doğrulama (service worker v7, son derleme): çevrimiçi ilk açılışta
  `navigator.serviceWorker.controller` etkinleşti; önbellekte uygulama
  kabuğu, CanvasKit, fontlar, `tts-worker.js`, 7 model dosyası, 6 ses ve
  6 önizleme WAV'ı yer aldı. Sunucu kapatılıp sayfa yeniden yüklendiğinde
  uygulama kabuğu önbellekten açıldı, 502 hatası alınmadı.
- Çevrimdışıyken tüm model, WASM, ses ve font istekleri önbellekten 200
  döndü.
- Ayrı bir çevrimdışı worker testi (sunucu kapalı, yalnızca önbellek):
  - Model dosyaları: 9.962.530 + 76.341.079 + 20.753.635 + 22.684.077 +
    16.388.344 bayt (tamamı önbellekten).
  - Sentez: 57.792 örnek @ 24 kHz = **2,408 s** ses.
  - RMS 0,082, tepe 0,697 → sessiz değil.
  - Toplam süre 3,6 s (model yükleme + sentez).
- Bu test, uygulamanın kullandığı `tts-worker.js` ve aynı mesaj protokolünü
  kullanır; çevrimdışı seslendirme yolunun uçtan uca çalıştığını gösterir.

### Ekranlar ve etkileşimler
- Ana akış (metin, ses seçimi, sentez, oynatma, MP3) Chrome'da doğrulandı.
- Ayarlar, geçmiş (boş/dolu), hakkında, gizlilik ve lisanslar ekranları ile
  konum değiştirme ve ses önizlemesi otomatik widget/denetleyici testleriyle
  doğrulandı. Son oturumda tarayıcı penceresi görünür olmadığı için bu ikincil
  ekranlar tarayıcıda yeniden tıklanarak doğrulanamadı.

### Rakam ve özel karakter hatası doğrulaması
- Kullanıcı geri bildirimi: **“Bad state: Seslendirme hatası: 316276752”**.
- Kök neden: Pocket TTS Türkçe modelinin SentencePiece sözlüğünde **rakam,
  q/w/x harfleri ve çoğu sembol yok**. Metinde bunlardan biri kalınca
  tokenizer 0 token üretiyor; Emscripten bunu sayısal bir istisna olarak
  fırlatıyor ve arayüze anlamsız bir kod olarak yansıyordu.
- Düzeltme: normalizasyonun sonuna `_sanitizeForModel` eklendi. Kalan
  rakamlar Türkçe okunuşa, q/w/x ve aksanlı Latin harfleri Türkçe
  karşılıklarına çevriliyor; semboller okunabilir sözcüklere dönüştürülüyor;
  sözlükte olmayan karakterler temizleniyor.
- Doğrulama: **“Teknik”** örnek metni (MP3, 24 kHz, 44,1 kHz, 160 kbps
  içerir) Chrome'da uçtan uca seslendirildi; oynatıcı ve **MP3 indir**
  düğmesi göründü, hata alınmadı.
- Ek testler: `MP3`, `B12`, `5G`, `3D`, `WhatsApp`, emoji, `#`, `@`,
  yeni satır ve e-postadaki rakamlar için normalizasyon ve denetleyici
  testleri eklendi.

## 5. Bulunan ve düzeltilen hatalar

1. **Normalizasyon:** `replaceAll` içinde `$1` değişmez olarak kalıyordu;
   `3.5` → `üç$1 beş` oluyordu. `replaceAllMapped` kullanıldı.
2. **Ondalık/binlik:** `3.5` binlik ayırıcı sanılıyordu; ondalık deseni
   eklendi.
3. **Sıra sayısı:** Cümle sonundaki `25.` sıra sayısına çevriliyordu;
   yalnızca ardından küçük harf gelen nokta sıra sayısı sayılıyor.
4. **Birimler:** `23°C` ve `5kg` gibi bitişik birimler tanınmıyordu; `° C`
   ve bitişik ölçü desenleri eklendi.
5. **TL:** Para birimi sözlüğünde `TL` eksikti; eklendi.
6. **Service worker:** Flutter 3.47'nin ürettiği `flutter_service_worker.js`
   kendini iptal ediyor ve özel SW'yi eziyordu. Özel
   `flutter_bootstrap.js` ile Flutter'ın SW kaydı kapatıldı.
7. **Service worker 502:** Sunucu kapalıyken proxy 502 döndürdüğünde
   önbelleğe düşmüyordu; `response.ok` kontrolü eklendi.
8. **İlk yükleme yarışı:** Uygulama, service worker etkinleşmeden ilk model
   dosyasını (`lm_flow`) istiyor ve bu dosya önbelleğe girmiyordu. Motor,
   model yüklemeden önce `navigator.serviceWorker.ready` ve `controller`
   durumunu bekliyor.
9. **Oynatıcı kartı:** Sonuç, o an seçili sesi gösteriyordu; sentez anındaki
   ses ve duygu `SynthesisResult` içine taşındı.
10. **Test altyapısı:** `testWidgets` içinde `Isolate.run` (MP3) kilitleniyordu;
    oynatma/önizleme testleri düz `test` olarak yazıldı.
11. **Model sözlüğü / rakamlar:** Modelin SentencePiece sözlüğünde rakam,
    q/w/x ve çoğu sembol yoktu. `MP3`, `B12`, `5G`, `2026` gibi metinlerde
    tokenizer 0 token üretiyor, Emscripten sayısal istisna fırlatıyor ve
    arayüzde **“Bad state: Seslendirme hatası: 316276752”** görünüyordu.
    Normalizasyona `_sanitizeForModel` eklendi; kalan her karakter okunabilir
    Türkçeye çevriliyor. Ayrıca işçi (worker) sayısal istisnalarda artık
    anlaşılır bir hata iletisi gösteriyor.
12. **Önbellekte eski `tts-worker.js`:** Service worker, `tts-worker.js`
    dosyasını cache-first sunduğu için yeni derlemedeki düzeltilmiş worker
    tarayıcıda çalışmıyordu. Worker, uygulama kabuğu desenine eklendi ve
    önbellek sürümü yükseltildi (v7). Böylece yeni worker her açılışta
    ağdan doğrulanıyor.
13. **İngilizce kelimeler harf harf okunuyordu:** “webcam” → “ve be ce a em”
    gibi. `EnglishTransliterator` eklendi; harita + CMUdict + G2P ile Türkçe
    sesletim üretiliyor, Türkçe kelimeler korunuyor.
14. **Konuşma aceleye geliyordu:** `silenceScale` 0,2 tüm duraklamaları
    %20'ye sıkıştırıyordu. Önce 0,9'a, son olarak 1,12'ye çıkarıldı; ayrıca
    parçalar arasına noktalama işaretine göre değişen doğal duraklamalar
    eklendi (cümle sonu 380 ms, virgül 180 ms).
15. **Hız kaydırıcısı etkisizdi:** Pocket TTS `speed` parametresini C++
    uygulamasında yok sayıyor. Perde koruyan WSOLA zaman germe eklendi.
16. **Ses boğuk/tıslamalıydı:** Kübik yeniden örnekleme yerine pencereleştirilmiş
    sinc; ayrıca 80 Hz rumble temizliği, 250 Hz altında −4 dB bas kesme,
    3,4 kHz'de +5 dB varlık, 6,5 kHz üstünde +3,5 dB raf ve tepe
    normalizasyonu eklendi. Oynatma kayıpsız 44,1 kHz WAV'a alındı; MP3
    bit hızı 160 kbps'e çıkarıldı.

## 6. Bu ortamda yapılamayanlar

- **macOS derlemesi, çalıştırma ve DMG:** Makinede tam Xcode yok, yalnızca
  Command Line Tools var; CocoaPods de kurulu değil. Bu nedenle macOS
  uygulaması derlenemedi ve gerçek cihazda test edilemedi. Gerekli komutlar
  `README.md` içinde.
- **macOS performansı ve çevrimdışı testi:** Derleme yapılamadığı için
  ölçülemedi.
- **Tarayıcıda ikincil ekranların son oturumda elle doğrulanması:** Tarayıcı
  penceresi görünür değildi; bu ekranlar otomatik testlerle kapsandı.
- **Farklı tarayıcılar:** Yalnızca Chromium (uygulama içi tarayıcı) test
  edildi; Safari/Firefox'ta çalışma zamanı testi yapılmadı.

## 7. Kullanıcı için tam komutlar

### Web
```bash
cd /Users/mehmeticme/VscodeApps/text_to_speech
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 -d build/web
```

### macOS
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
sudo gem install cocoapods

cd /Users/mehmeticme/VscodeApps/text_to_speech
flutter clean
flutter pub get
flutter build macos --release
open build/macos/Build/Products/Release/Sesli.app
```

### DMG
```bash
hdiutil create -volname "Sesli" \
  -srcfolder build/macos/Build/Products/Release/Sesli.app \
  -ov -format UDZO Sesli-1.0.0.dmg
```

## 8. Dosya haritası

- `lib/features/tts/presentation/tts_controller.dart` — uygulama durumu.
- `lib/features/tts/domain/turkish_text_normalizer.dart` — normalizasyon.
- `lib/features/tts/domain/english_transliterator.dart` — İngilizce sesletim.
- `lib/features/tts/infrastructure/audio_resampler.dart` — sinc yeniden
  örnekleme.
- `lib/features/tts/infrastructure/audio_post_processor.dart` — sessizlik,
  duraklama, EQ ve WSOLA.
- `lib/features/tts/data/pocket_tts_params.dart` — ortak model parametreleri.
- `lib/features/tts/infrastructure/tts_engine_web.dart` — Web Worker köprüsü.
- `web/tts-worker.js` — WASM/ONNX worker protokolü.
- `web/sw.js` — çevrimdışı önbellek.
- `web/flutter_bootstrap.js` — özel Flutter yükleyici.
- `lib/features/tts/infrastructure/mp3_encoder.dart` — Shine MP3 kodlayıcı.
- `assets/models/pocket_tts_tr/` — ONNX model paketi.
- `test/` — 146 test.
- `README.md`, `LICENSES.md`, `THIRD_PARTY_NOTICES.md` — bu belgeler.
- `docs/SES_KALITESI_ARASTIRMASI.md` — ses kalitesi araştırması ve
  öncelikli iyileştirme planı.

## 9. Ses kalitesi araştırması (14 Kasım 2026)

Sesin doğallaştırılması ve netleştirilmesi için ayrıntılı araştırma
`docs/SES_KALITESI_ARASTIRMASI.md` dosyasında toplandı. Öne çıkan
ölçümler:

- Aynı EQ sonrası sesler arasında **4,4 dB** yükseklik farkı var
  (`female_3` −22,2 LUFS, `male_3` −17,8 LUFS).
- Global EQ erkek seslerde yetersiz: `male_2` hâlâ %55 bas, %15 varlık;
  `female_1` ise %12 tıslama.
- Model çıktısında 6–12 kHz neredeyse yok; basit high shelf veya exciter
  bu boşluğu doldurmuyor.
- Cümle bazlı sentez + tutarlı duraklama, mevcut parça bazlı kırpma/ekleme
  yaklaşımından daha öngörülebilir.
- Resmî `pocket-tts-turkish` normalizörü telefon numaralarını grup grup
  okuyor; modelin tekrar döngülerini önlüyor.

Önerilen ilk faz: LUFS normalizasyonu + gerçek tepe limiter, ses bazlı EQ,
`female_1` için de-esser, cümle bazlı duraklama ve resmî normalizör
kuralları.

## 10. Sonuç

Web hedefi uçtan uca çalışır durumda: gerçek Türkçe ses, gerçek MP3,
çevrimdışı önbellek ve doğrulanmış çevrimdışı sentez. macOS kodu hazır ancak
bu ortamda derlenemedi; kullanıcı Xcode ve CocoaPods kurduktan sonra
`flutter build macos --release` ile derleyebilir.

## 11. Ses kalitesi iyileştirme turu (15 Kasım 2026)

Araştırma raporundaki (`docs/SES_KALITESI_ARASTIRMASI.md`) ilk faz
uygulandı. Değişiklikler:

1. **LUFS normalizasyonu + gerçek tepe limiter.** `AudioPostProcessor`
   artık ITU-R BS.1770-4 benzeri K-ağırlıklı entegre yükseklik ölçüyor ve
   çıktıyı **−20 LUFS** ile **−1,5 dBTP** hedefine getiriyor. Look-ahead
   limiter, Catmull-Rom enterpolasyonuyla örnekler arası tepeyi de
   sınırlıyor. Sonuç: ses değiştirildiğinde yükseklik farkı duyulmuyor.
2. **Ses bazlı EQ.** Yeni `VoiceEqProfile` ve `VoiceCatalog.eqFor()`
   altı sesin her biri için ayrı bas/varlık/hava düzeltmesi tanımlıyor.
   `female_1` için varlık bölgesi −1 dB kısılıp de-esser %100 devreye
   alındı; `male_2` için 250 Hz altı ek −4 dB, varlık +4 dB.
3. **De-esser.** 5,5 kHz üstünü yan zincirle izleyen dinamik de-esser
   eklendi; “s/ş” tıslaması azaltılırken ses kaybolmuyor.
4. **Cümle bazlı sentez.** `TextChunker.segments()` her cümleyi ayrı
   `SpeechSegment` olarak döndürüyor; denetleyici cümleleri tek tek
   sentezliyor, paragrafları ayrı normalize ediyor. Böylece modelin kendi
   cümle sonu sessizliği uygulamanın duraklama politikasıyla çakışmıyor.
   Duraklamalar: nokta 360 ms, soru 430 ms, ünlem 390 ms, üç nokta 600 ms,
   virgül 160 ms, noktalı virgül 230 ms, iki nokta 280 ms, paragraf 600 ms,
   uzun cümle ara parçası 150 ms. Başlangıç 120 ms, kapanış 260 ms.
5. **Model parametreleri.** `silenceScale` 1,12 → **1,05** (cümle arası
   payı artık uygulama yönetiyor), `temperature` 0,5 → **0,45**, sabit
   `seed 42`, `max_reference_audio_len 5`. Web worker yedekleri de
   eşitlendi.
6. **48 kHz çıkış.** Oynatma WAV'ı ve MP3 hedefi 44,1 kHz'den **48 kHz**'e
   alındı; 24 kHz kaynaktan tam 2× yükseltme olduğu için ek yeniden
   örnekleme gerekmiyor.
7. **TPDF dither.** 16-bit WAV kodlamasında sabit tohumlu üçgen dither
   eklendi; çok düşük seviyeli kuantizasyon bozulması maskeleniyor.
8. **Normalizör genişletmeleri.** Telefonlar grup grup okunuyor
   (`0555 123 45 67` → “sıfır beş yüz elli beş, yüz yirmi üç, kırk beş,
   altmış yedi”); kesirler (`3/4` → “dörtte üç”), aralıklar
   (`10-15` → “on ile on beş”), Romen rakamları (`XVI. yüzyıl` → “on
   altıncı yüzyıl”), matematik sembolleri (`≥ ≤ ≠ ± > <`), HTML etiketleri
   ve üçten fazla kelime tekrarı işleniyor.
9. **Testler.** `flutter analyze` temiz; `flutter test` **162 test**
   geçiyor. Yeni testler LUFS/limiter/de-esser/ses EQ profili, cümle
   segmentasyonu, telefon/kesir/aralık/Romen/matematik normalizasyonu ve
   dither davranışını kapsıyor.

### Ölçümler

Gerçek model çıktısı (`sherpa-onnx` 2.0.1, Python) üzerinde iki cümle
birleştirilip yeni zincirden geçirildi:

| Ses | Süre | Entegre yükseklik | Gerçek tepe |
| --- | --- | --- | --- |
| female_1 | 4,83 s | −20,03 LUFS | −1,77 dBTP |
| female_2 | 4,42 s | −20,05 LUFS | −1,67 dBTP |
| male_2 | 5,17 s | −20,06 LUFS | −1,68 dBTP |

`ffmpeg ebur128=peak=true` ölçümü de −20 LUFS ve −1,6…−1,8 dBFS aralığını
doğruladı. Spektral denge (enerjinin bantlara dağılımı):

| Ses | Durum | <300 Hz | 1–3 kHz | 3–6 kHz | Ağırlık merkezi |
| --- | --- | --- | --- | --- | --- |
| female_1 | ham | %53,0 | %17,4 | %1,8 | 722 Hz |
| female_1 | işlenmiş | %33,2 | %45,6 | %4,5 | 1342 Hz |
| male_2 | ham | %71,1 | %4,1 | %0,1 | 297 Hz |
| male_2 | işlenmiş | %38,8 | %34,3 | %1,4 | 912 Hz |

Yani bas ağırlığı belirgin biçimde azaldı, konuşma netliğini taşıyan
1–6 kHz bandı güçlendi. Ölçümler tek metin ve tek tohumla yapıldığı için
gösterge niteliğindedir; nihai değerlendirme dinleme testiyle yapılmalıdır.

### Web üzerinde doğrulama (15 Kasım 2026)

Yeni derleme (`build/web`, service worker `sesli-cache-v11`) tarayıcıda
uçtan uca çalıştırıldı. Kullanılan metin: “Sesli 15 Kasım 2026'da
yayınlandı. Cambridge ve Oxford üniversiteleri webcam testini 3/4 oranında
tamamladı. Bilet 1.250,75 TL, indirim %25. Telefon: 0555 123 45 67. Aralık
10-15 gün, XVI. yüzyıl.”

- **Seslendirme süresi:** 20,9 sn ses, 17,6 sn'de üretildi (Elif · Nötr).
- **Normalize metin (uygulamadan kopyalandı):** “sesli on beş kasım iki bin
  yirmi altıda yayınlandı. kembriç ve oksford üniversiteleri vebkem testini
  dörtte üç oranında tamamladı. bilet bin iki yüz elli lira yetmiş beş
  kuruş, indirim yüzde yirmi beş telefon: sıfır beş yüz elli beş, yüz yirmi
  üç, kırk beş, altmış yedi. aralık on ile on beş gün, on altıncı yüzyıl.”
  Yani tarih, İngilizce özel adlar, kesir, para birimi, yüzde, telefon
  gruplaması, aralık ve Romen rakamı kurallarının tamamı tarayıcıda devreye
  giriyor.
- **Oynatma:** Ses kaynağı `data:audio/wav`; başlıktan okunan değerler
  **48 kHz, mono, 16-bit, 20,919 sn, 2,0 MB**. Yani kayıpsız oynatma da
  48 kHz'e yükseltildi.
- **Oynatıcı kontrolleri:** Oynat → duraklat (`currentTime` sabit kaldı) →
  devam et → ilerleme çubuğunda ~%75'e sarma (`currentTime` 15,74 sn'ye
  atladı, süre 20,92 sn) adımları gerçek tıklamalarla doğrulandı.
- **MP3:** Uygulamadan indirilen dosya `ffprobe` ile **MP3, 48 kHz, mono,
  160 kbps, 20,928 sn, 418.560 bayt**; `ffmpeg -f null` ile hatasız çözüldü.

### Kalan işler

- macOS derlemesi hâlâ bu ortamda yapılamıyor (tam Xcode + CocoaPods yok).
- Safari/Firefox çalışma zamanı testi yapılmadı (yalnızca Chromium test
  edildi).
- Ses kalitesi değerlendirmesi dinleme testiyle yapılmalı; ölçümler tek
  metin ve tek tohumla alındı.
- İsteğe bağlı: “Cambridge” için kullanıcının belirttiği birebir
  “Kembiriç” yazımı istenirse `cambridge` haritası tek satırda değişir.

## 12. GitHub yayını ve hukuki tamamlama (16 Kasım 2026)

Uygulama herkese açık depoya yüklendi, GitHub Actions ile GitHub Pages'e
dağıtıldı ve canlı adreste uçtan uca doğrulandı.

### Yayın bilgileri

| Alan | Değer |
| --- | --- |
| Depo | https://github.com/MehmetIcm/sesli (public) |
| Canlı site | https://mehmeticm.github.io/sesli/ |
| Dağıtım | `.github/workflows/web.yml` — verify → build → deploy |
| Tetikleyici | `main` dalına push, PR (yalnız verify + build), elle çalıştırma |
| Sürüm etiketi | `v1.0.0` — https://github.com/MehmetIcm/sesli/releases/tag/v1.0.0 |
| İlk commit | `8086a38` — 162 dosya, 47.276 satır |
| Pages düzeltmesi | `4cd3379` — yanlış “mehmetricm” yazımı “mehmeticm” olarak düzeltildi |

Derleme `--base-href "/sesli/"` ve `--no-web-resources-cdn` ile yapılır;
`web/privacy.html`, `web/terms.html`, `web/robots.txt` ve `web/sitemap.xml`
`build/web` içine kopyalanır, `.nojekyll` eklenir. Böylece uygulama alt
yolda, service worker kapsamı `/sesli/` olacak şekilde çalışır.

### Eklenen hukuki ve topluluk dosyaları

- `LICENSE` — MIT (telif: Mehmet ICME); üçüncü taraf bileşenlerin ayrı
  lisanslı olduğu notuyla.
- `PRIVACY.md` — GDPR/KVKK uyumlu gizlilik, çerez ve yerel depolama
  politikası; GitHub Pages erişim günlükleri ve hukuki dayanak açıklaması.
- `TERMS.md` — kullanım koşulları, “olduğu gibi” sunum, sorumluluk sınırı,
  kabul edilebilir kullanım, çıktıların mülkiyeti.
- `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `CHANGELOG.md`, `CITATION.cff`.
- `THIRD_PARTY_NOTICES.md` ve `LICENSES.md` — CC-BY-4.0 model atfı,
  Apache-2.0 normalizör bildirimi ve özet tablo.
- `licenses/` — Apache-2.0, LGPL-2.0, CC-BY-4.0, Flutter BSD-3-Clause,
  Manrope OFL-1.1 ve CMUdict BSD-2-Clause tam metinleri.
- `web/privacy.html`, `web/terms.html` — uygulamadan bağımsız, statik ve
  çerez kullanmayan hukuki sayfalar; `robots.txt` ve `sitemap.xml` ile
  birlikte yayınlanır.
- `.github/ISSUE_TEMPLATE/` ve `PULL_REQUEST_TEMPLATE.md` — hata/öneri
  şablonları, güvenlik açığı için özel kanal yönlendirmesi.
- `web/index.html` — canonical, Open Graph/Twitter kartları,
  `rel=privacy-policy` ve `rel=terms-of-service` bağlantıları.
- Uygulama içi: **Hakkında** ekranında depo bağlantısı, **Gizlilik**
  ekranında barındırma günlükleri kartı, **Lisanslar** ekranında MIT
  uygulama kodu kaydı.

**Çerez bandı neden yok:** Uygulama `document.cookie` yazmaz; yalnızca
çalışması için zorunlu yerel depolama ve service worker önbelleği kullanır.
Bu, GDPR md. 5(3) / ePrivacy kapsamında “kesinlikle gerekli” olduğundan
onay bandı gerekmez; durum politikada ve uygulama içinde açıklanır.

### Canlı yayın doğrulaması

- `https://mehmeticm.github.io/sesli/`, `/privacy.html`, `/terms.html` →
  HTTP 200; `<base href="/sesli/">`; service worker kapsamı
  `https://mehmeticm.github.io/sesli/sw.js`.
- Model dosyaları canlı adresten yüklendi (`lm_main.int8.onnx` ~6,2 sn);
  WASM motoru ve tüm ONNX dosyaları 200 döndü.
- “Teknik” örnek metniyle gerçek seslendirme yapıldı; üretilen kaynak
  `data:audio/wav`, başlıktan okunan değerler **48 kHz, mono, 16-bit,
  15,785 sn, 1,45 MB**. Ses sonuna kadar oynatıldı; oynatıcıda
  “Elif · Nötr · 0:15 · 308 KB” göründü.
- Konsolda hata veya uyarı yok.
- GitHub Actions çalışması `success`; `v1.0.0` sürümü yayınlandı.

### Bant genişliği

GitHub Pages'in aylık ~100 GB yumuşak sınırı vardır. Her yeni ziyaretçi
model (~143 MB) dahil yaklaşık 150 MB indirir; bu yaklaşık **ayda 600 yeni
ziyarete** karşılık gelir. Trafik artarsa model ayrı bir Release varlığına
veya CDN'e taşınmalıdır (uygulama yine çevrimdışı kalır).

### Kullanıcının yapması gerekenler

- **macOS DMG:** Bu makinede tam Xcode ve CocoaPods yok. Kurulumdan sonra
  `flutter build macos --release` çalıştırılmalı; imzalama/notarization
  için Apple Developer hesabı gerekir.
- **Safari/Firefox:** Yalnızca Chromium test edildi; bu tarayıcılarda
  çalışma zamanı testi yapılmalı.
- **Özel alan adı (isteğe bağlı):** GitHub Pages ayarlarından CNAME
  eklenebilir; `sitemap.xml`, `robots.txt`, canonical/OG etiketleri ve
  `AppInfo` adresleri buna göre güncellenmelidir.
- **Kimlik bilgisi:** Lisans ve künyede “Mehmet ICME” kullanıldı; gerçek
  ad/e-posta farklıysa `LICENSE`, `CITATION.cff` ve `pubspec.yaml`
  güncellenmelidir.

## 13. 1.1.0 — Doğallık turu ve model karşılaştırması (25 Kasım 2026)

### Düzeltilen ana sorun: yeniden örnekleyici

24 kHz model çıktısı 48 kHz'e çevrilirken kesim frekansı Nyquist'in
%47'sinde (5,6 kHz) kalıyordu. Ölçüm: 6 kHz −14 dB, 8 kHz −38 dB,
10 kHz −73 dB. Bu, sesin boğuk ve tizsiz duyulmasının ana nedeniydi.
Kesim %94'e, tap sayısı 32'ye, Kaiser β 8,6'ya çıkarıldı. Artık 6–10 kHz
−1 dB içinde, görüntüler −40 dB altında. Regresyon testleri eklendi.

### DSP ve EQ

- `DspProfile.natural`: 60 Hz high-pass, 220 Hz −1,5 dB low shelf,
  550 Hz +0,8 dB gövde, 2,8 kHz +0,8 dB varlık, de-esser 0,6, kompresör
  kapalı, −18 LUFS / −1,5 dBTP.
- Altı sesin EQ'su ölçülen spektruma göre yeniden ayarlandı.
- SQUIM_OBJECTIVE PESQ (natural): Elif 3,609; Zeynep 3,238; Defne 3,226;
  Emre 2,437; Kerem 2,353; Mert 2,422. Altısı da eski profili geçti
  (3,416 / 3,100 / 3,083 / 2,010 / 2,307 / 2,190).

### Model paketi

- Mimi kod çözücüsü INT8 yerine fp32: `decoder.onnx` 41.478.706 bayt.
- Paket toplamı 165.084.904 bayt (~157 MB); `approximateTotalBytes`
  165.000.000.
- Cümle başına deterministik tohum (42, 104729 adım) eklendi.

### Alternatif model değerlendirmesi

Aynı metin, seviye eşitlenmiş, UTMOS22 (1–5) ile ölçüldü:

| Model | Lisans | Boyut | Ses | UTMOS |
| --- | --- | --- | --- | --- |
| Pocket TTS (mevcut) | CC-BY-4.0 | ~157 MB | 6 | Elif 3,90; Emre 2,82; aralık 2,82–3,90 |
| Canora Turkish int8 | Apache-2.0 | 115 MB | 2 | elif 3,57; emre 3,50 |
| Canora Turkish fp16 | Apache-2.0 | 163 MB | 2 | elif 3,90; emre ~3,8 |
| Canora Turkish fp32 | Apache-2.0 | 325 MB | 2 | üretici beyanı 4,24 / 4,04 |
| Clarvia tiny | Apache-2.0 | 20 MB | 10 | female_1 3,01; male_1 2,90 |
| Piper dfki medium | CC-BY-4.0 | 63 MB | 1 | 3,71 |

Sonuç: Web/masaüstü için makul boyutta kalan izin verici modeller
arasında Pocket TTS'in en iyi kadın sesi (3,90) hâlâ en yüksek doğallıkta.
Canora fp16 aynı seviyeye ulaşıyor ama yalnızca 2 ses sunuyor ve fp16
ONNX'in web CPU/WASM desteği güvenilir değil. Clarvia çok küçük ve 10 sesli
ama doğallığı belirgin şekilde düşük. Piper tek sesli ve 3,71'de kalıyor.

### Referans kaydı deneyi

Pocket TTS ses klonlama kullandığı için çıktı, referans kaydın kalitesini
izliyor. Mevcut erkek referanslarının UTMOS'u düşük (male_1 1,84;
male_2 2,26; male_3 2,54), kadın referansları daha iyi (female_1 4,32).
Canora `emre` referansıyla aynı Pocket motoru 2,93 → 3,62'ye çıktı;
Canora `elif` referansı Zeynep'i 3,70'e taşıdı. Bu, model değiştirmeden
erkek seslerini iyileştirmenin en ucuz yolu. Ancak ses kimliği Canora'nın
tasarlanmış sesine dayanır ve yalnızca bir erkek tınısı verir; üç ayrı
erkek sesi için yeterli değildir.

Karşılaştırma sayfası: `build/ses-karsilastirma/index.html` (dinleme
örnekleri, seviye eşitlenmiş).
