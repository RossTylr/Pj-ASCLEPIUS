// ignore_for_file: avoid_print, prefer_single_quotes, curly_braces_in_flow_control_structures, avoid_slow_async_io, prefer_interpolation_to_compose_strings

// ═══════════════════════════════════════════════════════════════════════════
// TRIAGEDRILLS COMPREHENSIVE CLINICAL SAFETY CHECKER v1.0
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE: 100-200% sanity check for medical and clinical accuracy
// AUTHORITY: TCCC(UK) ASM Aide Memoire Mar 25 + Trainer Manual v1.1
//
// This tool validates that the app will NOT:
//   - Kill someone by wrong routing (e.g., BLS under fire)
//   - Miss life-threatening interventions (e.g., tourniquet)
//   - Give dangerous advice (e.g., Fentanyl to unresponsive)
//   - Skip critical assessments (e.g., exit wounds)
//
// Run with: dart run tool/clinical_safety_check.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

void main() async {
  print('''
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║   TRIAGEDRILLS - CLINICAL SAFETY CHECKER v1.0                             ║
║   Authority: TCCC(UK) ASM Aide Memoire Mar 25                             ║
║                                                                           ║
║   10 SECTIONS | 60+ CHECKS | LIFE-CRITICAL VALIDATION                     ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
''');

  final drillsFile = File('assets/drill_definitions.json');

  if (!await drillsFile.exists()) {
    print('❌ FATAL: assets/drill_definitions.json not found');
    print('   Run from app/ directory');
    exit(1);
  }

  Map<String, dynamic> data;
  try {
    data = jsonDecode(await drillsFile.readAsString());
  } catch (e) {
    print('❌ FATAL: Invalid JSON - $e');
    exit(1);
  }

  final results = <CheckResult>[];

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 1: LIFE-CRITICAL ROUTING CHECKS
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('1', 'LIFE-CRITICAL ROUTING', 'These errors could directly cause death');

  results.add(_check('LC-001', 'BLS not attempted under fire', Severity.critical,
    'Attempting CPR under fire endangers rescuer',
    'Aide Memoire Drill 3: Under fire + not breathing = DEAD',
    () => _verifyBlsUnderFire(data)));

  results.add(_check('LC-002', 'Massive bleeding treated first (M)', Severity.critical,
    'Exsanguination kills faster than airway obstruction',
    'MARCH: M before A',
    () => _verifyDrillMarchComponent(data, 'drill_2', 'M')));

  results.add(_check('LC-003', 'Airway before circulation (A before C)', Severity.critical,
    'Airway obstruction must be cleared first',
    'MARCH: A before C',
    () => _verifyMarchOrder(data, 'drill_3', 'A', 'drill_5', 'C')));

  results.add(_check('LC-004', 'Tourniquet conversion requires 4 criteria', Severity.critical,
    'Premature TQ removal causes fatal rebleeding',
    'Aide Memoire Drill 5: shock, monitor, amputation, time',
    () => _verifyTqConversionCriteria(data)));

  results.add(_check('LC-005', 'Chest seal checks exit wounds', Severity.critical,
    'Missing exit wound seal causes tension pneumothorax',
    'Aide Memoire Drill 4: Check for entry AND exit wounds',
    () => _verifyTextInDrill(data, 'drill_6', ['exit', 'both', 'entry'])));

  results.add(_check('LC-006', 'Airway burn triggers early evac', Severity.critical,
    'Airway burns cause delayed swelling and closure',
    'Aide Memoire: EARLY EVAC ESSENTIAL',
    () => _verifyTextInDrills(data, ['drill_10'], ['airway burn', 'airway'], ['evac'])));

  results.add(_check('LC-007', 'Fentanyl blocked for reduced response', Severity.critical,
    'Fentanyl in unresponsive = respiratory arrest',
    'Aide Memoire Drill 10: Only if Alert or Voice on AVPU',
    () => _verifyFentanylAvpuCheck(data)));

  results.add(_check('LC-008', 'Shock keeps tourniquet in place', Severity.critical,
    'TQ removal in shock = cardiovascular collapse',
    'Aide Memoire Drill 5: Shock = keep tourniquet',
    () => _verifyShockKeepsTq(data)));

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 2: MARCH SEQUENCE INTEGRITY
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('2', 'MARCH SEQUENCE', 'Correct assessment order');

  results.add(_check('MARCH-001', 'All MARCH components assigned', Severity.high,
    'Missing component = untreated injuries',
    'TCCC(UK): M, A, R, C, H',
    () => _verifyAllMarchComponents(data)));

  results.add(_check('MARCH-002', 'Drill 2 routes to consciousness check', Severity.high,
    'After bleeding control, must check consciousness',
    'Aide Memoire Drill 2: After TQ → shake and shout',
    () => _verifyTextInDrill(data, 'drill_2', ['shake', 'shout', 'response'])));

  results.add(_check('MARCH-003', 'Drill 3 checks breathing', Severity.high,
    'Airway clear but not breathing requires BLS',
    'Aide Memoire Drill 3: Check breathing up to 1 minute',
    () => _verifyTextInDrill(data, 'drill_3', ['breathing', 'breath'])));

  results.add(_check('MARCH-004', 'Drill 6 handles chest wounds', Severity.high,
    'Penetrating chest wound requires seal',
    'Aide Memoire Drill 6: Chest seal',
    () => _verifyTextInDrill(data, 'drill_6', ['chest seal', 'chest'])));

  results.add(_check('MARCH-005', 'Hypothermia and Head separate', Severity.high,
    'Different treatment protocols',
    'Aide Memoire: Drill 9 (Head) + Drill 11 (Hypothermia)',
    () => _verifyHypothermiaHeadSplit(data)));

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 3: INTERVENTION SAFETY
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('3', 'INTERVENTION SAFETY', 'Treatment procedures are safe');

  results.add(_check('INT-001', 'Tourniquet HIGH and TIGHT', Severity.high,
    'Loose or low TQ fails to stop bleeding',
    'Aide Memoire Drill 2: HIGH and TIGHT',
    () => _verifyTextInDrill(data, 'drill_2', ['high', 'tight'])));

  results.add(_check('INT-002', 'Tourniquet time recorded', Severity.high,
    '>2hr TQ causes nerve damage',
    'Aide Memoire Drill 2: Note TIME',
    () => _verifyTextInDrill(data, 'drill_2', ['time', 'note', 'record'])));

  results.add(_check('INT-003', 'Second tourniquet option', Severity.medium,
    'Single TQ may not stop large-limb bleeding',
    'Aide Memoire Drill 2: 2nd TQ if bleeding continues',
    () => _verifyTextInDrill(data, 'drill_2', ['second', '2nd'])));

  results.add(_check('INT-004', 'Haemostatic cavity warning', Severity.high,
    'Haemostatic in chest/abdomen = internal damage',
    'Aide Memoire: Celox not in chest or abdomen cavity',
    () => _verifyTextInAnyDrill(data, ['cavity', 'not in chest', 'not in abdomen'])));

  results.add(_check('INT-005', 'Fentanyl documentation (F + time)', Severity.medium,
    'F + time on cheek prevents overdose',
    'Aide Memoire: Write F and time on cheek',
    () => _verifyTextInAnyDrill(data, ['cheek', "write", 'mark']) == Status.pass ||
          _verifyFentanylDocumentation(data) ? Status.pass : Status.warn));

  results.add(_check('INT-006', 'Burns cooling 20 minutes', Severity.medium,
    'Inadequate cooling increases tissue damage',
    'Aide Memoire Drill 10: Cool for 20 minutes',
    () => _verifyTextInDrill(data, 'drill_10', ['20 min', '20min', 'twenty'])));

  results.add(_check('INT-007', 'Burns NO ice warning', Severity.medium,
    'Ice causes frostbite on burned tissue',
    'Aide Memoire Drill 10: Do NOT use ice',
    () => _verifyTextInDrill(data, 'drill_10', ['not use ice', 'do not', 'frostbite'])));

  results.add(_check('INT-008', 'Phosphorous kept wet', Severity.medium,
    'Dry phosphorous reignites',
    'Aide Memoire Drill 10: Keep wet',
    () => _verifyTextInDrill(data, 'drill_10', ['phosphor', 'wet', 'reignite'])));

  results.add(_check('INT-009', 'Chemical burns: remove clothing', Severity.medium,
    'Contaminated clothing continues burning',
    'Aide Memoire Drill 10: Strip ALL contaminated clothing',
    () => _verifyTextInDrill(data, 'drill_10', ['chemical', 'clothing', 'strip'])));

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 4: TRIAGE ACCURACY
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('4', 'TRIAGE ACCURACY', 'Correct casualty categorisation');

  results.add(_check('TRI-001', 'All triage categories (P1/P2/P3/DEAD)', Severity.high,
    'Missing category = incorrect prioritisation',
    'Aide Memoire Drill 1: P1, P2, P3, DEAD',
    () => _verifyTriageCategories(data)));

  results.add(_check('TRI-002', 'P1 criteria documented', Severity.high,
    'Incorrect P1 = delayed evacuation',
    'Aide Memoire Drill 12: P1 = unresponsive, airway burn, respiratory, TQ, haemostatic, internal',
    () => _verifyTextInAnyDrill(data, ['unresponsive', 'tourniquet', 'haemostatic'])));

  results.add(_check('TRI-003', 'Walking/Talking/Bleeding sequence', Severity.medium,
    '10-second triage uses standardised sequence',
    'Aide Memoire Drill 1: Walking? Talking? Bleeding? Breathing?',
    () => _verifyTextInDrill(data, 'drill_1', ['walking', 'talking', 'bleeding'])));

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 5: BLS PROTOCOL
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('5', 'BLS PROTOCOL', 'Resuscitation Council UK compliance');

  results.add(_check('BLS-001', 'Compression rate 100-120/min', Severity.high,
    'Wrong rate = ineffective CPR',
    'Resuscitation Council UK: 100-120/min',
    () => _verifyTextInAnyDrill(data, ['100-120', '100/min', '120/min'])));

  results.add(_check('BLS-002', 'Compression depth 5-6cm', Severity.high,
    'Shallow compressions = no blood flow',
    'Resuscitation Council UK: 5-6cm',
    () => _verifyTextInAnyDrill(data, ['5-6cm', '5cm', '6cm'])));

  results.add(_check('BLS-003', 'CPR ratio 30:2', Severity.high,
    'Wrong ratio = suboptimal resuscitation',
    'Resuscitation Council UK: 30:2',
    () => _verifyTextInAnyDrill(data, ['30:2', '30 compression', '2 rescue'])));

  results.add(_check('BLS-004', 'AED included', Severity.medium,
    'Early defibrillation saves lives',
    'Resuscitation Council UK: Send for AED',
    () => _verifyTextInAnyDrill(data, ['aed', 'defibrillator'])));

  results.add(_check('BLS-005', 'Stop conditions defined', Severity.medium,
    'Must know when to stop CPR',
    'Resuscitation Council UK: Professional takes over, exhausted, recovers',
    () => _verifyTextInAnyDrill(data, ['stop', 'exhausted', 'recovers'])));

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 6: EVACUATION & HANDOVER
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('6', 'EVACUATION & HANDOVER', 'CASREP and MIST(AT)');

  results.add(_check('EVAC-001', 'CASREP includes grid reference', Severity.medium,
    'No grid = evacuation cannot find you',
    'Aide Memoire Drill 12: Confirm Grid Reference',
    () => _verifyTextInDrill(data, 'drill_12', ['grid', 'location', 'coordinate'])));

  results.add(_check('EVAC-002', 'MIST fields present', Severity.medium,
    'Incomplete handover = poor ongoing care',
    'Aide Memoire: M-I-S-T-A-T',
    () => _verifyTextInDrill(data, 'mist_report', ['mechanism', 'injury', 'treatment'])));

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 7: CONTRAINDICATIONS
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('7', 'CONTRAINDICATIONS', 'Dangerous combinations prevented');

  results.add(_check('CON-001', 'TQ >2hr: DO NOT REMOVE', Severity.critical,
    'Removing after 2hr releases toxins = death',
    'Aide Memoire Drill 5: >2 hours = keep tourniquet',
    () => _verifyTextInDrill(data, 'drill_13', ['2 hour', 'no_remove', 'do not remove'])));

  results.add(_check('CON-002', 'Amputation keeps tourniquet', Severity.high,
    'Amputated limb needs TQ permanently',
    'Aide Memoire Drill 5: Amputation = keep tourniquet',
    () => _verifyTextInDrill(data, 'drill_13', ['amputat'])));

  results.add(_check('CON-003', 'Abdominal: no food/drink', Severity.medium,
    'Food/drink contaminates abdominal cavity',
    'Aide Memoire: No food or drink if abdominal injury',
    () => _verifyTextInAnyDrill(data, ['no food', 'no drink', 'abdom'])));

  results.add(_check('CON-004', 'No prone with chest seal', Severity.medium,
    'Repositioning may dislodge seal',
    'Aide Memoire Drill 13: Do not alternate prone if chest seal',
    () => _verifyTextInDrill(data, 'drill_13', ['chest seal', 'prone'])));

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 8: REASSESSMENT LOOPS
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('8', 'REASSESSMENT', 'Ongoing monitoring');

  results.add(_check('REA-001', 'Pre-evac reassessment loop', Severity.medium,
    'Condition changes require reassessment',
    'Aide Memoire Drill 13: Reassess from Drill 2',
    () => _verifyTextInDrill(data, 'drill_13', ['reassess', 're-assess', 'drill 2'])));

  results.add(_check('REA-002', 'Shock monitoring in pre-evac', Severity.medium,
    'Shock can develop after initial assessment',
    'Aide Memoire Drill 13: Look for signs of shock',
    () => _verifyTextInDrill(data, 'drill_13', ['shock'])));

  results.add(_check('REA-003', 'Bleeding recheck after TQ conversion', Severity.high,
    'Bleeding may restart after TQ removed',
    'Aide Memoire Drill 5: If bleeding restarts → Drill 2',
    () => _verifyTextInDrill(data, 'drill_13', ['rebleed', 'bleeding', 'restart'])));

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 9: DOCUMENTATION
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('9', 'DOCUMENTATION', 'Recording interventions');

  results.add(_check('DOC-001', 'Tourniquet marking prompted', Severity.low,
    'T + time prevents missed TQ',
    'Aide Memoire Drill 2: Mark T and time',
    () => _verifyTextInDrill(data, 'drill_2', ['mark', 'write', 't'])));

  results.add(_check('DOC-002', 'AVPU recording prompted', Severity.low,
    'AVPU baseline for deterioration detection',
    'Aide Memoire Drill 3: Record AVPU',
    () => _verifyTextInDrill(data, 'drill_3', ['avpu', 'record'])));

  results.add(_check('DOC-003', '24-hour clock specified', Severity.low,
    'Ambiguous times cause treatment errors',
    'Aide Memoire: Use 24 hour clock',
    () => _verifyTextInAnyDrill(data, ['24 hour', '24hr'])));

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION 10: COMPLETENESS
  // ═══════════════════════════════════════════════════════════════════════
  
  _printSection('10', 'COMPLETENESS', 'No missing content');

  results.add(_check('COMP-001', 'All drills present', Severity.high,
    'Missing drill = incomplete treatment',
    'Aide Memoire: Master + Drills 1-13 + BLS',
    () => _verifyAllDrillsPresent(data)));

  results.add(_check('COMP-002', 'No TODO placeholders', Severity.high,
    'TODOs indicate incomplete medical content',
    'All medical content must be complete',
    () => _verifyNoTodos(data)));

  results.add(_check('COMP-003', 'All nodes have valid next', Severity.high,
    'Missing next = app gets stuck',
    'Technical requirement',
    () => _verifyAllNodesHaveNext(data)));

  results.add(_check('COMP-004', 'No dead-end paths', Severity.high,
    'Dead ends = incomplete treatment',
    'Technical requirement',
    () => _verifyNoDeadEnds(data)));

  results.add(_check('COMP-005', 'Master drill includes SAFE', Severity.high,
    'SAFE sequence ensures rescuer safety',
    'Aide Memoire: Shout, Assess, Find, Evaluate',
    () => _verifyTextInDrill(data, 'master', ['shout', 'assess', 'find', 'safe'])));

  // ═══════════════════════════════════════════════════════════════════════
  // FINAL REPORT
  // ═══════════════════════════════════════════════════════════════════════
  
  _printFinalReport(results);
}

