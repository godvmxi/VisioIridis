import 'dart:typed_data';

/// 把 16bit 小端 PCM 字节流转换为 [-1, 1) 的浮点采样。
/// 录音回调的数据块可能在采样中间截断，多出的单个字节留到下一块。
class Pcm16Decoder {
  int? _carry;

  Float32List convert(Uint8List bytes) {
    final carry = _carry;
    final input = carry == null ? bytes : (Uint8List(bytes.length + 1)
      ..[0] = carry
      ..setRange(1, bytes.length + 1, bytes));
    final count = input.length ~/ 2;
    _carry = input.length.isOdd ? input.last : null;

    final data = ByteData.sublistView(input);
    final out = Float32List(count);
    for (var i = 0; i < count; i++) {
      out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  void reset() => _carry = null;
}

/// 按固定长度切分连续采样，用于向 VAD 逐窗口送数据。
class SampleWindower {
  SampleWindower(this.windowSize);

  final int windowSize;
  Float32List _pending = Float32List(0);

  List<Float32List> add(Float32List samples) {
    final all = Float32List(_pending.length + samples.length)
      ..setAll(0, _pending)
      ..setAll(_pending.length, samples);
    final windows = <Float32List>[];
    var offset = 0;
    while (all.length - offset >= windowSize) {
      windows.add(Float32List.sublistView(all, offset, offset + windowSize));
      offset += windowSize;
    }
    _pending = Float32List.fromList(Float32List.sublistView(all, offset));
    return windows;
  }

  void reset() => _pending = Float32List(0);
}

Float32List concatSamples(Iterable<Float32List> parts) {
  final total = parts.fold(0, (sum, p) => sum + p.length);
  final out = Float32List(total);
  var offset = 0;
  for (final p in parts) {
    out.setAll(offset, p);
    offset += p.length;
  }
  return out;
}

/// PRD 4.1：只勾选两种语言时，若识别出的语种不在勾选范围内，
/// 返回用于强制重解码的主语种（普通话 > 粤语 > 英语）；否则返回 null。
String? fallbackLanguage(String? detected, Set<String> allowed) {
  if (allowed.length != 2 || detected == null || allowed.contains(detected)) {
    return null;
  }
  const priority = ['zh', 'yue', 'en'];
  for (final lang in priority) {
    if (allowed.contains(lang)) return lang;
  }
  return null;
}
