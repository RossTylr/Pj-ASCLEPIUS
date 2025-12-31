/// Drill Screen
/// 
/// Main screen for executing drill flow. Displays current drill node
/// and handles user interactions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/drills/drill_engine.dart';
import '../../domain/drills/drill_types.dart';
import '../theme/app_theme.dart';
import '../components/large_action_button.dart';

/// Provider for drill definitions loaded from assets.
final drillDefinitionsProvider = FutureProvider<DrillDefinitions>((ref) async {
  final jsonString = await rootBundle.loadString('assets/drill_definitions.json');
  return DrillEngine.loadDefinitions(jsonString);
});

/// Provider for the drill engine.
final drillEngineProvider = Provider.family<DrillEngine, DrillDefinitions>(
  (ref, definitions) => DrillEngine(
    definitions: definitions,
    userRole: UserRole.general, // TODO: Get from settings
  ),
);

/// Provider for drill state.
final drillStateProvider = StateNotifierProvider<DrillStateNotifier, DrillState?>(
  (ref) => DrillStateNotifier(),
);

/// State notifier for drill state management.
class DrillStateNotifier extends StateNotifier<DrillState?> {
  DrillStateNotifier() : super(null);
  
  void startNewIncident() {
    final incidentId = const Uuid().v4();
    state = DrillState.initial(incidentId: incidentId);
  }
  
  void updateState(DrillState newState) {
    state = newState;
  }
  
  void clear() {
    state = null;
  }
}

/// Main drill screen widget.
class DrillScreen extends ConsumerStatefulWidget {
  const DrillScreen({super.key});
  
  @override
  ConsumerState<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends ConsumerState<DrillScreen> {
  @override
  void initState() {
    super.initState();
    // Start new incident when screen opens
    Future.microtask(() {
      ref.read(drillStateProvider.notifier).startNewIncident();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final definitionsAsync = ref.watch(drillDefinitionsProvider);
    final drillState = ref.watch(drillStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: const Text('DRILL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: definitionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading drills: $error'),
        ),
        data: (definitions) {
          if (drillState == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final engine = ref.read(drillEngineProvider(definitions));
          final currentNode = engine.getCurrentNode(drillState);
          
          if (currentNode == null) {
            return const Center(child: Text('Unknown drill state'));
          }
          
          if (drillState.isComplete) {
            return _buildCompleteView(context);
          }
          
          return _buildDrillNode(
            context,
            engine,
            drillState,
            currentNode,
          );
        },
      ),
    );
  }
  
  Widget _buildDrillNode(
    BuildContext context,
    DrillEngine engine,
    DrillState state,
    DrillNode node,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            _DrillProgress(state: state),
            
            const SizedBox(height: AppTheme.paddingLarge),
            
            // Node title
            Text(
              node.title,
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppTheme.paddingMedium),
            
            // Node prompt
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      node.prompt,
                      style: AppTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    
                    // Warnings
                    if (node.warnings != null && node.warnings!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.paddingMedium),
                      ...node.warnings!.map((w) => _WarningCard(text: w)),
                    ],
                    
                    // Actions list
                    if (node.actions != null && node.actions!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.paddingMedium),
                      _ActionsList(actions: node.actions!),
                    ],
                    
                    // Guidance
                    if (node.guidance != null) ...[
                      const SizedBox(height: AppTheme.paddingMedium),
                      Text(
                        node.guidance!,
                        style: AppTheme.bodyMedium.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.paddingLarge),
            
            // Action buttons based on node type
            _buildNodeActions(context, engine, state, node),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNodeActions(
    BuildContext context,
    DrillEngine engine,
    DrillState state,
    DrillNode node,
  ) {
    return switch (node.type) {
      DrillNodeType.decision => _buildDecisionActions(engine, state, node),
      DrillNodeType.instruction => _buildInstructionActions(engine, state, node),
      DrillNodeType.action => _buildActionActions(engine, state, node),
      DrillNodeType.checkpoint => _buildCheckpointActions(engine, state, node),
      DrillNodeType.triageAssignment => _buildTriageActions(engine, state, node),
      _ => _buildDefaultActions(engine, state, node),
    };
  }
  
  Widget _buildDecisionActions(
    DrillEngine engine,
    DrillState state,
    DrillNode node,
  ) {
    final options = node.options ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTheme.paddingMedium),
          LargeActionButton(
            label: options[i].label,
            color: i == 0 ? AppTheme.primaryAccent : AppTheme.info,
            outlined: i > 0,
            onPressed: () => _handleDecision(engine, state, options[i]),
          ),
        ],
      ],
    );
  }
  
  Widget _buildInstructionActions(
    DrillEngine engine,
    DrillState state,
    DrillNode node,
  ) {
    return LargeActionButton(
      label: 'CONTINUE',
      icon: Icons.arrow_forward,
      color: AppTheme.primaryAccent,
      onPressed: () => _handleInstruction(engine, state),
    );
  }
  
  Widget _buildActionActions(
    DrillEngine engine,
    DrillState state,
    DrillNode node,
  ) {
    return LargeActionButton(
      label: 'DONE',
      icon: Icons.check,
      color: AppTheme.primaryAccent,
      onPressed: () => _handleAction(engine, state, node),
    );
  }
  
  Widget _buildCheckpointActions(
    DrillEngine engine,
    DrillState state,
    DrillNode node,
  ) {
    return LargeActionButton(
      label: 'NEXT',
      icon: Icons.arrow_forward,
      color: AppTheme.primaryAccent,
      onPressed: () => _handleInstruction(engine, state),
    );
  }
  
  Widget _buildTriageActions(
    DrillEngine engine,
    DrillState state,
    DrillNode node,
  ) {
    return LargeActionButton(
      label: 'MARK ${node.category ?? "CASUALTY"}',
      color: AppTheme.getTriageCategoryColor(node.category ?? 'P1'),
      onPressed: () => _handleTriageAssignment(engine, state, node),
    );
  }
  
  Widget _buildDefaultActions(
    DrillEngine engine,
    DrillState state,
    DrillNode node,
  ) {
    return LargeActionButton(
      label: 'CONTINUE',
      color: AppTheme.primaryAccent,
      onPressed: () => _handleInstruction(engine, state),
    );
  }
  
  Widget _buildCompleteView(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.primaryAccent,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            const Text(
              'DRILL COMPLETE',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            const Text(
              'Casualty has been handed over',
              style: AppTheme.bodyLarge,
            ),
            const Spacer(),
            LargeActionButton(
              label: 'VIEW SUMMARY',
              icon: Icons.summarize,
              color: AppTheme.info,
              onPressed: () => _showSummary(context),
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            LargeActionButton(
              label: 'NEW INCIDENT',
              icon: Icons.add,
              color: AppTheme.primaryAccent,
              onPressed: () {
                ref.read(drillStateProvider.notifier).startNewIncident();
              },
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            LargeActionButton(
              label: 'EXIT',
              color: AppTheme.textMuted,
              outlined: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
  
  // --- Event handlers ---
  
  void _handleDecision(DrillEngine engine, DrillState state, DrillOption option) {
    final event = AnswerDecision(
      optionLabel: option.label,
      nextNodeId: option.next,
    );
    final newState = engine.transition(state, event);
    ref.read(drillStateProvider.notifier).updateState(newState);
  }
  
  void _handleInstruction(DrillEngine engine, DrillState state) {
    const event = AcknowledgeInstruction();
    final newState = engine.transition(state, event);
    ref.read(drillStateProvider.notifier).updateState(newState);
  }

  void _handleAction(DrillEngine engine, DrillState state, DrillNode node) {
    // TODO: Collect input data for interventions
    const event = CompleteAction();
    final newState = engine.transition(state, event);
    ref.read(drillStateProvider.notifier).updateState(newState);
  }
  
  void _handleTriageAssignment(DrillEngine engine, DrillState state, DrillNode node) {
    // TODO: Proper casualty ID management
    final casualtyId = const Uuid().v4();
    final category = _parseTriageCategory(node.category ?? 'P1');
    
    final event = AssignTriageCategory(
      casualtyId: casualtyId,
      category: category,
    );
    final newState = engine.transition(state, event);
    ref.read(drillStateProvider.notifier).updateState(newState);
  }
  
  TriageCategory _parseTriageCategory(String category) {
    return switch (category.toUpperCase()) {
      'P1' => TriageCategory.p1,
      'P2' => TriageCategory.p2,
      'P3' => TriageCategory.p3,
      'DEAD' => TriageCategory.dead,
      _ => TriageCategory.p1,
    };
  }
  
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Drill?'),
        content: const Text('Progress will be saved. You can resume later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drill screen
            },
            child: const Text('EXIT'),
          ),
        ],
      ),
    );
  }
  
  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('HELP', style: AppTheme.headlineSmall),
            const SizedBox(height: AppTheme.paddingMedium),
            const Text(
              'Follow the drill prompts in order. '
              'Answer questions to progress through the MARCH sequence.',
              style: AppTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            LargeActionButton(
              label: 'CLOSE',
              color: AppTheme.primaryAccent,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSummary(BuildContext context) {
    // TODO: Implement summary screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary view coming soon')),
    );
  }
}

