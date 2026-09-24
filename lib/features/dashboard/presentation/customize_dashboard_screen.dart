import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/models/dashboard_layout.dart';
import 'providers/dashboard_layout_provider.dart';

class CustomizeDashboardScreen extends ConsumerWidget {
  const CustomizeDashboardScreen({super.key});

  Future<void> _showResetConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('Reset Dashboard?'),
          content: const Text(
            'Your widget order and visibility will be restored to the default dashboard.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(dashboardLayoutProvider.notifier).resetToDefault();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard layout restored to default.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final layout = ref.watch(dashboardLayoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Dashboard'),
        actions: [
          IconButton(
            key: const Key('reset_dashboard_appbar_button'),
            icon: const Icon(LucideIcons.rotateCcw, size: 20),
            tooltip: 'Reset to Default',
            onPressed: () => _showResetConfirmationDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: 18,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag handles (☰) to reorder widgets. Toggle switches to show or hide cards on your dashboard.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: layout.widgets.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                ref.read(dashboardLayoutProvider.notifier).reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final config = layout.widgets[index];
                return _WidgetReorderTile(
                  key: ValueKey('widget_tile_${config.type.key}'),
                  index: index,
                  config: config,
                  onToggle: (val) {
                    ref
                        .read(dashboardLayoutProvider.notifier)
                        .toggleVisibility(config.type, val);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('reset_dashboard_bottom_button'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  icon: const Icon(LucideIcons.rotateCcw, size: 18),
                  label: const Text('Reset to Default'),
                  onPressed: () => _showResetConfirmationDialog(context, ref),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetReorderTile extends StatelessWidget {
  const _WidgetReorderTile({
    super.key,
    required this.index,
    required this.config,
    required this.onToggle,
  });

  final int index;
  final DashboardWidgetConfig config;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Drag Handle
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.gripVertical,
                  size: 20,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Widget Icon
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: (config.isVisible ? AppColors.primary : Colors.grey)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                config.type.icon,
                size: 20,
                color: config.isVisible
                    ? AppColors.primary
                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.type.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: config.isVisible
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config.type.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Toggle Switch
            Switch.adaptive(
              key: Key('toggle_switch_${config.type.key}'),
              value: config.isVisible,
              activeTrackColor: AppColors.primary,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
