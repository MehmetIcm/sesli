# Üçüncü Taraf Bildirimleri

Bu dosya, Sesli uygulamasında kullanılan üçüncü taraf bileşenlerin atıf ve
lisans bildirimlerini içerir. Tam lisans metinleri ilgili paketlerin
`LICENSE` dosyalarında ve kaynak depolarında bulunur.

---

## Pocket TTS Türkçe

- **Eser:** Pocket TTS Türkçe model ağırlıkları
- **Kaynak:** https://huggingface.co/wite-tech/pocket-tts-turkish
- **Lisans:** Creative Commons Attribution 4.0 International (CC-BY-4.0)
- **Lisans metni:** https://creativecommons.org/licenses/by/4.0/legalcode

**Değişiklikler:** Model ağırlıkları, `lomotron/pocket-tts-onnx-export`
aracıyla ONNX biçimine aktarılmıştır. Dil modeli ve flow bileşeni INT8
nicemlenirken sesin en çok duyulan bileşeni olan Mimi kod çözücüsü tam
duyarlıkta (fp32) tutulmuştur. Ses kalitesini ve çıkarım biçimini etkileyen
bu dönüştürme dışında model ağırlıkları değiştirilmemiştir. Elif, Kerem ve
Mert konuşmacılarına ait referans kayıtları modelle birlikte gelir. Zeynep,
Defne ve Emre referansları ise aşağıda belirtilen Apache-2.0 lisanslı sentetik
Türkçe ses modelleriyle üretilmiştir.

**Atıf:** Bu uygulama, Pocket TTS Türkçe modelini kullanır. Model,
`wite-tech/pocket-tts-turkish` kaynağından CC-BY-4.0 lisansı altında
alınmıştır.

> This work uses the Pocket TTS Turkish model from
> `wite-tech/pocket-tts-turkish`, licensed under CC-BY-4.0. The model was
> converted to ONNX; the language model is INT8 and the Mimi decoder is
> fp32. See the license for the full terms.

---

## Canora Turkish (referans ses)

- **Eser:** Canora Turkish — `elif` ve `emre` sesleri
- **Kaynak:** https://huggingface.co/empiriolabsai/canora-turkish
- **Lisans:** Apache License 2.0
- **Kullanım:** Zeynep ve Emre seslerinin 24 kHz referans kayıtları bu
  modelle üretilmiştir. Model ağırlıkları uygulamaya dahil edilmez;
  yalnızca üretilen kısa referans WAV dosyaları paketlenir.

Canora Turkish, EmpirioLabs AI tarafından geliştirilmiştir. Sesler
tasarlanmış sentetik seslerdir; gerçek bir kişinin kaydı veya taklidi
değildir. Apache-2.0 lisans metni `licenses/Apache-2.0.txt` dosyasındadır.

> Reference voice clips for Zeynep and Emre were generated with Canora
> Turkish (`empiriolabsai/canora-turkish`), licensed under the Apache
> License 2.0. No model weights are distributed with this application.

---

## Clarvia TTS tiny (referans ses)

- **Eser:** Clarvia TTS tiny — `female_4` sesi
- **Kaynak:** https://huggingface.co/wite-tech/clarvia-tts-tiny
- **Lisans:** Apache License 2.0
- **Kullanım:** Defne sesinin 24 kHz referans kaydı bu modelle üretilmiştir.
  Model ağırlıkları uygulamaya dahil edilmez; yalnızca üretilen kısa
  referans WAV dosyası paketlenir.

Clarvia TTS tiny, `n4ze3m/tiny-voca` mimarisi üzerine kurulmuş Türkçe bir
sentetik ses modelidir. Apache-2.0 lisans metni `licenses/Apache-2.0.txt`
dosyasındadır.

> The reference voice clip for Defne was generated with Clarvia TTS tiny
> (`wite-tech/clarvia-tts-tiny`), licensed under the Apache License 2.0.
> No model weights are distributed with this application.

---

## Pocket TTS ONNX dışa aktarıcı

- **Eser:** `lomotron/pocket-tts-onnx-export`
- **Lisans:** MIT
- **Kaynak:** https://github.com/lomotron/pocket-tts-onnx-export

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## pocket-tts-turkish metin normalizörü

- **Eser:** `wite-tech/pocket-tts-turkish` deposundaki Türkçe metin
  normalizasyon kuralları
- **Lisans:** Apache License 2.0
- **Kaynak:** https://huggingface.co/wite-tech/pocket-tts-turkish
- **Kullanım:** Telefon numarası gruplama, kesir, sayı aralığı, Romen
  rakamı ve matematik sembolü kuralları Dart'a uyarlanmıştır. Uyarlama
  `lib/features/tts/domain/turkish_text_normalizer.dart` içindedir.

