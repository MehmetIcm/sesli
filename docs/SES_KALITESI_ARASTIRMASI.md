# Ses Kalitesi Araştırması

**Tarih:** 14 Kasım 2026  
**Kapsam:** Sesli’nin mevcut Pocket TTS Türkçe + Dart DSP hattında sesi daha
doğal, daha net ve daha tutarlı hâle getirmek için yapılabilecekler.  
**Yöntem:** Model doğrudan Python `sherpa-onnx` 2.0.1 ile çalıştırıldı; altı
sesin çıktısı, model parametreleri, referans ses işleme, duraklama düzeni ve
normalizasyon davranışı ölçüldü. Ölçümler tek bir test cümlesi ve tek tohum
ile yapıldığı için **gösterge niteliğindedir**; nihai karar dinleme testiyle
verilmelidir.

---

> **Uygulama durumu (15 Kasım 2026):** Bu raporun ilk fazı uygulandı.
> LUFS normalizasyonu + gerçek tepe limiter (−20 LUFS / −1,5 dBTP), ses
> bazlı EQ, `female_1` de-esser’ı, cümle bazlı sentez ve duraklama düzeni,
> `silenceScale 1,05` / `temperature 0,45` / `seed 42` /
> `max_reference_audio_len 5`, 48 kHz oynatma ve MP3, TPDF dither ile resmî
> normalizör kuralları devrede. Ölçüm sonuçları `Progress.md` bölüm 11’de.
> Aşağıdaki metin, kararların gerekçesini ve ölçümleri tarihsel kayıt
> olarak korur.

## 1. Yönetici özeti

Sesi boğuk duyuran ana neden modelin kendisi değil, **modelin eğitildiği
sentetik seslerin spektral dengesi** ve buna bağlı olarak çıktının aşırı bas
ağırlıklı olması. Mevcut EQ zinciri bu sorunu büyük ölçüde azaltıyor; ancak
altı sesin hepsine aynı EQ uygulandığı için özellikle erkek sesleri hâlâ
karanlık, kadın seslerinden biri ise fazla tıslıyor.

Ölçülen en önemli bulgular:

1. **Sesler arasında 4,4 dB’ye varan yükseklik farkı var.** Aynı metin ve aynı
   EQ sonrası `female_3` −22,2 LUFS, `male_3` −17,8 LUFS. Kullanıcı ses
   değiştirdiğinde sesin “zayıf” veya “gürültülü” gelmesinin başlıca nedeni bu.
2. **Tek bir global EQ altı sesi birden memnun etmiyor.** EQ sonrası 300 Hz
   altı enerji oranı `female_1`’de %22, `male_2`’de %55. 1–3 kHz varlık oranı
   ise `female_1`’de %43, `male_2`’de %15.
3. **Model çıktısında 6–12 kHz neredeyse yok.** Ham çıktıda “air” oranı
   %0,1; mevcut EQ sonrası bile %0,7. Bu, yüksek raf (high shelf) ile
   düzeltilebilecek bir eksiklik değil; kaynakta o bantta içerik yok.
4. **Referans sesi agresif işlemek riskli.** Parlak bir İngilizce/Türkçe
   referansla model daha da karanlık çıktı (%79 bas). Referansın kimliğine
   dokunmadan yalnızca hafif bir bas kesintisi denenebilir; o da dinleme
   testi gerektirir.
5. **Duraklama düzeni tutarsız.** Model iki cümle arasına doğal olarak
   ~580–600 ms koyuyor. Uygulama parçaların kenar sessizliğini kırpıp yerine
   380 ms koyduğunda bu doğal pay kısalabiliyor; parçalama uzunluğuna göre
   bazen 380 ms, bazen 600 ms duyuluyor.
6. **Resmî `pocket-tts-turkish` paketi cümleleri tek tek üretiyor ve
   aralarına 150 ms koyuyor; ayrıca ses sonrası DSP uygulamıyor.** Yani
   bizim EQ/kompresör hattımız bir “iyileştirme” katmanı; faydası kadar
   riski de var.
7. **Telefon numarası okuması iyileştirilebilir.** Resmî paket, modelin
   tekrarlanan rakamlarda döngüye girmemesi için numaraları grup grup
   okuyor (`0555 123 45 67` → “sıfır beş yüz elli beş, yüz yirmi üç, kırk
   beş, altmış yedi”). Uygulama şu an rakam rakam okuyor; “beş beş beş”
   dizisi modelde tekrara yol açabilir.

**Öneri:** Önce düşük riskli, ölçülebilir dört iş yapılmalı:

- Çıktıyı **LUFS tabanlı yükseklik normalizasyonu + gerçek tepe sınırlayıcı**
  ile −20 LUFS / −1,5 dBTP’ye getirmek.
- **Ses bazlı EQ profilleri** ve `female_1` için **de-esser** eklemek.
- **Cümle bazlı sentez + tutarlı duraklama politikası** kurmak.
- Resmî normalizörün **telefon grubu, tekrar birleştirme, sıra sayısı,
  kesir, aralık, romen rakamı, emoji/HTML** kurallarını uygulamaya almak.

Bunlar sesi belirgin biçimde daha net ve tutarlı yapar; model değiştirmeden,
çevrimdışı ve permissive lisans sınırları içinde kalır.

---

## 2. Mevcut durum ve ölçüm yöntemi

### 2.1 Hat

```
metin → TurkishTextNormalizer → EnglishTransliterator → cümle segmentleri
      → Pocket TTS (24 kHz, cümle bazlı) → trim/join + duraklama
      → WSOLA hız → global EQ + ses bazlı EQ + de-esser + kompresör
      → LUFS + gerçek tepe limiter → 48 kHz WAV (oynatma) + MP3 (indirme)
```

Mevcut EQ (`AudioPostProcessor.enhance`):

| Aşama | Ayar |
|---|---|
| High-pass | 80 Hz, Q 0,707 |
| Low shelf | 250 Hz, −4 dB |
| Peaking | 500 Hz, −1,5 dB, Q 1,0 |
| Peaking | 2 kHz, +2,5 dB, Q 1,0 |
| Peaking | 3,4 kHz, +5 dB, Q 0,9 |
| High shelf | 6,5 kHz, +3,5 dB |
| Kompresör | −22 dB eşik, 2:1, 12 ms attack, 180 ms release |
| Tepe | 0,91 (−0,8 dBFS) |

