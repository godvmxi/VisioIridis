import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/model_store/downloader.dart';

void main() {
  final payload = Uint8List.fromList(List.generate(100000, (i) => i % 251));
  late HttpServer server;
  late Directory dir;
  final rangeHeaders = <String?>[];

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('downloader_test');
    rangeHeaders.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      final res = request.response;
      if (request.uri.path == '/missing') {
        res.statusCode = HttpStatus.notFound;
        res.close();
        return;
      }
      final range = request.headers.value(HttpHeaders.rangeHeader);
      rangeHeaders.add(range);
      if (range != null && request.uri.path != '/norange') {
        final start = int.parse(range.substring(6, range.length - 1));
        res.statusCode = HttpStatus.partialContent;
        res.add(payload.sublist(start));
      } else {
        res.add(payload);
      }
      res.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    dir.deleteSync(recursive: true);
  });

  String url(String path) => 'http://127.0.0.1:${server.port}$path';
  File dest() => File('${dir.path}/file.part');

  test('downloads the whole file and reports progress', () async {
    var lastDone = 0;
    await HttpDownloader().fetch([url('/f')], dest(), payload.length,
        onProgress: (done, total) => lastDone = done);
    expect(dest().readAsBytesSync(), payload);
    expect(lastDone, payload.length);
    expect(rangeHeaders, [null]);
  });

  test('resumes an existing partial file with a Range request', () async {
    dest().writeAsBytesSync(payload.sublist(0, 40000));
    await HttpDownloader().fetch([url('/f')], dest(), payload.length);
    expect(dest().readAsBytesSync(), payload);
    expect(rangeHeaders, ['bytes=40000-']);
  });

  test('restarts from zero when the server ignores Range', () async {
    dest().writeAsBytesSync(payload.sublist(0, 40000));
    await HttpDownloader().fetch([url('/norange')], dest(), payload.length);
    expect(dest().readAsBytesSync(), payload);
  });

  test('falls back to the next url', () async {
    await HttpDownloader()
        .fetch([url('/missing'), url('/f')], dest(), payload.length);
    expect(dest().readAsBytesSync(), payload);
  });

  test('fails when every url fails or size differs', () async {
    expect(
      () => HttpDownloader().fetch([url('/missing')], dest(), payload.length),
      throwsA(isA<HttpException>()),
    );
    expect(
      () => HttpDownloader().fetch([url('/f')], dest(), payload.length + 1),
      throwsA(isA<HttpException>()),
    );
  });

  test('stops when cancelled', () async {
    expect(
      () => HttpDownloader().fetch([url('/f')], dest(), payload.length,
          isCancelled: () => true),
      throwsA(isA<DownloadCancelled>()),
    );
  });

  test('sha256OfFile matches crypto', () async {
    dest().writeAsBytesSync(payload);
    expect(await sha256OfFile(dest().path), sha256.convert(payload).toString());
  });
}
