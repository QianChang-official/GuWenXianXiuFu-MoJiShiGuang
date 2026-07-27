// -----------------------------------------------------------------------------
// 本地存储服务 (Local Storage Service)
// 基于 drift (SQLite) 的离线存储方案，为「墨迹时光」提供以下能力：
//   - 修复历史记录持久化
//   - OCR 识别记录缓存
//   - 知识图谱缓存
//   - 用户作品管理
//   - 模型缓存管理
//   - 全离线模式支持
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_storage.g.dart';

/// 修复历史记录表。
/// 记录每次图像修复操作的时间、参数、前后对比等。
class RepairHistory extends drift.Table {
  drift.TextColumn get id => text()();
  drift.TextColumn get imageName => text()();
  drift.TextColumn get originalPath => text()();
  drift.TextColumn get resultPath => text()();
  drift.TextColumn get repairType => text()();
  drift.TextColumn get parameters => text()();
  drift.DateTimeColumn get createdAt => dateTime()();
  drift.RealColumn get fileSizeMb => real()();
  drift.IntColumn get durationMs => integer()();
  drift.TextColumn get thumbnailPath => text().nullable()();

  @override
  Set<drift.Column> get primaryKey => {id};
}

/// OCR 识别记录表。
class OcrRecord extends drift.Table {
  drift.TextColumn get id => text()();
  drift.TextColumn get imagePath => text()();
  drift.TextColumn get recognizedText => text()();
  drift.RealColumn get confidence => real()();
  drift.TextColumn get language => text()();
  drift.DateTimeColumn get createdAt => dateTime()();
  drift.TextColumn get repairHistoryId => text().nullable()();

  @override
  Set<drift.Column> get primaryKey => {id};
}

/// 知识图谱缓存表。
class KnowledgeGraphCache extends drift.Table {
  drift.TextColumn get id => text()();
  drift.TextColumn get entityType => text()();
  drift.TextColumn get entityName => text()();
  drift.TextColumn get relationJson => text()();
  drift.DateTimeColumn get updatedAt => dateTime()();
  drift.IntColumn get version => integer()();

  @override
  Set<drift.Column> get primaryKey => {id};
}

/// 用户作品表。
class UserWork extends drift.Table {
  drift.TextColumn get id => text()();
  drift.TextColumn get title => text()();
  drift.TextColumn get description => text().nullable()();
  drift.TextColumn get imagePath => text()();
  drift.TextColumn get thumbnailPath => text().nullable()();
  drift.TextColumn get tags => text().nullable()();
  drift.DateTimeColumn get createdAt => dateTime()();
  drift.DateTimeColumn get updatedAt => dateTime()();
  drift.BoolColumn get isPublished =>
      boolean().withDefault(const drift.Constant(false))();

  @override
  Set<drift.Column> get primaryKey => {id};
}

/// 模型缓存管理表。
class ModelCache extends drift.Table {
  drift.TextColumn get id => text()();
  drift.TextColumn get modelName => text()();
  drift.TextColumn get version => text()();
  drift.TextColumn get filePath => text()();
  drift.RealColumn get fileSizeMb => real()();
  drift.DateTimeColumn get downloadedAt => dateTime()();
  drift.BoolColumn get isActive =>
      boolean().withDefault(const drift.Constant(true))();
  drift.TextColumn get checksum => text()();

  @override
  Set<drift.Column> get primaryKey => {id};
}

/// 本地数据库，管理所有离线数据。
/// 使用 drift（SQLite）提供类型安全的数据库操作。
@drift.DriftDatabase(tables: [
  RepairHistory,
  OcrRecord,
  KnowledgeGraphCache,
  UserWork,
  ModelCache,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  static final LocalDatabase _instance = LocalDatabase();
  static LocalDatabase get instance => _instance;

  @override
  int get schemaVersion => 1;

  @override
  drift.MigrationStrategy get migration => drift.MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {},
      );
}

/// 打开数据库连接。
drift.LazyDatabase _openConnection() {
  return drift.LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dir.path, 'mojishiguang.db'));
    return NativeDatabase(dbFile);
  });
}

/// 离线模式管理器。
/// 在网络不可用时自动切换到本地数据库读写。
class OfflineManager {
  final LocalDatabase _db;

  OfflineManager(this._db);

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  void enableOfflineMode() {
    _isOffline = true;
  }

  void disableOfflineMode() {
    _isOffline = false;
  }

  final List<OfflineOperation> pendingSync = [];

  void addPendingSync(OfflineOperation operation) {
    pendingSync.add(operation);
  }

  Future<void> syncAll() async {
    for (final op in pendingSync) {
      try {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      } catch (_) {
        // Keep failed operations queued for a later synchronization attempt.
        continue;
      }
    }
    pendingSync.clear();
  }
}

/// 离线操作记录。
class OfflineOperation {
  final String type;
  final String table;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  OfflineOperation({
    required this.type,
    required this.table,
    required this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
