# ADR-0002: Data Model Design

**Status:** Accepted  
**Date:** 2025-01-01  
**Deciders:** Engineering Team  

## Context

The application must:

1. Store casualty data offline with full persistence
2. Support MIST(AT) structured reporting with time-stamped reassessments
3. Enable CASREP generation per Drill 12 requirements
4. Maintain audit trail of all actions
5. Be extensible for Phase 2 sync capabilities

## Decision

We will implement a relational data model using Drift (SQLite) with the following schema:

### Entity Relationship Diagram

```
┌─────────────────────┐
│      Incident       │
├─────────────────────┤
│ id: TEXT (PK, UUID) │
│ created_at: INTEGER │
│ grid_ref: TEXT?     │
│ under_fire: INTEGER │
│ notes: TEXT?        │
│ sync_status: TEXT   │
└──────────┬──────────┘
           │
           │ 1:N
           ▼
┌─────────────────────┐     ┌─────────────────────────┐
│      Casualty       │     │   AssessmentSnapshot    │
├─────────────────────┤     ├─────────────────────────┤
│ id: TEXT (PK, UUID) │◀───▶│ id: TEXT (PK, UUID)     │
│ incident_id: TEXT   │ 1:N │ casualty_id: TEXT (FK)  │
│ zap_number: TEXT?   │     │ timestamp: INTEGER      │
│ triage_category:TEXT│     │ m_massive_bleeding: TEXT│
│ age_class: TEXT?    │     │ a_airway: TEXT          │
│ time_of_wounding:INT│     │ r_respiratory: TEXT     │
│ mechanism: TEXT?    │     │ c_circulation: TEXT     │
│ sync_status: TEXT   │     │ h_head_hypothermia: TEXT│
└──────────┬──────────┘     │ gcs_score: INTEGER?     │
           │                │ avpu: TEXT?             │
           │ 1:N            │ notes: TEXT?            │
           ▼                │ sync_status: TEXT       │
┌─────────────────────┐     └─────────────────────────┘
│    Intervention     │
├─────────────────────┤
│ id: TEXT (PK, UUID) │
│ casualty_id: TEXT   │
│ timestamp: INTEGER  │
│ type: TEXT          │
│ details: TEXT (JSON)│
│ sync_status: TEXT   │
└─────────────────────┘

┌─────────────────────┐     ┌─────────────────────────┐
│     Evacuation      │     │      ExportLog          │
├─────────────────────┤     ├─────────────────────────┤
│ id: TEXT (PK, UUID) │     │ id: TEXT (PK, UUID)     │
│ incident_id: TEXT   │     │ casualty_id: TEXT (FK)  │
│ casrep_json: TEXT   │     │ exported_at: INTEGER    │
│ sent_at: INTEGER?   │     │ format: TEXT            │
│ sync_status: TEXT   │     │ hash: TEXT              │
└─────────────────────┘     └─────────────────────────┘
```

### Table Definitions

#### Incident

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PK | UUID v4 |
| created_at | INTEGER | NOT NULL | Unix timestamp (ms) |
| grid_ref | TEXT | NULLABLE | MGRS or lat/long |
| under_fire | INTEGER | NOT NULL, DEFAULT 0 | Boolean: under effective enemy fire |
| notes | TEXT | NULLABLE | Free text notes |
| sync_status | TEXT | NOT NULL, DEFAULT 'pending' | pending/synced/conflict |

#### Casualty

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PK | UUID v4 |
| incident_id | TEXT | FK, NOT NULL | Reference to Incident |
| zap_number | TEXT | NULLABLE | Military ID |
| triage_category | TEXT | NOT NULL | P1/P2/P3/DEAD |
| age_class | TEXT | NULLABLE | adult/child |
| time_of_wounding | INTEGER | NULLABLE | Unix timestamp |
| mechanism | TEXT | NULLABLE | Mechanism of injury |
| sync_status | TEXT | NOT NULL, DEFAULT 'pending' | Sync state |

#### AssessmentSnapshot

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PK | UUID v4 |
| casualty_id | TEXT | FK, NOT NULL | Reference to Casualty |
| timestamp | INTEGER | NOT NULL | When assessment taken |
| m_massive_bleeding | TEXT | NULLABLE | JSON: bleeding status, tourniquet times |
| a_airway | TEXT | NULLABLE | JSON: airway status, interventions |
| r_respiratory | TEXT | NULLABLE | JSON: respiratory assessment |
| c_circulation | TEXT | NULLABLE | JSON: circulation/shock status |
| h_head_hypothermia | TEXT | NULLABLE | JSON: head injury, temp management |
| gcs_score | INTEGER | NULLABLE | Glasgow Coma Scale (3-15) |
| avpu | TEXT | NULLABLE | Alert/Voice/Pain/Unresponsive |
| notes | TEXT | NULLABLE | Free text observations |
| sync_status | TEXT | NOT NULL, DEFAULT 'pending' | Sync state |

#### Intervention

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PK | UUID v4 |
| casualty_id | TEXT | FK, NOT NULL | Reference to Casualty |
| timestamp | INTEGER | NOT NULL | When intervention performed |
| type | TEXT | NOT NULL | Intervention type code |
| details | TEXT | NOT NULL | JSON with intervention-specific data |
| sync_status | TEXT | NOT NULL, DEFAULT 'pending' | Sync state |

