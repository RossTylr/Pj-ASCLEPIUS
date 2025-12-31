# Medical Content Handoff: Drills 4, 5, and 10

## Purpose

This document provides instructions for adding doctrinal medical content to three placeholder drills in the TriageDrills application. These drills have been structurally implemented but require accurate medical content from TCCC(UK) ASM doctrine.

**IMPORTANT:** All content must come from official doctrine sources. Do not invent medical procedures.

---

## Doctrine Sources Required

- **TCCC(UK) ASM Aide Memoire (Mar 25)** - "ASM AM"
- **TCCC(UK) ASM Trainer Manual v1.1 (May 25)** - "TM"
  - Section 5.4: Suspected Spinal Injury
  - Section 5.5: Face Down / Obstructed Airway
  - Section 5.10: Burns

---

## File to Edit

```
app/assets/drill_definitions.json
```

All placeholder text is marked with `[TODO: Reference needed]` or `[TODO: ...]`

---

## Drill 4: Suspected Spinal Injury

**Location in JSON:** Search for `"drill_4"`
**Doctrine Source:** TM Section 5.4

### Current Placeholders to Replace

| Node ID | Field | Current Value | Replace With |
|---------|-------|---------------|--------------|
| `drill_4_start` | prompt | `[TODO: Reference needed] Maintain manual in-line stabilisation.` | Exact doctrine text for spinal precautions |
| `drill_4_jaw_thrust` | prompt | `[TODO: Reference needed] Open airway using jaw thrust manoeuvre.` | Exact doctrine text for jaw thrust |
| `drill_4_jaw_thrust` | actions | `["[TODO: Step 1]", "[TODO: Step 2]", "[TODO: Step 3]"]` | Step-by-step jaw thrust procedure |
| `drill_4_npa` | prompt | `[TODO: Reference needed] Consider NPA - preferred over OPA for spinal.` | Exact doctrine guidance on NPA for spinal |
| `drill_4_npa` | actions | `["[TODO: NPA insertion steps]"]` | Step-by-step NPA insertion |
| `drill_4_not_breathing` | prompt | `[TODO: Reference needed] Maintain jaw thrust, reassess.` | Doctrine guidance for non-breathing spinal casualty |

### Key Points from Doctrine Notes (verify against source)
- Jaw thrust (no head tilt)
- Manual in-line stabilisation
- NPA preferred over OPA

---

## Drill 5: Face Down / Obstructed Airway

**Location in JSON:** Search for `"drill_5"`
**Doctrine Source:** TM Section 5.5

### Current Placeholders to Replace

| Node ID | Field | Current Value | Replace With |
|---------|-------|---------------|--------------|
| `drill_5_start` | prompt | `[TODO: Reference needed] Casualty face down or airway obstructed.` | Exact doctrine text |
| `drill_5_log_roll` | prompt | `[TODO: Reference needed] Log roll to assess airway.` | Exact doctrine text for log roll |
| `drill_5_log_roll` | actions | `["[TODO: Log roll steps]"]` | Step-by-step log roll procedure |
| `drill_5_remove_obstruction` | prompt | `[TODO: Reference needed] Remove visible obstruction.` | Exact doctrine guidance |
| `drill_5_remove_obstruction` | actions | `["[TODO: Clearance steps]", "Suction if available (medic)"]` | Step-by-step obstruction clearance |

### Key Points from Doctrine Notes (verify against source)
- Log roll to assess
- Clear visible obstruction
- Suction if available (medic only)

---

## Drill 10: Burns

**Location in JSON:** Search for `"drill_10"`
**Doctrine Source:** TM Section 5.10

### Current Placeholders to Replace

| Node ID | Field | Current Value | Replace With |
|---------|-------|---------------|--------------|
| `drill_10_remove_source` | prompt | `[TODO: Reference needed] Remove casualty from burn source. Stop the burning process.` | Exact doctrine text |
| `drill_10_remove_source` | actions | `["[TODO: Steps to stop burning]"]` | Step-by-step procedure |
| `drill_10_cool` | prompt | `[TODO: Reference needed] Cool burns with clean water if available.` | Exact doctrine guidance on cooling |
| `drill_10_cool` | actions | `["[TODO: Cooling steps]", "Do NOT use ice"]` | Step-by-step cooling procedure |
| `drill_10_cover` | prompt | `[TODO: Reference needed] Cover burns with cling film or clean dressing.` | Exact doctrine guidance |
| `drill_10_cover` | actions | `["[TODO: Covering steps]"]` | Step-by-step covering procedure |
| `drill_10_tbsa` | prompt | `[TODO: Reference needed] Estimate total body surface area affected using Rule of 9s.` | Exact doctrine guidance on TBSA assessment |

### Key Points from Doctrine Notes (verify against source)
- Remove from source
- Cool burns (no ice)
- Cover with cling film
- Assess %TBSA (rule of 9s)

---

## Validation After Editing

After updating the JSON, run these commands to verify:

```bash
cd app
flutter pub get
flutter test
flutter analyze
```

All 19 tests should pass and analyzer should show no issues.

---

## Content Guidelines

1. **UK English spelling** - haemorrhage, colour, etc.
2. **Concise prompts** - Keep text readable on mobile screen
3. **Actionable steps** - Each action should be a single clear instruction
4. **Warnings array** - Use for critical safety points (red box in UI)
5. **No invented content** - If doctrine is unclear, keep `[TODO: Reference needed]`

---

## Example: Completed Node

Here's an example of a properly completed action node from Drill 2:

```json
{
  "id": "drill_2_tourniquet",
  "type": "action",
  "title": "TOURNIQUET",
  "prompt": "Apply tourniquet HIGH and TIGHT",
  "actions": [
    "Place 2-3 inches above wound",
    "NOT over joint",
    "Tighten until bleeding stops",
    "Note TIME"
  ],
  "intervention_type": "TOURNIQUET",
  "next": "drill_2_junction_check"
}
```

---

## Questions to Resolve with SME

1. Should Drill 4 include OPA as an alternative if NPA unavailable?
2. What specific signs indicate spinal injury for the decision point?
3. For Drill 10 burns - what is the minimum cooling time recommended?
4. Should Rule of 9s diagram be referenced or included as image asset?

---

## Contact

If doctrine sources are unavailable or unclear, mark remaining placeholders with:
```
[TODO: Awaiting doctrine reference - TM Section X.X]
```

This ensures the app can still function while flagging incomplete content.
