import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/model_store/downloader.dart';
import 'package:seevoice/model_store/model_config.dart';
import 'package:seevoice/model_store/model_repository.dart';
import 'package:seevoice/model_store/model_store.dart';

/// 按 URL 返回预设内容的下载器，并记录下载次数。
class FakeDownloader implements Downloader {
  FakeDownloader(this.contents);

  final Map<String, List<int>> contents;
  int calls = 0;

  @override
  Future<void> fetch(
    List<String> urls,
    File dest,
    int expectedSize, {
    ProgressCallback? onProgress,
    CancelCheck? isCancelled,
  }) async {
    calls++;
    if (isCancelled?.call() ?? false) throw const DownloadCancelled();
    final bytes = contents[urls.first]!;
    await dest.writeAsBytes(bytes);
    onProgress?.call(bytes.length, expectedSize);
  }
}

void main() {
  final modelBytes = utf8.encode('fake onnx model');
  final tokenBytes = utf8.encode('fake tokens');

  ModelFile file(String name, List<int> bytes, {String? sha}) => ModelFile(
    name: name,
    size: bytes.length,
    sha256: sha ?? sha256.convert(bytes).toString(),
    urls: ['https://example.com/$name'],
  );

  final model = ModelDef(
    id: 'm',
    version: '1',
    files: [file('model.onnx', modelBytes), file('tokens.txt', tokenBytes)],
  );

  late Directory tmp;
  late ModelCache cache;
  late DirectoryModelStore store;
  late FakeDownloader downloader;

  ModelRepository repo({List<ModelStore>? stores}) => ModelRepository(
    cache: cache,
    stores: stores ?? [store],
    downloader: downloader,
  );

  File storeFile(String name) => File('${store.root.path}/models/m/1/$name');

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('repo_test');
    cache = ModelCache(Directory('${tmp.path}/cache'));
    store = DirectoryModelStore(Directory('${tmp.path}/public'));
    downloader = FakeDownloader({
      'https://example.com/model.onnx': modelBytes,
      'https://example.com/tokens.txt': tokenBytes,
    });
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test(
    'downloads missing files into cache and saves them to the store',
    () async {
      final plan = await repo().plan(model);
      expect(plan.toDownload.length, 2);
      expect(plan.downloadBytes, modelBytes.length + tokenBytes.length);

      final dir = await repo().ensure(model);
      expect(downloader.calls, 2);
      expect(File('${dir.path}/model.onnx').readAsBytesSync(), modelBytes);
      expect(storeFile('model.onnx').readAsBytesSync(), modelBytes);
      expect(await cache.isReady(model), isTrue);
      expect(File('${dir.path}/model.onnx.part').existsSync(), isFalse);
    },
  );

  test('uses cache without touching store or network', () async {
    await repo().ensure(model);
    storeFile('model.onnx').deleteSync();
    await repo().ensure(model);
    expect(downloader.calls, 2);
  });

  test(
    'restores from store after cache is cleared, without downloading',
    () async {
      await repo().ensure(model);
      cache.root.deleteSync(recursive: true);

      final plan = await repo().plan(model);
      expect(plan.fromStore.length, 2);
      expect(plan.downloadBytes, 0);

      await repo().ensure(model);
      expect(downloader.calls, 2);
      expect(await cache.isReady(model), isTrue);
    },
  );

  test('re-downloads when the store copy is corrupted', () async {
    await repo().ensure(model);
    cache.root.deleteSync(recursive: true);
    // 同样大小但内容被改动。
    storeFile('model.onnx').writeAsBytesSync(List.filled(modelBytes.length, 0));

    await repo().ensure(model);
    expect(downloader.calls, 3);
    expect(storeFile('model.onnx').readAsBytesSync(), modelBytes);
  });

  test(
    'throws and leaves nothing behind when the hash does not match',
    () async {
      final bad = ModelDef(
        id: 'm',
        version: '1',
        files: [file('model.onnx', modelBytes, sha: 'deadbeef')],
      );
      await expectLater(
        repo().ensure(bad),
        throwsA(isA<ModelIntegrityException>()),
      );
      expect(await cache.isReady(bad), isFalse);
      expect(storeFile('model.onnx').existsSync(), isFalse);
    },
  );

  test('works without any store', () async {
    await repo(stores: []).ensure(model);
    expect(await cache.isReady(model), isTrue);
  });

  test('finds files in a secondary store', () async {
    final preloaded = DirectoryModelStore(Directory('${tmp.path}/preloaded'));
    await repo(stores: [preloaded]).ensure(model);
    cache.root.deleteSync(recursive: true);

    await repo(stores: [store, preloaded]).ensure(model);
    expect(downloader.calls, 2);
  });
}
