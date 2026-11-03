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
        'sichuan',
        'dongbei',
        'shandong',
        'shanghai',
        'minnan',
        'ja',
        'ko',
      ]);
      expect(config.vad.files.single.name, 'silero_vad.onnx');
      expect(config.asrModels.map((m) => m.id), [
        'sense-voice-small-int8',
        'telespeech-ctc-int8',
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

  group('selectModel (PRD 4.5.3)', () {
    String? pick(Set<String> langs) => selectModel(config, langs)?.id;

    test('default three languages use SenseVoice', () {
      expect(pick({'zh', 'yue', 'en'}), 'sense-voice-small-int8');
    });

    test('mandarin alone prefers the higher score', () {
      expect(pick({'zh'}), 'sense-voice-small-int8');
    });

    test('henan alone or with mandarin uses TeleSpeech', () {
      expect(pick({'henan'}), 'telespeech-ctc-int8');
      expect(pick({'zh', 'henan'}), 'telespeech-ctc-int8');
    });

    test('cantonese with a dialect uses Dolphin', () {
      expect(pick({'yue', 'henan'}), 'dolphin-base-ctc-int8');
      expect(pick({'shanghai'}), 'dolphin-base-ctc-int8');
      expect(pick({'zh', 'minnan'}), 'dolphin-base-ctc-int8');
    });

    test('french and german use Whisper', () {
      expect(pick({'fr'}), 'whisper-small-int8');
      expect(pick({'de'}), 'whisper-small-int8');
      expect(pick({'en', 'fr', 'de'}), 'whisper-small-int8');
    });

    test('english alone still prefers SenseVoice', () {
      expect(pick({'en'}), 'sense-voice-small-int8');
    });

    test('unsupported combination returns null', () {
      expect(pick({'yue', 'fr'}), isNull);
      expect(pick({'de', 'sichuan'}), isNull);
    });

    test('a preferred model wins over a higher score', () {
      expect(
        selectModel(
          config,
          {'zh'},
          preferred: {'zh': 'telespeech-ctc-int8'},
        )?.id,
        'telespeech-ctc-int8',
      );
    });

    test('a preferred model wins even if it lacks another language', () {
      final model = selectModel(
        config,
        {'zh', 'en'},
        preferred: {'zh': 'telespeech-ctc-int8'},
      )!;
      expect(model.id, 'telespeech-ctc-int8');
      expect(unsupportedLanguages(model, {'zh', 'en'}), {'en'});
    });

    test('unknown preferred ids are ignored', () {
      expect(
        selectModel(config, {'zh'}, preferred: {'zh': 'removed-model'})?.id,
        'sense-voice-small-int8',
      );
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
      expect((await repo().load()).configVersion, 3);
    });

    test('prefers a cached remote config', () async {
      File('${dir.path}/model_config.json').writeAsStringSync(
        builtin.replaceFirst('"configVersion": 3', '"configVersion": 5'),
      );
      expect((await repo().load()).configVersion, 5);
    });

    test('ignores a cached config with unsupported schema', () async {
      File('${dir.path}/model_config.json').writeAsStringSync(
        builtin.replaceFirst('"schemaVersion": 2', '"schemaVersion": 9'),
      );
      expect((await repo().load()).configVersion, 3);
    });

    test('acceptRemote requires a newer configVersion', () {
      final newer = builtin.replaceFirst(
        '"configVersion": 3',
        '"configVersion": 4',
      );
      expect(ConfigRepository.acceptRemote(config, newer)?.configVersion, 4);
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
