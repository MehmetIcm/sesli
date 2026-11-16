# Güvenlik Politikası

## Desteklenen sürümler

| Sürüm | Destek |
| --- | --- |
| 1.0.x | ✅ Güvenlik düzeltmeleri alır |
| < 1.0 | ❌ Desteklenmez |

## Açık bildirimi

Güvenlik açıklarını **herkese açık issue olarak açmayın**. Bunun yerine:

1. GitHub'ın özel bildirim kanalını kullanın:
   https://github.com/MehmetIcm/sesli/security/advisories/new
2. Mümkünse şunları ekleyin: etkilenen sürüm, işletim sistemi/tarayıcı,
   yeniden üretme adımları, olası etki.

Geri bildirim hedefi: **72 saat içinde** ilk yanıt, doğrulanan açıklar için
düzeltme sürümü ve `CHANGELOG.md` kaydı.

## Kapsam

**Kapsam içinde**

- Uygulama kodu (`lib/`, `web/`, `macos/`)
- Service worker önbellek mantığı ve kaynak yolları
- MP3/WAV üretim hattı (bellek taşması, hatalı çıktı)
- Bağımlılık zinciri (bilinen CVE'ler)

**Kapsam dışında**

- Modelin ses kalitesi, doğallığı veya sesletim hataları (hata olarak
  bildirin, güvenlik açığı olarak değil)
- Üçüncü taraf paketlerin kendi hataları (ilgili projeye bildirin; bize de
  haber verirseniz sürüm yükseltiriz)
- Devasa metinlerle kasıtlı hizmet dışı bırakma (DoS)
- GitHub Pages altyapısı

## Tasarım gereği güvenlik

- Uygulama, çalışma sırasında ağ isteği yapmaz; metinler cihazdan çıkmaz.
- Hiçbir gizli anahtar, API anahtarı veya kimlik bilgisi depoda tutulmaz.
- Web yayını HTTPS üzerindendir.
- Ses ve metin işleme tamamen yerel olduğu için sunucu tarafı veri ihlali
  riski yoktur.
