import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:visioiridis/asr/audio_utils.dart';

import 'fake_asr_engine.dart';

Uint8List pcm(List<int> samples) {
  final data = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  group('Pcm16Decoder', () {
    test('converts little-endian int16 to floats', () {
      final out = Pcm16Decoder().convert(pcm([0, 16384, -32768, 32767]));
      expect(out, [0.0, 0.5, -1.0, closeTo(1.0, 1e-4)]);
    });

    test('carries a split sample over to the next chunk', () {
      final bytes = pcm([1000, -2000, 3000]);
      final decoder = Pcm16Decoder();
      final first = decoder.convert(Uint8List.sublistView(bytes, 0, 3));
      final second = decoder.convert(Uint8List.sublistView(bytes, 3));
      expect(
        [...first, ...second],
        [1000 / 32768, -2000 / 32768, 3000 / 32768],
      );
    });
  });

  group('SampleWindower', () {
    test('emits fixed windows and keeps the remainder', () {
      final windower = SampleWindower(4);
      expect(windower.add(Float32List.fromList([1, 2, 3])), isEmpty);
      final windows = windower.add(Float32List.fromList([4, 5, 6, 7, 8, 9]));
      expect(windows.map((w) => w.toList()), [
        [1, 2, 3, 4],
        [5, 6, 7, 8],
      ]);
      expect(windower.add(Float32List.fromList([10, 11, 12])).single.toList(), [
        9,
        10,
        11,
        12,
      ]);
    });
  });

  test('concatSamples joins in order', () {
    expect(
      concatSamples([
        Float32List.fromList([1, 2]),
        Float32List.fromList([3]),
      ]).toList(),
      [1, 2, 3],
    );
  });

  group('fallbackLanguage (PRD 4.1)', () {
    test('only applies with exactly two languages selected', () {
      expect(fallbackLanguage('yue', {'zh', 'yue', 'en'}), isNull);
      expect(fallbackLanguage('yue', {'en'}), isNull);
    });

    test('keeps a detected language that is selected', () {
      expect(fallbackLanguage('en', {'zh', 'en'}), isNull);
    });

    test('forces the primary selected language otherwise', () {
      expect(fallbackLanguage('yue', {'zh', 'en'}), 'zh');
      expect(fallbackLanguage('zh', {'yue', 'en'}), 'yue');
      expect(fallbackLanguage(null, {'zh', 'en'}), isNull);
    });
  });

  test('PreparedModel resolves model and tokens paths', () {
    expect(testPreparedModel.modelPath, '/models/sense-voice/model.int8.onnx');
    expect(testPreparedModel.tokensPath, '/models/sense-voice/tokens.txt');
  });
}
