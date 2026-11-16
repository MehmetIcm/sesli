import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/voice_eq_profile.dart';

/// Sentezlenen sesi netleştiren ve parçaları doğal duraklamalarla birleştiren
/// çevrimdışı ses işleme yardımcıları.
///
/// Tüm işlemler saf Dart'tır; Web ve macOS'ta aynı sonucu üretir.
class AudioPostProcessor {
  AudioPostProcessor._();

  /// Sessiz kabul edilen genlik eşiği (yaklaşık −50 dBFS).
  static const double _silenceThreshold = 0.00316;

  /// Kenarlardan kırpılırken korunacak sessizlik (saniye).
  static const double _trimKeepSeconds = 0.02;

  /// Parçaları birleştirirken eklenecek doğal duraklama.
  static const int defaultGapMs = 240;
  static const int defaultLeadInMs = 80;
  static const int defaultTailMs = 160;

  /// Baş ve sondaki sessizliği kırpar.
  ///
  /// Model her parçanın başında/sonunda değişken uzunlukta sessizlik
  /// bırakabilir; bunları kırpıp duraklamaları biz yönetiriz. Böylece
  /// parçalar arası boşluklar tutarlı olur.
  static Float32List trimSilence(
    Float32List samples, {
    required int sampleRate,
    double threshold = _silenceThreshold,
    double keepSeconds = _trimKeepSeconds,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return samples;

    var start = 0;
    while (start < samples.length && samples[start].abs() < threshold) {
      start++;
    }
    if (start == samples.length) return Float32List(0);

    var end = samples.length - 1;
    while (end > start && samples[end].abs() < threshold) {
      end--;
    }

    final keep = (sampleRate * keepSeconds).round();
    start = math.max(0, start - keep);
    end = math.min(samples.length - 1, end + keep);

    return Float32List.fromList(
      Float32List.sublistView(samples, start, end + 1),
    );
  }

  /// Parçaları sessizlikleri kırpıp doğal duraklamalarla birleştirir.
  ///
  /// [gapsMs] verilirse her parçadan sonra o kadar duraklama eklenir; böylece
  /// cümle sonu, virgül ve iki nokta gibi noktalama işaretleri farklı
  /// uzunluklarda nefes payı alır. Verilmezse [gapMs] kullanılır.
  /// [leadInMs] kaydın başındaki nefes payı, [tailMs] ise sonun doğal
  /// kapanışı içindir.
  static Float32List joinWithPauses(
    List<Float32List> parts, {
    required int sampleRate,
    List<int>? gapsMs,
    int gapMs = defaultGapMs,
    int leadInMs = defaultLeadInMs,
    int tailMs = defaultTailMs,
  }) {
    if (parts.isEmpty || sampleRate <= 0) return Float32List(0);

    final trimmed = <Float32List>[];
    for (final part in parts) {
      final value = trimSilence(part, sampleRate: sampleRate);
      if (value.isNotEmpty) {
        trimmed.add(_fadeEdges(value, sampleRate: sampleRate));
      }
    }
    if (trimmed.isEmpty) return Float32List(0);

    final leadIn = (sampleRate * leadInMs / 1000).round();
    final tail = (sampleRate * tailMs / 1000).round();

    var total = leadIn + tail;
    for (var index = 0; index < trimmed.length; index++) {
      total += trimmed[index].length;
      if (index != trimmed.length - 1) {
        total += (sampleRate * _gapAt(gapsMs, index, gapMs) / 1000).round();
      }
    }

    final output = Float32List(total);
    var offset = leadIn;
    for (var index = 0; index < trimmed.length; index++) {
      final part = trimmed[index];
      output.setRange(offset, offset + part.length, part);
      offset += part.length;
      if (index != trimmed.length - 1) {
        offset += (sampleRate * _gapAt(gapsMs, index, gapMs) / 1000).round();
      }
    }
    return output;
  }

  static int _gapAt(List<int>? gapsMs, int index, int fallback) {
    if (gapsMs == null || index >= gapsMs.length) return fallback;
    return gapsMs[index].clamp(0, 2000).toInt();
  }

  /// Parçanın başında ve sonunda kısa bir yükselme/alçalma uygular.
  /// Birleştirme noktalarında oluşabilecek tık seslerini engeller.
  static Float32List _fadeEdges(
    Float32List samples, {
    required int sampleRate,
    int fadeMs = 6,
  }) {
    final fade = math.min(
      samples.length ~/ 2,
      (sampleRate * fadeMs / 1000).round(),
    );
    if (fade <= 0) return samples;

    final output = Float32List.fromList(samples);
    for (var i = 0; i < fade; i++) {
      final gain = i / fade;
      output[i] *= gain;
      output[output.length - 1 - i] *= gain;
    }
    return output;
  }

  /// Sesi konuşma için netleştirir.
  ///
  /// Modelin çıkışı doğal olarak bas ağırlıklı ve 3 kHz üstünde zayıftır; bu
  /// yüzden ses "boğuk" duyulur. Zincir şunları yapar:
  ///
  /// 1. 80 Hz altını (rumble, DC) temizler.
  /// 2. 250 Hz altındaki aşırı bası −4 dB azaltır (yakınlık etkisi/oda
  ///    uğultusu).
  /// 3. 500 Hz çevresindeki "çamur" bölgesini hafifçe bastırır.
  /// 4. 2 kHz ve 3,4 kHz varlık (presence) bölgelerini yükseltir; konuşma
  ///    netliği bu bantta oluşur.
  /// 5. 6,5 kHz üstünü ölçülü biçimde açar (hava).
  /// 6. Ses bazlı ek EQ ve gerekiyorsa de-esser uygular.
  /// 7. Yumuşak kompresörle seviyeyi dengeler.
  /// 8. −20 LUFS entegre yükseklik ve −1,5 dBTP gerçek tepe hedefine
  ///    normalize eder.
  ///
  /// [targetLufs] `null` verilirse eski davranış korunur ve yalnızca tepe
  /// noktası [targetPeak] değerine normalize edilir.
  static Float32List enhance(
    Float32List samples, {
    required int sampleRate,
    VoiceEqProfile voiceEq = VoiceEqProfile.neutral,
    double? targetLufs = -20,
    double truePeakDb = -1.5,
    double targetPeak = 0.91,
    bool compressor = true,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return samples;

    final output = Float32List.fromList(samples);

    // 80 Hz: rumble ve DC temizliği.
    _Biquad.highPass(
      sampleRate: sampleRate,
      frequency: 80,
      q: 0.7071,
    ).processInPlace(output);

    // 250 Hz altı: aşırı bası azalt.
    _Biquad.lowShelf(
      sampleRate: sampleRate,
      frequency: 250,
      gainDb: -4.0,
      slope: 0.8,
    ).processInPlace(output);

    // 500 Hz: mud azaltma (−1,5 dB).
    _Biquad.peaking(
      sampleRate: sampleRate,
      frequency: 500,
      gainDb: -1.5,
      q: 1.0,
    ).processInPlace(output);

    // 2 kHz: gövde/varlık (+2,5 dB).
    _Biquad.peaking(
      sampleRate: sampleRate,
      frequency: 2000,
      gainDb: 2.5,
      q: 1.0,
    ).processInPlace(output);

    // 3,4 kHz: netlik (+5 dB). Boğukluğu gideren ana bant.
    _Biquad.peaking(
      sampleRate: sampleRate,
      frequency: 3400,
      gainDb: 5.0,
      q: 0.9,
    ).processInPlace(output);

    // 6,5 kHz üstü: parlaklık (+3,5 dB).
    _Biquad.highShelf(
      sampleRate: sampleRate,
      frequency: 6500,
      gainDb: 3.5,
      slope: 0.8,
    ).processInPlace(output);

    // Ses bazlı ek düzeltmeler. Ölçümler, aynı global EQ'nun altı sesi
    // dengeli yapmadığını gösterdi; bu yüzden her sesin kendi profili var.
    if (voiceEq.lowShelfDb.abs() > 0.01) {
      _Biquad.lowShelf(
        sampleRate: sampleRate,
        frequency: 250,
        gainDb: voiceEq.lowShelfDb,
        slope: 0.8,
      ).processInPlace(output);
    }
    if (voiceEq.presenceDb.abs() > 0.01) {
      _Biquad.peaking(
        sampleRate: sampleRate,
        frequency: 3400,
        gainDb: voiceEq.presenceDb,
        q: 0.9,
      ).processInPlace(output);
    }
    if (voiceEq.airDb.abs() > 0.01) {
      _Biquad.highShelf(
        sampleRate: sampleRate,
        frequency: 6500,
        gainDb: voiceEq.airDb,
        slope: 0.8,
      ).processInPlace(output);
    }
    if (voiceEq.deEsser > 0.01) {
      _deEss(
        output,
        sampleRate: sampleRate,
        amount: voiceEq.deEsser.clamp(0.0, 1.0),
      );
    }

    // Yumuşak kompresör: heceler arasındaki seviye farkını azaltır ama
    // doğallığı ve nefesleri korumak için oran düşük tutulur.
    if (compressor) {
      _compress(output, sampleRate: sampleRate);
    }

    // Kenarlarda tık sesi olmaması için çok kısa fade.
    _fadeEdges(output, sampleRate: sampleRate, fadeMs: 8);

    if (targetLufs == null) {
      // Eski davranış: yalnızca tepe normalizasyonu.
      final peak = _peak(output);
      if (peak > 1e-6) {
        final gain = targetPeak / peak;
        for (var i = 0; i < output.length; i++) {
          output[i] = (output[i] * gain).clamp(-1.0, 1.0).toDouble();
        }
      }
      return output;
    }

    return normalizeLoudness(
      output,
      sampleRate: sampleRate,
      targetLufs: targetLufs,
      truePeakDb: truePeakDb,
    );
  }

  /// Entegre yüksekliği hedefe getirir ve gerçek tepeyi sınırlar.
  ///
  /// ITU-R BS.1770-4 benzeri K-ağırlıklı ölçüm, 400 ms bloklar ve mutlak/
  /// bağıl kapı kullanılır. Limiter, hedefin altında kalan seslerde devreye
  /// girmez; yalnızca tepe sınırını aşan örnekleri yumuşatır.
  static Float32List normalizeLoudness(
    Float32List samples, {
    required int sampleRate,
    double targetLufs = -20,
    double truePeakDb = -1.5,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return samples;

    var output = Float32List.fromList(samples);

    // İki tur, limiter sonrası oluşan küçük yükseklik kaybını da düzeltir.
    for (var iteration = 0; iteration < 2; iteration++) {
      final lufs = integratedLufs(output, sampleRate);
      if (!lufs.isFinite) return output;
      final gainDb = targetLufs - lufs;
      if (gainDb.abs() < 0.05) break;
      final gain = math.pow(10, gainDb / 20).toDouble();
      for (var i = 0; i < output.length; i++) {
        output[i] *= gain;
      }
      output = limitTruePeak(
        output,
        sampleRate: sampleRate,
        ceilingDb: truePeakDb,
      );
    }

    // Son kontrol: limiter hedefi biraz aştıysa bir kez daha hizala.
    final finalLufs = integratedLufs(output, sampleRate);
    if (finalLufs.isFinite) {
      final gainDb = targetLufs - finalLufs;
      if (gainDb.abs() > 0.1) {
        final gain = math.pow(10, gainDb / 20).toDouble();
        for (var i = 0; i < output.length; i++) {
          output[i] *= gain;
        }
        output = limitTruePeak(
          output,
          sampleRate: sampleRate,
          ceilingDb: truePeakDb,
        );
      }
    }
    return output;
  }

  /// ITU-R BS.1770-4 benzeri entegre yükseklik (LUFS).
  ///
  /// K-ağırlıklı filtre, 400 ms bloklar (%75 örtüşme), −70 LUFS mutlak kapı
  /// ve −10 LU bağıl kapı uygulanır. Çok kısa seslerde tek blok kullanılır.
  static double integratedLufs(Float32List samples, int sampleRate) {
    if (samples.isEmpty || sampleRate <= 0) {
      return double.negativeInfinity;
    }

    final weighted = Float32List.fromList(samples);
    // K-ağırlıklandırma: yüksek raf (+4 dB) ve alt kesim.
    _Biquad.highShelf(
      sampleRate: sampleRate,
      frequency: 1681.974,
      gainDb: 4.0,
      slope: 1.0,
    ).processInPlace(weighted);
    _Biquad.highPass(
      sampleRate: sampleRate,
      frequency: 38.135,
      q: 0.500327,
    ).processInPlace(weighted);

    final blockSize = math.max(1, (sampleRate * 0.4).round());
    final hop = math.max(1, (sampleRate * 0.1).round());

    if (weighted.length < blockSize) {
      return _loudnessFromMeanSquare(_meanSquare(weighted, 0, weighted.length));
    }

    final blocks = <double>[];
    for (var start = 0; start + blockSize <= weighted.length; start += hop) {
      final meanSquare = _meanSquare(weighted, start, blockSize);
      final loudness = _loudnessFromMeanSquare(meanSquare);
      if (loudness > -70.0) blocks.add(meanSquare);
    }
    if (blocks.isEmpty) return double.negativeInfinity;

    final absoluteMean = blocks.reduce((a, b) => a + b) / blocks.length;
    final relativeGate = _loudnessFromMeanSquare(absoluteMean) - 10.0;

    var sum = 0.0;
    var count = 0;
    for (final meanSquare in blocks) {
      if (_loudnessFromMeanSquare(meanSquare) > relativeGate) {
        sum += meanSquare;
        count++;
      }
    }
    if (count == 0) return double.negativeInfinity;
    return _loudnessFromMeanSquare(sum / count);
  }

  /// Gerçek tepe noktasını dBTP olarak ölçer (4× Catmull-Rom yaklaşımı).
  static double truePeakDb(Float32List samples) {
    final peak = truePeakLinear(samples);
    if (peak <= 1e-9) return double.negativeInfinity;
    return 20 * math.log(peak) / math.ln10;
  }

  /// Örnekler arası tepe noktasını 4× enterpolasyonla tahmin eder.
  static double truePeakLinear(Float32List samples) {
    if (samples.isEmpty) return 0;
    var peak = 0.0;
    final length = samples.length;

    for (var i = 0; i < length; i++) {
      final magnitude = samples[i].abs();
      if (magnitude > peak) peak = magnitude;
      if (i + 1 >= length) continue;

      final p0 = samples[i > 0 ? i - 1 : i];
      final p1 = samples[i];
      final p2 = samples[i + 1];
      final p3 = samples[i + 2 < length ? i + 2 : i + 1];
      for (var step = 1; step < 4; step++) {
        final value = _catmullRom(p0, p1, p2, p3, step / 4).abs();
        if (value > peak) peak = value;
      }
    }
    return peak;
  }

  /// Gerçek tepe sınırlayıcı (look-ahead + yavaş bırakma).
  static Float32List limitTruePeak(
    Float32List samples, {
    required int sampleRate,
    double ceilingDb = -1.5,
    double lookAheadMs = 5,
    double releaseMs = 80,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return samples;

    final ceiling = math.pow(10, ceilingDb / 20).toDouble();
    // Örnek tepe sınırını yarım dB daha aşağıda tut; enterpolasyon
    // taşmalarına karşı pay bırakır.
    final sampleCeiling = ceiling * 0.944;

    final target = Float64List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      final magnitude = samples[i].abs();
      target[i] = magnitude <= 1e-9
          ? 1.0
          : math.min(1.0, sampleCeiling / magnitude);
    }

    // [i, i + lookAhead] aralığının kayan minimumu.
    final window = math.max(1, (sampleRate * lookAheadMs / 1000).round());
    final minFuture = Float64List(samples.length);
    final deque = ListQueue<int>();
    for (var i = samples.length - 1; i >= 0; i--) {
      while (deque.isNotEmpty && target[deque.first] >= target[i]) {
        deque.removeFirst();
      }
      deque.addFirst(i);
      final limit = i + window;
      while (deque.isNotEmpty && deque.last > limit) {
        deque.removeLast();
      }
      minFuture[i] = target[deque.first];
    }

    final release = math.exp(-1 / (sampleRate * releaseMs / 1000));
    final output = Float32List(samples.length);
    var gain = 1.0;
    for (var i = 0; i < samples.length; i++) {
      final desired = minFuture[i];
      if (desired < gain) {
        gain = desired;
      } else {
        gain = desired + (gain - desired) * release;
      }
      output[i] = (samples[i] * gain).clamp(-ceiling, ceiling).toDouble();
    }

    // Enterpolasyon sonrası gerçek tepe hâlâ yüksekse tamamını ölçekle.
    final truePeak = truePeakLinear(output);
    if (truePeak > ceiling && truePeak > 1e-9) {
      final scale = ceiling / truePeak;
      for (var i = 0; i < output.length; i++) {
        output[i] *= scale;
      }
    }
    return output;
  }

  /// Yumuşak, tek bantlı kompresör.
  ///
  /// Eşik altındaki seslere dokunmaz; üstündeki tepe noktalarını [ratio]
  /// oranında bastırır. Konuşmanın doğal dinamiklerini korumak için eşik
  /// düşük, oran yumuşaktır.
  static void _compress(
    Float32List samples, {
    required int sampleRate,
    double thresholdDb = -26,
    double ratio = 1.5,
    double attackMs = 20,
    double releaseMs = 250,
  }) {
    final threshold = math.pow(10, thresholdDb / 20).toDouble();
    final attack = math.exp(-1 / (sampleRate * attackMs / 1000));
    final release = math.exp(-1 / (sampleRate * releaseMs / 1000));
    final slope = 1 / ratio - 1;

    var envelope = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final magnitude = samples[i].abs();
      final coefficient = magnitude > envelope ? attack : release;
      envelope = coefficient * envelope + (1 - coefficient) * magnitude;
      if (envelope > threshold) {
        final gain = math.pow(envelope / threshold, slope).toDouble();
        samples[i] *= gain;
      }
    }
  }

  /// Dinamik de-esser: 5,5 kHz üstündeki tıslama bandını yumuşatır.
  ///
  /// Yan zincir olarak yüksek geçiren filtre çıktısı kullanılır; zarf eşiği
  /// aştığında yalnızca bu bant azaltılır. Böylece “s” ve “ş” sesleri
  /// kaybolmadan tıslama kontrol edilir.
  static void _deEss(
    Float32List samples, {
    required int sampleRate,
    double amount = 1.0,
    double frequency = 5500,
    double thresholdDb = -28,
    double ratio = 3.5,
    double maxReductionDb = 5.0,
    double attackMs = 1.0,
    double releaseMs = 50,
  }) {
    if (samples.isEmpty || amount <= 0) return;

    final high = Float32List.fromList(samples);
    _Biquad.highPass(
      sampleRate: sampleRate,
      frequency: frequency,
      q: 0.7071,
    ).processInPlace(high);

    final threshold = math.pow(10, thresholdDb / 20).toDouble();
    final attack = math.exp(-1 / (sampleRate * attackMs / 1000));
    final release = math.exp(-1 / (sampleRate * releaseMs / 1000));
    final slope = 1 - 1 / ratio;

    var envelope = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final magnitude = high[i].abs();
      final coefficient = magnitude > envelope ? attack : release;
      envelope = coefficient * envelope + (1 - coefficient) * magnitude;

      var reductionDb = 0.0;
      if (envelope > threshold) {
        reductionDb = (20 * math.log(envelope / threshold) / math.ln10) * slope;
        reductionDb = math.min(maxReductionDb, reductionDb) * amount;
      }
      final gain = math.pow(10, -reductionDb / 20).toDouble();
      samples[i] = samples[i] - high[i] * (1 - gain);
    }
  }

  static double _peak(Float32List samples) {
    var peak = 0.0;
    for (final value in samples) {
      final magnitude = value.abs();
      if (magnitude > peak) peak = magnitude;
    }
    return peak;
  }

  static double _meanSquare(Float32List samples, int start, int length) {
    if (length <= 0) return 0;
    var sum = 0.0;
    final end = math.min(samples.length, start + length);
    for (var i = start; i < end; i++) {
      sum += samples[i] * samples[i];
    }
    return sum / length;
  }

  static double _loudnessFromMeanSquare(double meanSquare) {
    if (meanSquare <= 1e-12) return double.negativeInfinity;
    return -0.691 + 10 * math.log(meanSquare) / math.ln10;
  }

  static double _catmullRom(
    double p0,
    double p1,
    double p2,
    double p3,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;
    return 0.5 *
        ((2 * p1) +
            (-p0 + p2) * t +
            (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
            (-p0 + 3 * p1 - 3 * p2 + p3) * t3);
  }

  /// Sesi hızlandırır/yavaşlatır; perdeyi korur (WSOLA).
  static Float32List timeStretch(
    Float32List input,
    double speed, {
    int sampleRate = 24000,
  }) {
    if (input.isEmpty || sampleRate <= 0) return input;
    if ((speed - 1.0).abs() < 0.01) return Float32List.fromList(input);

    final frameSize = math.max(64, (sampleRate * 0.042).round());
    final synthesisHop = frameSize ~/ 2;
    final overlap = frameSize - synthesisHop;
    final analysisHop = (synthesisHop * speed).round().clamp(1, frameSize - 1);
    final tolerance = math.max(
      16,
      math.min(overlap ~/ 2, (sampleRate * 0.010).round()),
    );

    final window = Float64List(frameSize);
    for (var i = 0; i < frameSize; i++) {
      window[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (frameSize - 1));
    }

    final expectedLength = math.max(1, (input.length / speed).round());
    final paddedLength = expectedLength + frameSize;
    final accumulator = Float64List(paddedLength);
    final weight = Float64List(paddedLength);

    var analysisPosition = 0;
    var outputPosition = 0;
    var template = Float32List(0);

    while (analysisPosition + frameSize <= input.length) {
      var offset = 0;
      if (template.isNotEmpty) {
        offset = _bestOffset(input, analysisPosition, template, tolerance);
      }
      final start = (analysisPosition + offset).clamp(
        0,
        input.length - frameSize,
      );

      for (var i = 0; i < frameSize; i++) {
        final target = outputPosition + i;
        if (target >= paddedLength) break;
        final w = window[i];
        accumulator[target] += input[start + i] * w;
        weight[target] += w;
      }

      // Bir sonraki çerçevenin doğal devamı.
      final templateStart = start + synthesisHop;
      final templateEnd = math.min(input.length, templateStart + overlap);
      template = templateStart < templateEnd
          ? Float32List.fromList(
              Float32List.sublistView(input, templateStart, templateEnd),
            )
          : Float32List(0);

      analysisPosition += analysisHop;
      outputPosition += synthesisHop;
    }

    final output = Float32List(expectedLength);
    for (var i = 0; i < expectedLength; i++) {
      final w = weight[i];
      final value = w > 1e-3 ? accumulator[i] / w : accumulator[i];
      output[i] = value.clamp(-1.0, 1.0).toDouble();
    }
    return output;
  }

  /// Şablonla en iyi eşleşen kayma miktarını bulur.
  static int _bestOffset(
    Float32List input,
    int base,
    Float32List template,
    int tolerance,
  ) {
    const stride = 4;
    var bestOffset = 0;
    var bestScore = double.negativeInfinity;

    for (var offset = -tolerance; offset <= tolerance; offset += stride) {
      final score = _similarity(input, base + offset, template);
      if (score > bestScore) {
        bestScore = score;
        bestOffset = offset;
      }
    }

    // Kaba aramanın çevresinde ince ayar.
    final low = bestOffset - stride + 1;
    final high = bestOffset + stride - 1;
    for (var offset = low; offset <= high; offset++) {
      final score = _similarity(input, base + offset, template);
      if (score > bestScore) {
        bestScore = score;
        bestOffset = offset;
      }
    }
    return bestOffset;
  }

  /// Normalleştirilmiş çapraz ilişki (her 2 örnekte bir).
  static double _similarity(
    Float32List input,
    int start,
    Float32List template,
  ) {
    var dot = 0.0;
    var energyA = 0.0;
    var energyB = 0.0;
    for (var i = 0; i < template.length; i += 2) {
      final index = start + i;
      if (index < 0 || index >= input.length) continue;
      final a = input[index];
      final b = template[i];
      dot += a * b;
      energyA += a * a;
      energyB += b * b;
    }
    if (energyA < 1e-9 || energyB < 1e-9) return 0.0;
    return dot / math.sqrt(energyA * energyB);
  }
}

/// RBJ cookbook tabanlı ikinci dereceden (biquad) filtre.
class _Biquad {
  _Biquad._(this._b0, this._b1, this._b2, this._a1, this._a2);

  factory _Biquad.peaking({
    required int sampleRate,
    required double frequency,
    required double gainDb,
    required double q,
  }) {
    final a = math.pow(10, gainDb / 40).toDouble();
    final w0 = 2 * math.pi * frequency / sampleRate;
    final cosW0 = math.cos(w0);
    final alpha = math.sin(w0) / (2 * q);

    final b0 = 1 + alpha * a;
    final b1 = -2 * cosW0;
    final b2 = 1 - alpha * a;
    final a0 = 1 + alpha / a;
    final a1 = -2 * cosW0;
    final a2 = 1 - alpha / a;
    return _Biquad._(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  factory _Biquad.highPass({
    required int sampleRate,
    required double frequency,
    required double q,
  }) {
    final w0 = 2 * math.pi * frequency / sampleRate;
    final cosW0 = math.cos(w0);
    final alpha = math.sin(w0) / (2 * q);

    final b0 = (1 + cosW0) / 2;
    final b1 = -(1 + cosW0);
    final b2 = (1 + cosW0) / 2;
    final a0 = 1 + alpha;
    final a1 = -2 * cosW0;
    final a2 = 1 - alpha;
    return _Biquad._(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  factory _Biquad.lowShelf({
    required int sampleRate,
    required double frequency,
    required double gainDb,
    required double slope,
  }) {
    final a = math.pow(10, gainDb / 40).toDouble();
    final w0 = 2 * math.pi * frequency / sampleRate;
    final cosW0 = math.cos(w0);
    final sinW0 = math.sin(w0);
    final alpha = sinW0 / 2 * math.sqrt((a + 1 / a) * (1 / slope - 1) + 2);
    final sqrtA = math.sqrt(a);

    final b0 = a * ((a + 1) - (a - 1) * cosW0 + 2 * sqrtA * alpha);
    final b1 = 2 * a * ((a - 1) - (a + 1) * cosW0);
    final b2 = a * ((a + 1) - (a - 1) * cosW0 - 2 * sqrtA * alpha);
    final a0 = (a + 1) + (a - 1) * cosW0 + 2 * sqrtA * alpha;
    final a1 = -2 * ((a - 1) + (a + 1) * cosW0);
    final a2 = (a + 1) + (a - 1) * cosW0 - 2 * sqrtA * alpha;
    return _Biquad._(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  factory _Biquad.highShelf({
    required int sampleRate,
    required double frequency,
    required double gainDb,
    required double slope,
  }) {
    final a = math.pow(10, gainDb / 40).toDouble();
    final w0 = 2 * math.pi * frequency / sampleRate;
    final cosW0 = math.cos(w0);
    final sinW0 = math.sin(w0);
    final alpha = sinW0 / 2 * math.sqrt((a + 1 / a) * (1 / slope - 1) + 2);
    final sqrtA = math.sqrt(a);

    final b0 = a * ((a + 1) + (a - 1) * cosW0 + 2 * sqrtA * alpha);
    final b1 = -2 * a * ((a - 1) + (a + 1) * cosW0);
    final b2 = a * ((a + 1) + (a - 1) * cosW0 - 2 * sqrtA * alpha);
    final a0 = (a + 1) - (a - 1) * cosW0 + 2 * sqrtA * alpha;
    final a1 = 2 * ((a - 1) - (a + 1) * cosW0);
    final a2 = (a + 1) - (a - 1) * cosW0 - 2 * sqrtA * alpha;
    return _Biquad._(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  final double _b0;
  final double _b1;
  final double _b2;
  final double _a1;
  final double _a2;

  void processInPlace(Float32List samples) {
    var x1 = 0.0;
    var x2 = 0.0;
    var y1 = 0.0;
    var y2 = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final x0 = samples[i];
      final y0 = _b0 * x0 + _b1 * x1 + _b2 * x2 - _a1 * y1 - _a2 * y2;
      x2 = x1;
      x1 = x0;
      y2 = y1;
      y1 = y0;
      samples[i] = y0.clamp(-4.0, 4.0).toDouble();
    }
  }
}
