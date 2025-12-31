# QUICK_REFERENCE.md
# TriageDrills - Claude Code Quick Reference

## 🚀 Session Startup (Run Every Time)

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
dart run tool/validate_drills.dart
dart run tool/doctrine_check.dart
```

## 📁 Key Files

| Need To... | Open This File |
|------------|----------------|
| Change drill content | `assets/drill_definitions.json` |
| Modify FSM logic | `lib/domain/drills/drill_engine.dart` |
| Add node types | `lib/domain/drills/drill_types.dart` |
| Change UI rendering | `lib/ui/screens/drill_screen.dart` |
| Update colours | `lib/ui/theme/app_theme.dart` |
| Add tests | `test/domain/drill_engine_test.dart` |

## 🔴 Never Do

- ❌ Hardcode drill text in Dart
- ❌ Invent medical procedures
- ❌ Add network calls to drill flow
- ❌ Skip running tests
- ❌ Ignore doctrine_check failures

## ✅ Always Do

- ✅ Check DOCTRINAL_ANALYSIS.md first
- ✅ Put all text in JSON
- ✅ Run tests after changes
- ✅ Add tests for new transitions
- ✅ Use UK English (haemorrhage)

## 🎨 Colour Reference

```dart
// Box types (Aide Memoire)
actionBox   = 0xFF0066CC  // Blue - steps to do
adviceBox   = 0xFFFFCC00  // Yellow - guidance
warningBox  = 0xFFCC0000  // Red - critical

// Triage
P1 = 0xFFFF0000  // Red - Immediate
P2 = 0xFFFFCC00  // Yellow - Urgent
P3 = 0xFF00CC00  // Green - Delayed
DEAD = 0xFF333333 // Black
```

## 📋 Node Types

| Type | UI | Required Fields |
|------|-----|-----------------|
| `decision` | 2+ buttons | `options[]` |
| `instruction` | Text + CONTINUE | `prompt` |
| `action` | Steps + DONE | `actions[]` |
| `checkpoint` | Summary + NEXT | `march_component` |
| `triage_assignment` | Category btn | `category` |
| `casrep_form` | Form fields | `fields[]` |

## 🧪 Test Pattern

```dart
test('describes the behaviour', () {
  var state = DrillState.initial(incidentId: 'test');
  state = engine.transition(state, SomeEvent());
  expect(state.currentNodeId, 'expected_node');
});
```

## 📞 Help

- **Doctrine unclear?** → Check DOCTRINAL_ANALYSIS.md
- **Architecture question?** → Check docs/ADR/
- **Missing content?** → Add `// TODO: [Reference needed]`
- **Test failure?** → Fix before continuing

## 🔗 Task Queue

Current Phase: **Phase 2 - Complete MARCH**

1. ⬜ Drill routing alignment
2. ⬜ Tourniquet conversion
3. ⬜ BLS integration
4. ⬜ Pain relief interrupt
5. ⬜ UI colour-coding
6. ⬜ MIST auto-fill
7. ⬜ Prone reminders
8. ⬜ Doc prompts
9. ⬜ Re-triage loop
10. ⬜ Shock assessment
