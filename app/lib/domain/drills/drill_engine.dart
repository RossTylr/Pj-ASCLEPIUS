/// Drill Engine - Deterministic finite state machine for TCCC drill flow.
/// 
/// This is the core domain logic that drives the triage application.
/// It is pure Dart with no Flutter dependencies, making it fully testable.
library;

import 'dart:convert';
import 'package:collection/collection.dart';

import 'drill_types.dart';

/// Events that can be sent to the drill engine.
sealed class DrillEvent {
  const DrillEvent();
}

/// User answered a binary (yes/no) decision.
class AnswerDecision extends DrillEvent {
  final String optionLabel;
  final String nextNodeId;
  
  const AnswerDecision({
    required this.optionLabel,
    required this.nextNodeId,
  });
}

/// User completed an action step.
class CompleteAction extends DrillEvent {
  final Map<String, dynamic>? inputData;
  
  const CompleteAction({this.inputData});
}

/// User acknowledged an instruction.
class AcknowledgeInstruction extends DrillEvent {
  const AcknowledgeInstruction();
}

/// User acknowledged a checkpoint.
class AcknowledgeCheckpoint extends DrillEvent {
  const AcknowledgeCheckpoint();
}

/// User assigned a triage category.
class AssignTriageCategory extends DrillEvent {
  final String casualtyId;
  final TriageCategory category;
  
  const AssignTriageCategory({
    required this.casualtyId,
    required this.category,
  });
}

/// User selected a casualty to treat.
class SelectCasualty extends DrillEvent {
  final String casualtyId;
  
  const SelectCasualty({required this.casualtyId});
}

/// User selected option(s) in single/multi select.
class SelectOptions extends DrillEvent {
  final List<String> selectedOptions;
  
  const SelectOptions({required this.selectedOptions});
}

/// User submitted CASREP form.
class SubmitCasrep extends DrillEvent {
  final Map<String, dynamic> casrepData;
  
  const SubmitCasrep({required this.casrepData});
}

/// Jump directly to a specific drill.
class JumpToDrill extends DrillEvent {
  final String drillId;
  final String? nodeId;
  
  const JumpToDrill({required this.drillId, this.nodeId});
}

/// Restart from Master Drill.
class RestartIncident extends DrillEvent {
  const RestartIncident();
}

/// History entry for audit trail.
class DrillHistoryEntry {
  final String nodeId;
  final String drillId;
  final DateTime timestamp;
  final DrillEvent? event;
  final Map<String, dynamic>? inputData;
  
  const DrillHistoryEntry({
    required this.nodeId,
    required this.drillId,
    required this.timestamp,
    this.event,
    this.inputData,
  });
  
  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'drillId': drillId,
    'timestamp': timestamp.toIso8601String(),
    'inputData': inputData,
  };
}

/// Current state of the drill engine.
class DrillState {
  /// Current drill ID (e.g., 'master', 'drill_1', 'drill_2')
  final String currentDrillId;
  
  /// Current node ID within the drill
  final String currentNodeId;
  
  /// Context data accumulated during the drill
  final DrillContext context;
  
  /// History of all visited nodes
  final List<DrillHistoryEntry> history;
  
  /// Whether the drill flow has completed
  final bool isComplete;
  
  /// Error message if in error state
  final String? error;
  
  const DrillState({
    required this.currentDrillId,
    required this.currentNodeId,
    required this.context,
    required this.history,
    this.isComplete = false,
    this.error,
  });
  
