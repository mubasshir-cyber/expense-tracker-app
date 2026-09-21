import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/report_period.dart';
import '../providers/reports_providers.dart';

/// Period selection bar shown at the top of the Reports screen.
/// Provides preset chips and a "Custom" button that opens a date range picker.
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  static const _presets = [
    ReportPeriod.today,
    ReportPeriod.yesterday,
    ReportPeriod.thisWeek,
    ReportPeriod.thisMonth,
    ReportPeriod.lastMonth,
    ReportPeriod.last3Months,
    ReportPeriod.thisYear,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(reportFilterProvider);
    final notifier = ref.read(reportFilterProvider.notifier);

    final isSingleDateCustom = filter.period == ReportPeriod.custom &&
        filter.startDate.year == filter.endDate.year &&
        filter.startDate.month == filter.endDate.month &&
        filter.startDate.day == filter.endDate.day;

    final isDateRangeCustom = filter.period == ReportPeriod.custom && !isSingleDateCustom;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ..._presets.map((period) {
            final isSelected = filter.period == period;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(period.label),
                selected: isSelected,
                onSelected: (_) => notifier.setPeriod(period),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          // Single Date picker chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    isSingleDateCustom
                        ? _formatSingleDateLabel(filter.startDate)
                        : 'Pick Date',
                  ),
                ],
              ),
              selected: isSingleDateCustom,
              onSelected: (_) => _pickSingleDate(context, ref),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSingleDateCustom
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: isSingleDateCustom
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              side: BorderSide(
                color: isSingleDateCustom
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
          // Custom range chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    isDateRangeCustom
                        ? _formatCustomLabel(filter.startDate, filter.endDate)
                        : 'Date Range',
                  ),
                ],
              ),
              selected: isDateRangeCustom,
              onSelected: (_) => _pickCustomRange(context, ref),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isDateRangeCustom
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: isDateRangeCustom
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              side: BorderSide(
                color: isDateRangeCustom
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSingleDate(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(reportFilterProvider);
    final notifier = ref.read(reportFilterProvider.notifier);

    final picked = await showDatePicker(
      context: context,
      initialDate: filter.startDate.isAfter(DateTime.now())
          ? DateTime.now()
          : filter.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      notifier.setSingleDate(picked);
    }
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(reportFilterProvider);
    final notifier = ref.read(reportFilterProvider.notifier);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: filter.startDate,
        end: filter.endDate.isAfter(DateTime.now())
            ? DateTime.now()
            : filter.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final end = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23, 59, 59, 999,
      );
      notifier.setCustomRange(picked.start, end);
    }
  }

  String _formatSingleDateLabel(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }

  String _formatCustomLabel(DateTime start, DateTime end) {
    String fmt(DateTime d) =>
        '${d.day}/${d.month}/${d.year.toString().substring(2)}';
    return '${fmt(start)} – ${fmt(end)}';
  }
}
