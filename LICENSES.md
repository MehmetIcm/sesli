# Lisanslar

Sesli, yalnızca izin verici (permissive) ve açık kaynak lisanslı bileşenler
kullanır. Ticari kullanımı kısıtlayan (NC) hiçbir model, ses veya kod
bileşeni yoktur.

> Bu dosya bilgilendirme amaçlıdır; hukuki danışmanlık değildir. Bileşenlerin
> tam lisans metinleri ilgili paketlerin `LICENSE` dosyalarında ve kaynak
> depolarında bulunur.

## Uygulama ve model

| Bileşen | Sürüm | Lisans | Kullanım | Kaynak |
| --- | --- | --- | --- | --- |
| Pocket TTS Türkçe (model ağırlıkları) | 1.0 (INT8 ONNX) | **CC-BY-4.0** | Türkçe ses sentezi | `wite-tech/pocket-tts-turkish` |
| Pocket TTS ONNX dışa aktarıcı | — | **MIT** | Modelin ONNX'e aktarımı | `lomotron/pocket-tts-onnx-export` |
| pocket-tts-turkish metin normalizörü | — | **Apache-2.0** | Türkçe normalizasyon kuralları (telefon, kesir, aralık, Romen rakamı) | `wite-tech/pocket-tts-turkish` |
| CMU Pronouncing Dictionary | 0.7b | **BSD-2-Clause** | İngilizce kelimelerin çevrimdışı sesletim sözlüğü | `cmusphinx/cmudict` |
| FrequencyWords Türkçe listesi | — | **MIT** | Türkçe kelime koruma listesi | `hermitdave/FrequencyWords` |
| Sesli uygulama kodu | 1.0.0 | **MIT** | Uygulama | [LICENSE](LICENSE) |

Tam lisans metinleri [`licenses/`](licenses/) klasöründe, atıf metinleri
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) dosyasındadır. Uygulama
kodu MIT lisanslıdır; model, motor ve diğer bileşenler kendi lisanslarına
tabidir.

Model, CC-BY-4.0 gereği atıf gerektirir. Atıf metni
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) dosyasındadır ve uygulama
içindeki **Lisanslar** ekranında da gösterilir.

Altı konuşmacının referans kayıtları Pocket TTS Türkçe modeliyle birlikte
gelir ve aynı CC-BY-4.0 lisansı kapsamındadır. Perde kaydırma veya başka bir
ses değiştirme işlemi uygulanmaz.

## Çalışma zamanı ve Flutter paketleri

| Bileşen | Sürüm | Lisans | Kullanım |
| --- | --- | --- | --- |
| Flutter | 3.47.6 | BSD-3-Clause | Uygulama çatısı |
| Dart | 3.13.x | BSD-3-Clause | Dil ve çalışma zamanı |
| sherpa-onnx | 2.0.1 | Apache-2.0 | ONNX tabanlı TTS çıkarımı |
| ONNX Runtime | sherpa-onnx ile birlikte | MIT | Model çıkarım motoru |
| audioplayers | 6.8.1 | MIT | Ses oynatma |
| provider | 6.1.5+1 | MIT | Durum yönetimi |
| shared_preferences | 2.5.6 | BSD-3-Clause | Ayar ve geçmiş saklama |
| path_provider | 2.1.6 | BSD-3-Clause | Uygulama desteği klasörü (macOS) |
| file_selector | 1.1.0 | BSD-3-Clause | MP3 kaydetme (macOS) |
| web | 1.1.2 | BSD-3-Clause | Tarayıcı API'leri |
| path | 1.9.1 | BSD-3-Clause | Dosya yolu işlemleri |
| cupertino_icons | 1.0.9 | MIT | Simgeler |
| shine_dart | 0.1.1 | **LGPL-2.0** | Saf Dart MP3 kodlayıcı (Shine portu) |

### shine_dart / Shine (LGPL-2.0)

`shine_dart`, Shine MP3 kodlayıcısının saf Dart portudur ve LGPL-2.0 ile
lisanslanmıştır. Uygulamada değiştirilmeden, kütüphane olarak kullanılır.
LGPL-2.0, kütüphanenin kaynak kodunun erişilebilir olmasını ve kullanıcının
kütüphaneyi değiştirilmiş bir sürümle değiştirebilmesini gerektirir.
Kaynak kod `pub.dev/packages/shine_dart` ve Shine projesinde mevcuttur.
Uygulama kodu bu kütüphaneyi yeniden bağlayabilecek şekilde açık kaynak
olarak bu depoda tutulur.

## Varlıklar (assets)

| Varlık | Lisans | Kaynak |
| --- | --- | --- |
| Manrope yazı tipi | **OFL-1.1** | `google/fonts` (Manrope) |
| Material Icons | Apache-2.0 | Flutter |
| Roboto yazı tipi | Apache-2.0 | Flutter |
| CanvasKit / Skia | BSD-3-Clause | Flutter web |
| Emscripten | MIT / UIUC | sherpa-onnx WASM derlemesi |
| Uygulama simgesi ve marka işareti | Bu depo | Sesli için üretildi |
| `english_lexicon.json` | BSD-2-Clause (CMUdict) türevi | CMUdict'ten üretildi |
| `turkish_words.txt` | MIT (FrequencyWords) türevi | Türkçe sıklık listesinden üretildi |

## Lisans uyumluluğu

- **Atıf:** CC-BY-4.0 model ve OFL yazı tipi için atıf sağlanır.
- **Kaynak erişimi:** LGPL-2.0 bileşenin kaynağı erişilebilir tutulur.
- **Ticari kullanım:** Kullanılan tüm bileşenler ticari kullanıma açıktır.
- **NC bileşen yok:** Araştırma aşamasında NC lisanslı Piper sesleri
  reddedilmiş; yerine CC-BY-4.0 Pocket TTS Türkçe kullanılmıştır.

## Doğrulama

Bağımlılık ağacını ve lisansları görmek için:

```bash
flutter pub deps
find ~/.pub-cache/hosted/pub.dev -maxdepth 2 -name LICENSE | head
```

Uygulama içinde **Ayarlar → Lisanslar ve kaynaklar** ekranı bileşen
lisanslarını listeler.
