// Drill Engine Tests
//
// Unit tests for the core drill state machine logic.
import 'package:flutter_test/flutter_test.dart';

import 'package:triage_drills/domain/drills/drill_engine.dart';
import 'package:triage_drills/domain/drills/drill_types.dart';

/// Minimal drill definitions for testing.
const testDrillJson = '''
{
  "version": "1.0.0-test",
  "doctrine_source": "Test",
  "last_updated": "2025-01-01",
  "drills": {
    "master": {
      "id": "master",
      "name": "Master Drill",
      "nodes": [
        {
          "id": "master_start",
          "type": "decision",
          "title": "Test",
          "prompt": "Are you under fire?",
          "options": [
            {"label": "YES", "next": "master_under_fire"},
            {"label": "NO", "next": "master_safe"}
          ]
        },
        {
          "id": "master_under_fire",
          "type": "instruction",
          "title": "Under Fire",
          "prompt": "Take cover",
          "next": "master_safe"
        },
        {
          "id": "master_safe",
          "type": "decision",
          "title": "Casualties",
          "prompt": "Multiple casualties?",
          "options": [
            {"label": "YES", "next": "drill_1_start"},
            {"label": "NO", "next": "drill_2_start"}
          ]
        }
      ]
    },
    "drill_1": {
      "id": "drill_1",
      "name": "Triage",
      "nodes": [
        {
          "id": "drill_1_start",
          "type": "instruction",
          "title": "Triage",
          "prompt": "Begin triage",
          "next": "drill_1_assign"
        },
        {
          "id": "drill_1_assign",
          "type": "triage_assignment",
          "title": "Assign",
          "prompt": "Assign category",
          "category": "P1",
          "next": "drill_2_start"
        }
      ]
    },
    "drill_2": {
      "id": "drill_2",
      "name": "Massive Bleeding",
      "march_component": "M",
      "nodes": [
        {
          "id": "drill_2_start",
          "type": "action",
          "title": "Check Bleeding",
          "prompt": "Check for bleeding",
          "actions": ["Visual sweep", "Check limbs"],
          "next": "drill_2_complete"
        },
        {
          "id": "drill_2_complete",
          "type": "checkpoint",
          "title": "M Complete",
          "prompt": "Massive bleeding done",
          "march_component": "M",
          "next": "end"
        }
      ]
    }
  },
  "intervention_types": {},
  "triage_categories": {
    "P1": {"name": "Immediate", "color": "#FF0000"},
    "P2": {"name": "Urgent", "color": "#FFA500"}
  }
}
''';