/// Progress indicator showing MARCH completion.
class _DrillProgress extends StatelessWidget {
  final DrillState state;
  
  const _DrillProgress({required this.state});
  
  @override
  Widget build(BuildContext context) {
    final marchStatus = state.context.marchStatus;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MarchIndicator('M', marchStatus[MarchComponent.m] ?? false),
        _MarchIndicator('A', marchStatus[MarchComponent.a] ?? false),
        _MarchIndicator('R', marchStatus[MarchComponent.r] ?? false),
        _MarchIndicator('C', marchStatus[MarchComponent.c] ?? false),
        _MarchIndicator('H', marchStatus[MarchComponent.h] ?? false),
      ],
    );
  }
}

class _MarchIndicator extends StatelessWidget {
  final String label;
  final bool isComplete;
  
  const _MarchIndicator(this.label, this.isComplete);
  
  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getMarchComponentColor(label);
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isComplete ? color : Colors.transparent,
        border: Border.all(
          color: color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTheme.titleLarge.copyWith(
            color: isComplete ? AppTheme.backgroundDark : color,
          ),
        ),
      ),
    );
  }
}

/// Warning card for critical information.
class _WarningCard extends StatelessWidget {
  final String text;
  
  const _WarningCard({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppTheme.warning),
          const SizedBox(width: AppTheme.paddingSmall),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// Actions list for procedure steps.
class _ActionsList extends StatelessWidget {
  final List<String> actions;
  
  const _ActionsList({required this.actions});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < actions.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: AppTheme.labelLarge.copyWith(
                          color: AppTheme.backgroundDark,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingSmall),
                  Expanded(
                    child: Text(
                      actions[i],
                      style: AppTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
