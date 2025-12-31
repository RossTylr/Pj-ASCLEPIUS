/// Drift Database Schema
/// 
/// Defines the SQLite database schema using Drift ORM.
/// Supports SQLCipher encryption when available.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

/// Incidents table - represents a triage event.
class Incidents extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  TextColumn get gridRef => text().nullable()();
  BoolColumn get underEffectiveEnemyFire => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Casualties table - individuals within an incident.
class Casualties extends Table {
  TextColumn get id => text()();
  TextColumn get incidentId => text().references(Incidents, #id)();
  TextColumn get zapNumber => text().nullable()();
  TextColumn get triageCategory => text()(); // P1, P2, P3, DEAD
  TextColumn get ageClass => text().nullable()(); // adult, child
  IntColumn get timeOfWounding => integer().nullable()();
  TextColumn get mechanism => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Assessment snapshots - point-in-time MARCH assessments.
class AssessmentSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get casualtyId => text().references(Casualties, #id)();
  IntColumn get timestamp => integer()();
  TextColumn get mMassiveBleeding => text().nullable()(); // JSON
  TextColumn get aAirway => text().nullable()(); // JSON
  TextColumn get rRespiratory => text().nullable()(); // JSON
  TextColumn get cCirculation => text().nullable()(); // JSON
  TextColumn get hHeadHypothermia => text().nullable()(); // JSON
  IntColumn get gcsScore => integer().nullable()();
  TextColumn get avpu => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Interventions table - treatments performed.
class Interventions extends Table {
  TextColumn get id => text()();
  TextColumn get casualtyId => text().references(Casualties, #id)();
  IntColumn get timestamp => integer()();
  TextColumn get type => text()(); // tourniquet, chest_seal, etc.
  TextColumn get details => text()(); // JSON
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Evacuations table - CASREP data.
class Evacuations extends Table {
  TextColumn get id => text()();
  TextColumn get incidentId => text().references(Incidents, #id)();
  TextColumn get casrepJson => text()(); // Full CASREP as JSON
  IntColumn get sentAt => integer().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Export logs - record of data exports.
class ExportLogs extends Table {
  TextColumn get id => text()();
  TextColumn get casualtyId => text().references(Casualties, #id)();
  IntColumn get exportedAt => integer()();
  TextColumn get format => text()(); // json, pdf, screen
  TextColumn get hash => text()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Drift database definition.
@DriftDatabase(tables: [
  Incidents,
  Casualties,
  AssessmentSnapshots,
  Interventions,
  Evacuations,
  ExportLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  /// Database with custom executor (for testing).
  AppDatabase.forTesting(super.e);
  
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future migrations go here
    },
  );
  
  // --- Incident Operations ---
  
  Future<int> insertIncident(IncidentsCompanion incident) {
    return into(incidents).insert(incident);
  }
  
  Future<Incident?> getIncident(String id) {
    return (select(incidents)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
  
  Stream<List<Incident>> watchAllIncidents() {
    return (select(incidents)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
  }
  
  Future<bool> updateIncident(IncidentsCompanion incident) {
    return update(incidents).replace(incident);
  }
  
  // --- Casualty Operations ---
  
  Future<int> insertCasualty(CasualtiesCompanion casualty) {
    return into(casualties).insert(casualty);
  }
  
  Future<Casualty?> getCasualty(String id) {
    return (select(casualties)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
  
  Stream<List<Casualty>> watchCasualtiesForIncident(String incidentId) {
    return (select(casualties)
      ..where((t) => t.incidentId.equals(incidentId)))
      .watch();
  }
  
  Future<List<Casualty>> getCasualtiesForIncident(String incidentId) {
    return (select(casualties)
      ..where((t) => t.incidentId.equals(incidentId)))
      .get();
  }
  
  Future<bool> updateCasualty(CasualtiesCompanion casualty) {
    return update(casualties).replace(casualty);
  }
  
  // --- Assessment Operations ---
  
  Future<int> insertAssessment(AssessmentSnapshotsCompanion assessment) {
    return into(assessmentSnapshots).insert(assessment);
  }
  
  Stream<List<AssessmentSnapshot>> watchAssessmentsForCasualty(String casualtyId) {
    return (select(assessmentSnapshots)
      ..where((t) => t.casualtyId.equals(casualtyId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
      .watch();
  }
  
  Future<List<AssessmentSnapshot>> getAssessmentsForCasualty(String casualtyId) {
    return (select(assessmentSnapshots)
      ..where((t) => t.casualtyId.equals(casualtyId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
      .get();
  }
  
  // --- Intervention Operations ---
  
  Future<int> insertIntervention(InterventionsCompanion intervention) {
    return into(interventions).insert(intervention);
  }
  
  Stream<List<Intervention>> watchInterventionsForCasualty(String casualtyId) {
    return (select(interventions)
      ..where((t) => t.casualtyId.equals(casualtyId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
      .watch();
  }
  
  Future<List<Intervention>> getInterventionsForCasualty(String casualtyId) {
    return (select(interventions)
      ..where((t) => t.casualtyId.equals(casualtyId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
      .get();
  }
  
  // --- Evacuation Operations ---
  
  Future<int> insertEvacuation(EvacuationsCompanion evacuation) {
    return into(evacuations).insert(evacuation);
  }
  
  Future<Evacuation?> getEvacuationForIncident(String incidentId) {
    return (select(evacuations)
      ..where((t) => t.incidentId.equals(incidentId)))
      .getSingleOrNull();
  }
  
  // --- Export Log Operations ---
  
  Future<int> insertExportLog(ExportLogsCompanion log) {
    return into(exportLogs).insert(log);
  }
  
  Future<List<ExportLog>> getExportLogsForCasualty(String casualtyId) {
    return (select(exportLogs)
      ..where((t) => t.casualtyId.equals(casualtyId))
      ..orderBy([(t) => OrderingTerm.desc(t.exportedAt)]))
      .get();
  }
  
  // --- Bulk Operations ---
  
  Future<void> deleteIncidentAndRelated(String incidentId) async {
    await transaction(() async {
      // Get all casualties for this incident
      final casualtyList = await getCasualtiesForIncident(incidentId);
      final casualtyIds = casualtyList.map((c) => c.id).toList();
      
      // Delete export logs
      for (final cId in casualtyIds) {
        await (delete(exportLogs)..where((t) => t.casualtyId.equals(cId))).go();
      }
      
      // Delete interventions
      for (final cId in casualtyIds) {
        await (delete(interventions)..where((t) => t.casualtyId.equals(cId))).go();
      }
      
      // Delete assessments
      for (final cId in casualtyIds) {
        await (delete(assessmentSnapshots)..where((t) => t.casualtyId.equals(cId))).go();
      }
      
      // Delete evacuations
      await (delete(evacuations)..where((t) => t.incidentId.equals(incidentId))).go();
      
      // Delete casualties
      await (delete(casualties)..where((t) => t.incidentId.equals(incidentId))).go();
      
      // Delete incident
      await (delete(incidents)..where((t) => t.id.equals(incidentId))).go();
    });
  }
}

/// Opens the database connection.
/// 
/// In production, this should use SQLCipher for encryption.
/// For MVP, we use standard SQLite with a note about encryption.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'triage_drills.db'));
    
    // TODO: Add SQLCipher encryption in production
    // For now, using standard SQLite
    // To add encryption:
    // 1. Add sqlcipher_flutter_libs dependency
    // 2. Use open.overrideFor() to configure SQLCipher
    // 3. Store encryption key in flutter_secure_storage
    
    return NativeDatabase.createInBackground(file);
  });
}