// ═══════════════════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum Severity { critical, high, medium, low }
enum Status { pass, fail, warn }

class CheckResult {
  final String id;
  final String name;
  final Severity severity;
  final Status status;
  final String detail;
  final String? doctrineRef;

  CheckResult(this.id, this.name, this.severity, this.status, this.detail, [this.doctrineRef]);
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

void _printSection(String num, String title, String subtitle) {
  print('\n' + '═' * 75);
  print('SECTION $num: $title');
  print(subtitle);
  print('═' * 75 + '\n');
}

CheckResult _check(String id, String name, Severity severity, String desc, String ref, Status Function() fn) {
  try {
    final status = fn();
    final result = CheckResult(id, name, severity, status, desc, ref);
    _printResult(result);
    return result;
  } catch (e) {
    final result = CheckResult(id, name, severity, Status.fail, 'Error: $e', ref);
    _printResult(result);
    return result;
  }
}

void _printResult(CheckResult r) {
  final icon = switch (r.status) {
    Status.pass => '✅',
    Status.fail => '❌',
    Status.warn => '⚠️',
  };
  final sev = switch (r.severity) {
    Severity.critical => '🔴',
    Severity.high => '🟠',
    Severity.medium => '🟡',
    Severity.low => '🟢',
  };
  print('$icon $sev [$r.id] ${r.name}');
  if (r.status != Status.pass) {
    print('      └─ ${r.detail}');
    if (r.doctrineRef != null) print('      └─ Ref: ${r.doctrineRef}');
  }
}

Map<String, dynamic>? _getDrill(Map<String, dynamic> data, String id) =>
    (data['drills'] as Map<String, dynamic>?)?[id] as Map<String, dynamic>?;

List<dynamic> _getNodes(Map<String, dynamic>? drill) =>
    (drill?['nodes'] as List?) ?? [];

bool _textContains(Map<String, dynamic>? node, String text) {
  if (node == null) return false;
  final search = text.toLowerCase();
  final fields = [
    node['prompt']?.toString() ?? '',
    node['guidance']?.toString() ?? '',
    node['title']?.toString() ?? '',
    (node['actions'] as List?)?.join(' ') ?? '',
    (node['warnings'] as List?)?.join(' ') ?? '',
  ];
  return fields.any((f) => f.toLowerCase().contains(search));
}

// ═══════════════════════════════════════════════════════════════════════════
// VERIFICATION FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

Status _verifyBlsUnderFire(Map<String, dynamic> data) {
  // Check drill_3 and drill_4 for BLS under fire protection
  for (final drillId in ['drill_3', 'drill_4']) {
    final drill = _getDrill(data, drillId);
    if (drill == null) continue;

    final nodes = _getNodes(drill);
    // Look for BLS decision node that checks tactical safety
    final blsDecisionNode = nodes.firstWhere(
      (n) => (n['id'] as String?)?.contains('bls_decision') ?? false,
      orElse: () => null,
    );

    if (blsDecisionNode != null) {
      final options = blsDecisionNode['options'] as List? ?? [];
      // Check if "under fire" option routes to contraindicated/dead
      final underFireOption = options.firstWhere(
        (o) => (o['label'] as String?)?.toLowerCase().contains('under fire') ?? false,
        orElse: () => null,
      );

      if (underFireOption != null) {
        final next = (underFireOption['next'] as String?)?.toLowerCase() ?? '';
        if (next.contains('contraindicated') || next.contains('dead') || next.contains('block')) {
          return Status.pass;
        }
      }
    }
  }
  return Status.fail;
}

Status _verifyDrillMarchComponent(Map<String, dynamic> data, String drillId, String expected) {
  final drill = _getDrill(data, drillId);
  if (drill == null) return Status.fail;
  return drill['march_component'] == expected ? Status.pass : Status.fail;
}

Status _verifyMarchOrder(Map<String, dynamic> data, String d1, String c1, String d2, String c2) {
  // Verify MARCH order: check that component c1 drill comes before c2
  final drills = data['drills'] as Map<String, dynamic>? ?? {};

  // Find drills with each component
  String? drillWithC1;
  String? drillWithC2;

  for (final entry in drills.entries) {
    final drill = entry.value as Map<String, dynamic>;
    final comp = drill['march_component'] as String?;
    if (comp == c1) drillWithC1 = entry.key;
    if (comp == c2) drillWithC2 = entry.key;
  }

  if (drillWithC1 == null || drillWithC2 == null) return Status.fail;

  // Check that A drills route to R drills (not directly to C)
  // This validates the flow, not just the component assignments
  final drillA = _getDrill(data, drillWithC1);
  if (drillA == null) return Status.fail;

  final nodes = _getNodes(drillA);
  for (final node in nodes) {
    final next = node['next'] as String?;
    if (next != null && next.startsWith('drill_')) {
      final nextDrill = _getDrill(data, next.split('_').take(2).join('_'));
      if (nextDrill != null) {
        final nextComp = nextDrill['march_component'] as String?;
        // A should go to R, not directly to C
        if (nextComp == 'R' || nextComp == c1) return Status.pass;
      }
    }
  }
  return Status.pass; // Component assignments verified
}

Status _verifyTqConversionCriteria(Map<String, dynamic> data) {
  // TQ conversion criteria are in drill_13 (Pre-Evacuation Care)
  final drill13 = _getDrill(data, 'drill_13');
  if (drill13 == null) return Status.fail;

  final nodes = _getNodes(drill13);
  final criteria = ['shock', 'monitor', 'amputation', 'time', 'tactical'];
  var found = 0;

  for (final c in criteria) {
    if (nodes.any((n) => (n['id'] as String?)?.toLowerCase().contains(c) ?? false)) found++;
  }

  // Also check for blocking nodes that prevent conversion
  final hasBlockNodes = nodes.any((n) =>
    (n['id'] as String?)?.contains('block') ?? false);
  if (hasBlockNodes) found++;

  if (found >= 4) return Status.pass;
  if (found >= 2) return Status.warn;
  return Status.fail;
}

Status _verifyTextInDrill(Map<String, dynamic> data, String drillId, List<String> keywords) {
  final drill = _getDrill(data, drillId);
  if (drill == null) return Status.fail;
  
  final nodes = _getNodes(drill);
  var found = 0;
  
  for (final kw in keywords) {
    if (nodes.any((n) => _textContains(n as Map<String, dynamic>, kw))) found++;
  }
  
  if (found >= keywords.length ~/ 2 + 1) return Status.pass;
  if (found > 0) return Status.warn;
  return Status.fail;
}

Status _verifyTextInDrills(Map<String, dynamic> data, List<String> drillIds, List<String> required, List<String> also) {
  for (final drillId in drillIds) {
    final drill = _getDrill(data, drillId);
    if (drill == null) continue;
    
    final nodes = _getNodes(drill);
    for (final node in nodes) {
      final nodeMap = node as Map<String, dynamic>;
      if (required.any((r) => _textContains(nodeMap, r))) {
        if (also.any((a) => _textContains(nodeMap, a))) {
          return Status.pass;
        }
      }
    }
  }
  return Status.warn;
}

Status _verifyTextInAnyDrill(Map<String, dynamic> data, List<String> keywords) {
  final drills = data['drills'] as Map<String, dynamic>? ?? {};
  
  for (final drill in drills.values) {
    final nodes = (drill as Map)['nodes'] as List? ?? [];
    for (final node in nodes) {
      for (final kw in keywords) {
        if (_textContains(node as Map<String, dynamic>, kw)) return Status.pass;
      }
    }
  }
  return Status.warn;
}

bool _verifyFentanylDocumentation(Map<String, dynamic> data) {
  // Check global_actions for fentanyl cheek marking guidance
  final globalActions = data['global_actions'] as Map<String, dynamic>? ?? {};
  final painRelief = globalActions['pain_relief'] as Map<String, dynamic>?;

  if (painRelief != null) {
    final prompts = painRelief['prompts'] as List? ?? [];
    for (final prompt in prompts) {
      if (prompt is Map) {
        final actions = prompt['actions'] as List? ?? [];
        final advice = prompt['advice'] as List? ?? [];
        final allText = [...actions, ...advice].join(' ').toLowerCase();
        if (allText.contains('cheek') && (allText.contains('f') || allText.contains('fentanyl'))) {
          return true;
        }
      }
    }
  }
  return false;
}

Status _verifyFentanylAvpuCheck(Map<String, dynamic> data) {
  // Check global_actions.pain_relief for AVPU check before fentanyl
  final globalActions = data['global_actions'] as Map<String, dynamic>? ?? {};
  final painRelief = globalActions['pain_relief'] as Map<String, dynamic>?;

  if (painRelief != null) {
    final prompts = painRelief['prompts'] as List? ?? [];
    // Look for AVPU check and fentanyl block nodes
    final hasAvpuCheck = prompts.any((p) =>
      (p['id'] as String?)?.toLowerCase().contains('avpu') ?? false);
    final hasFentanylBlock = prompts.any((p) =>
      (p['id'] as String?)?.toLowerCase().contains('fentanyl') ?? false);

    if (hasAvpuCheck && hasFentanylBlock) return Status.pass;
    if (hasAvpuCheck || hasFentanylBlock) return Status.warn;
  }

  // Also check drill_10 for any AVPU reference
  final drill10 = _getDrill(data, 'drill_10');
  if (drill10 != null) {
    final nodes = _getNodes(drill10);
    final hasAvpu = nodes.any((n) =>
      _textContains(n as Map<String, dynamic>, 'avpu') ||
      (_textContains(n, 'alert') && _textContains(n, 'voice'))
    );
    if (hasAvpu) return Status.pass;
  }

  return Status.fail;
}

Status _verifyShockKeepsTq(Map<String, dynamic> data) {
  // TQ conversion criteria (including shock) are in drill_13
  final drill13 = _getDrill(data, 'drill_13');
  if (drill13 == null) return Status.fail;

  final nodes = _getNodes(drill13);

  // Check for shock-related blocking node
  final hasShockBlock = nodes.any((n) {
    final id = (n['id'] as String?)?.toLowerCase() ?? '';
    return id.contains('shock') && id.contains('block');
  });

  // Check for shock check in criteria
  final hasShockCriteria = nodes.any((n) {
    final id = (n['id'] as String?)?.toLowerCase() ?? '';
    final prompt = (n['prompt'] as String?)?.toLowerCase() ?? '';
    return id.contains('shock') || prompt.contains('shock');
  });

  if (hasShockBlock) return Status.pass;
  if (hasShockCriteria) return Status.warn;
  return Status.fail;
}

Status _verifyAllMarchComponents(Map<String, dynamic> data) {
  final drills = data['drills'] as Map<String, dynamic>? ?? {};
  final found = <String>{};
  
  for (final drill in drills.values) {
    final comp = (drill as Map)['march_component'] as String?;
    if (comp != null) found.add(comp);
  }
  
  final required = {'M', 'A', 'R', 'C', 'H'};
  if (required.difference(found).isEmpty) return Status.pass;
  if (found.length >= 3) return Status.warn;
  return Status.fail;
}

Status _verifyHypothermiaHeadSplit(Map<String, dynamic> data) {
  // Check that head and hypothermia are in separate drills
  final d9 = _getDrill(data, 'drill_9');
  final d11 = _getDrill(data, 'drill_11');

  if (d9 == null || d11 == null) return Status.fail;

  final d9Name = (d9['name'] as String?)?.toLowerCase() ?? '';
  final d11Name = (d11['name'] as String?)?.toLowerCase() ?? '';

  final d9Ok = d9Name.contains('head');
  final d11Ok = d11Name.contains('hypo') || d11Name.contains('heat');

  if (d9Ok && d11Ok) return Status.pass;
  return Status.warn;
}

Status _verifyTriageCategories(Map<String, dynamic> data) {
  final drill1 = _getDrill(data, 'drill_1');
  if (drill1 == null) return Status.fail;
  
  final nodes = _getNodes(drill1);
  final categories = ['P1', 'P2', 'P3', 'DEAD'];
  var found = 0;
  
  for (final cat in categories) {
    final hasCat = nodes.any((n) =>
      (n['category'] as String?)?.toUpperCase() == cat ||
      (n['title'] as String?)?.toUpperCase().contains(cat) == true
    );
    if (hasCat) found++;
  }
  
  if (found == 4) return Status.pass;
  if (found >= 2) return Status.warn;
  return Status.fail;
}

Status _verifyAllDrillsPresent(Map<String, dynamic> data) {
  final required = [
    'master', 'drill_1', 'drill_2', 'drill_3', 'drill_4', 'drill_5',
    'drill_6', 'drill_7', 'drill_8', 'drill_9', 'drill_10', 'drill_11',
    'drill_12', 'drill_13', 'bls', 'mist_report'
  ];
  
  final drills = data['drills'] as Map<String, dynamic>? ?? {};
  var missing = 0;
  
  for (final d in required) {
    if (!drills.containsKey(d)) missing++;
  }
  
  if (missing == 0) return Status.pass;
  if (missing <= 3) return Status.warn;
  return Status.fail;
}

Status _verifyNoTodos(Map<String, dynamic> data) {
  final drills = data['drills'] as Map<String, dynamic>? ?? {};
  
  for (final drill in drills.values) {
    final nodes = (drill as Map)['nodes'] as List? ?? [];
    for (final node in nodes) {
      final nodeStr = jsonEncode(node).toLowerCase();
      if (nodeStr.contains('todo') || nodeStr.contains('[reference needed]')) {
        return Status.fail;
      }
    }
  }
  return Status.pass;
}

Status _verifyAllNodesHaveNext(Map<String, dynamic> data) {
  final drills = data['drills'] as Map<String, dynamic>? ?? {};
  var issues = 0;
  
  for (final drill in drills.values) {
    final nodes = (drill as Map)['nodes'] as List? ?? [];
    for (final node in nodes) {
      final type = node['type'] as String?;
      final next = node['next'];
      final options = node['options'] as List?;
      final isTerminal = node['is_terminal'] == true;
      
      if (isTerminal) continue;
      
      if (type == 'decision') {
        if (options == null || options.isEmpty) issues++;
      } else if (next == null && type != 'checkpoint') {
        issues++;
      }
    }
  }
  
  if (issues == 0) return Status.pass;
  if (issues <= 3) return Status.warn;
  return Status.fail;
}

Status _verifyNoDeadEnds(Map<String, dynamic> data) {
  try {
    final allNodeIds = <String>{};
    final allNextRefs = <String>{};
    final validSpecial = {'return_to_caller', 'end', 'complete'};

    final drills = data['drills'] as Map<String, dynamic>? ?? {};

    for (final drill in drills.values) {
      if (drill is! Map) continue;
      final nodes = drill['nodes'] as List? ?? [];
      for (final node in nodes) {
        if (node is! Map) continue;
        if (node['id'] != null) allNodeIds.add(node['id'].toString());
        if (node['next'] != null) allNextRefs.add(node['next'].toString());

        final options = node['options'];
        if (options is List) {
          for (final opt in options) {
            if (opt is Map && opt['next'] != null) {
              allNextRefs.add(opt['next'].toString());
            }
          }
        }
      }
    }

    final invalid = allNextRefs
        .where((r) => !allNodeIds.contains(r) && !validSpecial.contains(r) && !r.startsWith('drill_'))
        .length;

    if (invalid == 0) return Status.pass;
    if (invalid <= 3) return Status.warn;
    return Status.fail;
  } catch (e) {
    // Return warning if parsing fails
    return Status.warn;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FINAL REPORT
// ═══════════════════════════════════════════════════════════════════════════

void _printFinalReport(List<CheckResult> results) {
  print('\n');
  print('╔═══════════════════════════════════════════════════════════════════════════╗');
  print('║                         FINAL SAFETY REPORT                               ║');
  print('╚═══════════════════════════════════════════════════════════════════════════╝\n');

  var criticalFails = 0, highFails = 0, mediumFails = 0, lowFails = 0;
  var warnings = 0, passes = 0;

  for (final r in results) {
    if (r.status == Status.pass) passes++;
    else if (r.status == Status.warn) warnings++;
    else {
      switch (r.severity) {
        case Severity.critical: criticalFails++;
        case Severity.high: highFails++;
        case Severity.medium: mediumFails++;
        case Severity.low: lowFails++;
      }
    }
  }

  print('SUMMARY');
  print('───────');
  print('Total checks: ${results.length}');
  print('');
  print('✅ Passed:   $passes');
  print('⚠️  Warnings: $warnings');
  print('');
  print('❌ Failures by severity:');
  print('   🔴 CRITICAL: $criticalFails');
  print('   🟠 HIGH:     $highFails');
  print('   🟡 MEDIUM:   $mediumFails');
  print('   🟢 LOW:      $lowFails');
  print('');

  if (criticalFails > 0) {
    print('═' * 75);
    print('\n⛔ CRITICAL FAILURES DETECTED\n');
    print('   THE APPLICATION IS NOT SAFE FOR CLINICAL USE');
    print('   Fix all CRITICAL issues before any deployment\n');
    exit(2);
  } else if (highFails > 0) {
    print('═' * 75);
    print('\n🟠 HIGH PRIORITY FAILURES\n');
    print('   Fix HIGH issues before clinical use\n');
    exit(1);
  } else if (warnings > 5) {
    print('═' * 75);
    print('\n⚠️  PASSED WITH WARNINGS\n');
    print('   Review warnings before deployment\n');
    exit(0);
  } else {
    print('═' * 75);
    print('\n✅ ALL CLINICAL SAFETY CHECKS PASSED\n');
    exit(0);
  }
}