### 2.2 Ölçümler

- Model: `assets/models/pocket_tts_tr/` (INT8), `sherpa-onnx` 2.0.1,
  `num_steps=8`, `temperature=0.5`, `silence_scale=1.12`.
- Referans: `assets/voices/female_1.wav` (resmî 24 kHz, 3,93 s).
- Test cümlesi: “kembriç üniversitesi çok eski. yeni vebkem sürücüsünü
  indirip test ettim.”
- Spektral bantlar: 0–300 Hz (bas), 300–1000 Hz (gövde), 1–3 kHz (varlık),
  3–6 kHz (tıslama), 6–12 kHz (hava).
- Yükseklik: `ffmpeg ebur128` ile entegre LUFS ve gerçek tepe.
- Süreler: 10 ms çerçeve RMS’i ile sessizlik aralıkları.

> Not: Tek cümle/tek tohum ölçümü, sesin karakterini göstermek için yeterli
> ama kesin karar için 10–20 cümle ve 3 farklı tohumla tekrarlanmalı.

---

## 3. Temel bulgu: model ve referans sesler karanlık

### 3.1 Referans seslerin spektrumu

Resmî `female_1.wav` referansı:

| Bant | Oran |
|---|---:|
| 0–80 Hz | %0,0 |
| 80–150 Hz | %0,0 |
| 150–300 Hz | %35,1 |
| 300–500 Hz | %23,7 |
| 500–1.000 Hz | %24,4 |
| 1–2 kHz | %8,0 |
| 2–3 kHz | %6,2 |
| 3–4 kHz | %1,0 |
| 4–6 kHz | %1,4 |
| 6–8 kHz | %0,2 |
| 8–12 kHz | %0,0 |

Altı referansın tamamı benzer: 300 Hz altı %19–45, 3–6 kHz %0,2–1,5,
8–12 kHz ~%0. Yani referanslar **8 kHz üstünde neredeyse tamamen boş**.
Model bu referansların tınısını taklit ettiği için çıktı da karanlık.

### 3.2 Ham model çıktısı

`num_steps=8`, `temperature=0.5`, `female_1`:

| Ölçüm | Değer |
|---|---:|
| Süre | 5,05 s |
| LUFS | −19,4 |
| Gerçek tepe | −2,6 dBTP |
| 0–300 Hz | %42,3 |
| 300–1.000 Hz | %34,7 |
| 1–3 kHz | %19,2 |
| 3–6 kHz | %0,3 |
| 6–12 kHz | %0,1 |

Ham çıktı, referanstan bile daha bas ağırlıklı. Bu yüzden “boğuk” algısı
normaldir; EQ burada gerçekten gerekli.

### 3.3 Mevcut EQ sonrası

| Ölçüm | Ham | EQ sonrası |
|---|---:|---:|
| 0–300 Hz | %42,3 | %27,1 |
| 300–1.000 Hz | %34,7 | %19,5 |
| 1–3 kHz | %19,2 | %42,5 |
| 3–6 kHz | %0,3 | %10,2 |
| 6–12 kHz | %0,1 | %0,7 |
| LUFS | −19,4 | −19,5 |
| Gerçek tepe | −2,6 | −0,7 |

EQ, bası belirgin biçimde azaltıp varlık bölgesini açıyor. Ancak 3–6 kHz
oranı %10’a çıkarken `female_1` gibi seslerde tıslama rahatsız edici
olabilir; bu yüzden de-esser gerekli.

### 3.4 Neden yüksek raf tek başına yetmiyor?

6–12 kHz’te içerik yoksa +3,5 dB high shelf yalnızca çok düşük seviyeli
gürültüyü yükseltir. Basit bir harmonik uyarıcı (2–4 kHz bandını doyurup
5,5 kHz üstünü karıştırma) denendi: −30, −24 ve −18 dB karışımda “air”
oranı yalnızca %0,5–0,8 aralığında kaldı. Yani **basit exciter bu modelde
işe yaramıyor**. Gerçek bant genişliği uzatma (neural BWE) veya 48 kHz
üreten başka bir model gerekir.

---

## 4. Ses bazlı farklar: asıl sorun

Aynı metin, aynı EQ, altı ses. Ölçümler EQ sonrası:

| Ses | 0–300 Hz | 300–1k | 1–3k | 3–6k | 6–12k | LUFS | Gerçek tepe |
|---|---:|---:|---:|---:|---:|---:|---:|
| Elif (`female_1`) | %22,4 | %21,4 | %43,5 | %12,0 | %0,7 | −19,6 | −0,4 |
| Zeynep (`female_2`) | %34,5 | %37,1 | %25,3 | %2,6 | %0,6 | −21,3 | −0,8 |
| Defne (`female_3`) | %38,5 | %34,9 | %23,4 | %3,1 | %0,2 | −22,2 | −0,7 |
| Emre (`male_1`) | %45,4 | %31,3 | %16,6 | %2,3 | %4,4 | −21,3 | −0,8 |
| Kerem (`male_2`) | %55,4 | %29,1 | %14,5 | %0,6 | %0,4 | −18,9 | −0,7 |
| Mert (`male_3`) | %42,0 | %37,5 | %16,4 | %0,9 | %3,2 | −17,8 | −0,8 |

Çıkarımlar:

- **Elif** zaten parlak; sorun tıslama (%12) ve hafif sertlik.
- **Zeynep ve Defne** orta karanlık; varlık bölgesi %23–25, bas %34–39.
- **Emre, Kerem, Mert** belirgin karanlık; bas %42–55, varlık %15–17.
- **Yükseklik farkı 4,4 dB.** `female_3` ile `male_3` aynı cihazda çok
  farklı algılanır. Bu, kullanıcı deneyiminde “bazı sesler bozuk/boğuk”
  hissinin önemli bir parçası.

### 4.1 Ses bazlı EQ adayları

Aşağıdaki ek filtreler mevcut EQ’nun **üzerine** uygulandığında ölçülen
sonuçlar:

