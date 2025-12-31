/// Domain models for the triage application.
/// 
/// These models represent the core business entities and are independent
/// of the database layer.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// Sync status for offline-first data.
enum SyncStatus {
  pending,   // Created/modified locally
  synced,    // Confirmed synced with server
  conflict,  // Sync conflict detected
}

/// An incident represents a single triage event.
@freezed
class Incident with _$Incident {
  const factory Incident({
    required String id,
    required DateTime createdAt,
    String? gridRef,
    @Default(false) bool underEffectiveEnemyFire,
    String? notes,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Incident;
  
  factory Incident.fromJson(Map<String, dynamic> json) => _$IncidentFromJson(json);
}

/// Triage category per TCCC doctrine.
enum CasualtyTriageCategory {
  @JsonValue('P1')
  p1,
  @JsonValue('P2')
  p2,
  @JsonValue('P3')
  p3,
  @JsonValue('DEAD')
  dead,
}

extension CasualtyTriageCategoryX on CasualtyTriageCategory {
  String get displayName => switch (this) {
    CasualtyTriageCategory.p1 => 'P1 - Immediate',
    CasualtyTriageCategory.p2 => 'P2 - Urgent',
    CasualtyTriageCategory.p3 => 'P3 - Delayed',
    CasualtyTriageCategory.dead => 'Dead',
  };
}

/// Age classification for casualties.
enum AgeClass {
  adult,
  child,
}

/// A casualty within an incident.
@freezed
class Casualty with _$Casualty {
  const factory Casualty({
    required String id,
    required String incidentId,
    String? zapNumber,
    required CasualtyTriageCategory triageCategory,
    AgeClass? ageClass,
    DateTime? timeOfWounding,
    String? mechanism,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Casualty;
  
  factory Casualty.fromJson(Map<String, dynamic> json) => _$CasualtyFromJson(json);
}

/// MARCH assessment component values.
@freezed
class MarchAssessment with _$MarchAssessment {
  const factory MarchAssessment({
    // Massive bleeding
    bool? bleedingControlled,
    List<String>? tourniquetSites,
    
    // Airway
    String? airwayStatus,
    String? airwayIntervention,
    
    // Respiratory
    String? respiratoryStatus,
    int? respiratoryRate,
    String? chestInjury,
    
    // Circulation
    String? circulationStatus,
    int? pulseRate,
    String? capillaryRefill,
    bool? shockPresent,
    
    // Head/Hypothermia
    String? avpu,
    int? gcsScore,
    String? pupils,
    bool? hypothermiaPrevention,
  }) = _MarchAssessment;
  
  factory MarchAssessment.fromJson(Map<String, dynamic> json) => _$MarchAssessmentFromJson(json);
}

/// A snapshot of assessment at a point in time.
@freezed
class AssessmentSnapshot with _$AssessmentSnapshot {
  const factory AssessmentSnapshot({
    required String id,
    required String casualtyId,
    required DateTime timestamp,
    MarchAssessment? marchAssessment,
    String? notes,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _AssessmentSnapshot;
  
  factory AssessmentSnapshot.fromJson(Map<String, dynamic> json) => _$AssessmentSnapshotFromJson(json);
}

/// Type of intervention performed.
enum InterventionTypeEnum {
  tourniquet,
  chestSeal,
  needleDecompression,
  npa,
  opa,
  recoveryPosition,
  woundPacking,
  pelvicBinder,
  ivIo,
  analgesia,
  hypothermiaMgmt,
}

/// An intervention performed on a casualty.
@freezed
class Intervention with _$Intervention {
  const factory Intervention({
    required String id,
    required String casualtyId,
    required DateTime timestamp,
    required InterventionTypeEnum type,
    required Map<String, dynamic> details,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Intervention;
  
  factory Intervention.fromJson(Map<String, dynamic> json) => _$InterventionFromJson(json);
}

/// Evacuation request and CASREP data.
@freezed
class Evacuation with _$Evacuation {
  const factory Evacuation({
    required String id,
    required String incidentId,
    required CasrepData casrepData,
    DateTime? sentAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Evacuation;
  
  factory Evacuation.fromJson(Map<String, dynamic> json) => _$EvacuationFromJson(json);
}

/// CASREP structured data (Drill 12).
@freezed
class CasrepData with _$CasrepData {
  const factory CasrepData({
    String? callsign,
    String? gridRef,
    required int casualtyCount,
    @Default(0) int p1Count,
    @Default(0) int p2Count,
    @Default(0) int p3Count,
    @Default(false) bool medevacRequired,
    String? urgency,
    String? evacType,
    String? eta,
    String? specialEquipment,
    @Default([]) List<String> lifeThreats,
    String? notes,
  }) = _CasrepData;
  
  factory CasrepData.fromJson(Map<String, dynamic> json) => _$CasrepDataFromJson(json);
}

/// MIST(AT) handover data.
@freezed
class MistData with _$MistData {
  const factory MistData({
    required String casualtyId,
    
    // M - Mechanism
    String? mechanism,
    
    // I - Injury/Illness
    String? injuries,
    
    // S - Signs (MARCH)
    MarchAssessment? signs,
    
    // T - Treatment
    List<Intervention>? treatments,
    
    // A - Age
    AgeClass? age,
    
    // T - Time
    DateTime? timeOfWounding,
    
    // Additional
    String? zapNumber,
    CasualtyTriageCategory? triageCategory,
  }) = _MistData;
  
  factory MistData.fromJson(Map<String, dynamic> json) => _$MistDataFromJson(json);
}

/// Export log entry.
@freezed
class ExportLog with _$ExportLog {
  const factory ExportLog({
    required String id,
    required String casualtyId,
    required DateTime exportedAt,
    required String format, // 'json', 'pdf', 'screen'
    required String hash,
  }) = _ExportLog;
  
  factory ExportLog.fromJson(Map<String, dynamic> json) => _$ExportLogFromJson(json);
}