  /// Initial state - always starts at Master Drill.
  factory DrillState.initial({
    required String incidentId,
    bool underEffectiveEnemyFire = false,
  }) {
    return DrillState(
      currentDrillId: 'master',
      currentNodeId: 'master_start',
      context: DrillContext(
        incidentId: incidentId,
        underEffectiveEnemyFire: underEffectiveEnemyFire,
        currentCasualtyId: null,
        casualties: {},
        marchStatus: {},
        casrepData: null,
      ),
      history: [
        DrillHistoryEntry(
          nodeId: 'master_start',
          drillId: 'master',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }
  
  DrillState copyWith({
    String? currentDrillId,
    String? currentNodeId,
    DrillContext? context,
    List<DrillHistoryEntry>? history,
    bool? isComplete,
    String? error,
  }) {
    return DrillState(
      currentDrillId: currentDrillId ?? this.currentDrillId,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      context: context ?? this.context,
      history: history ?? this.history,
      isComplete: isComplete ?? this.isComplete,
      error: error,
    );
  }
}

/// Accumulated context during drill execution.
class DrillContext {
  final String incidentId;
  final bool underEffectiveEnemyFire;
  final String? currentCasualtyId;
  final Map<String, CasualtyContext> casualties;
  final Map<MarchComponent, bool> marchStatus;
  final Map<String, dynamic>? casrepData;
  
  const DrillContext({
    required this.incidentId,
    required this.underEffectiveEnemyFire,
    required this.currentCasualtyId,
    required this.casualties,
    required this.marchStatus,
    required this.casrepData,
  });
  
  DrillContext copyWith({
    String? incidentId,
    bool? underEffectiveEnemyFire,
    String? currentCasualtyId,
    Map<String, CasualtyContext>? casualties,
    Map<MarchComponent, bool>? marchStatus,
    Map<String, dynamic>? casrepData,
  }) {
    return DrillContext(
      incidentId: incidentId ?? this.incidentId,
      underEffectiveEnemyFire: underEffectiveEnemyFire ?? this.underEffectiveEnemyFire,
      currentCasualtyId: currentCasualtyId ?? this.currentCasualtyId,
      casualties: casualties ?? this.casualties,
      marchStatus: marchStatus ?? this.marchStatus,
      casrepData: casrepData ?? this.casrepData,
    );
  }
  
  CasualtyContext? get currentCasualty => 
      currentCasualtyId != null ? casualties[currentCasualtyId] : null;
}

/// Context for a single casualty.
class CasualtyContext {
  final String id;
  final TriageCategory? triageCategory;
  final Map<String, dynamic> assessments;
  final List<InterventionRecord> interventions;
  
  const CasualtyContext({
    required this.id,
    this.triageCategory,
    this.assessments = const {},
    this.interventions = const [],
  });
  
  CasualtyContext copyWith({
    String? id,
    TriageCategory? triageCategory,
    Map<String, dynamic>? assessments,
    List<InterventionRecord>? interventions,
  }) {
    return CasualtyContext(
      id: id ?? this.id,
      triageCategory: triageCategory ?? this.triageCategory,
      assessments: assessments ?? this.assessments,
      interventions: interventions ?? this.interventions,
    );
  }
}

/// Record of an intervention performed.
class InterventionRecord {
  final InterventionType type;
  final DateTime timestamp;
  final Map<String, dynamic> details;
  
  const InterventionRecord({
    required this.type,
    required this.timestamp,
    required this.details,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };
}

/// The drill engine processes events and produces new states.
class DrillEngine {
  final DrillDefinitions definitions;
  final UserRole userRole;
  
  const DrillEngine({
    required this.definitions,
    required this.userRole,
  });
  
  /// Load drill definitions from JSON string.
  static DrillDefinitions loadDefinitions(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return _parseDefinitions(json);
  }
  
  /// Process an event and return the new state.
  DrillState transition(DrillState current, DrillEvent event) {
    if (current.isComplete) {
      return current.copyWith(
        error: 'Drill flow is complete. Start new incident to continue.',
      );
    }
    
    try {
      return switch (event) {
        final AnswerDecision e => _handleAnswerDecision(current, e),
        final CompleteAction e => _handleCompleteAction(current, e),
        final AcknowledgeInstruction e => _handleAcknowledgeInstruction(current, e),
        final AcknowledgeCheckpoint e => _handleAcknowledgeCheckpoint(current, e),
        final AssignTriageCategory e => _handleAssignTriageCategory(current, e),
        final SelectCasualty e => _handleSelectCasualty(current, e),
        final SelectOptions e => _handleSelectOptions(current, e),
        final SubmitCasrep e => _handleSubmitCasrep(current, e),
        final JumpToDrill e => _handleJumpToDrill(current, e),
        RestartIncident() => _handleRestartIncident(current),
      };
    } catch (e) {
      return current.copyWith(error: 'Error processing event: $e');
    }
  }
  
  /// Get the current node definition.
  DrillNode? getCurrentNode(DrillState state) {
    final drill = definitions.drills[state.currentDrillId];
    if (drill == null) return null;
    
    return drill.nodes.firstWhereOrNull((n) => n.id == state.currentNodeId);
  }
  
  /// Check if a node requires medic role.
  bool nodeRequiresMedic(DrillNode node) {
    return node.roleRequired == true;
  }
  
  /// Check if user can access current node based on role.
  bool canAccessCurrentNode(DrillState state) {
    final node = getCurrentNode(state);
    if (node == null) return false;
    if (!nodeRequiresMedic(node)) return true;
    return userRole == UserRole.medic;
  }
  
  // --- Private transition handlers ---
  
  DrillState _handleAnswerDecision(DrillState current, AnswerDecision event) {
    final node = getCurrentNode(current);
    if (node == null || node.type != DrillNodeType.decision) {
      return current.copyWith(error: 'Invalid state for decision');
    }
    
    // Update context based on specific decisions
    var newContext = current.context;
    if (current.currentNodeId == 'master_start' && event.optionLabel == 'YES') {
      newContext = newContext.copyWith(underEffectiveEnemyFire: true);
    }
    
    return _moveToNode(
      current,
      event.nextNodeId,
      event: event,
      context: newContext,
    );
  }
  
  DrillState _handleCompleteAction(DrillState current, CompleteAction event) {
    final node = getCurrentNode(current);
    if (node == null || node.type != DrillNodeType.action) {
      return current.copyWith(error: 'Invalid state for action');
    }
    
    // Record intervention if applicable
    var newContext = current.context;
    if (node.interventionType != null && event.inputData != null) {
      final interventionType = _parseInterventionType(node.interventionType!);
      if (interventionType != null && newContext.currentCasualtyId != null) {
        final casualty = newContext.casualties[newContext.currentCasualtyId];
        if (casualty != null) {
          final newIntervention = InterventionRecord(
            type: interventionType,
            timestamp: DateTime.now(),
            details: event.inputData!,
          );
          final updatedCasualty = casualty.copyWith(
            interventions: [...casualty.interventions, newIntervention],
          );
          newContext = newContext.copyWith(
            casualties: {
              ...newContext.casualties,
              newContext.currentCasualtyId!: updatedCasualty,
            },
          );
        }
      }
    }
    
    final nextNodeId = node.next;
    if (nextNodeId == null) {
      return current.copyWith(error: 'No next node defined for action');
    }
    
    return _moveToNode(current, nextNodeId, event: event, context: newContext);
  }
  
  DrillState _handleAcknowledgeInstruction(
    DrillState current,
    AcknowledgeInstruction event,
  ) {
    final node = getCurrentNode(current);
    if (node == null || node.type != DrillNodeType.instruction) {
      return current.copyWith(error: 'Invalid state for instruction');
    }

    final nextNodeId = node.next;
    if (nextNodeId == null) {
      return current.copyWith(error: 'No next node defined for instruction');
    }

    return _moveToNode(current, nextNodeId, event: event);
  }

  DrillState _handleAcknowledgeCheckpoint(
    DrillState current,
    AcknowledgeCheckpoint event,
  ) {
    final node = getCurrentNode(current);
    if (node == null || node.type != DrillNodeType.checkpoint) {
      return current.copyWith(error: 'Invalid state for checkpoint');
    }

    // Update MARCH status if this checkpoint has a component
    var newContext = current.context;
    if (node.marchComponent != null) {
      final component = _parseMarchComponent(node.marchComponent!);
      if (component != null) {
        newContext = newContext.copyWith(
          marchStatus: {...newContext.marchStatus, component: true},
        );
      }
    }

    final nextNodeId = node.next;
    if (nextNodeId == null) {
      return current.copyWith(error: 'No next node defined for checkpoint');
    }

    return _moveToNode(current, nextNodeId, event: event, context: newContext);
  }
  
  DrillState _handleAssignTriageCategory(
    DrillState current,
    AssignTriageCategory event,
  ) {
    final node = getCurrentNode(current);
    if (node == null || node.type != DrillNodeType.triageAssignment) {
      return current.copyWith(error: 'Invalid state for triage assignment');
    }
    
    // Create or update casualty with triage category
    final casualties = Map<String, CasualtyContext>.from(current.context.casualties);
    final existingCasualty = casualties[event.casualtyId];
    
    casualties[event.casualtyId] = existingCasualty?.copyWith(
      triageCategory: event.category,
    ) ?? CasualtyContext(
      id: event.casualtyId,
      triageCategory: event.category,
    );
    
    final newContext = current.context.copyWith(casualties: casualties);
    
    final nextNodeId = node.next;
    if (nextNodeId == null) {
      return current.copyWith(error: 'No next node defined');
    }
    
    return _moveToNode(current, nextNodeId, event: event, context: newContext);
  }
  
  DrillState _handleSelectCasualty(DrillState current, SelectCasualty event) {
    final node = getCurrentNode(current);
    if (node == null || node.type != DrillNodeType.casualtySelection) {
      return current.copyWith(error: 'Invalid state for casualty selection');
    }
    
    // Set current casualty
    final newContext = current.context.copyWith(
      currentCasualtyId: event.casualtyId,
    );
    
    final nextNodeId = node.next;
    if (nextNodeId == null) {
      return current.copyWith(error: 'No next node defined');
    }
    
    return _moveToNode(current, nextNodeId, event: event, context: newContext);
  }
  
  DrillState _handleSelectOptions(DrillState current, SelectOptions event) {
    final node = getCurrentNode(current);
    if (node == null || 
        (node.type != DrillNodeType.singleSelect && 
         node.type != DrillNodeType.multiSelect)) {
      return current.copyWith(error: 'Invalid state for option selection');
    }
    
    // Store selection in current casualty's assessments
    var newContext = current.context;
    if (newContext.currentCasualtyId != null) {
      final casualty = newContext.casualties[newContext.currentCasualtyId];
      if (casualty != null) {
        final updatedAssessments = Map<String, dynamic>.from(casualty.assessments);
        updatedAssessments[node.id] = event.selectedOptions;
        
        newContext = newContext.copyWith(
          casualties: {
            ...newContext.casualties,
            newContext.currentCasualtyId!: casualty.copyWith(
              assessments: updatedAssessments,
            ),
          },
        );
      }
    }
    
    final nextNodeId = node.next;
    if (nextNodeId == null) {
      return current.copyWith(error: 'No next node defined');
    }
    
    return _moveToNode(current, nextNodeId, event: event, context: newContext);
  }
  
  DrillState _handleSubmitCasrep(DrillState current, SubmitCasrep event) {
    final node = getCurrentNode(current);
    if (node == null || node.type != DrillNodeType.casrepForm) {
      return current.copyWith(error: 'Invalid state for CASREP submission');
    }
    
    final newContext = current.context.copyWith(casrepData: event.casrepData);
    
    final nextNodeId = node.next;
    if (nextNodeId == null) {
      return current.copyWith(error: 'No next node defined');
    }
    
    return _moveToNode(current, nextNodeId, event: event, context: newContext);
  }
  
  DrillState _handleJumpToDrill(DrillState current, JumpToDrill event) {
    final targetDrill = definitions.drills[event.drillId];
    if (targetDrill == null) {
      return current.copyWith(error: 'Unknown drill: ${event.drillId}');
    }
    
    final targetNodeId = event.nodeId ?? targetDrill.nodes.first.id;
    final targetNode = targetDrill.nodes.firstWhereOrNull(
      (n) => n.id == targetNodeId,
    );
    
    if (targetNode == null) {
      return current.copyWith(error: 'Unknown node: $targetNodeId');
    }
    
    return _moveToNode(
      current, 
      targetNodeId, 
      drillId: event.drillId,
      event: event,
    );
  }
  
  DrillState _handleRestartIncident(DrillState current) {
    return DrillState.initial(
      incidentId: current.context.incidentId,
    );
  }
  
  /// Move to a new node, handling drill transitions.
  DrillState _moveToNode(
    DrillState current,
    String nodeId, {
    String? drillId,
    DrillEvent? event,
    DrillContext? context,
  }) {
    // Determine target drill
    var targetDrillId = drillId ?? current.currentDrillId;
    
    // Check if nodeId references another drill
    if (nodeId.startsWith('drill_') && !nodeId.contains('_start')) {
      // This is a node within a drill, keep current drill
    } else if (nodeId.endsWith('_start')) {
      // This is a drill start node, switch drills
      targetDrillId = nodeId.replaceAll('_start', '');
      if (targetDrillId == 'master') targetDrillId = 'master';
    }
    
    // Validate target drill exists
    final targetDrill = definitions.drills[targetDrillId];
    if (targetDrill == null) {
      // Try to find the node in any drill
      for (final entry in definitions.drills.entries) {
        if (entry.value.nodes.any((n) => n.id == nodeId)) {
          targetDrillId = entry.key;
          break;
        }
      }
    }
    
    // Handle 'end' node
    if (nodeId == 'end') {
      return current.copyWith(
        isComplete: true,
        context: context ?? current.context,
        history: [
          ...current.history,
          DrillHistoryEntry(
            nodeId: 'end',
            drillId: current.currentDrillId,
            timestamp: DateTime.now(),
            event: event,
          ),
        ],
      );
    }
    
    // Update MARCH status on checkpoint nodes
    var newContext = context ?? current.context;
    final currentNode = getCurrentNode(current);
    if (currentNode?.type == DrillNodeType.checkpoint && 
        currentNode?.marchComponent != null) {
      final component = _parseMarchComponent(currentNode!.marchComponent!);
      if (component != null) {
        newContext = newContext.copyWith(
          marchStatus: {...newContext.marchStatus, component: true},
        );
      }
    }
    
    return current.copyWith(
      currentDrillId: targetDrillId,
      currentNodeId: nodeId,
      context: newContext,
      history: [
        ...current.history,
        DrillHistoryEntry(
          nodeId: nodeId,
          drillId: targetDrillId,
          timestamp: DateTime.now(),
          event: event,
        ),
      ],
    );
  }
  
  InterventionType? _parseInterventionType(String type) {
    return switch (type.toUpperCase()) {
      'TOURNIQUET' => InterventionType.tourniquet,
      'CHEST_SEAL' => InterventionType.chestSeal,
      'NEEDLE_DECOMPRESSION' => InterventionType.needleDecompression,
      'NPA' => InterventionType.npa,
      'OPA' => InterventionType.opa,
      'RECOVERY_POSITION' => InterventionType.recoveryPosition,
      'WOUND_PACKING' => InterventionType.woundPacking,
      'PELVIC_BINDER' => InterventionType.pelvicBinder,
      'IV_IO' => InterventionType.ivIo,
      'ANALGESIA' => InterventionType.analgesia,
      'HYPOTHERMIA_MGMT' => InterventionType.hypothermiaMgmt,
      _ => null,
    };
  }
  
  MarchComponent? _parseMarchComponent(String component) {
    return switch (component.toUpperCase()) {
      'M' => MarchComponent.m,
      'A' => MarchComponent.a,
      'R' => MarchComponent.r,
      'C' => MarchComponent.c,
      'H' => MarchComponent.h,
      _ => null,
    };
  }
  
  /// Parse drill definitions from raw JSON map.
  static DrillDefinitions _parseDefinitions(Map<String, dynamic> json) {
    final drillsJson = json['drills'] as Map<String, dynamic>;
    final drills = <String, DrillDefinition>{};
    
    for (final entry in drillsJson.entries) {
      final drillJson = entry.value as Map<String, dynamic>;
      final nodesJson = drillJson['nodes'] as List<dynamic>;
      
      final nodes = nodesJson.map((nodeJson) {
        final node = nodeJson as Map<String, dynamic>;
        return DrillNode(
          id: node['id'] as String,
          type: _parseNodeType(node['type'] as String),
          title: node['title'] as String,
          prompt: node['prompt'] as String,
          guidance: node['guidance'] as String?,
          warnings: (node['warnings'] as List<dynamic>?)?.cast<String>(),
          actions: (node['actions'] as List<dynamic>?)?.cast<String>(),
          options: (node['options'] as List<dynamic>?)?.map((o) {
            final opt = o as Map<String, dynamic>;
            return DrillOption(
              label: opt['label'] as String,
              next: opt['next'] as String,
              value: opt['value'] as String?,
            );
          }).toList(),
          next: node['next'] as String?,
          interventionType: node['intervention_type'] as String?,
          marchComponent: node['march_component'] as String?,
          category: node['category'] as String?,
          roleRequired: node['role_required'] as bool?,
          fields: (node['fields'] as List<dynamic>?)?.cast<String>(),
        );
      }).toList();
      
      drills[entry.key] = DrillDefinition(
        id: entry.key,
        name: drillJson['name'] as String,
        description: drillJson['description'] as String?,
        marchComponent: drillJson['march_component'] as String?,
        roleRequired: drillJson['role_required'] as String?,
        nodes: nodes,
      );
    }
    
    // Parse intervention types
    final interventionTypesJson = json['intervention_types'] as Map<String, dynamic>? ?? {};
    final interventionTypes = <String, InterventionTypeDefinition>{};
    for (final entry in interventionTypesJson.entries) {
      final def = entry.value as Map<String, dynamic>;
      interventionTypes[entry.key] = InterventionTypeDefinition(
        name: def['name'] as String,
        fields: (def['fields'] as List<dynamic>).cast<String>(),
        timeCritical: def['time_critical'] as bool? ?? false,
        roleRequired: def['role_required'] as String?,
      );
    }
    
    // Parse triage categories
    final triageCategoriesJson = json['triage_categories'] as Map<String, dynamic>? ?? {};
    final triageCategories = <String, TriageCategoryDefinition>{};
    for (final entry in triageCategoriesJson.entries) {
      final def = entry.value as Map<String, dynamic>;
      triageCategories[entry.key] = TriageCategoryDefinition(
        name: def['name'] as String,
        color: def['color'] as String,
        description: def['description'] as String?,
      );
    }
    
    return DrillDefinitions(
      version: json['version'] as String,
      doctrineSource: json['doctrine_source'] as String,
      lastUpdated: json['last_updated'] as String,
      drills: drills,
      interventionTypes: interventionTypes,
      triageCategories: triageCategories,
    );
  }
  
  static DrillNodeType _parseNodeType(String type) {
    return switch (type) {
      'decision' => DrillNodeType.decision,
      'instruction' => DrillNodeType.instruction,
      'action' => DrillNodeType.action,
      'checkpoint' => DrillNodeType.checkpoint,
      'triage_assignment' => DrillNodeType.triageAssignment,
      'casualty_selection' => DrillNodeType.casualtySelection,
      'single_select' => DrillNodeType.singleSelect,
      'multi_select' => DrillNodeType.multiSelect,
      'casrep_form' => DrillNodeType.casrepForm,
      _ => DrillNodeType.instruction,
    };
  }
}
