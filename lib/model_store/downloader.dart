import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

typedef ProgressCallback = void Function(int done, int total);
typedef CancelCheck = bool Function();

class DownloadCancelled implements Exception {
  const DownloadCancelled();

  @override
  String toString() => '下载已取消';
}

/// 把文件下载到 [dest]。
abstract class Downloader {
  /// 按顺序尝试 [urls]，前一个失败自动换下一个。[dest] 已有部分内容时断点续传。
  Future<void> fetch(
    List<String> urls,
    File dest,
    int expectedSize, {
    ProgressCallback? onProgress,
    CancelCheck? isCancelled,
  });
}

class HttpDownloader implements Downloader {
  HttpDownloader({HttpClient? client, this.hfToken})
    : _client =
          client ??
          (HttpClient()..connectionTimeout = const Duration(seconds: 15));

  final HttpClient _client;

  /// HuggingFace personal access token，用于访问需要认证的仓库。
  final String? hfToken;

  static bool _isHfHost(Uri uri) =>
      uri.host == 'huggingface.co' || uri.host == 'hf-mirror.com';

  @override
  Future<void> fetch(
    List<String> urls,
    File dest,
    int expectedSize, {
    ProgressCallback? onProgress,
    CancelCheck? isCancelled,
  }) async {
    Object? lastError;
    for (final url in urls) {
      if (isCancelled?.call() ?? false) throw const DownloadCancelled();
      try {
        await _fetchOne(
          Uri.parse(url),
          dest,
          expectedSize,
          onProgress,
          isCancelled,
        );
        return;
      } on DownloadCancelled {
        rethrow;
      } catch (e) {
        lastError = e;
      }
    }
    throw HttpException('所有下载地址均失败: $lastError');
  }

  Future<void> _fetchOne(
    Uri uri,
    File dest,
    int expectedSize,
    ProgressCallback? onProgress,
    CancelCheck? isCancelled,
  ) async {
    var offset = await dest.exists() ? await dest.length() : 0;
    if (offset > expectedSize) {
      await dest.delete();
      offset = 0;
    }
    if (offset == expectedSize) {
      onProgress?.call(offset, expectedSize);
      return;
    }

    final request = await _client.getUrl(uri);
    // Range 按原始字节计算，禁止服务器压缩传输。
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    if (hfToken != null && _isHfHost(uri)) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $hfToken');
    }
    if (offset > 0) {
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
    }
    final response = await request.close();

    final FileMode mode;
    if (response.statusCode == HttpStatus.partialContent && offset > 0) {
      mode = FileMode.append;
    } else if (response.statusCode == HttpStatus.ok) {
      // 服务器不支持 Range，从头下载。
      mode = FileMode.write;
      offset = 0;
    } else {
      await response.drain<void>();
      if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
        await dest.delete();
      }
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }

    final sink = dest.openWrite(mode: mode);
    var received = offset;
    try {
      await for (final chunk in response) {
        if (isCancelled?.call() ?? false) throw const DownloadCancelled();
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, expectedSize);
      }
    } finally {
      await sink.close();
    }
    if (received != expectedSize) {
      throw HttpException('文件大小不符: $received / $expectedSize', uri: uri);
    }
  }
}

/// 在后台 Isolate 计算文件 sha256（小写十六进制），避免阻塞 UI。
Future<String> sha256OfFile(String path) => Isolate.run(
  () async => (await sha256.bind(File(path).openRead()).first).toString(),
);
