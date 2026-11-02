import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/asr/asr_language.dart';
import 'package:seevoice/asr/tag_formatter.dart';
import 'package:seevoice/l10n/l10n.dart';

void main() {
  group('TagFormatter', () {
    test('normalize strips <| |> and returns null for empty', () {
      expect(TagFormatter.normalize('<|zh|>'), 'zh');
      expect(TagFormatter.normalize('<|Laughter|>'), 'Laughter');
      expect(TagFormatter.normalize(''), isNull);
      expect(TagFormatter.normalize('<||>'), isNull);
    });

    test('eventLabel maps known events case-insensitively', () {
      final zh = lookupAppLocalizations(const Locale('zh')).eventName;
      expect(TagFormatter.eventLabel('Laughter', zh), '😄 [笑声]');
      expect(TagFormatter.eventLabel('APPLAUSE', zh), '👏 [掌声]');
      expect(TagFormatter.eventLabel('cry', zh), '😢 [哭泣声]');
      expect(TagFormatter.eventLabel('Speech', zh), isNull);
      expect(TagFormatter.eventLabel('BGM', zh), isNull);
      expect(TagFormatter.eventLabel(null, zh), isNull);
    });

    test('eventLabel follows the interface language', () {
      final en = lookupAppLocalizations(const Locale('en')).eventName;
      final hant = lookupAppLocalizations(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ).eventName;
      expect(TagFormatter.eventLabel('Laughter', en), '😄 [laughter]');
      expect(TagFormatter.eventLabel('Applause', hant), '👏 [掌聲]');
    });

    test('cleanText removes every tag', () {
      expect(TagFormatter.cleanText('<|zh|><|NEUTRAL|><|Speech|>你好'), '你好');
    });
  });

  group('AsrLanguage.languageParamFor', () {
    test('single language forces that code', () {
      expect(AsrLanguage.languageParamFor({AsrLanguage.english}), 'en');
      expect(AsrLanguage.languageParamFor({AsrLanguage.cantonese}), 'yue');
    });

    test('two or three languages use auto', () {
      expect(
        AsrLanguage.languageParamFor({
          AsrLanguage.mandarin,
          AsrLanguage.english,
        }),
        'auto',
      );
      expect(AsrLanguage.languageParamFor(AsrLanguage.values.toSet()), 'auto');
    });
  });
}