| Ses | Ek filtreler | 0–300 Hz | 1–3k | 3–6k | 6–12k |
|---|---|---:|---:|---:|---:|
| Kerem | low shelf 250 Hz −4 dB, 3,4 kHz +4 dB, 6,5 kHz +2 dB | %35,5 | %28,7 | %2,1 | %0,9 |
| Emre | low shelf 250 Hz −2 dB, 3,4 kHz +3 dB, 6,5 kHz +2 dB | %34,5 | %22,4 | %4,8 | %7,0 |
| Mert | low shelf 250 Hz −2 dB, 3,4 kHz +3 dB, 6,5 kHz +2 dB | %32,0 | %24,5 | %1,7 | %5,2 |
| Zeynep | low shelf 250 Hz −1 dB, 3,4 kHz +2 dB, 6,5 kHz +1 dB | %29,5 | %30,3 | %3,9 | %0,7 |
| Defne | low shelf 250 Hz −2 dB, 3,4 kHz +3 dB, 6,5 kHz +2 dB | %28,3 | %33,0 | %5,9 | %0,3 |

Bu profiller bası %30–35’e çekip varlık bölgesini %22–33’e taşıyor. Yine de
“doğru” profil dinleme testiyle seçilmeli; özellikle 3,4 kHz ve 6,5 kHz
artışları tıslama üretebilir.

### 4.2 Daha ilkeli yöntem: hedef spektruma eşleme

Tek tek elle EQ denemek yerine:

1. Her ses için 10–20 cümle sentezle.
2. Her sesin uzun süreli ortalama spektrumunu (LTAS) çıkar.
3. Hedef bir konuşma LTAS’ı tanımla (ör. 0–300 Hz %20–25, 300–1k %25–30,
   1–3k %35–40, 3–6k %8–10, 6–12k %1–2).
4. Hedef ile ölçülen arasındaki farkı 6–8 peaking/shelf filtresiyle
   yaklaşıkla.
5. Elde edilen katsayıları `VoiceProfile` yanında sakla; çalışma anında
   yalnızca uygula.

Bu, “ses bazlı EQ”nun en savunulabilir hâli. Altı ses sabit olduğu için
kalibrasyon bir kez yapılır; çalışma anında ek maliyet yoktur.

---

## 5. Model parametreleri

### 5.1 `num_steps`

Aynı metin, `temperature=0.5`, EQ sonrası:

| Adım | 0–300 Hz | 1–3k | 3–6k | Süre | Üretim |
|---:|---:|---:|---:|---:|---:|
| 4 | %25,5 | %46,1 | %7,5 | 5,06 s | 1,31 s |
| 8 | %27,1 | %42,5 | %10,2 | 5,05 s | 1,13 s |
| 16 | %38,2 | %35,9 | %7,7 | 4,98 s | 1,31 s |
| 32 | %32,0 | %37,4 | %8,4 | 4,98 s | 1,61 s |

İlk bakışta 4 ve 8 daha dengeli; 16 daha karanlık. Ancak bu tek tohumluk
bir sonuç; adım sayısı arttıkça çıktı farklı bir örnekleme yörüngesine
girebilir. **Sonuç:** 8 varsayılanı makul; 4 daha hızlı ve biraz daha az
tıslı. 16/32’yi “daha kaliteli” diye sunmak için kanıt yok; dinleme testi
gerekir.

### 5.2 `temperature`

0,3 / 0,5 / 0,7 / 1,0 denendi. Spektral farklar küçük; 0,3 biraz daha az
bas ve tıslama verdi, 0,7–1,0 benzer. Düşük sıcaklık daha kararlı ve
tekrarlanabilir; 0,4–0,5 iyi bir aralık. Çok düşük (≤0,2) muhtemelen
donuk/tek düze olur.

### 5.3 `silence_scale`

1,0 / 1,12 / 1,4 denendi; süre 4,88 → 5,31 s. Modelin kendi cümle arası
payı zaten ~580–600 ms. Uygulama kenar sessizliğini kırptığı için
`silence_scale`’in etkisi büyük ölçüde kayboluyor. **Öneri:** 1,0–1,1
kullanıp duraklamayı açıkça yönetmek; 1,4 gereksiz uzunluk ve yapaylık
riski taşır.

### 5.4 `max_reference_audio_len`

2 / 4 / 6 / 8 s denendi. 2 s daha dengeli spektrum verdi (%23 bas, %42
varlık) ama kimlik kaybı riski var. 4 s mevcut referanslarla uyumlu;
6–8 s belirgin kazanç sağlamadı. **Öneri:** 4–5 s’de kalın; referansı
keserken resmî `cut_reference` kuralına (3–5 s arasında kelime arası
duraklama) uyun.

### 5.5 `seed`

Uygulama şu an tohum vermiyor; her sentez farklı çıkabilir. Sabit tohum:

- tekrarlanabilir test ve hata ayıklama sağlar;
- bazı metinlerde kötü bir örnekleme denk gelme riskini artırır.

Öneri: varsayılan sabit tohum (ör. 42) + “çeşitlilik” isteyenler için
opsiyonel rastgele. Alternatif olarak iki aday üretip basit bir kalite
ölçütüyle (kırpılma yok, sessizlik dengesi, spektral hedefe yakınlık)
seçmek; maliyet 2×.

### 5.6 INT8 / FP32

