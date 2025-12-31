#!/usr/bin/env dart
// ignore_for_file: avoid_print
/// Checks drill content against doctrinal requirements.
///
/// Run with: dart run tool/doctrine_check.dart
library;

import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== Doctrine Compliance Checker ===\n');

  final file = File('assets/drill_definitions.json');
  if (!file.existsSync()) {
    print('ERROR: drill_definitions.json not found');
    print('Run from app/ directory');
    exit(1);
  }

  final content = await file.readAsString();
  final json = jsonDecode(content) as Map<String, dynamic>;

  var issues = 0;
  var todoCount = 0;

  final drills = json['drills'] as Map<String, dynamic>? ?? {};

  // Check for required drills (per ASM doctrine)
  final requiredDrills = {
    'master': 'Master Drill',
    'drill_1': 'Multiple Casualty Triage',
    'drill_2': 'Massive Bleeding (M)',
    'drill_3': 'Airway (A)',
    'drill_4': 'Spinal Injury (A)',
    'drill_5': 'Obstructed Airway (A)',
    'drill_6': 'Respiratory (R)',
    'drill_7': 'Needle Decompression (R)',
    'drill_8': 'Circulation (C)',
    'drill_9': 'Head Injury (H)',
    'drill_10': 'Burns (H)',
    'drill_11': 'Hypothermia (H)',
    'drill_12': 'CASREP',
    'drill_13': 'Pre-Evacuation Care',
  };

  print('Checking required drills...');
  for (final entry in requiredDrills.entries) {
    if (!drills.containsKey(entry.key)) {
      print('  MISSING: ${entry.key} - ${entry.value}');
      issues++;
    } else {
      print('  OK: ${entry.key}');
    }
  }

  // Check MARCH component assignments
  print('\nChecking MARCH component assignments...');
  final marchComponents = <String, List<String>>{
    'M': [],
    'A': [],
    'R': [],
    'C': [],
    'H': [],
  };

  for (final entry in drills.entries) {
    final drill = entry.value as Map<String, dynamic>;
    final component = drill['march_component'] as String?;
    if (component != null && marchComponents.containsKey(component)) {
      marchComponents[component]!.add(entry.key);
    }
  }

  for (final entry in marchComponents.entries) {
    if (entry.value.isEmpty) {
      print('  WARNING: No drills assigned to MARCH-${entry.key}');
      issues++;
    } else {
      print('  ${entry.key}: ${entry.value.join(", ")}');
    }
  }

  // Check for UK English spelling
  print('\nChecking UK English spelling...');
  final usSpellings = {
    'hemorrhage': 'haemorrhage',
    'color': 'colour',
    'behavior': 'behaviour',
    'center': 'centre',
    'defense': 'defence',
    'analyze': 'analyse',
    'organize': 'organise',
  };

  void checkText(String text, String location) {
    for (final entry in usSpellings.entries) {
      if (text.toLowerCase().contains(entry.key)) {
        print('  WARNING: US spelling "${entry.key}" at $location (use "${entry.value}")');
        issues++;
      }
    }
  }

  for (final drillEntry in drills.entries) {
    final drill = drillEntry.value as Map<String, dynamic>;
    final nodes = drill['nodes'] as List<dynamic>? ?? [];

    for (final node in nodes) {
      final nodeMap = node as Map<String, dynamic>;
      final nodeId = nodeMap['id'] as String? ?? 'unknown';
      final location = '${drillEntry.key}/$nodeId';

      final prompt = nodeMap['prompt'] as String? ?? '';
      checkText(prompt, location);

      final actions = nodeMap['actions'] as List<dynamic>?;
      if (actions != null) {
        for (final action in actions) {
          if (action is String) {
            checkText(action, location);
          }
        }
      }
    }
  }

  // Count TODO placeholders
  print('\nChecking for incomplete content (TODOs)...');
  for (final drillEntry in drills.entries) {
    final drill = drillEntry.value as Map<String, dynamic>;
    final nodes = drill['nodes'] as List<dynamic>? ?? [];

    for (final node in nodes) {
      final nodeMap = node as Map<String, dynamic>;
      final nodeId = nodeMap['id'] as String? ?? 'unknown';

      final prompt = nodeMap['prompt'] as String? ?? '';
      if (prompt.contains('[TODO')) {
        print('  TODO: ${drillEntry.key}/$nodeId - prompt');
        todoCount++;
      }

      final actions = nodeMap['actions'] as List<dynamic>?;
      if (actions != null) {
        for (final action in actions) {
          if (action is String && action.contains('[TODO')) {
            print('  TODO: ${drillEntry.key}/$nodeId - actions');
            todoCount++;
            break;
          }
        }
      }

      final description = drill['description'] as String? ?? '';
      if (description.contains('TODO')) {
        print('  TODO: ${drillEntry.key} - description');
        todoCount++;
      }
    }
  }

  // Check for required intervention types
  print('\nChecking intervention types...');
  final requiredInterventions = [
    'TOURNIQUET',
    'CHEST_SEAL',
    'NPA',
    'RECOVERY_POSITION',
    'WOUND_PACKING',
  ];

  final interventionTypes = json['intervention_types'] as Map<String, dynamic>? ?? {};
  for (final required in requiredInterventions) {
    if (!interventionTypes.containsKey(required)) {
      print('  MISSING: $required');
      issues++;
    } else {
      print('  OK: $required');
    }
  }

  // Check triage categories
  print('\nChecking triage categories...');
  final requiredCategories = ['P1', 'P2', 'P3', 'DEAD'];
  final triageCategories = json['triage_categories'] as Map<String, dynamic>? ?? {};

  for (final required in requiredCategories) {
    if (!triageCategories.containsKey(required)) {
      print('  MISSING: $required');
      issues++;
    } else {
      print('  OK: $required');
    }
  }

  // Summary
  print('\n=== Summary ===');
  print('Issues found: $issues');
  print('TODO placeholders: $todoCount');

  if (issues > 0) {
    print('\nDOCTRINE CHECK FAILED');
    exit(1);
  } else if (todoCount > 0) {
    print('\nDoctrine check passed with $todoCount incomplete items');
    exit(0);
  } else {
    print('\nDoctrine check passed');
    exit(0);
  }
}
