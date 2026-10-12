import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive health profile model capturing reproductive stage, contraception,
/// gynecological conditions, family medical history, and lifestyle factors.
class HealthProfileModel {
  final String reproductiveStatus;
  final int? menarcheAge;
  final String activityLevel;
  final String contraception;
  final List<String> gynecologicalConditions;
  final List<String> familyMedicalHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HealthProfileModel({
    this.reproductiveStatus = 'single',
    this.menarcheAge,
    this.activityLevel = 'moderate',
    this.contraception = 'none',
    this.gynecologicalConditions = const ['none'],
    this.familyMedicalHistory = const ['none'],
    this.createdAt,
    this.updatedAt,
  });

  /// Helper to safely parse dates from Timestamp, ISO String, or epoch milliseconds.
  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    if (raw is num) {
      final intVal = raw.toInt();
      if (intVal > 10000000000) return DateTime.fromMillisecondsSinceEpoch(intVal);
      if (intVal > 10000000) return DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
      if (intVal >= 1900 && intVal <= 2100) return DateTime(intVal, 1, 1);
    }
    return null;
  }

  /// Factory to construct [HealthProfileModel] from Firestore or local document map.
  factory HealthProfileModel.fromJson(Map<String, dynamic> json) {
    final parsedCreatedAt = _parseDate(json['createdAt'] ?? json['created_at']);
    final parsedUpdatedAt = _parseDate(json['updatedAt'] ?? json['updated_at']);

    List<String> parseStringList(dynamic rawList, String fallback) {
      if (rawList is List) {
        final list = rawList.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        if (list.isNotEmpty) return list;
      }
      return [fallback];
    }

    final repStatus = json['reproductiveStatus'] ?? json['reproductive_status'];
    final menAge = json['menarcheAge'] ?? json['menarche_age'];
    final actLevel = json['activityLevel'] ?? json['activity_level'];
    final contra = json['contraception'];
    final gyneco = json['gynecologicalConditions'] ?? json['gynecological_conditions'];
    final familyHist = json['familyMedicalHistory'] ?? json['family_medical_history'];

    return HealthProfileModel(
      reproductiveStatus: repStatus is String && repStatus.isNotEmpty ? repStatus : 'single',
      menarcheAge: (menAge as num?)?.toInt(),
      activityLevel: actLevel is String && actLevel.isNotEmpty ? actLevel : 'moderate',
      contraception: contra is String && contra.isNotEmpty ? contra : 'none',
      gynecologicalConditions: parseStringList(gyneco, 'none'),
      familyMedicalHistory: parseStringList(familyHist, 'none'),
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Converts this model into a Firestore-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      'reproductiveStatus': reproductiveStatus,
      'menarcheAge': menarcheAge,
      'activityLevel': activityLevel,
      'contraception': contraception,
      'gynecologicalConditions': gynecologicalConditions,
      'familyMedicalHistory': familyMedicalHistory,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Converts this model into a standard JSON-serializable Map for local SharedPreferences cache.
  Map<String, dynamic> toLocalMap() {
    return {
      'reproductiveStatus': reproductiveStatus,
      'menarcheAge': menarcheAge,
      'activityLevel': activityLevel,
      'contraception': contraception,
      'gynecologicalConditions': gynecologicalConditions,
      'familyMedicalHistory': familyMedicalHistory,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Copies this model instance with optional parameter overrides.
  HealthProfileModel copyWith({
    String? reproductiveStatus,
    int? menarcheAge,
    bool clearMenarcheAge = false,
    String? activityLevel,
    String? contraception,
    List<String>? gynecologicalConditions,
    List<String>? familyMedicalHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthProfileModel(
      reproductiveStatus: reproductiveStatus ?? this.reproductiveStatus,
      menarcheAge: clearMenarcheAge ? null : (menarcheAge ?? this.menarcheAge),
      activityLevel: activityLevel ?? this.activityLevel,
      contraception: contraception ?? this.contraception,
      gynecologicalConditions: gynecologicalConditions ?? this.gynecologicalConditions,
      familyMedicalHistory: familyMedicalHistory ?? this.familyMedicalHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Indonesian readable label for reproductive status.
  String get reproductiveStatusLabel {
    switch (reproductiveStatus) {
      case 'single':
        return 'Belum Menikah / Tidak Promil';
      case 'planning_pregnancy':
        return 'Merencanakan Kehamilan (Promil)';
      case 'pregnant':
        return 'Sedang Hamil';
      case 'postpartum':
        return 'Pasca Melahirkan / Menyusui';
      case 'not_planning':
        return 'Sudah Menikah (Belum Promil)';
      case 'prefer_not_to_say':
        return 'Dirahasiakan';
      default:
        return 'Belum Menikah';
    }
  }

  /// Indonesian readable label for contraception.
  String get contraceptionLabel {
    switch (contraception) {
      case 'none':
        return 'Tidak Menggunakan Kontrasepsi';
      case 'pill':
        return 'Pil KB Hormonal';
      case 'injection':
        return 'Suntik KB (1/3 Bulan)';
      case 'implant':
        return 'Implan / Susuk KB';
      case 'iud_hormonal':
        return 'IUD Hormonal (Mirena/Kyleena)';
      case 'iud_copper':
        return 'IUD Tembaga (Non-Hormonal)';
      case 'patch_ring':
        return 'Patch / Cincin Vagina';
      case 'prefer_not_to_say':
        return 'Dirahasiakan';
      default:
        return 'Tidak Menggunakan';
    }
  }

  /// Indonesian readable label for physical activity level.
  String get activityLevelLabel {
    switch (activityLevel) {
      case 'sedentary':
        return 'Banyak Duduk / Santai';
      case 'light':
        return 'Aktivitas Ringan (Jalan Santai)';
      case 'moderate':
        return 'Sedang (Olahraga 2-3x/minggu)';
      case 'active':
        return 'Aktif (Olahraga Rutin 4-5x/minggu)';
      case 'prefer_not_to_say':
        return 'Dirahasiakan';
      default:
        return 'Sedang';
    }
  }

  /// Returns readable names for gynecological conditions.
  static String conditionToLabel(String condition) {
    switch (condition) {
      case 'pcos':
        return 'PCOS (Sindrom Ovarium Polikistik)';
      case 'endometriosis':
        return 'Endometriosis';
      case 'myoma_cyst':
        return 'Miom / Kista Ovarium';
      case 'anemia':
        return 'Anemia Defisiensi Besi';
      case 'thyroid':
        return 'Gangguan Tiroid';
      case 'none':
        return 'Tidak Ada Riwayat Kondisi';
      case 'prefer_not_to_say':
        return 'Dirahasiakan';
      default:
        return condition;
    }
  }

  /// Returns readable names for family medical history items.
  static String familyConditionToLabel(String condition) {
    switch (condition) {
      case 'pcos':
        return 'PCOS / Gangguan Siklus Turunan';
      case 'endometriosis':
        return 'Endometriosis';
      case 'myoma':
        return 'Miom / Tumor Jinak Rahim';
      case 'breast_cervical_cancer':
        return 'Kanker Payudara / Serviks';
      case 'none':
        return 'Tidak Ada Riwayat / Tidak Tahu';
      case 'prefer_not_to_say':
        return 'Dirahasiakan';
      default:
        return condition;
    }
  }

  /// Formats this health profile into a medical context block for AI and clinical inference engines.
  String toClinicalContextString({int? age, int? cycleLength, int? periodDuration, String? regularity}) {
    final buffer = StringBuffer();
    buffer.write('Konteks Klinis Pengguna:');

    if (age != null) buffer.write(' Usia $age tahun.');
    if (cycleLength != null) buffer.write(' Panjang siklus $cycleLength hari.');
    if (periodDuration != null) buffer.write(' Durasi haid $periodDuration hari.');
    if (regularity != null && regularity.isNotEmpty) buffer.write(' Keteraturan: $regularity.');

    if (reproductiveStatus != 'prefer_not_to_say') {
      buffer.write(' Status Reproduksi: $reproductiveStatusLabel.');
    }

    if (contraception != 'prefer_not_to_say') {
      buffer.write(' Kontrasepsi: $contraceptionLabel.');
    }

    final activeConditions = gynecologicalConditions
        .where((c) => c != 'none' && c != 'prefer_not_to_say')
        .map(conditionToLabel)
        .toList();
    if (activeConditions.isNotEmpty) {
      buffer.write(' Riwayat Ginekologis Pribadi: ${activeConditions.join(', ')}.');
    } else if (gynecologicalConditions.contains('none')) {
      buffer.write(' Riwayat Ginekologis Pribadi: Tidak ada riwayat dilaporkan.');
    }

    final activeFamily = familyMedicalHistory
        .where((f) => f != 'none' && f != 'prefer_not_to_say')
        .map(familyConditionToLabel)
        .toList();
    if (activeFamily.isNotEmpty) {
      buffer.write(' Riwayat Penyakit Keluarga: ${activeFamily.join(', ')}.');
    }

    if (menarcheAge != null) {
      buffer.write(' Usia Menstruasi Pertama (Menarche): $menarcheAge tahun.');
    }

    if (activityLevel != 'prefer_not_to_say') {
      buffer.write(' Aktivitas Fisik: $activityLevelLabel.');
    }

    return buffer.toString();
  }
}