Model başlangıçta tamamen INT8 idi. INT8 quantizasyon özellikle
flow/decoder’da artefakt üretebilir. 1.1.0'da dil modeli INT8 kalırken
Mimi kod çözücüsü fp32'ye alındı; paket 143 MB'tan 157 MB'a çıktı ve
kuantizasyon gürültüsü belirgin şekilde azaldı. Ayrıntılar için
[bölüm 7](#7-110-doğallık-turu-25-kasım-2026).

---

## 6. Referans ses işleme: dikkatli olun

Referans, modelin tınısını belirleyen en güçlü girdi. Ancak işlemek her
zaman iyileştirmiyor:

| Referans işlemi | EQ sonrası 0–300 Hz | 1–3k | 3–6k | Yorum |
|---|---:|---:|---:|---|
| Orijinal `female_1` | %27,1 | %42,5 | %10,2 | Dengeli ama tıslı |
| Yalnızca low shelf −3 dB (250 Hz) | %20,9 | %47,2 | %9,1 | Daha iyi bas/orta dengesi |
| Low shelf −2, presence +2, high +1 | %21,4 | %51,4 | %12,4 | Daha parlak, tıslama artıyor |
| Low shelf −2, presence +3, high +2 | %14,3 | %55,3 | %15,4 | Fazla parlak/sert |
| Low shelf −3, presence +4, high +3 | %14,4 | %53,5 | %18,6 | Dinlemek zor olabilir |
| Parlak İngilizce referans (Samantha) | %79,1 | %0,8 | %0,3 | Çok daha karanlık; kimlik uyuşmuyor |
| Parlak Türkçe OS sesi (Yelda) | %75,5 | %0,2 | %0,0 | Aynı sorun |

**Sonuç:**

- Agresif referans EQ’su tınıyı öngörülemez biçimde kaydırıyor.
- Farklı dil/ses kimliğinden referans, modeli bozuyor.
- Yalnızca **hafif low shelf (−2…−3 dB @ 250 Hz)** denenebilir; bu, bası
  azaltıp kimliği fazla bozmadan dengeyi iyileştiriyor.
- Daha güvenli referans hazırlığı: baş/son sessizliği kırp, 3–5 s’de
  kelime arası duraklamada kes, gerekirse yalnızca loudness normalize et
  (EQ’siz). Resmî referanslar zaten bu şekilde hazırlanmış.

**Öneri:** Referans işlemeyi ilk aşamada değiştirmeyin. Yalnızca
“low shelf −2 dB” varyantını A/B dinleme testine koyun; kazanç yoksa
bırakın.

---

## 7. Duraklama ve ritim

### 7.1 Modelin doğal davranışı

İki cümlelik metin tek istekte üretildiğinde:

- Cümle sınırında **580 ms** sessizlik.
- Soru işaretinde **600 ms**.
- Cümle içi virgüllerde **90–160 ms**.

Yani model zaten doğal bir ritim üretiyor.

### 7.2 Uygulamanın davranışı

`joinWithPauses` her parçanın başındaki/sonundaki sessizliği kırpıyor
(eşik −50 dBFS, 20 ms koruma) ve yerine `_pauseAfter` ile 180–620 ms
koyuyor. Parçalar cümle sınırında bölünürse modelin 580 ms’lik doğal payı
silinip yerine 380 ms konuyor. Parçalar birden fazla cümle içerirse modelin
580 ms’i korunuyor ve ek pay eklenmiyor. Sonuç: **parçalama uzunluğuna göre
tutarsız duraklama**.

### 7.3 Öneri: cümle bazlı sentez + tek politika

Resmî paket gibi her cümleyi ayrı üretin:

1. Normalize metni cümlelere böl (`[.!?…]` + boşluk).
2. Her cümleyi ayrı sentezle.
3. Kenar sessizliğini kırp, 6–8 ms fade uygula.
4. Cümle arasına **300–380 ms**, virgül/iki nokta arasına **140–200 ms**,
   üç nokta/paragraf arasına **550–650 ms** koy.
5. Başlangıç 120–150 ms, bitiş 250–300 ms.

Neden 150 ms değil? Resmî paket 150 ms kullanıyor ama modelin kendi
kuyruk sessizliği de ekleniyor; biz kenarı kırptığımız için 150 ms kısa
kalabilir. 300–380 ms, Türkçe okuma için doğal ve acele etmeyen bir aralık.
Kullanıcı isterse hız ayarıyla birlikte bu değerler ölçeklenebilir.

Alternatif: çok cümleli parçaları koruyup yalnızca parça sınırında pay
eklemek. Bu, modelin doğal cümle içi ritmini korur; ancak parça sınırları
metne göre değiştiği için tutarlılık zor. Cümle bazlı yaklaşım daha
kontrol edilebilir.

### 7.4 Durum: acele hissi

Kullanıcı “aceleye gelmesin” dediyse, cümle bazlı sentez + 300–380 ms pay
iyi bir başlangıç. Ayrıca varsayılan hızı 1,0 yerine 0,95 yapmak
düşünülebilir; ancak WSOLA 0,95’te de temiz. Dinleme testiyle karar verin.

---

## 8. Metin normalizasyonu: resmî paketten alınacaklar

Resmî `pocket-tts-turkish` normalizörü, modelin davranışına göre
şekillendirilmiş ve bizimkinden bazı yerlerde daha güvenli. Öne çıkanlar:

### 8.1 Telefon numaraları: grup grup oku

Bizimki rakam rakam okuyor:

```
0555 123 45 67 → sıfır beş beş beş, yüz yirmi üç, kırk beş, altmış yedi
```

Resmî paket:

```
0555 123 45 67 → sıfır beş yüz elli beş, yüz yirmi üç, kırk beş, altmış yedi
```

Ayrıca `_merge_repeats` ile `55 55` → `5555` birleştirmesi var; amaç
modelin tekrarlanan kelimelerde döngüye girmesini önlemek. Bu, telefon
numaralarında ve kodlarda önemli.

### 8.2 Diğer kurallar

- Binlik ayırıcı: `2.345` → `2345` (bizde de var).
- Sıra sayıları: bağlamdaki isimlere göre (`3. kat` → `üçüncü kat`).
- Kesirler: `3/4` → `dörtte üç`, `1/2` → `yarım`.
- Aralıklar: `10-15` → `on ile on beş`.
- Matematik: `+`, `×`, `÷`, `=`, `>`, `<`, `≥`, `≤`, `≠`, `±`.
- Romen rakamları: `XVI. yüzyıl` → `on altıncı yüzyıl`.
- Emoji/HTML temizliği.
- Tüm büyük harfli kelimeleri normal yazıya çevirme (bazı kısaltmalar
  hariç).
- `w → v`, `x → ks`, `q → k`, `/ → boşluk`, `@ → et` eşlemesi.
- Cümle başındaki büyük harfi küçültme; model büyük harfle başlayan ilk
  kelimeyi atlama/eğme eğiliminde. Biz zaten tüm metni küçültüyoruz;
  bu, model için güvenli.

### 8.3 Öneri

Resmî normalizörün ilgili fonksiyonlarını (Apache-2.0) Dart’a port edin;
özellikle telefon grubu ve tekrar birleştirme. `LICENSES.md` ve
`THIRD_PARTY_NOTICES.md`’ye “pocket-tts-turkish normalizer, Apache-2.0”
ekleyin. Model CC-BY-4.0 zaten mevcut.

---

## 9. Önerilen iyileştirmeler ve öncelik

| # | İş | Beklenen etki | Risk | Efor |
|---|---|---|---|---|
| 1 | LUFS normalizasyonu + gerçek tepe limiter | Yüksek: sesler arası tutarlılık | Düşük | Orta |
| 2 | Ses bazlı EQ profilleri | Yüksek: erkek seslerde netlik | Orta (dinleme) | Orta |
| 3 | `female_1` için de-esser | Orta-yüksek: tıslama kontrolü | Orta | Orta |
| 4 | Cümle bazlı sentez + tutarlı duraklama | Orta-yüksek: doğal ritim | Düşük | Düşük |
| 5 | Resmî normalizör kuralları | Orta: yanlış okuma/döngü azalır | Düşük | Orta |
| 6 | 48 kHz oynatma + dither | Düşük-orta: tarayıcı resampling’i azalır | Düşük | Düşük |
| 7 | Kompresörü yumuşatma / kapatma | Orta: daha doğal dinamik | Orta | Düşük |
| 8 | Referans low shelf −2 dB A/B | Belirsiz | Orta-yüksek | Düşük |
| 9 | `num_steps`/`temperature` ince ayarı | Düşük | Düşük | Düşük |
| 10 | Harmonik exciter / BWE | Düşük (basit exciter) / yüksek (neural) | Yüksek | Yüksek |
| 11 | Alternatif model (FreyaTTS-small, Piper) | Belirsiz; model değişimi | Yüksek | Çok yüksek |
| 12 | FP32/FP16 masaüstü modu | Orta (belki) | Orta | Yüksek |

### 9.1 Neden 1–5 önce?

- 1, sesler arasındaki en görünür sorunu çözer; dinleme gerektirmez,
  ölçülebilir.
- 2–3, “boğuk” ve “tıslı” şikâyetlerinin doğrudan karşılığı.
- 4, kullanıcıın “acele etmesin” isteğini karşılar; kod değişikliği küçük.
- 5, modelin kendi hata modlarını (tekrar, yanlış okuma) azaltır.

---

## 10. Somut parametre önerileri

### 10.1 Yükseklik normalizasyonu

Hedef: **−20 LUFS entegre**, **−1,5 dBTP gerçek tepe**.

Neden −20, −16 değil?

- Mevcut çıktı −17,8…−22,2 LUFS aralığında. −16 hedefi, özellikle
  `female_3` için 6 dB’ye varan kazanç ve agresif limiter gerektirir;
  doğallık azalır.
- −20 LUFS, konuşma için rahat, web uygulamasında yeterince yüksek ve
  limiter yükünü makul tutar.
- İsterseniz “yüksek ses” seçeneği −18 LUFS olabilir; varsayılan −20.

Uygulama:

1. ITU-R BS.1770-4 K-ağırlıklı filtre + 400 ms blok + gating ile entegre
   LUFS hesapla.
2. `gain = targetLufs − measuredLufs`.
3. Uygula; gerçek tepe −1,5 dBTP’yi aşıyorsa 5 ms look-ahead, 50–80 ms
   release ile yumuşak limiter uygula.
4. Limiter sonrası LUFS’yi tekrar ölç; hedefin ±0,5 LU içinde kalana kadar
   gain’i küçük adımlarla güncelle (1–2 iterasyon yeter).

Basit alternatif: ses başına sabit gain (kalibrasyon tablosu). Daha az kod
ama içerik bağımlı yükseklik farklarını tam çözmez. LUFS daha doğru.

### 10.2 Ses bazlı EQ

Mevcut global EQ’yu koruyup ses başına ek profil:

| Ses | Ek low shelf | Ek 3,4 kHz | Ek 6,5 kHz | Not |
|---|---|---|---:|---|
| Elif | 0 dB | −1,0 dB | 0 dB | De-esser ekle |
| Zeynep | −1 dB @ 250 | +2 dB | +1 dB | |
| Defne | −2 dB @ 250 | +3 dB | +2 dB | |
| Emre | −2 dB @ 250 | +3 dB | +2 dB | |
| Kerem | −4 dB @ 250 | +4 dB | +2 dB | En karanlık |
| Mert | −2 dB @ 250 | +3 dB | +2 dB | |

Bu değerler ölçümlere göre başlangıç; dinleme testiyle ±1–2 dB ayarlayın.
Daha iyisi: LTAS eşleme ile otomatik kalibrasyon (bkz. 4.2).

### 10.3 De-esser

Öneri:

- Yan zincir: 5–9 kHz bandı.
- Eşik: tam bant zarfına göre −24…−30 dB (veya konuşma RMS’ine göre).
- Oran: 3:1–4:1.
- Maksimum azaltma: 4–6 dB.
- Attack 1 ms, release 40–60 ms.
- Uygulama: 6–8 kHz peaking filtresinin gain’ini dinamik olarak azalt
  (split-band veya dinamik EQ).

Hedef: `female_1`’de 3–6 kHz oranını %12’den %8–9’a çekmek; tıslama
azalırken “s” sesleri kaybolmasın. Aşırıya kaçarsa “peltek” duyulur.

### 10.4 Kompresör

Mevcut: −22 dB, 2:1, 12 ms / 180 ms. LRA 0,5–1,1 LU; bu, konuşma için
oldukça düz. Öneri:

- Önce kompresörü **kapatıp** yalnızca LUFS + limiter ile deneyin.
- Doğallık artıyorsa kompresörü tamamen kaldırın.
- Kalıyorsa: −24 dB, 1,5:1, 20 ms / 250 ms gibi daha yumuşak ayar.

Amaç, heceler arası seviye farkını korumak; agresif kompresör “stüdyo”
hissi verirken doğallığı ve nefesleri yok eder.

### 10.5 Duraklama

| Bağlam | Öneri |
|---|---:|
| Başlangıç | 120–150 ms |
| Cümle sonu `.` | 320–380 ms |
| Soru `?` | 380–450 ms |
| Ünlem `!` | 350–420 ms |
| Üç nokta `…` | 550–650 ms |
| Virgül `,` | 140–180 ms |
| Noktalı virgül `;` | 200–250 ms |
| İki nokta `:` | 240–300 ms |
| Paragraf | 550–650 ms |
| Bitiş | 250–300 ms |

Cümle bazlı sentezde bu değerler doğrudan uygulanır; çok cümleli
parçalarda iç cümle sınırlarına dokunulmaz.

### 10.6 48 kHz, dither, limiter

- **48 kHz oynatma:** 24 kHz → 48 kHz tam 2× yükseltme; tarayıcının
  44,1 → 48 kHz resampling’i önlenir. Çoğu cihaz 48 kHz çalışır.
- **MP3:** Shine 48 kHz’i destekliyor; 160 kbps mono yeterli. İsterseniz
  192 kbps.
- **Dither:** 16-bit WAV’e TPDF dither (±1 LSB) ekleyin; kuantizasyon
  bozulmasını azaltır. Çok düşük seviyeli ama doğru bir iyileştirme.
- **Limiter:** MP3 ve WAV öncesi −1,5 dBTP; inter-sample peak’leri
  önlemek için 4× oversampling ile ölçüm veya en azından 0,5 dB ek pay.

### 10.7 Model parametreleri

| Parametre | Mevcut | Öneri | Not |
|---|---:|---:|---|
| `num_steps` | 8 | 8 (varsayılan), 4 hızlı | 16’yı kanıtsız yükseltmeyin |
| `temperature` | 0,5 | 0,4–0,5 | Daha kararlı |
| `silence_scale` | 1,12 | 1,0–1,1 | Duraklamayı biz yönetelim |
| `max_reference_audio_len` | yok | 4–5 s | Referansı resmî kuralla kes |
| `seed` | yok | sabit (42) | Tekrarlanabilirlik |
| `min_char_in_sentence` | 20 | 20 | Kısa cümleleri koru |
| `max_char_in_sentence` | 240 | 240 | Dart parçalamasıyla uyumlu |

### 10.8 Normalizör

- Telefon numaralarını grup grup oku; tekrarlanan grupları birleştir.
- Sıra sayılarını bağlama göre genişlet.
- Kesir, aralık, matematik, romen rakamı, emoji/HTML kurallarını ekle.
- `@` → “et”, `/` → boşluk, `w` → `v`, `x` → `ks`, `q` → `k`.
- Tüm büyük harfleri normal yazıya çevir; bilinen kısaltmaları koru.
- Cümle başını küçült (model için).
- İngilizce kelime katmanını koru; resmî paket yalnızca `w/x/q` ve
  `WhatsApp` ile sınırlı, bizimki daha kapsamlı.

---

## 11. Yapılmaması gerekenler

1. **Agresif referans EQ’su.** Tınıyı öngörülemez biçimde kaydırıyor;
   parlak referans daha karanlık çıktı.
2. **Yüksek raf ile “air” eklemeye çalışmak.** Kaynakta 6–12 kHz yok;
   yalnızca gürültüyü yükseltir.
3. **Basit harmonik exciter.** Ölçümde <1% air; artefakt riski yüksek.
4. **Aşırı kompresör.** LRA’yı 1 LU’nun altına indiriyor; doğallığı
   azaltıyor.
5. **−16 LUFS hedefi.** `female_3` gibi seslerde 6 dB kazanç + agresif
   limiter gerekir; doğallık bozulur.
6. **Pitch shifting ile “daha kadın/erkek” ses.** Perde kaydırma kimliği
   bozar; zaten referans sesler var.
7. **OS TTS / bulut / `SpeechSynthesis`.** Proje gereksinimlerine aykırı.
8. **GPL-3.0 Piper’ı uygulamaya gömmek.** Lisans uyumsuzluğu; eski MIT
   sürümü ve ses lisansları ayrıca incelenmeli.
9. **CC-BY-NC modeller (MMS, XTTS-v2).** Ticari kullanım kapalı.
10. **Tek ölçümle karar vermek.** Tohum/metin değişince spektrum
    değişebilir; 10–20 cümle ve dinleme testi gerekir.

---

## 12. Alternatif modeller (bilgi amaçlı)

| Model | Lisans | Türkçe | Çıkış | WER (Freya-TR-Eval) | Web/macOS uygunluğu |
|---|---|---|---:|---:|---|
| **Pocket TTS Türkçe** (mevcut) | CC-BY-4.0 | Var, 6 ses | 24 kHz | %1,9 | ONNX/WASM hazır |
| FreyaTTS-small | Apache-2.0 | Var, tek ses | 48 kHz | %8,0 | PyTorch; ONNX export gerekir |
| Piper (eski MIT / yeni GPL-3.0) | MIT / GPL-3.0 + ses lisansları | Var, 3 ses | 22,05 kHz | %3,2 | ONNX; lisans riski |
| MMS-TTS | CC-BY-NC-4.0 | Var | 16 kHz | %6,1 | Ticari değil |
| XTTS-v2 | CPML (ticari değil) | Var | 24 kHz | %11,1 | Ticari değil |
| Qwen3-TTS 0.6B | Apache-2.0 (doğrulanmalı) | Var | 24 kHz | %1,7 | Büyük; web zor |
| Kokoro | Apache-2.0 | Yok | 24 kHz | — | Türkçe yok |

**Değerlendirme:**

- Pocket TTS, WER ve boyut dengesiyle açık ara en iyi seçenek. DSP ile
  iyileştirmek, model değiştirmekten daha düşük riskli.
- FreyaTTS-small, 48 kHz çıkışı ve Apache-2.0 lisansıyla ilginç bir
  “yüksek kalite” alternatifi; ancak WER %8 ve ONNX/web entegrasyonu
  ciddi iş. Ayrı bir Ar-Ge projesi olarak değerlendirilmeli.
- Piper, lisans ve ses modeli belirsizlikleri nedeniyle önerilmez.

---

## 13. Uygulama ve doğrulama planı

### Faz 1 — Ölçülebilir, düşük risk (1–2 gün)

1. `AudioPostProcessor`’a LUFS ölçümü + limiter ekle.
2. Ses bazlı EQ profillerini `VoiceProfile`/yeni `VoiceEqProfile` ile
   tanımla; varsayılan global EQ’nun üzerine uygula.
3. `female_1` için de-esser ekle.
4. Cümle bazlı sentez + duraklama tablosunu uygula.
5. Testler: LUFS hedefi ±0,5, tepe ≤ −1,5 dBTP, sesler arası fark
   ≤1 LU, duraklama süreleri, kırpılma yok.

### Faz 2 — Metin ve format (1 gün)

6. Resmî normalizör kurallarını port et; telefon/tekrar testleri ekle.
7. 48 kHz oynatma + MP3 48 kHz; TPDF dither.
8. Kompresörü kapatma/yumuşatma A/B’si.

### Faz 3 — Dinleme ve ince ayar (1–2 gün)

9. 10–20 cümlelik Türkçe test seti; 6 ses; 3 tohum.
10. Kör dinleme (5–10 kişi): doğallık, netlik, tercih.
11. EQ/de-esser değerlerini ±1–2 dB ayarla; gerekirse geri al.

### Faz 4 — İleri (opsiyonel)

12. Referans low shelf −2 dB A/B.
13. `num_steps`/`temperature`/`seed` denemeleri.
14. FP32 masaüstü modu.
15. FreyaTTS-small ONNX araştırması (ayrı proje).

### Doğrulama komutları

```bash
# LUFS ve tepe
ffmpeg -hide_banner -nostats -i ses.wav \
  -filter_complex ebur128=peak=true -f null -

# Spektral bantlar (Python)
python3 tools/spectrum.py ses.wav

# Testler
flutter analyze
flutter test
```

---

## 14. Kaynaklar

- Pocket TTS Türkçe model kartı:  
  https://huggingface.co/wite-tech/pocket-tts-turkish
- Resmî `pocket-tts-turkish` paketi (normalizör, referans kesme, cümle
  bazlı sentez):  
  https://github.com/witetech/pocket-tts-turkish
- sherpa-onnx Pocket TTS:  
  https://github.com/k2-fsa/sherpa-onnx
- EBU R128 / ITU-R BS.1770 loudness:  
  https://tech.ebu.ch/publications/r128
- FreyaTTS-small (Apache-2.0, 48 kHz):  
  https://huggingface.co/freyavoice/Freya-TTS
- Piper ses listesi ve lisans notları:  
  https://github.com/rhasspy/piper/blob/master/VOICES.md

---

## Ek A — Ölçüm tabloları

### A.1 Ham model çıktısı (female_1, 8 adım, 0,5 sıcaklık)

| Bant | Oran |
|---|---:|
| 0–300 Hz | %42,3 |
| 300–1.000 Hz | %34,7 |
| 1–3 kHz | %19,2 |
| 3–6 kHz | %0,3 |
| 6–12 kHz | %0,1 |
| LUFS | −19,4 |
| Gerçek tepe | −2,6 dBTP |

### A.2 EQ sonrası sesler

| Ses | 0–300 | 300–1k | 1–3k | 3–6k | 6–12k | LUFS |
|---|---:|---:|---:|---:|---:|---:|
| Elif | %22,4 | %21,4 | %43,5 | %12,0 | %0,7 | −19,6 |
| Zeynep | %34,5 | %37,1 | %25,3 | %2,6 | %0,6 | −21,3 |
| Defne | %38,5 | %34,9 | %23,4 | %3,1 | %0,2 | −22,2 |
| Emre | %45,4 | %31,3 | %16,6 | %2,3 | %4,4 | −21,3 |
| Kerem | %55,4 | %29,1 | %14,5 | %0,6 | %0,4 | −18,9 |
| Mert | %42,0 | %37,5 | %16,4 | %0,9 | %3,2 | −17,8 |

### A.3 Adım sayısı (EQ sonrası)

| Adım | 0–300 | 1–3k | 3–6k | Süre |
|---:|---:|---:|---:|---:|
| 4 | %25,5 | %46,1 | %7,5 | 5,06 s |
| 8 | %27,1 | %42,5 | %10,2 | 5,05 s |
| 16 | %38,2 | %35,9 | %7,7 | 4,98 s |
| 32 | %32,0 | %37,4 | %8,4 | 4,98 s |

### A.4 Duraklama ölçümleri

| Durum | Cümle arası | Soru arası |
|---|---:|---:|
| Tek istek (model doğal) | 580 ms | 600 ms |
| Cümle bazlı + 150 ms | 760 ms | 650 ms |
| Uygulama (kenar kırp + 380 ms) | 380 ms | 450 ms |

> Uygulama değeri, parçanın cümle sınırında bölünmesi durumunda geçerlidir;
> çok cümleli parçalarda modelin 580 ms’i korunur.

### A.5 Referans işleme (EQ sonrası)

| Referans | 0–300 | 1–3k | 3–6k |
|---|---:|---:|---:|
| Orijinal | %27,1 | %42,5 | %10,2 |
| Low shelf −3 dB | %20,9 | %47,2 | %9,1 |
| Low −2, presence +2, high +1 | %21,4 | %51,4 | %12,4 |
| Low −2, presence +3, high +2 | %14,3 | %55,3 | %15,4 |
| Low −3, presence +4, high +3 | %14,4 | %53,5 | %18,6 |
| Parlak İngilizce referans | %79,1 | %0,8 | %0,3 |

---

## 7. 1.1.0 doğallık turu (25 Kasım 2026)

Bu bölüm, önceki ölçümlerden sonra yapılan düzeltmeleri ve güncel model
karşılaştırmasını kaydeder.

### 7.1 Yeniden örnekleyici hatası

24 kHz → 48 kHz dönüşümünde kesim frekansı Nyquist'in %47'sindeydi
(5,6 kHz). Ölçülen zayıflama: 6 kHz −14 dB, 8 kHz −38 dB, 10 kHz −73 dB.
Bu, “boğuk/tizsiz” algısının ana nedeniydi. Yeni ayar: kesim %94, 32 tap,
Kaiser β 8,6. 6–10 kHz −1 dB içinde; görüntüler −40 dB altında. Regresyon
testleri `test/features/tts/infrastructure/audio_resampler_test.dart`
içinde.

### 7.2 Yeni DSP profili

`DspProfile.natural`:

| Aşama | Ayar |
| --- | --- |
| High-pass | 60 Hz |
| Low shelf | 220 Hz, −1,5 dB |
| Gövde | 550 Hz, +0,8 dB, Q 0,9 |
| Varlık | 2,8 kHz, +0,8 dB, Q 0,9 |
| Hava | kapalı |
| De-esser | 0,6 ölçek |
| Kompresör | kapalı |
| Hedef | −18 LUFS / −1,5 dBTP |

Eski profil (250 Hz −4 dB, 3,4 kHz +5 dB, 6,5 kHz +3,5 dB, kompresör,
−20 LUFS) sertlik ve boğukluk üretiyordu; A/B için `DspProfile.legacy`
olarak korundu.

### 7.3 SQUIM_OBJECTIVE PESQ

| Ses | Legacy | Natural |
| --- | ---: | ---: |
| Elif | 3,416 | **3,609** |
| Zeynep | 3,100 | **3,238** |
| Defne | 3,083 | **3,226** |
| Emre | 2,010 | **2,437** |
| Kerem | 2,307 | **2,353** |
| Mert | 2,190 | **2,422** |

### 7.4 Alternatif modeller (UTMOS22)

| Model | Lisans | Boyut | Ses | UTMOS |
| --- | --- | ---: | ---: | --- |
| Pocket TTS | CC-BY-4.0 | 157 MB | 6 | 2,82–3,90 |
| Canora int8 | Apache-2.0 | 115 MB | 2 | 3,50–3,57 |
| Canora fp16 | Apache-2.0 | 163 MB | 2 | 3,80–3,90 |
| Canora fp32 | Apache-2.0 | 325 MB | 2 | 4,04–4,24 (beyan) |
| Clarvia tiny | Apache-2.0 | 20 MB | 10 | 2,90–3,01 |
| Piper dfki | CC-BY-4.0 | 63 MB | 1 | 3,71 |

Web için makul boyutta kalan izin verici modeller arasında Pocket TTS'in
en iyi kadın sesi hâlâ en yüksek doğallıkta. Canora fp16 aynı seviyeye
ulaşıyor ama 2 sesli ve fp16'nın web CPU/WASM desteği güvenilir değil.

### 7.5 Referans kalitesi

Pocket TTS ses klonlama kullandığı için çıktı, referans kaydın kalitesini
izliyor:

| Referans | Referans UTMOS | Pocket çıktısı UTMOS |
| --- | ---: | ---: |
| female_1 (mevcut) | 4,32 | 3,90 |
| Canora elif | 4,14 | 3,70 |
| Canora emre | 3,81 | 3,62 |
| Clarvia male_2 | 3,46 | 2,98 |
| male_1 (mevcut) | 1,84 | 2,93 |

Erkek seslerindeki düşük doğallık, büyük ölçüde referans kayıtlarının
kalitesinden kaynaklanıyor. Canora `emre` referansı Emre'yi 2,93 → 3,62'ye
çıkarıyor. Ancak bu, Canora'nın tasarlanmış tek erkek tınısını kullanır;
üç ayrı erkek sesi için yeterli değildir. Model değiştirmeden uygulanacak
en ucuz iyileştirme budur; yine de ses kimliği ve lisans atfı açısından
ayrıca değerlendirilmelidir.

---

## 8. 1.2.0 referans ses turu (25 Kasım 2026)

Pocket TTS ses klonlama kullandığı için çıktı, referans kaydın kalitesini
izler. 1.1.0'daki ölçümlerde erkek referanslarının UTMOS'u 1,84–2,54
arasındaydı; bu, erkek çıktılarının 2,82–3,18 bandında kalmasının ana
nedeniydi.

### 8.1 Aday referanslar

Aynı metin, ham 24 kHz model çıktısı ve üç tohum (42, 43, 44) ile her
aday referansın Pocket çıktısı ölçüldü. UTMOS22 ortalamaları:

| Referans | Cinsiyet | UTMOS |
| --- | --- | ---: |
| Canora `elif` | kadın | **3,80** |
| Mevcut `female_1` | kadın | 3,75 |
| Piper `dfki` | kadın | 3,68 |
| Clarvia `female_4` | kadın | 3,68 |
| Clarvia `female_5` | kadın | 3,55 |
| Mevcut `female_3` | kadın | 3,52 |
| Canora `emre` | erkek | **3,52** |
| Clarvia `m1` | erkek | 3,14 |
| Clarvia `male_3` | erkek | 3,10 |
| Clarvia `male_5` | erkek | 3,05 |
| Mevcut `male_3` | erkek | 3,03 |
| Mevcut `male_2` | erkek | 3,01 |
| Mevcut `male_1` | erkek | 2,92 |

Erkeklerde Canora `emre` tek başına belirgin bir sıçrama sağlıyor; diğer
adaylar mevcut Kerem/Mert ile aynı bantta. Bu nedenle yalnızca Emre
değiştirildi, Kerem ve Mert'in kullanıcı tarafından bilinen tınıları
korundu.

### 8.2 Seçilen set

| Ses | Referans | Önce | Sonra |
| --- | --- | ---: | ---: |
| Elif | mevcut `female_1` | 3,75 | 3,75 |
| Zeynep | Canora `elif` | 3,36 | **3,78** |
| Defne | Clarvia `female_4` | 3,52 | **3,73** |
| Emre | Canora `emre` | 2,92 | **3,61** |
| Kerem | mevcut `male_2` | 3,01 | 3,01 |
| Mert | mevcut `male_3` | 3,03 | 3,03 |

Altı sesin ortalaması 3,27 → 3,49. Referanslar 3,7–4,7 s, 24 kHz,
sessizliği kırpılmış ve tepe noktası 0,9'a hizalanmış WAV dosyalarıdır.
Yeni referanslarda ek ses bazlı EQ uygulanmaz.

### 8.3 Lisans

Canora Turkish (`empiriolabsai/canora-turkish`) ve Clarvia TTS tiny
(`wite-tech/clarvia-tts-tiny`) Apache-2.0 lisanslıdır. Uygulamaya yalnızca
bu modellerle üretilmiş kısa referans WAV dosyaları girer; model ağırlıkları
dağıtılmaz. Atıflar `LICENSES.md` ve `THIRD_PARTY_NOTICES.md` içindedir.
