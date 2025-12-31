# Claude Code Instructions: TriageDrills MVP

## Project Context

You are building **TriageDrills**, an offline-first mobile application for UK military tactical casualty care. The app guides users through TCCC(UK) ASM drills using a deterministic finite state machine.

**Key Documents to Reference:**
- `docs/PRD.md` - Product requirements and user journeys
- `docs/ADR/0001-tech-stack.md` - Technology decisions
- `docs/ADR/0002-data-model.md` - Database schema
- `docs/doctrine/asm_drills_source_notes.md` - Medical drill content

---

## Tech Stack (Do Not Change)

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.19+ |
| Language | Dart 3.3+ |
| State Management | Riverpod 2.x |
| Database | Drift 2.x (SQLite) |
| Encryption | sqlcipher_flutter_libs (Phase 2) |
| Code Generation | freezed, json_serializable, drift_dev |

---

## Critical Constraints

### 1. OFFLINE-FIRST IS NON-NEGOTIABLE
- All core features MUST work without network
- Local SQLite is the single source of truth
- No API calls in MVP core workflows
- Test with airplane mode enabled

### 2. DETERMINISTIC LOGIC ONLY
- No AI/LLM features
- No probabilistic decision-making
- All drill flow defined in `drill_definitions.json`
- State machine transitions must be predictable and testable

### 3. CONTENT SEPARATION
- Medical drill content lives in `assets/drill_definitions.json`
- NEVER hardcode drill steps, prompts, or medical guidance in Dart code
- UI reads from JSON; logic routes based on node types
- This allows doctrine updates without code changes

### 4. DO NOT INVENT MEDICAL CONTENT
- Only implement what's in `drill_definitions.json`
- If information is missing, add `// TODO: [Reference needed]` placeholder
- Never guess medical procedures or sequences
- All content must trace to TCCC(UK) ASM doctrine

---

## Project Structure

```
app/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── domain/                      # Pure Dart, no Flutter imports
│   │   ├── drills/
│   │   │   ├── drill_types.dart     # Enums, sealed classes
│   │   │   └── drill_engine.dart    # FSM implementation
│   │   ├── models/
│   │   │   └── models.dart          # Domain entities (freezed)
│   │   └── services/
│   │       └── report_builder.dart  # CASREP/MIST generation
│   ├── data/                        # Persistence layer
│   │   ├── database/
│   │   │   └── database.dart        # Drift tables & queries
│   │   └── repositories/            # Data access abstractions
│   └── ui/                          # Flutter widgets
│       ├── theme/
│       │   └── app_theme.dart       # Combat-optimised theme
│       ├── screens/
│       └── components/
├── test/
│   └── domain/
│       └── drill_engine_test.dart   # Unit tests for FSM
└── assets/
    └── drill_definitions.json       # Drill content (JSON)
```

---

## Development Workflow

### Before Making Changes

```bash
# 1. Generate code (required after modifying freezed/drift files)
cd app
dart run build_runner build --delete-conflicting-outputs

# 2. Run tests
flutter test

# 3. Analyze
flutter analyze
```

### After Making Changes

```bash
# Re-run if you modified any .dart files with @freezed or @DriftDatabase
dart run build_runner build --delete-conflicting-outputs

# Always run tests before committing
flutter test
```

---

## Implementation Tasks (Priority Order)

### Phase 1: Core Infrastructure ✅ (Scaffolded)

- [x] Repository structure
- [x] Drill engine FSM
- [x] Drill definitions JSON (Master, D1-D13)
- [x] Domain models
- [x] Database schema
- [x] Basic UI screens
- [x] Unit tests for drill engine

### Phase 2: Complete Drill Flow

1. **Wire up drill_definitions.json loading**
   - File: `lib/ui/screens/drill_screen.dart`
   - Ensure `rootBundle.loadString()` works
   - Handle loading errors gracefully

2. **Implement all node types in UI**
   - `decision` - Two or more buttons (YES/NO, options)
   - `instruction` - Text + CONTINUE button
   - `action` - Steps list + DONE button + optional input capture
   - `checkpoint` - Summary + NEXT button (updates MARCH progress)
   - `triage_assignment` - Category button (P1/P2/P3/DEAD)
   - `casualty_selection` - List of triaged casualties
   - `single_select` / `multi_select` - Option chips
   - `casrep_form` - Form fields for CASREP

3. **Implement intervention recording**
   - When `action` node has `intervention_type`, capture:
     - Timestamp
     - Type-specific fields (limb for tourniquet, side for chest seal)
   - Store in `DrillContext.casualties[id].interventions`

4. **Implement casualty management**
   - Create casualty on first triage assignment
   - Track current casualty in context
   - Allow switching between casualties (Drill 1 flow)

### Phase 3: Data Persistence

1. **Connect Drift database**
   - Run `dart run build_runner build` to generate `database.g.dart`
   - Initialize database in `main.dart`
   - Provide via Riverpod

2. **Implement repositories**
   - `IncidentRepository` - CRUD for incidents
   - `CasualtyRepository` - CRUD for casualties
   - `AssessmentRepository` - Store MARCH snapshots
   - `InterventionRepository` - Store treatments

3. **Auto-save drill state**
   - Save to DB on every state transition
   - Restore on app relaunch
   - Handle app backgrounding

### Phase 4: Reporting

1. **CASREP generation (Drill 12)**
   - Collect form input
   - Build `CasrepData` object
   - Generate text summary
   - Export to JSON

2. **MIST(AT) generation (Drill 13)**
   - Aggregate casualty data
   - Build `MistData` object
   - Generate handover text
   - Export to JSON

3. **Handover screen**
   - Large-font display for field reading
   - Share/export functionality

### Phase 5: Polish

