#!/usr/bin/env dart
// ignore_for_file: avoid_print
/// Validates drill_definitions.json structure and node references.
///
/// Run with: dart run tool/validate_drills.dart
library;

import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== Drill Definitions Validator ===\n');

  final file = File('assets/drill_definitions.json');
  if (!file.existsSync()) {
    print('ERROR: drill_definitions.json not found');
    print('Run from app/ directory');
    exit(1);
  }

  final content = await file.readAsString();
  final Map<String, dynamic> json;

  try {
    json = jsonDecode(content) as Map<String, dynamic>;
  } catch (e) {
    print('ERROR: Invalid JSON: $e');
    exit(1);
  }

  var errors = 0;
  var warnings = 0;

  // Collect all node IDs across all drills
  final allNodeIds = <String>{};
  final drills = json['drills'] as Map<String, dynamic>? ?? {};

  for (final entry in drills.entries) {
    final drill = entry.value as Map<String, dynamic>;
    final nodes = drill['nodes'] as List<dynamic>? ?? [];

    for (final node in nodes) {
      final nodeMap = node as Map<String, dynamic>;
      final id = nodeMap['id'] as String?;
      if (id != null) {
        if (allNodeIds.contains(id)) {
          print('ERROR: Duplicate node ID: $id');
          errors++;
        }
        allNodeIds.add(id);
      }
    }
  }

  // Add special nodes
  allNodeIds.add('end');

  print('Found ${allNodeIds.length} unique node IDs across ${drills.length} drills\n');

  // Validate each drill
  for (final entry in drills.entries) {
    final drillId = entry.key;
    final drill = entry.value as Map<String, dynamic>;

    print('Checking drill: $drillId');

    // Check required fields
    if (drill['id'] == null) {
      print('  ERROR: Missing "id" field');
      errors++;
    }

    if (drill['name'] == null) {
      print('  ERROR: Missing "name" field');
      errors++;
    }

    final nodes = drill['nodes'] as List<dynamic>? ?? [];
    if (nodes.isEmpty) {
      print('  ERROR: No nodes defined');
      errors++;
      continue;
    }

    // Check each node
    for (final node in nodes) {
      final nodeMap = node as Map<String, dynamic>;
      final nodeId = nodeMap['id'] as String? ?? 'unknown';
      final nodeType = nodeMap['type'] as String?;

      // Check required node fields
      if (nodeMap['id'] == null) {
        print('  ERROR: Node missing "id" field');
        errors++;
      }

      if (nodeType == null) {
        print('  ERROR: Node $nodeId missing "type" field');
        errors++;
      }

      if (nodeMap['title'] == null) {
        print('  WARNING: Node $nodeId missing "title" field');
        warnings++;
      }

      // Check "next" references
      final next = nodeMap['next'] as String?;
      if (next != null && !allNodeIds.contains(next)) {
        print('  ERROR: Node $nodeId references unknown node: $next');
        errors++;
      }

      // Check option references
      final options = nodeMap['options'];
      if (options is List) {
        for (final option in options) {
          if (option is Map<String, dynamic>) {
            final optionNext = option['next'] as String?;
            if (optionNext != null && !allNodeIds.contains(optionNext)) {
              print('  ERROR: Node $nodeId option references unknown node: $optionNext');
              errors++;
            }
          }
        }
      }

      // Check for TODO placeholders
      final prompt = nodeMap['prompt'] as String? ?? '';
      if (prompt.contains('[TODO')) {
        print('  WARNING: Node $nodeId has TODO placeholder in prompt');
        warnings++;
      }

      final actions = nodeMap['actions'] as List<dynamic>?;
      if (actions != null) {
        for (final action in actions) {
          if (action is String && action.contains('[TODO')) {
            print('  WARNING: Node $nodeId has TODO placeholder in actions');
            warnings++;
            break;
          }
        }
      }

      // Validate node types
      final validTypes = {
        'decision',
        'instruction',
        'action',
        'checkpoint',
        'triage_assignment',
        'casrep_form',
        'single_select',
        'multi_select',
        'casualty_selection',
      };

      if (nodeType != null && !validTypes.contains(nodeType)) {
        print('  WARNING: Node $nodeId has unknown type: $nodeType');
        warnings++;
      }

      // Check decision nodes have options
      if (nodeType == 'decision') {
        if (options == null || (options is List && options.isEmpty)) {
          print('  ERROR: Decision node $nodeId missing options');
          errors++;
        }
      }

      // Check action nodes have actions or next
      if (nodeType == 'action') {
        if (next == null && options == null) {
          print('  ERROR: Action node $nodeId missing "next" field');
          errors++;
        }
      }
    }
  }

  // Check intervention types
  final interventionTypes = json['intervention_types'] as Map<String, dynamic>? ?? {};
  print('\nFound ${interventionTypes.length} intervention types');

  // Check triage categories
  final triageCategories = json['triage_categories'] as Map<String, dynamic>? ?? {};
  print('Found ${triageCategories.length} triage categories');

  // Summary
  print('\n=== Summary ===');
  print('Drills: ${drills.length}');
  print('Nodes: ${allNodeIds.length - 1}'); // -1 for 'end'
  print('Errors: $errors');
  print('Warnings: $warnings');

  if (errors > 0) {
    print('\nVALIDATION FAILED');
    exit(1);
  } else if (warnings > 0) {
    print('\nValidation passed with warnings');
    exit(0);
  } else {
    print('\nValidation passed');
    exit(0);
  }
}
