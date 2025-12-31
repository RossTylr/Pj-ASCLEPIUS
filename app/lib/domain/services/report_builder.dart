/// Report Builder Service
/// 
/// Generates structured CASREP and MIST(AT) reports from casualty data.
library;

import 'dart:convert';

import '../models/models.dart';

/// Builds handover reports in various formats.
class ReportBuilder {
  const ReportBuilder();
  
  /// Build MIST(AT) data for a casualty.
  MistData buildMist({
    required Casualty casualty,
    required List<AssessmentSnapshot> assessments,
    required List<Intervention> interventions,
  }) {
    // Get latest assessment
    final latestAssessment = assessments.isNotEmpty
        ? assessments.reduce((a, b) => 
            a.timestamp.isAfter(b.timestamp) ? a : b)
        : null;
    
    return MistData(
      casualtyId: casualty.id,
      mechanism: casualty.mechanism,
      injuries: _summariseInjuries(interventions),
      signs: latestAssessment?.marchAssessment,
      treatments: interventions,
      age: casualty.ageClass,
      timeOfWounding: casualty.timeOfWounding,
      zapNumber: casualty.zapNumber,
      triageCategory: casualty.triageCategory,
    );
  }
  
  /// Build CASREP data for an incident.
  CasrepData buildCasrep({
    required Incident incident,
    required List<Casualty> casualties,
    String? callsign,
    String? urgency,
    String? evacType,
    String? eta,
    String? specialEquipment,
    List<String>? lifeThreats,
    String? notes,
  }) {
    final p1Count = casualties.where(
      (c) => c.triageCategory == CasualtyTriageCategory.p1
    ).length;
    final p2Count = casualties.where(
      (c) => c.triageCategory == CasualtyTriageCategory.p2
    ).length;
    final p3Count = casualties.where(
      (c) => c.triageCategory == CasualtyTriageCategory.p3
    ).length;
    
    return CasrepData(
      callsign: callsign,
      gridRef: incident.gridRef,
      casualtyCount: casualties.where(
        (c) => c.triageCategory != CasualtyTriageCategory.dead
      ).length,
      p1Count: p1Count,
      p2Count: p2Count,
      p3Count: p3Count,
      medevacRequired: p1Count > 0 || p2Count > 0,
      urgency: urgency ?? (p1Count > 0 ? 'URGENT' : 
               p2Count > 0 ? 'PRIORITY' : 'ROUTINE'),
      evacType: evacType,
      eta: eta,
      specialEquipment: specialEquipment,
      lifeThreats: lifeThreats ?? _deriveLifeThreats(casualties),
      notes: notes,
    );
  }
  
