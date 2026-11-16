# Gizlilik, Çerez ve Yerel Depolama Politikası

**Son güncelleme:** 16 Kasım 2026
**Geçerli sürüm:** Sesli 1.0.0 (web ve macOS)
**Veri sorumlusu:** Mehmet ICME (bireysel geliştirici) — iletişim:
[GitHub üzerinden](https://github.com/MehmetIcm/sesli/issues)

Bu politika; Sesli web uygulaması (`https://mehmeticm.github.io/sesli/`
adresindeki GitHub Pages yayını) ve macOS uygulaması için geçerlidir.

> Kısa özet: **Metinleriniz cihazınızdan çıkmaz.** Hesap, çerez, reklam,
> izleme, analiz veya üçüncü taraf API yoktur. Yalnızca uygulamanın
> çalışması için gereken yerel ayarlar tarayıcınızda saklanır.

---

## 1. Hangi verileri işliyoruz?

**Geliştirici olarak hiçbir kişisel veri toplamıyor, sunucuya
göndermiyor, saklamıyor veya üçüncü taraflarla paylaşmıyoruz.**

- Yazdığınız metinler yalnızca cihazınızın belleğinde işlenir.
- Seslendirme tamamen cihaz üzerinde çalışır (WebAssembly / yerel ONNX).
- Ses dosyaları yalnızca siz indirene kadar bellekte tutulur.
- Hesap, e-posta, ad, konum, cihaz kimliği veya benzeri bir bilgi
  istenmez.

### 1.1 Yerel depolama (tarayıcı ve uygulama)

Uygulama, çalışması için **zorunlu** olan şu bilgileri yalnızca kendi
cihazınızda saklar:

| Anahtar / alan | İçerik | Amaç | Saklama |
| --- | --- | --- | --- |
| `flutter.sesli_*` (yerel depolama) | Tema, seçili ses, ton, hız, kalite, geçmiş kaydı açık/kapalı | Tercihlerinizi hatırlamak | Tarayıcı verileri silinene kadar |
| Geçmiş kayıtları | Yalnızca “Geçmişe kaydet” açıksa son metinler (kısaltılmış) ve ses bilgisi | Son seslendirmelere erişim | Siz silene veya tarayıcı verilerini temizleyene kadar |
| Service worker önbelleği (`sesli-cache-v11`) | Uygulama dosyaları, model, sesler | Çevrimdışı çalışma | Yeni sürüm yayınlanana kadar |
| macOS `Application Support` | Model kopyası ve ayarlar | Çevrimdışı çalışma | Uygulama silinene kadar |

Bu veriler **hiçbir sunucuya gönderilmez**. Tarayıcı ayarlarından site
verilerini temizlediğinizde veya uygulamada **Ayarlar → Veriler** yolundan
geçmişi sildiğinizde bu kayıtlar da silinir.

### 1.2 Çerezler

**Sesli hiçbir çerez kullanmaz.** Uygulama kodu `document.cookie` yazmaz;
oturum, kimlik veya izleme çerezi oluşturmaz.

- Yerel depolama ve service worker önbelleği, GDPR md. 5(3) ve ePrivacy
  Direktifi anlamında **“kesinlikle gerekli”** (strictly necessary)
  kapsamındadır; bu nedenle çerez onay bandı gösterilmez.
- İleride analiz, reklam veya üçüncü taraf içerik eklenirse, bu politika
  güncellenecek ve gerekiyorsa **açık rıza** alınacaktır.

## 2. Barındırma ve erişim günlükleri

Web sürümü **GitHub Pages** üzerinde barındırılır (GitHub, Inc., ABD).
Sayfayı ziyaret ettiğinizde GitHub'ın altyapısı, hizmetin güvenliği ve
kötüye kullanımın önlenmesi amacıyla IP adresi, tarayıcı bilgisi ve istek
zamanı gibi teknik günlükleri kendi politikalarına göre işleyebilir:

- GitHub Gizlilik Beyanı: https://docs.github.com/site-policy/privacy-policies/github-privacy-statement
- GitHub, bu günlükleri bizimle paylaşmaz; bizim erişimimiz yoktur.

**Hukuki dayanak:** GDPR md. 6(1)(f) / KVKK md. 5(2)(f) — meşru menfaat
(hizmetin güvenli biçimde sunulması). Yurt dışına aktarım yalnızca bu
barındırma günlükleriyle sınırlıdır ve GitHub'ın standart sözleşme
hükümleri kapsamında gerçekleşir.

macOS sürümü tamamen çevrimdışıdır; hiçbir barındırma günlüğü oluşmaz.

## 3. Üçüncü taraf istekleri

Uygulama çalışırken **hiçbir üçüncü taraf alan adına istek yapmaz**:

- Yazı tipi (Manrope) uygulamayla birlikte gelir; Google Fonts/CDN
  kullanılmaz.
- Ses modeli, WASM motoru, sözlükler ve referans sesler uygulama
  paketinin içindedir.
- Analiz (Google Analytics, Plausible vb.), reklam ağı, hata izleme
  (Sentry vb.), sosyal medya pikseli veya A/B test aracı yoktur.

Bu nedenle uygulama, ilk yüklemeden sonra **tamamen çevrimdışı**
çalışabilir.

## 4. Çocukların gizliliği

Uygulama her yaştan kullanıcıya uygundur ve kişisel veri toplamadığı için
çocuklardan da veri toplamaz. 13 yaş altı kullanıcılar için ebeveyn
gözetimi önerilir.

## 5. Haklarınız (GDPR / KVKK)

Kişisel veri işlemediğimiz için silme, düzeltme veya taşıma talebiniz
yalnızca **cihazınızdaki yerel kayıtlar** için geçerlidir; bunları
uygulama içinden veya tarayıcı ayarlarından kendiniz yönetebilirsiniz.
Yine de sorularınız için GitHub üzerinden bize ulaşabilirsiniz.

KVKK md. 11 kapsamındaki haklarınız saklıdır. Barındırma günlükleri
bakımından veri sorumlusu GitHub, Inc.'dir; taleplerinizi GitHub'a da
iletebilirsiniz.

## 6. Güvenlik

- Uygulama ağ üzerinden veri alıp göndermediği için saldırı yüzeyi
  yoktur.
- Web yayını HTTPS üzerinden sunulur.
- Güvenlik açığı bildirimi için `SECURITY.md` dosyasına bakın.

## 7. Değişiklikler

Bu politika güncellendiğinde “Son güncelleme” tarihi değişir ve önemli
değişiklikler depoda (`CHANGELOG.md`) duyurulur.

## 8. İletişim

- Sorular ve talepler: https://github.com/MehmetIcm/sesli/issues
- Güvenlik: `SECURITY.md` içindeki özel bildirim yolu

---

## English summary

Sesli is a fully offline Turkish text-to-speech app. **We do not collect,
transmit, store or share any personal data.** Your text never leaves your
device; synthesis runs locally (WebAssembly/ONNX). There are no accounts,
cookies, analytics, ads or third-party requests. Only strictly necessary
local storage (settings, optional history, service-worker cache) is used,
which is why no cookie banner is shown. The web version is hosted on
GitHub Pages, whose infrastructure may keep standard security logs under
GitHub's privacy statement. Contact: GitHub Issues.