Apache-2.0 lisans metni bu dosyanın "Apache License 2.0" bölümünde yer alır.

> Portions of the Turkish text normalization rules are adapted from
> `wite-tech/pocket-tts-turkish`, licensed under the Apache License 2.0.

---

## CMU Pronouncing Dictionary (CMUdict)

- **Eser:** CMU Pronouncing Dictionary
- **Sürüm:** 0.7b
- **Lisans:** BSD-2-Clause
- **Kaynak:** https://github.com/cmusphinx/cmudict
- **Kullanım:** `assets/data/english_lexicon.json` dosyası, CMUdict
  girdilerinden İngilizce kelimelerin Türkçe sesletimini üretmek için
  türetilmiştir.

Copyright (C) 1993–2008 Carnegie Mellon University. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY CARNEGIE MELLON UNIVERSITY "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---

## FrequencyWords Türkçe listesi

- **Eser:** FrequencyWords — Türkçe (`tr_full.txt`)
- **Lisans:** MIT
- **Kaynak:** https://github.com/hermitdave/FrequencyWords
- **Kullanım:** `assets/data/turkish_words.txt`, İngilizce sesletim
  katmanının Türkçe kelimeleri yanlışlıkla dönüştürmesini önleyen koruma
  listesi olarak türetilmiştir.

MIT License

Copyright (c) 2016 Hermit Dave

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## sherpa-onnx

- **Eser:** sherpa-onnx
- **Sürüm:** 2.0.1
- **Lisans:** Apache License 2.0
- **Kaynak:** https://github.com/k2-fsa/sherpa-onnx

Copyright 2022–2025 k2-fsa ve sherpa-onnx katkıda bulunanları.

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License. You may obtain a copy of
the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations under
the License.

---

## ONNX Runtime

- **Eser:** ONNX Runtime
- **Lisans:** MIT
- **Kaynak:** https://github.com/microsoft/onnxruntime

Copyright (c) Microsoft Corporation. All rights reserved.

MIT License — see the upstream `LICENSE` file for the full text. Permission is
hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files, to deal in the Software without
restriction, subject to inclusion of the copyright and permission notices.
The software is provided "AS IS", without warranty of any kind.

---

## Flutter ve Dart

- **Eser:** Flutter, Dart
- **Lisans:** BSD-3-Clause
- **Kaynak:** https://github.com/flutter/flutter

Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.

---

## shine_dart / Shine

- **Eser:** shine_dart (Shine MP3 kodlayıcısının Dart portu)
- **Sürüm:** 0.1.1
- **Lisans:** GNU Lesser General Public License 2.0 (LGPL-2.0)
- **Kaynak:** https://pub.dev/packages/shine_dart

Bu kütüphane uygulamada değiştirilmeden kullanılır. LGPL-2.0 kapsamında
kaynak kodu erişilebilir tutulur ve kullanıcı kütüphaneyi değiştirilmiş bir
sürümle değiştirebilir. Tam lisans metni paketin `LICENSE` dosyasındadır.

---

## Manrope yazı tipi

- **Eser:** Manrope
- **Lisans:** SIL Open Font License 1.1 (OFL-1.1)
- **Kaynak:** https://github.com/sharanda/manrope

Copyright 2018 The Manrope Project Authors.

This Font Software is licensed under the SIL Open Font License, Version 1.1.
The font is used unmodified as the application's UI typeface. The full
license text is available at https://scripts.sil.org/OFL.

---

## Material Icons ve Roboto

- **Lisans:** Apache License 2.0
- **Kaynak:** Flutter framework

Material Design ikonları ve Roboto yazı tipi, Apache-2.0 lisansı altında
Flutter ile birlikte gelir.

---

## Diğer Flutter paketleri

| Paket | Lisans |
| --- | --- |
| audioplayers | MIT |
| provider | MIT |
| cupertino_icons | MIT |
| shared_preferences | BSD-3-Clause |
| path_provider | BSD-3-Clause |
| file_selector | BSD-3-Clause |
| web | BSD-3-Clause |
| path | BSD-3-Clause |

Bu paketlerin tam lisans metinleri, `~/.pub-cache/hosted/pub.dev/` altındaki
ilgili paket klasörlerinde bulunur.

---

## CanvasKit / Skia ve Emscripten

- **CanvasKit / Skia:** BSD-3-Clause — https://skia.org
- **Emscripten:** MIT / University of Illinois Open Source License —
  https://emscripten.org

Bu bileşenler Flutter web ve sherpa-onnx WASM derlemesiyle birlikte gelir.

---

## Uygulama simgesi ve marka

Sesli adı, logosu ve marka işareti bu proje için üretilmiştir. Uygulama
simgesi `assets/images/app_icon.png` dosyasından üretilir.
