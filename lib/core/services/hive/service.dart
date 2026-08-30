import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../models/backup_model.dart';
import 'hive_registrar.g.dart';
import 'keys.dart';

class HiveService {
  static HiveService? _instance;

  static Future<HiveService?> getInstance() async {
    _instance ??= HiveService();

    await _instance?.openBoxes();

    return _instance;
  }

  Box? helperBox;
  Box<Backup>? backupsBox;

  HiveService();

  Future<void> openBoxes() async {
    Hive.registerAdapters();

    helperBox = await Hive.openBox(HiveKeys.helper);
    backupsBox = await Hive.openBox<Backup>(HiveKeys.backups);
  }
}
