# Product Requirements Document: TriageDrills

**Version:** 1.0  
**Status:** Draft  
**Last Updated:** 2025-01-01

---

## 1. Product Overview

### 1.1 Purpose

TriageDrills provides offline, deterministic, drill-driven triage and casualty-care guidance aligned to **TCCC(UK) ASM** doctrine. The application guides users through the Master Drill and Drills 1–13, supporting structured **CASREP + MIST(AT)** capture for handover and future casualty tracking.

### 1.2 Target Users

| Persona | Description | Primary Needs |
|---------|-------------|---------------|
| **General Service (ASM)** | Soldiers with TCCC-ASM training | Fast, minimal-input guidance; "do next" prompts; offline operation |
| **Combat Medic** | Advanced medical personnel | Richer documentation, repeated reassessment, structured MIST(AT), advanced intervention prompts |
| **Trainer** | Instructors conducting drills | Practice scaffolding, scenario scripts, SMMLE teaching method support |

### 1.3 Problem Statement

In high-stress tactical environments, ASM-level procedures must be executed rapidly and consistently. Reliance on memory and paper aide-mémoires risks:

- Omission of critical steps
- Sequencing errors
- Incomplete handover information

The application must reduce cognitive load by providing a deterministic, doctrine-aligned flow and structured handover artefacts, while remaining **fully usable offline**.

---

## 2. Product Goals (MVP)

1. **Guided triage & care flow** starting at Master Drill, supporting multiple casualty triage (Drill 1) and single-casualty MARCH progression (Drills 2–11)

2. **Role-layered UX**: Default "General" mode, optional "Medic" mode with additional fields, and "Trainer" area (read-only in MVP)

3. **Structured reporting**: Capture and export Final CASREP fields and MIST(AT) data

4. **Offline-first and resilient**: No network dependency for core workflows; local persistence; secure storage

5. **Foundation for casualty tracking**: Data model designed for Phase 2 sync capabilities

---

## 3. Non-Goals (MVP)

- No AI/LLM components or probabilistic decision-making
- No classified data handling
- No integration to external command systems
- No real-time commander dashboard
- No interactive training scenarios (read-only trainer content only)

---

## 4. Core User Journeys

### Journey A: Under Effective Enemy Fire → Single Casualty

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Master Drill  │────▶│  Single Casualty │────▶│   Drill 2–11    │
│  (Under Fire?)  │     │    Assessment    │     │  (MARCH Steps)  │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                        ┌──────────────────┐              │
                        │  CASREP + MIST   │◀─────────────┘
                        │    (Handover)    │
                        └──────────────────┘
```

1. Open app → Master Drill: assess threat, self/buddy tourniquet if required
2. Evaluate casualty → if one casualty, proceed to Drill 2 (Massive Bleeding)
3. Progress through MARCH sequence as required
4. Generate CASREP + MIST(AT) summary for handover

### Journey B: Multiple Casualties Triage

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Master Drill  │────▶│     Drill 1      │────▶│ Select Casualty │
│                 │     │ (10-sec Triage)  │     │   to Treat      │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │   Drill 2–11    │
                                                 │  (Per Casualty) │
                                                 └─────────────────┘
```

1. Master Drill → "Multiple casualties?" → Drill 1
2. 10-second triage: classify P1/P2/P3/Dead, mark, move on
3. After triage complete, select casualty to treat
4. Proceed via Drill 2 onward

### Journey C: Pre-Evacuation Care and Reassessment

1. Drill 12: Evacuation rules → send final CASREP
2. Drill 13: Pre-evacuation care → shock monitoring, warmth, reassessment
3. Loop back to Drill 2 if condition changes

---

## 5. Functional Requirements

### FR1: Drill Engine (State Machine)

The application must represent Master Drill + Drills 1–13 as a deterministic state machine:

- Ordered steps within each drill
- Branching based on yes/no decisions and key findings
- Ability to "jump to drill" per doctrine
- Mandatory start at Master Drill for each new incident
- History tracking for audit trail

### FR2: Triage Module (Drill 1)

- Implement P1/P2/P3/Dead classification rules
- Guide marking instructions (cheek/chest/visible)
- Support recording multiple casualties
- Enable selection of casualty to treat

### FR3: Single-Casualty MARCH Flow

Guide through in sequence:
- **M**assive Bleeding (Drill 2)
- **A**irway (Drills 3–5)
- **R**espiratory Distress (Drills 6–7)
- **C**irculation (Drill 8)
- **H**ead Injury/Hypothermia (Drills 9–11)

