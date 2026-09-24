class Backup {
  final String name;

  /// The step-by-step explanation as rendered when the backup was saved --
  /// in the language of that moment. Only shown when [data] can't be used
  /// to rebuild it (backups saved before [data] existed).
  final String resolutionHtml;

  /// Xi and Ni joined with '_' (Xi are the modality indices for qualitative
  /// backups), as the legacy app stored them.
  final String xi;
  final String ni;

  /// Save time as displayed by older app versions ("dd.MM.yyyy - HH:mm").
  final String date;

  /// A `BackupKind` name. Null for backups saved before it was stored.
  final String? kind;

  /// JSON-encoded `BackupData`: the values, selected stats and precision
  /// needed to recompute the calculation. Null for backups saved before it
  /// was stored.
  final String? data;

  /// Save time. Null for backups saved before it was stored.
  final DateTime? createdAt;

  Backup({
    required this.name,
    required this.resolutionHtml,
    required this.xi,
    required this.ni,
    required this.date,
    this.kind,
    this.data,
    this.createdAt,
  });
}
