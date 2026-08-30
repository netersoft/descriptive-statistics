import 'package:hive_ce/hive.dart';

import '../../enums/app_brightness.dart';
import '../../models/backup_model.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([
  AdapterSpec<AppBrightness>(),
  AdapterSpec<Backup>(),
], firstTypeId: 100)
class HiveAdapters {}