**Intervention Types:**

| Type Code | Details Schema |
|-----------|----------------|
| TOURNIQUET | `{limb, time_applied, converted_to?}` |
| CHEST_SEAL | `{side, type, time_applied}` |
| NEEDLE_DECOMPRESSION | `{side, time_performed}` |
| NPA | `{size, time_inserted}` |
| OPA | `{size, time_inserted}` |
| RECOVERY_POSITION | `{position, time}` |
| WOUND_PACKING | `{location, time}` |
| PELVIC_BINDER | `{time_applied}` |
| IV_IO | `{site, type, fluid, volume}` |
| ANALGESIA | `{drug, dose, route, time}` |
| HYPOTHERMIA_MGMT | `{interventions[]}` |

#### Evacuation

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PK | UUID v4 |
| incident_id | TEXT | FK, NOT NULL | Reference to Incident |
| casrep_json | TEXT | NOT NULL | Full CASREP as JSON |
| sent_at | INTEGER | NULLABLE | When transmitted (if applicable) |
| sync_status | TEXT | NOT NULL, DEFAULT 'pending' | Sync state |

#### ExportLog

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PK | UUID v4 |
| casualty_id | TEXT | FK, NOT NULL | Reference to Casualty |
| exported_at | INTEGER | NOT NULL | Export timestamp |
| format | TEXT | NOT NULL | json/pdf/screen |
| hash | TEXT | NOT NULL | SHA-256 of exported content |

### Indexes

```sql
CREATE INDEX idx_casualty_incident ON casualties(incident_id);
CREATE INDEX idx_assessment_casualty ON assessment_snapshots(casualty_id);
CREATE INDEX idx_intervention_casualty ON interventions(casualty_id);
CREATE INDEX idx_evacuation_incident ON evacuations(incident_id);
CREATE INDEX idx_sync_status ON casualties(sync_status);
```

## Rationale

### 1. UUID Primary Keys

Using UUIDs (v4) instead of auto-increment integers because:
- Enables offline record creation without ID conflicts
- Simplifies future sync implementation
- No need for sequence coordination across devices

### 2. JSON for Structured Fields

MARCH assessment components and intervention details stored as JSON:
- Flexibility for varying data structures per intervention type
- Avoids excessive normalisation for MVP
- Drift supports JSON columns with type conversion

### 3. Sync Status Column

Every table includes `sync_status` to support Phase 2:
- `pending`: Created/modified locally, not yet synced
- `synced`: Confirmed synced with server
- `conflict`: Sync conflict detected, requires resolution

### 4. Timestamps as Unix Integers

All timestamps stored as Unix milliseconds:
- Timezone agnostic
- Efficient indexing and comparison
- Consistent across platforms

### 5. Soft References (No CASCADE)

Foreign keys exist logically but without CASCADE DELETE:
- Prevents accidental data loss
- Audit trail preserved
- Repository layer handles referential integrity

## MIST(AT) Mapping

The data model maps directly to MIST(AT) reporting:

| MIST(AT) Field | Data Source |
|----------------|-------------|
| **M**echanism | `casualty.mechanism` |
| **I**njury | Latest `assessment_snapshot` + aggregated `interventions` |
| **S**igns | Latest `assessment_snapshot.{m,a,r,c,h}_*`, `gcs_score`, `avpu` |
| **T**reatment | All `interventions` for casualty |
| **A**ge | `casualty.age_class` |
| **T**ime | `casualty.time_of_wounding` |

## CASREP Mapping

CASREP (Drill 12) aggregates from:

| CASREP Field | Data Source |
|--------------|-------------|
| Number of casualties | COUNT of `casualties` per `incident` |
| Grid reference | `incident.grid_ref` |
| Priorities | GROUP BY `casualty.triage_category` |
| Life threats | Derived from latest `assessment_snapshots` |
| Evac details | User input at Drill 12 (stored in `evacuation.casrep_json`) |

## Encryption

All tables encrypted at database level via SQLCipher:

```dart
// Key derivation
final key = await _secureStorage.read(key: 'db_key');
if (key == null) {
  final newKey = _generateSecureKey(); // 256-bit random
  await _secureStorage.write(key: 'db_key', value: newKey);
}

// Database open with encryption
NativeDatabase.createInBackground(
  dbFile,
  setup: (db) => db.execute("PRAGMA key = '$key'"),
);
```

## Migration Strategy

Drift handles migrations via versioned schema:

```dart
@DriftDatabase(tables: [...])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Future migrations here
    },
  );
}
```

## Consequences

### Positive

- Clear relational model for casualty management
- Supports complex queries for reporting
- Migration path well-defined
- Sync-ready with status columns
- Full audit trail via timestamps

### Negative

- JSON columns require careful schema evolution
- More complex than NoSQL for simple cases
- Requires code generation (build_runner)

### Trade-offs

- Chose JSON for flexibility over strict normalisation
- Chose SQLite over NoSQL for query power
- Chose UUIDs over integers for sync preparation

## References

- [Drift Documentation](https://drift.simonbinder.eu)
- [SQLCipher Specification](https://www.zetetic.net/sqlcipher/design/)
- TCCC(UK) ASM Trainer Manual - MIST(AT) format
- TCCC(UK) ASM Aide Memoire - CASREP format
