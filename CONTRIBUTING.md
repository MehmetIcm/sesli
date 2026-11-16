# Katkı Rehberi

Sesli'ye katkı sağlamak istediğiniz için teşekkürler. Bu proje MIT
lisanslıdır ve katkılarınız da MIT kapsamında kabul edilir.

## Gereksinimler

- Flutter **3.47.6** (stable) / Dart 3.13.x
- macOS derlemesi için Xcode ve CocoaPods
- Web derlemesi için ek araç gerekmez

## Yerel kurulum

```bash
git clone https://github.com/MehmetIcm/sesli.git
cd sesli
flutter pub get
flutter run -d chrome
```

> Depo ~150 MB'tır; bunun ~143 MB'ı ONNX ses modelidir. Klonlama ilk
> seferde biraz sürebilir.

## Değişiklik göndermeden önce

```bash
dart format lib test
flutter analyze          # 0 sorun olmalı
flutter test             # tüm testler geçmeli
```

Web derlemesini de deneyin:

```bash
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 -d build/web
```

## Katkı kuralları

- **Kod stili:** mevcut yapıya uyun (`feature/` katmanları, Türkçe
  dokümantasyon yorumları, `provider` + `ChangeNotifier`).
- **Metin normalizasyonu:** yeni bir kural eklerken
  `test/features/tts/domain/turkish_text_normalizer_test.dart` içine test
  ekleyin.
- **Ses işleme:** DSP değişikliklerinde LUFS/tepe ölçümü ve ses bazlı EQ
  testlerini güncelleyin.
- **Bağımlılıklar:** yalnızca izin verici (permissive) lisanslı paketler.
  NC veya kapalı kaynak model/araç eklemeyin.
- **Model dosyaları:** yeni model eklemeyin; mevcut model CC-BY-4.0 ve
  atıf zinciri buna göre düzenlenmiştir.
- **Gizlilik:** ağ isteği, telemetri, çerez veya üçüncü taraf CDN eklemek
  kabul edilmez. Bu, projenin temel vaadidir.
- **Commit mesajı:** kısa, emir kipi ve Türkçe ya da İngilizce olabilir
  (ör. `Normalizör: kesir okumasını düzelt`).

## Pull request

1. Konuyu açıklayan kısa bir başlık yazın.
2. Değişikliğin nedenini ve varsa ölçüm sonuçlarını ekleyin.
3. Ekran görüntüsü/ses örneği davranışı değiştiriyorsa ekleyin.
4. `flutter analyze` ve `flutter test` çıktısını belirtin.

## Hata bildirimi

- Ses/sesletim hatası: metni, seçili sesi, hızı ve beklenen okunuşu yazın.
- Çökme: tarayıcı/sürüm, işletim sistemi ve konsol çıktısını ekleyin.
- Güvenlik: **issue açmayın**, `SECURITY.md` yolunu izleyin.