void main() {
  late DrillDefinitions definitions;
  late DrillEngine engine;
  
  setUp(() {
    definitions = DrillEngine.loadDefinitions(testDrillJson);
    engine = DrillEngine(
      definitions: definitions,
      userRole: UserRole.general,
    );
  });
  
  group('DrillEngine - Initialisation', () {
    test('loads drill definitions from JSON', () {
      expect(definitions.version, '1.0.0-test');
      expect(definitions.drills.length, 3);
      expect(definitions.drills['master'], isNotNull);
      expect(definitions.drills['drill_1'], isNotNull);
      expect(definitions.drills['drill_2'], isNotNull);
    });
    
    test('initial state starts at master drill', () {
      final state = DrillState.initial(incidentId: 'test-123');
      
      expect(state.currentDrillId, 'master');
      expect(state.currentNodeId, 'master_start');
      expect(state.isComplete, false);
      expect(state.context.incidentId, 'test-123');
      expect(state.history.length, 1);
    });
    
    test('initial state records history entry', () {
      final state = DrillState.initial(incidentId: 'test-123');
      
      expect(state.history.first.drillId, 'master');
      expect(state.history.first.nodeId, 'master_start');
    });
  });
  
  group('DrillEngine - Decision Transitions', () {
    test('handles YES answer to under fire question', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      state = engine.transition(
        state,
        const AnswerDecision(
          optionLabel: 'YES',
          nextNodeId: 'master_under_fire',
        ),
      );
      
      expect(state.currentNodeId, 'master_under_fire');
      expect(state.context.underEffectiveEnemyFire, true);
    });
    
    test('handles NO answer to under fire question', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      state = engine.transition(
        state,
        const AnswerDecision(
          optionLabel: 'NO',
          nextNodeId: 'master_safe',
        ),
      );
      
      expect(state.currentNodeId, 'master_safe');
      expect(state.context.underEffectiveEnemyFire, false);
    });
    
    test('decision transitions add to history', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      state = engine.transition(
        state,
        const AnswerDecision(
          optionLabel: 'YES',
          nextNodeId: 'master_under_fire',
        ),
      );
      
      expect(state.history.length, 2);
      expect(state.history.last.nodeId, 'master_under_fire');
    });
  });
  
  group('DrillEngine - Instruction Transitions', () {
    test('acknowledges instruction and moves to next', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      // First navigate to an instruction node
      state = engine.transition(
        state,
        const AnswerDecision(
          optionLabel: 'YES',
          nextNodeId: 'master_under_fire',
        ),
      );
      
      // Now acknowledge the instruction
      state = engine.transition(
        state,
        const AcknowledgeInstruction(),
      );
      
      expect(state.currentNodeId, 'master_safe');
    });
  });
  
  group('DrillEngine - Drill Transitions', () {
    test('transitions from master to drill_1 for multiple casualties', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      // Answer NO to under fire
      state = engine.transition(
        state,
        const AnswerDecision(
          optionLabel: 'NO',
          nextNodeId: 'master_safe',
        ),
      );
      
      // Answer YES to multiple casualties
      state = engine.transition(
        state,
        const AnswerDecision(
          optionLabel: 'YES',
          nextNodeId: 'drill_1_start',
        ),
      );
      
      expect(state.currentDrillId, 'drill_1');
      expect(state.currentNodeId, 'drill_1_start');
    });
    
    test('transitions from master to drill_2 for single casualty', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      // Answer NO to under fire
      state = engine.transition(
        state,
        const AnswerDecision(
          optionLabel: 'NO',
          nextNodeId: 'master_safe',
        ),
      );
      
      // Answer NO to multiple casualties
      state = engine.transition(
        state,
        const AnswerDecision(
          optionLabel: 'NO',
          nextNodeId: 'drill_2_start',
        ),
      );
      
      expect(state.currentDrillId, 'drill_2');
      expect(state.currentNodeId, 'drill_2_start');
    });
  });
  
  group('DrillEngine - Triage Assignment', () {
    test('assigns triage category to casualty', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      // Navigate to triage assignment
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'NO', nextNodeId: 'master_safe'),
      );
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'YES', nextNodeId: 'drill_1_start'),
      );
      state = engine.transition(
        state,
        const AcknowledgeInstruction(),
      );
      
      // Assign triage category
      state = engine.transition(
        state,
        const AssignTriageCategory(
          casualtyId: 'cas-001',
          category: TriageCategory.p1,
        ),
      );
      
      expect(state.context.casualties['cas-001'], isNotNull);
      expect(
        state.context.casualties['cas-001']!.triageCategory,
        TriageCategory.p1,
      );
    });
  });
  
  group('DrillEngine - Action Completion', () {
    test('completes action and moves to next node', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      // Navigate to drill_2 action
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'NO', nextNodeId: 'master_safe'),
      );
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'NO', nextNodeId: 'drill_2_start'),
      );
      
      // Complete the action
      state = engine.transition(
        state,
        const CompleteAction(),
      );
      
      expect(state.currentNodeId, 'drill_2_complete');
    });
  });
  
  group('DrillEngine - MARCH Progress', () {
    test('marks MARCH component complete at checkpoint', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      // Navigate through to checkpoint
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'NO', nextNodeId: 'master_safe'),
      );
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'NO', nextNodeId: 'drill_2_start'),
      );
      state = engine.transition(
        state,
        const CompleteAction(),
      );
      
      // At checkpoint, acknowledge to complete
      state = engine.transition(
        state,
        const AcknowledgeCheckpoint(),
      );

      // M should be marked complete
      expect(state.context.marchStatus[MarchComponent.m], true);
    });
  });

  group('DrillEngine - Completion', () {
    test('marks drill complete when reaching end', () {
      var state = DrillState.initial(incidentId: 'test-123');

      // Full flow through to end
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'NO', nextNodeId: 'master_safe'),
      );
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'NO', nextNodeId: 'drill_2_start'),
      );
      state = engine.transition(
        state,
        const CompleteAction(),
      );
      state = engine.transition(
        state,
        const AcknowledgeCheckpoint(),
      );

      expect(state.isComplete, true);
    });

    test('prevents transitions after completion', () {
      var state = DrillState.initial(incidentId: 'test-123');

      // Navigate to completion
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'NO', nextNodeId: 'master_safe'),
      );
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'NO', nextNodeId: 'drill_2_start'),
      );
      state = engine.transition(
        state,
        const CompleteAction(),
      );
      state = engine.transition(
        state,
        const AcknowledgeCheckpoint(),
      );
      
      // Try to transition after completion
      final attemptedState = engine.transition(
        state,
        const AcknowledgeInstruction(),
      );
      
      expect(attemptedState.error, isNotNull);
    });
  });
  
  group('DrillEngine - Jump to Drill', () {
    test('can jump directly to a specific drill', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      state = engine.transition(
        state,
        const JumpToDrill(drillId: 'drill_2'),
      );
      
      expect(state.currentDrillId, 'drill_2');
      expect(state.currentNodeId, 'drill_2_start');
    });
    
    test('returns error for unknown drill', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      state = engine.transition(
        state,
        const JumpToDrill(drillId: 'nonexistent'),
      );
      
      expect(state.error, contains('Unknown drill'));
    });
  });
  
  group('DrillEngine - Restart', () {
    test('restarts incident to initial state', () {
      var state = DrillState.initial(incidentId: 'test-123');
      
      // Make some progress
      state = engine.transition(
        state,
        const AnswerDecision(optionLabel: 'YES', nextNodeId: 'master_under_fire'),
      );
      state = engine.transition(
        state,
        const AcknowledgeInstruction(),
      );
      
      // Restart
      state = engine.transition(
        state,
        const RestartIncident(),
      );
      
      expect(state.currentDrillId, 'master');
      expect(state.currentNodeId, 'master_start');
      expect(state.history.length, 1);
    });
  });
  
  group('DrillEngine - getCurrentNode', () {
    test('returns current node definition', () {
      final state = DrillState.initial(incidentId: 'test-123');
      final node = engine.getCurrentNode(state);
      
      expect(node, isNotNull);
      expect(node!.id, 'master_start');
      expect(node.type, DrillNodeType.decision);
      expect(node.title, 'Test');
    });
    
    test('returns null for invalid state', () {
      const state = DrillState(
        currentDrillId: 'nonexistent',
        currentNodeId: 'nonexistent',
        context: DrillContext(
          incidentId: 'test',
          underEffectiveEnemyFire: false,
          currentCasualtyId: null,
          casualties: {},
          marchStatus: {},
          casrepData: null,
        ),
        history: [],
      );

      final node = engine.getCurrentNode(state);
      expect(node, isNull);
    });
  });
}
