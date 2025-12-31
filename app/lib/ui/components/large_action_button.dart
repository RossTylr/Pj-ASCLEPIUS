/// Large Action Button Component
/// 
/// Combat-friendly button with large touch targets for gloved use.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A large, high-contrast button designed for combat use.
class LargeActionButton extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData? icon;
  final Color color;
  final bool outlined;
  final VoidCallback onPressed;
  
  const LargeActionButton({
    super.key,
    required this.label,
    this.sublabel,
    this.icon,
    required this.color,
    this.outlined = false,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return _buildOutlined();
    }
    return _buildFilled();
  }
  
  Widget _buildFilled() {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          height: sublabel != null 
              ? AppTheme.xlButtonHeight 
              : AppTheme.largeButtonHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingLarge,
          ),
          child: _buildContent(
            textColor: AppTheme.backgroundDark,
            iconColor: AppTheme.backgroundDark,
          ),
        ),
      ),
    );
  }
  
  Widget _buildOutlined() {
    return Container(
      height: sublabel != null 
          ? AppTheme.xlButtonHeight 
          : AppTheme.largeButtonHeight,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingLarge,
            ),
            child: _buildContent(
              textColor: color,
              iconColor: color,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent({
    required Color textColor,
    required Color iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: AppTheme.paddingSmall),
        ],
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTheme.buttonText.copyWith(color: textColor),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (sublabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  sublabel!,
                  style: AppTheme.bodyMedium.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A decision button specifically styled for Yes/No choices.
class DecisionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;
  
  const DecisionButton({
    super.key,
    required this.label,
    this.isPrimary = false,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return LargeActionButton(
      label: label,
      color: isPrimary ? AppTheme.primaryAccent : AppTheme.info,
      outlined: !isPrimary,
      onPressed: onPressed,
    );
  }
}

/// A triage category button with appropriate colour coding.
class TriageButton extends StatelessWidget {
  final String category;
  final String label;
  final VoidCallback onPressed;
  
  const TriageButton({
    super.key,
    required this.category,
    required this.label,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return LargeActionButton(
      label: label,
      color: AppTheme.getTriageCategoryColor(category),
      onPressed: onPressed,
    );
  }
}
