/// Drill type definitions for the TCCC state machine.
/// 
/// Uses Dart's sealed classes for exhaustive pattern matching,
/// ensuring all drill states and transitions are handled at compile time.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'drill_types.freezed.dart';
part 'drill_types.g.dart';

/// User role determines available features and drill steps.
enum UserRole {
  general,  // ASM-trained soldier
  medic,    // Combat medic / CLS
  trainer,  // Instructor (read-only in MVP)
}

/// Triage category per TCCC doctrine.
enum TriageCategory {
  p1,   // Immediate - life-threatening, needs immediate treatment
  p2,   // Urgent - serious, can wait short period  
  p3,   // Delayed - minor, can wait
  dead, // Deceased - no signs of life
}

extension TriageCategoryX on TriageCategory {
  String get displayName => switch (this) {
    TriageCategory.p1 => 'P1 - Immediate',
    TriageCategory.p2 => 'P2 - Urgent',
    TriageCategory.p3 => 'P3 - Delayed',
    TriageCategory.dead => 'Dead',
  };
  
  String get shortName => switch (this) {
    TriageCategory.p1 => 'P1',
    TriageCategory.p2 => 'P2',
    TriageCategory.p3 => 'P3',
    TriageCategory.dead => 'DEAD',
  };
  
  int get priority => switch (this) {
    TriageCategory.p1 => 1,
    TriageCategory.p2 => 2,
    TriageCategory.p3 => 3,
    TriageCategory.dead => 99,
  };
}

/// MARCH component identifier.
enum MarchComponent {
  m, // Massive bleeding
  a, // Airway
  r, // Respiratory
  c, // Circulation
  h, // Head/Hypothermia
}

extension MarchComponentX on MarchComponent {
  String get displayName => switch (this) {
    MarchComponent.m => 'Massive Bleeding',
    MarchComponent.a => 'Airway',
    MarchComponent.r => 'Respiratory',
    MarchComponent.c => 'Circulation',
    MarchComponent.h => 'Head/Hypothermia',
  };
}

/// Type of intervention that can be recorded.
enum InterventionType {
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

extension InterventionTypeX on InterventionType {
  String get displayName => switch (this) {
    InterventionType.tourniquet => 'Tourniquet',
    InterventionType.chestSeal => 'Chest Seal',
    InterventionType.needleDecompression => 'Needle Decompression',
    InterventionType.npa => 'Nasopharyngeal Airway',
    InterventionType.opa => 'Oropharyngeal Airway',
    InterventionType.recoveryPosition => 'Recovery Position',
    InterventionType.woundPacking => 'Wound Packing',
    InterventionType.pelvicBinder => 'Pelvic Binder',
    InterventionType.ivIo => 'IV/IO Access',
    InterventionType.analgesia => 'Analgesia',
    InterventionType.hypothermiaMgmt => 'Hypothermia Management',
  };
  
  bool get requiresMedic => switch (this) {
    InterventionType.needleDecompression => true,
    InterventionType.ivIo => true,
    InterventionType.analgesia => true,
    _ => false,
  };
  
  bool get isTimeCritical => switch (this) {
    InterventionType.tourniquet => true,
    _ => false,
  };
}

/// Node type in the drill definition JSON.
enum DrillNodeType {
  decision,
  instruction,
  action,
  checkpoint,
  triageAssignment,
  casualtySelection,
  singleSelect,
  multiSelect,
  casrepForm,
}

/// Represents a node in the drill flow.
@freezed
class DrillNode with _$DrillNode {
  const factory DrillNode({
    required String id,
    required DrillNodeType type,
    required String title,
    required String prompt,
    String? guidance,
    List<String>? warnings,
    List<String>? actions,
    List<DrillOption>? options,
    String? next,
    String? interventionType,
    String? marchComponent,
    String? category,
    bool? roleRequired,
    List<String>? fields,
  }) = _DrillNode;
  
  factory DrillNode.fromJson(Map<String, dynamic> json) => _$DrillNodeFromJson(json);
}

/// Option for decision nodes.
@freezed
class DrillOption with _$DrillOption {
  const factory DrillOption({
    required String label,
    required String next,
    String? value,
  }) = _DrillOption;
  
  factory DrillOption.fromJson(Map<String, dynamic> json) => _$DrillOptionFromJson(json);
}

/// A complete drill definition.
@freezed
class DrillDefinition with _$DrillDefinition {
  const factory DrillDefinition({
    required String id,
    required String name,
    String? description,
    String? marchComponent,
    String? roleRequired,
    required List<DrillNode> nodes,
  }) = _DrillDefinition;
  
  factory DrillDefinition.fromJson(Map<String, dynamic> json) => _$DrillDefinitionFromJson(json);
}

/// Complete drill definitions loaded from JSON.
@freezed
class DrillDefinitions with _$DrillDefinitions {
  const factory DrillDefinitions({
    required String version,
    required String doctrineSource,
    required String lastUpdated,
    required Map<String, DrillDefinition> drills,
    required Map<String, InterventionTypeDefinition> interventionTypes,
    required Map<String, TriageCategoryDefinition> triageCategories,
  }) = _DrillDefinitions;
  
  factory DrillDefinitions.fromJson(Map<String, dynamic> json) => _$DrillDefinitionsFromJson(json);
}

@freezed
class InterventionTypeDefinition with _$InterventionTypeDefinition {
  const factory InterventionTypeDefinition({
    required String name,
    required List<String> fields,
    @Default(false) bool timeCritical,
    String? roleRequired,
  }) = _InterventionTypeDefinition;
  
  factory InterventionTypeDefinition.fromJson(Map<String, dynamic> json) => 
      _$InterventionTypeDefinitionFromJson(json);
}

@freezed
class TriageCategoryDefinition with _$TriageCategoryDefinition {
  const factory TriageCategoryDefinition({
    required String name,
    required String color,
    String? description,
  }) = _TriageCategoryDefinition;
  
  factory TriageCategoryDefinition.fromJson(Map<String, dynamic> json) => 
      _$TriageCategoryDefinitionFromJson(json);
}
