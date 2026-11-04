import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/model_store/config_repository.dart';
import 'package:seevoice/model_store/model_config.dart';
import 'package:seevoice/model_store/model_selector.dart';

void main() {
  final builtin = File('assets/config/model_config.json').readAsStringSync();
  final config = ModelConfig.parse(builtin);

  group('ModelConfig.parse', () {
    test('parses the builtin config', () {
      expect(config.languages.map((l) => l.id), [
        'zh',
        'yue',
        'en',
        'fr',
        'de',
        'henan',
        'chuan',
        'dongbei',
        'shandong',
        'wu',
        'minnan',
        'ja',
        'ko',
      ]);
      expect(config.vad.files.single.name, 'silero_vad.onnx');
      expect(config.asrModels.map((m) => m.id), [
        'sense-voice-small-int8',
        'telespeech-ctc-int8',
        'paraformer-yue-trilingual-int8',
        'wenetspeech-yue-wenet-ctc-int8',
        'paraformer-chuan-int8',
        'wenetspeech-wu-wenet-ctc-int8',
        'dolphin-base-ctc-int8',
        'whisper-small-int8',
      ]);
      expect(
        config.asrModels.first.relativeDir,
        'models/sense-voice-small-int8/2024-07-17',
      );
    });

    test('rejects unsupported schema version', () {
      expect(
        () => ModelConfig.parse(
          builtin.replaceFirst('"schemaVersion": 2', '"schemaVersion": 3'),
        ),
        throwsFormatException,
      );
    });

    test('rejects missing fields', () {
      expect(
        () => ModelConfig.parse('{"schemaVersion": 2}'),
        throwsFormatException,
      );
    });
  });

  group('language groups', () {
    test('groups dialects under their language', () {
      expect(config.groups.map((g) => g.id), [
        'chinese',
        'english',
        'japanese',
        'korean',
        'french',
        'german',
      ]);
      expect(config.languagesIn('chinese').map((l) => l.id), [
        'zh',
        'yue',
        'henan',
        'chuan',
        'dongbei',
        'shandong',
        'wu',
        'minnan',
      ]);
      expect(config.languagesIn('english').map((l) => l.id), ['en']);
    });

    test('the mainland config has the same groups', () {
      final cn = ModelConfig.parse(
        File('assets/config/model_config_cn.json').readAsStringSync(),
      );
      expect(cn.configVersion, config.configVersion);
      expect(cn.groups.map((g) => g.id), config.groups.map((g) => g.id));
      for (final l in config.languages) {
        expect(cn.languageById(l.id)?.group, l.group, reason: l.id);
      }
    });

    test('a config without groups makes each language its own group', () {
      final old = ModelConfig.parse(
        builtin
            .replaceAll(RegExp(r'"group": "\w+", '), '')
            .replaceFirst(RegExp(r'"languageGroups": \[[^\]]*\],'), ''),
      );
      expect(old.languageGroups, isEmpty);
      expect(old.groups.map((g) => g.id), old.sortedLanguages.map((l) => l.id));
      expect(old.languagesIn('yue').single.name, '粤语');
    });
  });

  group('model choice (PRD 4.5.3)', () {
    final senseVoice = config.asrModels.first;

    test('models for a dialect are sorted by its score', () {
      for (final language in config.languages) {
        final models = modelsFor(config, language.id);
        expect(models, isNotEmpty, reason: language.id);
        final scores = [
          for (final m in models)
            m.languages.firstWhere((s) => s.lang == language.id).score,
        ];
        expect(scores, [...scores]..sort((a, b) => b - a));
      }
      expect(modelsFor(config, 'zh').first.id, 'sense-voice-small-int8');
      expect(modelsFor(config, 'wu').first.id, 'wenetspeech-wu-wenet-ctc-int8');
      expect(modelsFor(config, 'fr').map((m) => m.id), ['whisper-small-int8']);
      expect(modelsFor(config, 'henan').map((m) => m.id), [
        'telespeech-ctc-int8',
        'dolphin-base-ctc-int8',
      ]);
    });

    test('the chosen model is used', () {
      expect(
        resolveModel(config, 'zh', 'telespeech-ctc-int8')?.id,
        'telespeech-ctc-int8',
      );
    });

    test('no or unknown choice falls back to the best model', () {
      expect(resolveModel(config, 'chuan', null)?.id, 'paraformer-chuan-int8');
      expect(
        resolveModel(config, 'zh', 'removed-model')?.id,
        'sense-voice-small-int8',
      );
      expect(
        resolveModel(config, 'unknown', null)?.id,
        'sense-voice-small-int8',
      );
    });

    test('recognition language is auto unless the model supports it', () {
      expect(effectiveLanguage(senseVoice, 'yue'), 'yue');
      expect(effectiveLanguage(senseVoice, 'henan'), isNull);
      expect(effectiveLanguage(senseVoice, null), isNull);
    });

    test('auto allows every language of the model', () {
      expect(allowedLanguages(senseVoice, null), {
        'zh',
        'yue',
        'en',
        'ja',
        'ko',
      });
      expect(allowedLanguages(senseVoice, 'en'), {'en'});
      expect(allowedLanguages(senseVoice, 'fr'), {
        'zh',
        'yue',
        'en',
        'ja',
        'ko',
      });
    });
  });

  group('decodeParamFor', () {
    final senseVoice = config.asrModels.first;
    AsrModelDef model(String id) =>
        config.asrModels.firstWhere((m) => m.id == id);
    final teleSpeech = model('telespeech-ctc-int8');
    final whisper = model('whisper-small-int8');

    test('single language uses its param, several use auto', () {
      expect(decodeParamFor(senseVoice, {'en'}), 'en');
      expect(decodeParamFor(senseVoice, {'zh', 'en'}), 'auto');
    });

    test('a language the model does not support means none', () {
      expect(decodeParamFor(teleSpeech, {'en'}), isNull);
    });

    test('whisper forces a single language and auto-detects several', () {
      expect(decodeParamFor(whisper, {'fr'}), 'fr');
      expect(decodeParamFor(whisper, {'fr', 'de'}), isNull);
    });

    test('empty param means none', () {
      expect(decodeParamFor(teleSpeech, {'henan'}), isNull);
      expect(decodeParamFor(teleSpeech, {'zh', 'henan'}), isNull);
    });
  });

  group('ConfigRepository', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('config_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    ConfigRepository repo() =>
        ConfigRepository(loadBuiltin: () async => builtin, storageDir: dir);

    test('falls back to builtin when nothing is cached', () async {
      expect((await repo().load()).configVersion, 6);
    });

    test('prefers a cached remote config', () async {
      File('${dir.path}/model_config.json').writeAsStringSync(
        builtin.replaceFirst('"configVersion": 6', '"configVersion": 7'),
      );
      expect((await repo().load()).configVersion, 7);
    });

    test('a newer builtin config wins over an older cache', () async {
      File('${dir.path}/model_config.json').writeAsStringSync(
        builtin.replaceFirst('"configVersion": 6', '"configVersion": 4'),
      );
      expect((await repo().load()).configVersion, 6);
    });

    test('ignores a cached config with unsupported schema', () async {
      File('${dir.path}/model_config.json').writeAsStringSync(
        builtin.replaceFirst('"schemaVersion": 2', '"schemaVersion": 9'),
      );
      expect((await repo().load()).configVersion, 6);
    });

    test('acceptRemote requires a newer configVersion', () {
      final newer = builtin.replaceFirst(
        '"configVersion": 6',
        '"configVersion": 7',
      );
      expect(ConfigRepository.acceptRemote(config, newer)?.configVersion, 7);
      expect(ConfigRepository.acceptRemote(config, builtin), isNull);
      expect(ConfigRepository.acceptRemote(config, 'not json'), isNull);
    });

    test('refresh skips non-https urls', () async {
      final insecure = ModelConfig.parse(
        builtin.replaceFirst('https://example.com', 'http://example.com'),
      );
      expect(await repo().refresh(insecure), isNull);
    });
  });
}
