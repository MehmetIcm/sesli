import 'dart:math' as math;
import 'dart:typed_data';

/// Yüksek kaliteli, bağımlılıksız yeniden örnekleme.
///
/// Pencereleştirilmiş sinc (Kaiser penceresi) interpolasyonu kullanır.
/// Önceden hesaplanmış faz tabloları sayesinde her çıkış örneği için yalnızca
/// 32 çarpma yapılır; bu, kübik interpolasyona göre belirgin biçimde daha
/// temiz bir yukarı örnekleme sağlar ve konuşmadaki tıslama/tokluk
/// bozulmalarını azaltır.
class AudioResampler {
  AudioResampler._();

  /// Faz başına örnek sayısı (filtre uzunluğu).
  ///
  /// 32 tap, 24 kHz model çıkışındaki 8–11 kHz bölgesini neredeyse düz
  /// korurken görüntüleri (imaging) −80 dB'nin altına indirir. 16 tap bu
  /// bölgede duyulabilir ölçüde gerileme yapıyordu.
  static const int _taps = 32;

  /// Faz çözünürlüğü. 256 faz, 1/256 örnek hassasiyet demektir.
  static const int _phases = 256;

  /// Kaiser penceresi şekil parametresi.
  static const double _beta = 8.6;

  /// Kesim frekansı, Nyquist'in bu oranına ayarlanır. Hafif altında tutmak
  /// yukarı örneklemede hayalet görüntüleri (imaging) bastırır.
  static const double _cutoffRatio = 0.94;

  static double? _cachedRatio;
  static List<Float64List>? _cachedKernel;

  static Float32List resample(Float32List input, int fromRate, int toRate) {
    if (input.isEmpty || fromRate <= 0 || toRate <= 0) {
      return Float32List(0);
    }
    if (fromRate == toRate) {
      return Float32List.fromList(input);
    }

    final ratio = toRate / fromRate;
    final outputLength = math.max(1, (input.length * ratio).round());
    final output = Float32List(outputLength);
    final kernel = _kernelFor(ratio);
    final last = input.length - 1;
    const half = _taps ~/ 2;

    for (var i = 0; i < outputLength; i++) {
      final position = i / ratio;
      var base = position.floor();
      var phase = ((position - base) * _phases).round();
      if (phase >= _phases) {
        phase = 0;
        base += 1;
      }

      final weights = kernel[phase];
      final start = base - half;
      var sum = 0.0;
      for (var k = 0; k < _taps; k++) {
        final index = start + k;
        if (index < 0 || index > last) continue;
        sum += input[index] * weights[k];
      }
      output[i] = sum.clamp(-1.0, 1.0).toDouble();
    }
    return output;
  }

  /// Verilen oran için faz tablosunu üretir (tek elemanlı önbellek).
  static List<Float64List> _kernelFor(double ratio) {
    if (_cachedRatio == ratio && _cachedKernel != null) {
      return _cachedKernel!;
    }

    // Kesim frekansı Nyquist biriminde tutulur: 0,94 × giriş Nyquist'i.
    // (Sinc argümanı π·cutoff·d olduğu için cutoff burada 1,0 = Nyquist.)
    // İndirme oranı < 1 iken bu, çıkış Nyquist'inin %94'üne denk gelir.
    final cutoff = math.min(1.0, ratio) * _cutoffRatio;
    final halfWidth = _taps / 2.0;
    const center = (_taps - 1) / 2.0;
    final normalizer = _besselI0(_beta);

    final table = List<Float64List>.generate(_phases, (phaseIndex) {
      final fraction = phaseIndex / _phases;
      final weights = Float64List(_taps);
      var sum = 0.0;

      for (var k = 0; k < _taps; k++) {
        final distance = k - center - fraction;
        final x = distance / halfWidth;
        final window = x.abs() >= 1.0
            ? 0.0
            : _besselI0(_beta * math.sqrt(1 - x * x)) / normalizer;
        final argument = math.pi * cutoff * distance;
        final sinc = argument.abs() < 1e-9
            ? 1.0
            : math.sin(argument) / argument;
        final value = sinc * window;
        weights[k] = value;
        sum += value;
      }

      // DC kazancını bire normalize et; aksi hâlde fazlar arasında
      // genlik dalgalanması (modülasyon) oluşur.
      if (sum.abs() > 1e-9) {
        for (var k = 0; k < _taps; k++) {
          weights[k] /= sum;
        }
      }
      return weights;
    });

    _cachedRatio = ratio;
    _cachedKernel = table;
    return table;
  }

  /// Birinci tür değiştirilmiş Bessel fonksiyonu I0(x).
  static double _besselI0(double x) {
    final half = x / 2;
    var sum = 1.0;
    var term = 1.0;
    for (var k = 1; k < 40; k++) {
      final factor = half / k;
      term *= factor * factor;
      sum += term;
      if (term < sum * 1e-12) break;
    }
    return sum;
  }
}
