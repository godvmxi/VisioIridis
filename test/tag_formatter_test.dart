import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/asr/asr_language.dart';
import 'package:seevoice/asr/tag_formatter.dart';

void main() {
  group('TagFormatter', () {
    test('normalize strips <| |> and returns null for empty', () {
      expect(TagFormatter.normalize('<|zh|>'), 'zh');
      expect(TagFormatter.normalize('<|Laughter|>'), 'Laughter');
      expect(TagFormatter.normalize(''), isNull);
      expect(TagFormatter.normalize('<||>'), isNull);
    });

    test('eventLabel maps known events case-insensitively', () {
      expect(TagFormatter.eventLabel('Laughter'), '😄 [笑声]');
      expect(TagFormatter.eventLabel('APPLAUSE'), '👏 [掌声]');
      expect(TagFormatter.eventLabel('cry'), '😢 [哭泣声]');
      expect(TagFormatter.eventLabel('Speech'), isNull);
      expect(TagFormatter.eventLabel('BGM'), isNull);
      expect(TagFormatter.eventLabel(null), isNull);
    });

    test('cleanText removes every tag', () {
      expect(
        TagFormatter.cleanText('<|zh|><|NEUTRAL|><|Speech|>你好'),
        '你好',
      );
    });
  });

  group('AsrLanguage.languageParamFor', () {
    test('single language forces that code', () {
      expect(AsrLanguage.languageParamFor({AsrLanguage.english}), 'en');
      expect(AsrLanguage.languageParamFor({AsrLanguage.cantonese}), 'yue');
    });

    test('two or three languages use auto', () {
      expect(
        AsrLanguage.languageParamFor(
            {AsrLanguage.mandarin, AsrLanguage.english}),
        'auto',
      );
      expect(AsrLanguage.languageParamFor(AsrLanguage.values.toSet()), 'auto');
    });
  });
}
