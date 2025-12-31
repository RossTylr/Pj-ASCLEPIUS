# TriageDrills

**Offline-first tactical casualty care triage application aligned to TCCC(UK) ASM doctrine.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

## Overview

TriageDrills provides deterministic, drill-driven triage and casualty-care guidance for UK military personnel. The application implements:

- **Master Drill** → **Drill 1–13** state machine progression
- **MARCH** assessment sequence (Massive haemorrhage, Airway, Respiration, Circulation, Head/Hypothermia)
- **CASREP + MIST(AT)** structured reporting for handover
- **Role-based UI**: General (ASM), Medic, Trainer modes

### Key Principles

- **Offline-first**: All core functionality works without network connectivity
- **Deterministic**: No AI/LLM; logic follows published doctrine exactly
- **Auditable**: All drill content in JSON, separable from code
- **Secure**: Local SQLite encryption; no PII in logs

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x |
| State Management | Riverpod |
| Database | Drift (SQLite) + SQLCipher |
| FSM Engine | Custom sealed-class state machine |
| Testing | flutter_test + integration_test |

## Project Structure

```
triage-drills/
├── README.md
├── LICENSE
├── docs/
│   ├── PRD.md                    # Product requirements
│   ├── doctrine/
│   │   └── asm_drills_source_notes.md
│   └── ADR/
│       ├── 0001-tech-stack.md
│       └── 0002-data-model.md
├── app/                          # Flutter application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── domain/
│   │   │   ├── drills/           # FSM engine + definitions
│   │   │   ├── models/           # Domain entities
│   │   │   └── services/         # Report building, export
│   │   ├── data/
│   │   │   ├── database/         # Drift DB + migrations
│   │   │   └── repositories/     # Data access layer
│   │   └── ui/
│   │       ├── screens/          # Screen widgets
│   │       ├── components/       # Reusable UI components
│   │       └── theme/            # Combat-optimised theme
│   └── test/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
└── assets/
    └── drill_definitions.json    # Doctrine content (JSON)
```

## Getting Started

### Prerequisites

- Flutter SDK 3.19+ ([installation guide](https://docs.flutter.dev/get-started/install))
- Dart SDK 3.3+
- Android Studio / Xcode (for device deployment)

### Setup

```bash
# Clone repository
git clone https://github.com/RossTylr/Pj-ASCLEPIUS.git
cd Pj-ASCLEPIUS/app

# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run on connected device/emulator
flutter run
```

### Running Tests

```bash
# Unit tests
flutter test

# Integration tests (requires device/emulator)
flutter test integration_test/

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Building for Release

```bash
# Android APK (for MDM distribution)
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

## Development

### Drill Content Updates

All drill content lives in `assets/drill_definitions.json`. To update:

1. Edit the JSON file (do not modify Dart code for content changes)
2. Run tests to validate state machine transitions
3. Bump version in `pubspec.yaml`
4. Create PR with doctrinal reference for review

### Adding New Drills

See `docs/doctrine/asm_drills_source_notes.md` for content guidelines.

### Architecture Decision Records

Significant technical decisions are documented in `docs/ADR/`.

## Security

- Local database encrypted with SQLCipher (AES-256)
- Encryption key stored in platform secure storage (Keychain/Keystore)
- No PII written to logs
- No network calls in core workflows

See `docs/ADR/0002-data-model.md` for data handling details.

## Deployment

### MDM Distribution

The application is designed for enterprise distribution via Mobile Device Management:

- **Android**: Signed APK distributed via MDM (VMware Workspace ONE, Intune, etc.)
- **iOS**: Enterprise-signed IPA via Apple Business Manager

See deployment documentation for MOD-specific procedures.

## Contributing

1. Create feature branch from `main`
2. Follow existing code style (enforced by `dart format`)
3. Add tests for new functionality
4. Update documentation if needed
5. Submit PR with clear description

## License

Proprietary - Ministry of Defence. See [LICENSE](LICENSE) for terms.

## References

- TCCC(UK) ASM Aide Memoire (Mar 25)
- TCCC(UK) ASM Trainer Manual v1.1 (May 25)
- BATLS Aide Memoire (2023)

---

**Version:** 0.1.0-dev  
**Last Updated:** 2025-01-01
