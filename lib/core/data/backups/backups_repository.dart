import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../models/backup_model.dart';
import '../../services/di/locator.dart';
import '../../services/hive/service.dart';

class BackupsRepository {
  Box<Backup> get _box => locator<HiveService>().backupsBox!;

  Future<void> add(Backup backup) => _box.add(backup);

  List<Backup> readAll() => _box.values.toList();

  ValueListenable<Box<Backup>> watch() => _box.listenable();

  Future<void> deleteAt(dynamic key) => _box.delete(key);

  Iterable<int> get keys => _box.keys.cast<int>();
}
