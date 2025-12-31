/// Home Screen
/// 
/// Entry point for the application. Allows starting a new incident
/// or viewing past incidents.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../components/large_action_button.dart';
import 'drill_screen.dart';

/// Home screen widget.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Logo/Title area
              const _AppHeader(),
              
              const Spacer(),
              
              // Main actions
              LargeActionButton(
                label: 'NEW INCIDENT',
                sublabel: 'Start Master Drill',
                icon: Icons.add_circle_outline,
                color: AppTheme.primaryAccent,
                onPressed: () => _startNewIncident(context),
              ),
              
              const SizedBox(height: AppTheme.paddingMedium),
              
              LargeActionButton(
                label: 'CONTINUE',
                sublabel: 'Resume previous incident',
                icon: Icons.history,
                color: AppTheme.info,
                outlined: true,
                onPressed: () => _showIncidentHistory(context),
              ),
              
              const SizedBox(height: AppTheme.paddingMedium),
              
              LargeActionButton(
                label: 'TRAINING',
                sublabel: 'View drills & reference',
                icon: Icons.school_outlined,
                color: AppTheme.warning,
                outlined: true,
                onPressed: () => _showTrainingMode(context),
              ),
              
              const Spacer(),
              
              // Role selector
              const _RoleSelector(),
              
              const SizedBox(height: AppTheme.paddingLarge),
              
              // Version info
              const _VersionInfo(),
            ],
          ),
        ),
      ),
    );
  }
  
  void _startNewIncident(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DrillScreen(),
      ),
    );
  }
  
  void _showIncidentHistory(BuildContext context) {
    // TODO: Implement incident history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Incident history coming soon'),
      ),
    );
  }
  
  void _showTrainingMode(BuildContext context) {
    // TODO: Implement training mode screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Training mode coming soon'),
      ),
    );
  }
}

/// Application header with logo and title.
class _AppHeader extends StatelessWidget {
  const _AppHeader();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Medical cross icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.danger,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: const Icon(
            Icons.local_hospital,
            size: 48,
            color: AppTheme.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppTheme.paddingLarge),
        
        const Text(
          'TRIAGE DRILLS',
          style: AppTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.paddingSmall),
        
        Text(
          'TCCC(UK) ASM',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Role selector for General/Medic/Trainer modes.
class _RoleSelector extends ConsumerWidget {
  const _RoleSelector();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Wire up to actual role provider
    const currentRole = 'General';
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingSmall),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RoleOption(
            label: 'General',
            isSelected: currentRole == 'General',
            onTap: () {},
          ),
          _RoleOption(
            label: 'Medic',
            isSelected: currentRole == 'Medic',
            onTap: () {},
          ),
          _RoleOption(
            label: 'Trainer',
            isSelected: currentRole == 'Trainer',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _RoleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingMedium,
          vertical: AppTheme.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          label,
          style: AppTheme.labelLarge.copyWith(
            color: isSelected ? AppTheme.backgroundDark : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Version information footer.
class _VersionInfo extends StatelessWidget {
  const _VersionInfo();
  
  @override
  Widget build(BuildContext context) {
    return Text(
      'v0.1.0-dev • UNCLASSIFIED',
      style: AppTheme.bodyMedium.copyWith(
        color: AppTheme.textMuted,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }
}
