import 'dart:io';

import 'package:flutter_starter/core/data/backups/backups_repository.dart';
import 'package:flutter_starter/core/models/backup_model.dart';
import 'package:flutter_starter/core/services/di/locator.dart';
import 'package:flutter_starter/core/services/hive/service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

// Plain (non-widget) tests against a real, temp-directory-backed Hive box --
// mirrors DB_Manager's db_insertBackup/db_readAllBackups/db_removeBackup
// from the legacy app. Deliberately not testWidgets: exercising the delete
// path together with widget pumping in the same process is covered instead,
// read-only, by backups_screen_test.dart -- see the comment there.
void main() {
  late Directory tempDir;
  late BackupsRepository repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('backups_repository_test');
    Hive.init(tempDir.path);

    final hiveService = await HiveService.getInstance();
    locator.registerSingleton<HiveService>(hiveService!);

    repository = BackupsRepository();
  });

  tearDown(() async {
    for (final key in repository.keys.toList()) {
      await repository.deleteAt(key);
    }
  });

  tearDownAll(() async {
    locator.unregister<HiveService>();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Backup sampleBackup(String name) => Backup(name: name, resolutionHtml: '<b>X = 3</b>', xi: '1_2_3', ni: '2_4_6', date: '01.01.2026 - 10:00');

  test('starts empty', () {
    expect(repository.readAll(), isEmpty);
    expect(repository.keys, isEmpty);
  });

  test('add persists a backup, readable back with the same fields', () async {
    await repository.add(sampleBackup('Etude 1'));

    final all = repository.readAll();
    expect(all, hasLength(1));
    expect(all.first.name, 'Etude 1');
    expect(all.first.resolutionHtml, '<b>X = 3</b>');
    expect(all.first.xi, '1_2_3');
    expect(all.first.ni, '2_4_6');
    expect(all.first.date, '01.01.2026 - 10:00');
  });

  test('add appends rather than replacing', () async {
    await repository.add(sampleBackup('Etude 1'));
    await repository.add(sampleBackup('Etude 2'));

    expect(repository.readAll().map((b) => b.name), ['Etude 1', 'Etude 2']);
    expect(repository.keys, hasLength(2));
  });

  test('deleteAt removes only the targeted backup', () async {
    await repository.add(sampleBackup('Etude 1'));
    await repository.add(sampleBackup('Etude 2'));

    final keys = repository.keys.toList();
    await repository.deleteAt(keys.first);

    final remaining = repository.readAll();
    expect(remaining, hasLength(1));
    expect(remaining.first.name, 'Etude 2');
  });

  test('watch notifies listeners on add and delete', () async {
    final events = <int>[];
    final listenable = repository.watch();
    void listener() => events.add(listenable.value.length);
    listenable.addListener(listener);

    await repository.add(sampleBackup('Etude 1'));
    await repository.deleteAt(repository.keys.first);

    listenable.removeListener(listener);

    expect(events, [1, 0]);
  });

  test('persists the kind, data and save time, and still reads backups saved without them', () async {
    final saved = DateTime(2026, 3, 7, 9, 5);
    await repository.add(sampleBackup('Ancienne'));
    await repository.add(
      Backup(
        name: 'Nouvelle',
        resolutionHtml: '<b>X</b>',
        xi: '1_2',
        ni: '2_4',
        date: '07.03.2026 - 09:05',
        kind: 'discrete',
        data: '{"columns": [[1, 2], [2, 4]], "selectedStats": ["mean"], "precision": 3}',
        createdAt: saved,
      ),
    );

    final [old, fresh] = repository.readAll();
    expect(old.kind, isNull);
    expect(old.data, isNull);
    expect(old.createdAt, isNull);
    expect(fresh.kind, 'discrete');
    expect(fresh.data, contains('"selectedStats"'));
    expect(fresh.createdAt, saved);
  });
}
