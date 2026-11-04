import 'dart:io';

/// 长期保存模型文件的位置（PRD 4.5.5 的“外置存储”）。
/// [relPath] 形如 `models/<模型id>/<version>/<文件名>`。
abstract class ModelStore {
  String get label;

  /// 文件不存在时返回 null。
  Future<int?> sizeOf(String relPath);

  Future<void> copyToLocal(String relPath, File dest);

  Future<void> copyFromLocal(File src, String relPath);
}

/// 普通文件系统目录。App 使用应用专属外置目录
/// （Android/data/com.visioiridis.visioiridis/files），盒子出厂时可通过 adb 预置模型。
class DirectoryModelStore implements ModelStore {
  DirectoryModelStore(this.root, {this.label = '应用专属目录'});

  final Directory root;

  @override
  final String label;

  File _file(String relPath) => File('${root.path}/$relPath');

  @override
  Future<int?> sizeOf(String relPath) async {
    final file = _file(relPath);
    return await file.exists() ? file.length() : null;
  }

  @override
  Future<void> copyToLocal(String relPath, File dest) async {
    await _file(relPath).copy(dest.path);
  }

  @override
  Future<void> copyFromLocal(File src, String relPath) async {
    final target = _file(relPath);
    await target.parent.create(recursive: true);
    await src.copy(target.path);
  }
}
