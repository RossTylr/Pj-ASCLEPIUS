# ADR-0001: Technology Stack Selection

**Status:** Accepted  
**Date:** 2025-01-01  
**Deciders:** Engineering Team  

## Context

We need to select a technology stack for an offline-first, cross-platform mobile application that:

1. Operates fully offline in DDIL (Denied, Disrupted, Intermittent, Low-bandwidth) environments
2. Implements a deterministic state machine for medical drill progression
3. Stores sensitive casualty data with encryption at rest
4. Deploys via MDM to iOS and Android devices
5. Supports future sync capabilities without architectural changes

## Decision

We will use **Flutter + Drift + Custom FSM** architecture:

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Flutter | 3.19+ |
| Language | Dart | 3.3+ |
| State Management | Riverpod | 2.x |
| Database | Drift (SQLite) | 2.x |
| Encryption | sqlcipher_flutter_libs | Latest |
| FSM Engine | Custom sealed classes | N/A |
| Testing | flutter_test, integration_test | Built-in |

## Alternatives Considered

### Option A: React Native + XState + WatermelonDB

**Pros:**
- Large ecosystem and talent pool
- XState provides formal statechart semantics with visualisation tools
- Strong TypeScript support

**Cons:**
- Two abstraction layers (XState + WatermelonDB) add complexity
- WatermelonDB encryption requires additional configuration
- JavaScript runtime overhead in performance-critical paths
- Bridge architecture can cause subtle issues

**Decision:** Rejected due to complexity and performance concerns.

### Option B: Flutter + Bloc + Hive (NoSQL)

**Pros:**
- Hive has built-in AES encryption
- Simple key-value storage model
- Fast read/write performance

**Cons:**
- NoSQL less suited to relational queries (casualty → assessments → interventions)
- Migration story weaker than SQL
- Query capabilities limited for complex reporting

**Decision:** Rejected due to data model requirements.

### Option C: Kotlin Multiplatform Mobile (KMM)

**Pros:**
- True native performance
- Shared business logic across platforms
- Strong typing with Kotlin

**Cons:**
- Immature tooling
- Two UI codebases required
- Slower iteration speed
- Overkill for MVP timeline

**Decision:** Rejected due to timeline and complexity.

### Option D: Progressive Web App (PWA)

**Pros:**
- No app store requirements
- Instant updates
- Works on any device with browser

**Cons:**
- iOS PWA limitations (storage quotas, no push notifications)
- Not truly native experience
- MDM distribution challenges
- Service worker reliability concerns

**Decision:** Rejected due to iOS limitations and MDM requirements.

## Rationale for Flutter + Drift

### 1. Type Safety & FSM Implementation

Dart's sealed classes with pattern matching provide compile-time safety for state machine transitions:

```dart
sealed class DrillState {
  String get nodeId;
}

DrillState transition(DrillState current, DrillEvent event) {
  return switch ((current, event)) {
    (MasterDrillState s, UnderFireAnswered e) when e.answer 
      => UnderFireActionsState(context: s.context),
    // Compiler enforces exhaustive handling
  };
}
```

### 2. Offline-First Excellence

Flutter + SQLite is the gold standard for offline mobile:
- Single source of truth on device
- Drift provides compile-time SQL verification
- Migrations are first-class citizens
- Repository pattern enables clean sync layer addition

### 3. Encryption

sqlcipher_flutter_libs provides:
- AES-256 encryption at rest
- Key storage via flutter_secure_storage (iOS Keychain / Android Keystore)
- Transparent to Drift queries
- Battle-tested in production apps

### 4. Combat UX Capability

Flutter's advantages for high-stress UI:
- 60fps rendering for responsive feel
- Custom widgets for glove-friendly targets
- Theme system for high-contrast modes
- Hot reload accelerates UX iteration

### 5. Enterprise Deployment

- Standard APK/IPA output
- No special runtime requirements
- Compatible with all major MDM solutions
- No dependency on external services

## Consequences

### Positive

- Single codebase for iOS and Android
- Compile-time safety catches errors early
- Strong offline capabilities out of the box
- Clear path to sync layer in Phase 2
- Excellent developer tooling (hot reload, DevTools)

### Negative

- Dart has smaller talent pool than JavaScript/Kotlin
- Some native features require platform channels
- App size larger than pure native (~15-20MB base)
- iOS requires macOS for building

### Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Dart talent scarcity | Training program; Dart is easy to learn for Java/JS devs |
| SQLCipher build issues | Pin to stable version; document build process |
| Large app size | Enable tree-shaking; review dependencies quarterly |

## Implementation Notes

### Project Structure

```
app/lib/
├── domain/          # Pure Dart, no Flutter imports
│   ├── drills/      # FSM engine
│   ├── models/      # Domain entities
│   └── services/    # Business logic
├── data/            # Drift DB, repositories
└── ui/              # Flutter widgets
```

### Key Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  sqlcipher_flutter_libs: ^0.1.0
  flutter_secure_storage: ^9.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

dev_dependencies:
  build_runner: ^2.4.0
  drift_dev: ^2.14.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

## References

- [Flutter Documentation](https://docs.flutter.dev)
- [Drift Documentation](https://drift.simonbinder.eu)
- [SQLCipher](https://www.zetetic.net/sqlcipher/)
- [Riverpod Documentation](https://riverpod.dev)
