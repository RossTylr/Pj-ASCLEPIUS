# ASM Drills Source Notes

**Purpose:** Document the source doctrine and mapping to application drill flow.

**Sources:**
- TCCC(UK) ASM Aide Memoire (Mar 25) - "ASM AM"
- TCCC(UK) ASM Trainer Manual v1.1 (May 25) - "TM"

---

## Master Drill

**Source:** ASM AM, TM Section 4

### Flow

```
START
  │
  ▼
┌─────────────────────────────────────┐
│ Are you under effective enemy fire? │
└──────────────┬──────────────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
     [YES]           [NO]
       │               │
       ▼               ▼
┌──────────────┐  ┌──────────────────────┐
│ Return fire  │  │ Approach casualty    │
│ Take cover   │  │ safely               │
│ Direct cas   │  └──────────┬───────────┘
│ to cover     │             │
└──────┬───────┘             │
       │                     │
       ▼                     │
┌──────────────────────┐     │
│ Severe limb bleeding?│     │
│ (self or buddy)      │     │
└──────────┬───────────┘     │
       ┌───┴───┐             │
       ▼       ▼             │
     [YES]   [NO]            │
       │       │             │
       ▼       │             │
┌──────────────┐             │
│ Apply        │             │
│ tourniquet   │             │
│ HIGH & TIGHT │             │
└──────┬───────┘             │
       │                     │
       ▼                     │
┌──────────────────────┐     │
│ Casualty conscious?  │     │
└──────────┬───────────┘     │
       ┌───┴───┐             │
       ▼       ▼             │
     [YES]   [NO]            │
       │       │             │
       │       ▼             │
       │  ┌────────────────┐ │
       │  │ Roll face down │ │
       │  │ (if accessible)│ │
       │  └────────┬───────┘ │
       │           │         │
       ▼           ▼         │
┌──────────────────────────┐ │
│ Move to cover when safe  │ │
└──────────────┬───────────┘ │
               │             │
               ▼             │
        ┌──────┴─────────────┘
        ▼
┌──────────────────────────┐
│ Multiple casualties?     │
└──────────────┬───────────┘
       ┌───────┴───────┐
       ▼               ▼
     [YES]           [NO]
       │               │
       ▼               ▼
   DRILL 1        DRILL 2
```

### Key Decision Points

1. **Under effective enemy fire** - Determines care phase
2. **Severe limb bleeding** - Triggers immediate tourniquet
3. **Casualty conscious** - Affects positioning (face down if unconscious)
4. **Multiple casualties** - Routes to triage (D1) or single casualty assessment (D2)

---

## Drill 1: Multiple Casualty Triage

**Source:** ASM AM, TM Section 5.1

### 10-Second Triage Protocol

For each casualty:

1. **Can they walk?** → YES = P3 (mark, move on)
2. **Are they breathing?** → NO = DEAD (mark, move on)
3. **Do they respond to commands?** → YES = P2 (mark, move on)
4. **Otherwise** → P1 (mark, move on)

### Marking

- Mark on **cheek** or **chest** (visible location)
- P1 = Immediate priority
- P2 = Urgent priority  
- P3 = Delayed priority
- DEAD = Deceased

### App Implementation Notes

- Timer guidance (10 seconds per casualty)
- Category selection with large touch targets
- List view of triaged casualties
- Selection interface to proceed to treatment

---

## Drill 2: Massive Bleeding (MARCH - M)

**Source:** ASM AM, TM Section 5.2

### Assessment

1. **Visual sweep** for blood loss
2. **Check limbs** for life-threatening bleeding
3. **Check junctions** (groin, axilla, neck)

### Interventions

| Finding | Action |
|---------|--------|
| Limb bleeding | Tourniquet HIGH & TIGHT |
| Junctional bleeding | Wound packing + direct pressure |
| Pelvic fracture suspected | Pelvic binder |

### Tourniquet Rules

- Apply 2-3 inches above wound
- Not over joint
- Note time of application
- Expose and reassess after 2 hours if not evacuated

---

## Drills 3-5: Airway (MARCH - A)

**Source:** ASM AM, TM Section 5.3-5.5

### Drill 3: Unconscious Casualty - Open Airway