  /// Generate handover summary text.
  String generateHandoverText({
    required MistData mist,
    required Casualty casualty,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('         MIST(AT) HANDOVER');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    
    // Header
    buffer.writeln('ZAP: ${mist.zapNumber ?? "Unknown"}');
    buffer.writeln('PRIORITY: ${casualty.triageCategory.displayName}');
    buffer.writeln();
    
    // M - Mechanism
    buffer.writeln('M - MECHANISM');
    buffer.writeln('  ${mist.mechanism ?? "Not recorded"}');
    buffer.writeln();
    
    // I - Injuries
    buffer.writeln('I - INJURIES');
    buffer.writeln('  ${mist.injuries ?? "Not recorded"}');
    buffer.writeln();
    
    // S - Signs
    buffer.writeln('S - SIGNS');
    if (mist.signs != null) {
      final signs = mist.signs!;
      if (signs.avpu != null) buffer.writeln('  AVPU: ${signs.avpu}');
      if (signs.respiratoryRate != null) {
        buffer.writeln('  RR: ${signs.respiratoryRate}/min');
      }
      if (signs.pulseRate != null) buffer.writeln('  Pulse: ${signs.pulseRate}/min');
      if (signs.bleedingControlled != null) {
        buffer.writeln('  Bleeding: ${signs.bleedingControlled! ? "Controlled" : "ACTIVE"}');
      }
      if (signs.airwayStatus != null) buffer.writeln('  Airway: ${signs.airwayStatus}');
      if (signs.shockPresent != null && signs.shockPresent!) {
        buffer.writeln('  ⚠️ SHOCK PRESENT');
      }
    } else {
      buffer.writeln('  Not recorded');
    }
    buffer.writeln();
    
    // T - Treatment
    buffer.writeln('T - TREATMENT');
    if (mist.treatments != null && mist.treatments!.isNotEmpty) {
      for (final treatment in mist.treatments!) {
        final time = _formatTime(treatment.timestamp);
        buffer.writeln('  [$time] ${_formatIntervention(treatment)}');
      }
    } else {
      buffer.writeln('  None recorded');
    }
    buffer.writeln();
    
    // A - Age
    buffer.writeln('A - AGE');
    buffer.writeln('  ${mist.age?.name.toUpperCase() ?? "Adult (presumed)"}');
    buffer.writeln();
    
    // T - Time
    buffer.writeln('T - TIME OF WOUNDING');
    buffer.writeln('  ${mist.timeOfWounding != null ? _formatDateTime(mist.timeOfWounding!) : "Unknown"}');
    buffer.writeln();
    
    buffer.writeln('═══════════════════════════════════════');
    
    return buffer.toString();
  }
  
  /// Generate CASREP summary text.
  String generateCasrepText(CasrepData casrep) {
    final buffer = StringBuffer();
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('            CASUALTY REPORT');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    
    buffer.writeln('CALL SIGN: ${casrep.callsign ?? "________"}');
    buffer.writeln('GRID REF:  ${casrep.gridRef ?? "________"}');
    buffer.writeln();
    
    buffer.writeln('CASUALTIES: ${casrep.casualtyCount}');
    buffer.writeln('  P1 (Immediate): ${casrep.p1Count}');
    buffer.writeln('  P2 (Urgent):    ${casrep.p2Count}');
    buffer.writeln('  P3 (Delayed):   ${casrep.p3Count}');
    buffer.writeln();
    
    buffer.writeln('MEDEVAC: ${casrep.medevacRequired ? "REQUIRED" : "Not required"}');
    buffer.writeln('URGENCY: ${casrep.urgency ?? "________"}');
    buffer.writeln('TYPE:    ${casrep.evacType ?? "________"}');
    buffer.writeln('ETA:     ${casrep.eta ?? "________"}');
    buffer.writeln();
    
    if (casrep.specialEquipment != null && casrep.specialEquipment!.isNotEmpty) {
      buffer.writeln('SPECIAL EQUIPMENT:');
      buffer.writeln('  ${casrep.specialEquipment}');
      buffer.writeln();
    }
    
    if (casrep.lifeThreats.isNotEmpty) {
      buffer.writeln('LIFE THREATENING CONDITIONS:');
      for (final threat in casrep.lifeThreats) {
        buffer.writeln('  ⚠️ $threat');
      }
      buffer.writeln();
    }
    
    if (casrep.notes != null && casrep.notes!.isNotEmpty) {
      buffer.writeln('NOTES:');
      buffer.writeln('  ${casrep.notes}');
      buffer.writeln();
    }
    
    buffer.writeln('═══════════════════════════════════════');
    
    return buffer.toString();
  }
  
  /// Export MIST data to JSON.
  String exportMistToJson(MistData mist) {
    return const JsonEncoder.withIndent('  ').convert(mist.toJson());
  }
  
  /// Export CASREP data to JSON.
  String exportCasrepToJson(CasrepData casrep) {
    return const JsonEncoder.withIndent('  ').convert(casrep.toJson());
  }
  
  /// Export complete handover package to JSON.
  String exportHandoverPackage({
    required Incident incident,
    required List<Casualty> casualties,
    required Map<String, MistData> mistDataByCasualty,
    required CasrepData casrep,
  }) {
    final package = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'incident': incident.toJson(),
      'casualties': casualties.map((c) => {
        'casualty': c.toJson(),
        'mist': mistDataByCasualty[c.id]?.toJson(),
      }).toList(),
      'casrep': casrep.toJson(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(package);
  }
  
  // --- Private helpers ---
  
  String _summariseInjuries(List<Intervention> interventions) {
    final injuries = <String>[];
    
    for (final intervention in interventions) {
      switch (intervention.type) {
        case InterventionTypeEnum.tourniquet:
          final limb = intervention.details['limb'] as String?;
          injuries.add('Limb haemorrhage${limb != null ? " ($limb)" : ""}');
        case InterventionTypeEnum.chestSeal:
          final side = intervention.details['side'] as String?;
          injuries.add('Chest wound${side != null ? " ($side)" : ""}');
        case InterventionTypeEnum.needleDecompression:
          injuries.add('Tension pneumothorax');
        case InterventionTypeEnum.woundPacking:
          final location = intervention.details['location'] as String?;
          injuries.add('Junctional bleeding${location != null ? " ($location)" : ""}');
        case InterventionTypeEnum.pelvicBinder:
          injuries.add('Suspected pelvic fracture');
        default:
          break;
      }
    }
    
    return injuries.isEmpty ? 'Not recorded' : injuries.join('; ');
  }
  
  List<String> _deriveLifeThreats(List<Casualty> casualties) {
    // This would ideally pull from assessment data
    // For now, return based on triage category
    final threats = <String>{};
    
    for (final casualty in casualties) {
      if (casualty.triageCategory == CasualtyTriageCategory.p1) {
        threats.add('Life-threatening injury (P1 casualty)');
      }
    }
    
    return threats.toList();
  }
  
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
           '${dt.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
           '${dt.month.toString().padLeft(2, '0')}/'
           '${dt.year} '
           '${_formatTime(dt)}';
  }
  
  String _formatIntervention(Intervention intervention) {
    final type = intervention.type.name;
    final details = intervention.details;
    
    return switch (intervention.type) {
      InterventionTypeEnum.tourniquet => 
        'Tourniquet - ${details['limb'] ?? "limb"}',
      InterventionTypeEnum.chestSeal => 
        'Chest seal - ${details['side'] ?? "side"} ${details['type'] ?? ""}',
      InterventionTypeEnum.needleDecompression => 
        'Needle decompression - ${details['side'] ?? "side"}',
      InterventionTypeEnum.npa => 
        'NPA inserted - size ${details['size'] ?? "?"}',
      InterventionTypeEnum.recoveryPosition => 
        'Recovery position',
      InterventionTypeEnum.woundPacking => 
        'Wound packed - ${details['location'] ?? "location"}',
      InterventionTypeEnum.pelvicBinder => 
        'Pelvic binder applied',
      InterventionTypeEnum.ivIo => 
        'IV/IO - ${details['site'] ?? ""} ${details['fluid'] ?? ""}',
      InterventionTypeEnum.analgesia => 
        'Analgesia - ${details['drug'] ?? ""} ${details['dose'] ?? ""}',
      InterventionTypeEnum.hypothermiaMgmt => 
        'Hypothermia prevention',
      _ => type,
    };
  }
}