### FR4: Reporting (CASREP + MIST(AT))

**CASREP Fields (Drill 12):**
- Number of casualties
- Grid reference
- Priorities breakdown
- ETA/type of MEDEVAC
- Life-threatening considerations

**MIST(AT) Fields:**
- Zap number
- Mechanism of injury
- Injury/illness description
- Signs/vitals (by MARCH)
- Treatment given
- Age
- Time of wounding

### FR5: Casualty Record & Timeline

For each casualty, maintain:
- Event timeline (assessments, interventions)
- Time-stamped observations
- Support reassessment workflows
- Enable handover summary generation

### FR6: Role Layering

| Feature | General | Medic | Trainer |
|---------|:-------:|:-----:|:-------:|
| Core drill flow | ✓ | ✓ | ✓ |
| Basic MIST capture | ✓ | ✓ | ✓ |
| Extended vitals fields | - | ✓ | ✓ |
| Intervention quicklists | - | ✓ | ✓ |
| Drill outline reference | - | - | ✓ |
| Scenario scaffolding | - | - | ✓ |

### FR7: Export

Export single casualty report as:
- On-screen handover view (large font, readable)
- JSON (for future sync)
- Optional PDF (Phase 1.5)

Export must work without connectivity.

---

## 6. Non-Functional Requirements

| Requirement | Target | Rationale |
|-------------|--------|-----------|
| **Offline operation** | 100% core features | DDIL environments |
| **App launch time** | < 2 seconds | Emergency access |
| **Drill navigation** | < 100ms | Combat stress tolerance |
| **Data persistence** | Never lose record | Autosave on every action |
| **Encryption** | AES-256 at rest | Protect casualty PII |
| **Tap targets** | ≥ 48dp | Glove-friendly |
| **Contrast ratio** | ≥ 7:1 | Low-light readability |

---

## 7. Data Model

```
┌─────────────┐       ┌─────────────┐       ┌───────────────────┐
│  Incident   │───┬──▶│  Casualty   │───┬──▶│AssessmentSnapshot │
│             │   │   │             │   │   │                   │
│ id          │   │   │ id          │   │   │ id                │
│ created_at  │   │   │ incident_id │   │   │ casualty_id       │
│ grid_ref    │   │   │ zap_number  │   │   │ timestamp         │
│ under_fire  │   │   │ triage_cat  │   │   │ m_assessment      │
│ notes       │   │   │ age_class   │   │   │ a_assessment      │
└─────────────┘   │   │ time_wound  │   │   │ r_assessment      │
                  │   └─────────────┘   │   │ c_assessment      │
                  │                     │   │ h_assessment      │
                  │                     │   │ notes             │
                  │                     │   └───────────────────┘
                  │                     │
                  │                     │   ┌───────────────────┐
                  │                     └──▶│   Intervention    │
                  │                         │                   │
                  │                         │ id                │
                  │                         │ casualty_id       │
                  │                         │ timestamp         │
                  │                         │ type              │
                  │                         │ details           │
                  │                         └───────────────────┘
                  │
                  │   ┌─────────────┐
                  └──▶│ Evacuation  │
                      │             │
                      │ id          │
                      │ incident_id │
                      │ casrep_data │
                      │ sent_at     │
                      └─────────────┘
```

---

## 8. MVP Acceptance Criteria

- [ ] New Incident → Master Drill → create and treat at least one casualty end-to-end
- [ ] Multiple casualty triage with ≥3 casualties and categories applied
- [ ] CASREP screen completed and exportable
- [ ] MIST(AT) captured with ≥2 time-stamped reassessment snapshots
- [ ] All data persists after app kill/relaunch
- [ ] Unit tests for drill state machine transitions
- [ ] Encrypted local database
- [ ] No PII in application logs

---

## 9. Future Roadmap (Post-MVP)

### Phase 2: Connectivity & Tracking
- Secure sync to central casualty tracking system
- Unit-level casualty dashboard
- CASREP transmission when network available

### Phase 3: Advanced Training
- Interactive scenario execution
- Performance timing and scoring
- Instructor scenario builder

### Phase 4: Integration
- NATO/coalition interoperability
- Medical system handoff (HL7 FHIR)
- Sensor integration (vital monitors)

---

## 10. References

1. Ministry of Defence (2025) *TCCC(UK) ASM Aide Memoire (Mar 25)*
2. Ministry of Defence (2025) *TCCC(UK) ASM Trainer Manual v1.1 (May 25)*
3. Ministry of Defence (2023) *BATLS Aide Memoire*