1. **Role-based UI**
   - Implement role selector persistence
   - Conditionally show medic-only fields
   - Hide advanced interventions for General role

2. **Incident history**
   - List past incidents
   - Resume incomplete incidents
   - View completed incident summaries

3. **Accessibility improvements**
   - Test with TalkBack/VoiceOver
   - Ensure 48dp+ touch targets
   - High contrast verification

---

## Drill Engine API Reference

### Events (send to engine)

```dart
// Decision answered
AnswerDecision(optionLabel: 'YES', nextNodeId: 'node_id')

// Instruction acknowledged
AcknowledgeInstruction()

// Action completed (with optional input)
CompleteAction(inputData: {'limb': 'left_arm', 'time_applied': timestamp})

// Triage category assigned
AssignTriageCategory(casualtyId: 'uuid', category: TriageCategory.p1)

// Casualty selected for treatment
SelectCasualty(casualtyId: 'uuid')

// Options selected
SelectOptions(selectedOptions: ['option1', 'option2'])

// CASREP submitted
SubmitCasrep(casrepData: {...})

// Jump to specific drill
JumpToDrill(drillId: 'drill_2', nodeId: 'drill_2_start')

// Restart from Master Drill
RestartIncident()
```

### State Access

```dart
final engine = DrillEngine(definitions: defs, userRole: UserRole.general);
final state = DrillState.initial(incidentId: uuid);

// Get current node
final node = engine.getCurrentNode(state);

// Transition
final newState = engine.transition(state, event);

// Check completion
if (newState.isComplete) { ... }

// Access context
state.context.casualties        // Map of casualties
state.context.marchStatus       // Map of MARCH completion
state.context.currentCasualtyId // Active casualty
state.context.casrepData        // CASREP if submitted
```

---

## Testing Requirements

### Unit Tests (Required)

Every drill engine change must have tests:

```dart
test('describes the behaviour', () {
  var state = DrillState.initial(incidentId: 'test');
  state = engine.transition(state, SomeEvent());
  expect(state.currentNodeId, 'expected_node');
});
```

Minimum coverage:
- All node type transitions
- MARCH completion tracking
- Triage category assignment
- Error states (invalid transitions)

### Integration Tests (Phase 2+)

- Full drill flow end-to-end
- Database persistence across restart
- Export functionality

---

## UI Guidelines

### Combat-Friendly Design

```dart
// Button sizes (from app_theme.dart)
minTouchTarget: 56.0    // Minimum
largeButtonHeight: 64.0 // Standard
xlButtonHeight: 80.0    // Critical actions

// Colours
AppTheme.primaryAccent  // Green - positive actions
AppTheme.danger         // Red - critical/warnings
AppTheme.warning        // Orange - caution
AppTheme.info           // Blue - information

// Triage colours
AppTheme.triageP1       // Red
AppTheme.triageP2       // Orange
AppTheme.triageP3       // Green
AppTheme.triageDead     // Grey
```

### Do's and Don'ts

✅ DO:
- Use `LargeActionButton` for all primary actions
- Show warnings in `_WarningCard` component
- Display action steps in numbered list
- Keep one decision per screen
- Use high contrast (white on dark)

❌ DON'T:
- Use small buttons or links
- Require precise tapping
- Show walls of text
- Use light backgrounds
- Require keyboard input where avoidable

---

## Common Commands

```bash
# Development
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run

# Testing
flutter test
flutter test --coverage
flutter test test/domain/drill_engine_test.dart

# Analysis
flutter analyze
dart format lib/ test/

# Building
flutter build apk --release
flutter build ios --release --no-codesign
```

---

## Guardrails (Include in Every Task)

When implementing features, always:

1. **Do not invent medical steps** - Only implement what's in `drill_definitions.json`
2. **Keep content separate from code** - Text/prompts in JSON, not Dart
3. **Add tests for every transition** - No untested state machine changes
4. **Maintain offline capability** - No network dependencies in core flow
5. **Use UK English** - "haemorrhage" not "hemorrhage"
6. **Add TODO markers** - For missing doctrine references, not guesses

---

## Example Task Prompt

When asking Claude to implement a feature, use this format:

```
## Task: [Feature Name]

### Context
[Brief description of what exists and what's needed]

### Requirements
- [ ] Requirement 1
- [ ] Requirement 2

### Files to Modify
- `lib/path/to/file.dart`

### Acceptance Criteria
- Given [precondition], when [action], then [result]

### Guardrails
- Do not invent medical steps not in drill_definitions.json
- Keep text content in JSON, not hardcoded
- Add unit tests for new transitions
- Maintain offline-first capability
```

---

## Reference: Drill Node Types

| Type | Purpose | UI Component |
|------|---------|--------------|
| `decision` | Yes/No or multi-option choice | 2+ `LargeActionButton` |
| `instruction` | Information to read | Text + CONTINUE button |
| `action` | Steps to perform | Numbered list + DONE button |
| `checkpoint` | MARCH completion marker | Summary + NEXT button |
| `triage_assignment` | Assign P1/P2/P3/DEAD | Category button |
| `casualty_selection` | Pick casualty to treat | List with tap selection |
| `single_select` | Choose one option | Radio-style chips |
| `multi_select` | Choose multiple options | Checkbox-style chips |
| `casrep_form` | CASREP data entry | Form fields |

---

## Contact & Escalation

If you encounter:
- **Missing doctrine content** → Add TODO, do not guess
- **Ambiguous requirements** → Check PRD.md, then ask
- **Security concerns** → Flag immediately, do not implement
- **Architectural decisions** → Document in `docs/ADR/`

---

*Last updated: 2025-01-01*
*Doctrine version: TCCC(UK) ASM Mar 25 / Trainer Manual v1.1 May 25*