- Head tilt, chin lift
- Recovery position (3/4 prone)
- Consider NPA if trained

### Drill 4: Casualty with Suspected Spinal Injury

- Jaw thrust (no head tilt)
- Manual in-line stabilisation
- NPA preferred over OPA

### Drill 5: Casualty Face Down / Obstructed Airway

- Log roll to assess
- Clear visible obstruction
- Suction if available (medic)

---

## Drills 6-7: Respiratory (MARCH - R)

**Source:** ASM AM, TM Section 5.6-5.7

### Drill 6: Chest Wound

- Apply chest seal (vented if available)
- Occlusive dressing if no seal available
- Position wounded side down if possible

### Drill 7: Tension Pneumothorax (Medic)

Signs: Increasing respiratory distress, tracheal deviation, absent breath sounds

**Needle Decompression:**
- 2nd intercostal space, mid-clavicular line
- 14G needle, at least 8cm
- Note time

---

## Drill 8: Circulation (MARCH - C)

**Source:** ASM AM, TM Section 5.8

### Shock Assessment

- Pale, cold, sweaty skin
- Weak/rapid pulse
- Altered consciousness
- Slow capillary refill (>2 seconds)

### Management

- Elevate legs (if no spinal injury suspected)
- Keep warm
- Reassure casualty
- IV/IO access (medic)

---

## Drills 9-11: Head & Hypothermia (MARCH - H)

**Source:** ASM AM, TM Section 5.9-5.11

### Drill 9: Head Injury

- AVPU assessment
- GCS if trained
- Note any fluid from ears/nose
- Do not remove penetrating objects

### Drill 10: Burns

- Remove from source
- Cool burns (no ice)
- Cover with cling film
- Assess %TBSA (rule of 9s)

### Drill 11: Hypothermia Prevention

**All casualties:**
- Remove wet clothing
- Insulate from ground
- Cover (casualty blanket/poncho)
- Warm fluids if conscious and able

---

## Drill 12: Evacuation

**Source:** ASM AM, TM Section 5.12

### CASREP Format

```
Call Sign: _______
Grid Reference: _______
Number of Casualties: _______
  P1: ___  P2: ___  P3: ___
MEDEVAC Required: YES/NO
Type: URGENT / PRIORITY / ROUTINE
ETA: _______
Special Equipment: _______
Life Threatening Conditions:
  □ Airway obstruction
  □ Tension pneumothorax
  □ Massive haemorrhage
  □ Shock
  □ Head injury
  □ Burns >20%
```

---

## Drill 13: Pre-Evacuation Care

**Source:** ASM AM, TM Section 5.13

### Continuous Reassessment

- Re-run MARCH sequence
- Monitor tourniquets (2-hour conversion consideration)
- Check dressings/seals
- Maintain warmth
- Document changes

### Handover Preparation

- Complete MIST(AT)
- Ensure all interventions documented
- Note times for all treatments

---

## MIST(AT) Format

**Source:** ASM AM, TM Annex A

```
M - Mechanism:      How was the casualty injured?
I - Injury/Illness: What injuries are present?
S - Signs:          Vital signs, AVPU/GCS, bleeding status
T - Treatment:      What has been done?
A - Age:            Approximate age
T - Time:           Time of wounding
```

---

## Implementation Checklist

- [ ] Master Drill: All decision points implemented
- [ ] Drill 1: Triage categories and marking
- [ ] Drill 2: Tourniquet, wound packing, pelvic binder
- [ ] Drills 3-5: Airway manoeuvres and adjuncts
- [ ] Drills 6-7: Chest seals, needle decompression (medic)
- [ ] Drill 8: Shock assessment and management
- [ ] Drills 9-11: Head injury, burns, hypothermia
- [ ] Drill 12: CASREP generation
- [ ] Drill 13: Reassessment loop, MIST(AT) compilation

---

## Content Governance

**Rules for drill content:**

1. All content must trace to official doctrine
2. No invented medical guidance
3. UK English spelling (haemorrhage, not hemorrhage)
4. Use placeholder `[TODO: Reference]` if doctrine unclear
5. Version control all content changes
6. Require medical SME review for updates
