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

// 注意：以下代码为 drift 数据库定义骨架。
// 在运行 build_runner 生成 *g.dart 文件之前，编译会报错。
// 请确保项目中已正确配置 drift（moor）依赖。

// 实际使用时请移除下面这行注释标记，并在项目中运行：
//     dart run build_runner build

/*
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_storage.g.dart';
*/

// ============================================================
// 表定义
// ============================================================

/// 修复历史记录表。
/// 记录每次图像修复操作的时间、参数、前后对比等。
// coverage:ignore-start
class RepairHistory extends Table {
  TextColumn get id => text()();
  TextColumn get imageName => text()();
  TextColumn get originalPath => text()();
  TextColumn get resultPath => text()();
  TextColumn get repairType => text()();       // 修复类型（去噪/上色/补全等）
  TextColumn get parameters => text()();      // JSON 参数
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get fileSizeMb => real()();
  IntColumn get durationMs => integer()();
  TextColumn get thumbnailPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// OCR 识别记录表。
class OcrRecord extends Table {
  TextColumn get id => text()();
  TextColumn get imagePath => text()();
  TextColumn get recognizedText => text()();
  RealColumn get confidence => real()();
  TextColumn get language => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get repairHistoryId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 知识图谱缓存表。
class KnowledgeGraphCache extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();       // character / artifact / location
  TextColumn get entityName => text()();
  TextColumn get relationJson => text()();     // JSON 关系数据
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 用户作品表。
class UserWork extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get imagePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get tags => text().nullable()();       // 逗号分隔
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isPublished => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 模型缓存管理表。
class ModelCache extends Table {
  TextColumn get id => text()();
  TextColumn get modelName => text()();
  TextColumn get version => text()();
  TextColumn get filePath => text()();
  RealColumn get fileSizeMb => real()();
  DateTimeColumn get downloadedAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get checksum => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// 数据库类
// ============================================================

// coverage:ignore-end

/// 本地数据库，管理所有离线数据。
/// 使用 drift（SQLite）提供类型安全的数据库操作。
///
/// 使用方式：
/// ```dart
/// final db = await LocalDatabase.instance;
/// await db.repairHistory.insert(RepairHistoryCompanion(...));
/// final records = await db.select(db.repairHistory).get();
/// ```
///
/// 注意：需要先运行 `dart run build_runner build` 生成代码。
/*
@DriftDatabase(tables: [
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

  /// 迁移策略（后续版本扩展时使用）
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // 版本升级时在此添加迁移逻辑
    },
  );
}

/// 打开数据库连接。
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
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

  /// 是否处于离线模式。
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  /// 切换到离线模式。
  void enableOfflineMode() {
    _isOffline = true;
  }

  /// 切换到在线模式。
  void disableOfflineMode() {
    _isOffline = false;
  }

  /// 待同步的队列（离线时写入的操作，上线后批量同步）。
  final List<OfflineOperation> pendingSync = [];

  /// 添加待同步操作。
  void addPendingSync(OfflineOperation operation) {
    pendingSync.add(operation);
  }

  /// 同步所有待处理操作。
  Future<void> syncAll() async {
    for (final op in pendingSync) {
      try {
        // TODO: 调用后端 API 同步
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // 记录失败操作，后续重试
      }
    }
    pendingSync.clear();
  }
}

/// 离线操作记录。
class OfflineOperation {
  final String type;      // create / update / delete
  final String table;     // 表名
  final Map<String, dynamic> data;
  final DateTime createdAt;

  OfflineOperation({
    required this.type,
    required this.table,
    required this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
*/
