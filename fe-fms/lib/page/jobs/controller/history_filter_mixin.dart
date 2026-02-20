import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/core/utils/timezone_util.dart';
import 'package:fms/data/models/response/get_job_history__response_model.dart';

enum HistoryDateRange { all, today, last7Days, last30Days, last90Days }

enum HistorySortOrder { newestFirst, oldestFirst }

/// Mixin that adds search, date-range filtering, job-type filtering, and
/// sorting capabilities to the History tab of [JobsController].
mixin HistoryFilterMixin on GetxController {
  final historySearchQuery = ''.obs;
  final historyDateRange = HistoryDateRange.all.obs;
  final historyTypeFilter = Rxn<int>();
  final historySortOrder = HistorySortOrder.newestFirst.obs;
  final isHistoryFilterVisible = false.obs;

  late final TextEditingController historySearchController;
  Timer? _debounceTimer;

  void initHistoryFilter() {
    historySearchController = TextEditingController();
  }

  void disposeHistoryFilter() {
    _debounceTimer?.cancel();
    historySearchController.dispose();
  }

  /// Called by the search TextField's onChanged. Uses a 300ms debounce so the
  /// TextField stays responsive while delaying the reactive filter update.
  void updateHistorySearch(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      historySearchQuery.value = value.trim();
    });
  }

  /// Whether any filter is currently active (non-default).
  bool get hasActiveHistoryFilters =>
      historySearchQuery.value.isNotEmpty ||
      historyDateRange.value != HistoryDateRange.all ||
      historyTypeFilter.value != null ||
      historySortOrder.value != HistorySortOrder.newestFirst;

  /// Resets all filters to their defaults.
  void clearHistoryFilters() {
    historySearchController.clear();
    historySearchQuery.value = '';
    historyDateRange.value = HistoryDateRange.all;
    historyTypeFilter.value = null;
    historySortOrder.value = HistorySortOrder.newestFirst;
  }

  /// Applies search, date range, type, and sort filters to the given job list.
  List<Data> getFilteredHistoryJobs(List<Data>? jobs) {
    if (jobs == null || jobs.isEmpty) return [];

    var filtered = List<Data>.from(jobs);

    // Text search on jobName and customerName
    final query = historySearchQuery.value.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((job) {
        final name = (job.jobName ?? '').toLowerCase();
        final customer = (job.customerName ?? '').toLowerCase();
        return name.contains(query) || customer.contains(query);
      }).toList();
    }

    // Date range filter
    final range = historyDateRange.value;
    if (range != HistoryDateRange.all) {
      final now = ManilaTimezone.now();
      final today = DateTime(now.year, now.month, now.day);
      late final DateTime cutoff;

      switch (range) {
        case HistoryDateRange.today:
          cutoff = today;
          break;
        case HistoryDateRange.last7Days:
          cutoff = today.subtract(const Duration(days: 7));
          break;
        case HistoryDateRange.last30Days:
          cutoff = today.subtract(const Duration(days: 30));
          break;
        case HistoryDateRange.last90Days:
          cutoff = today.subtract(const Duration(days: 90));
          break;
        case HistoryDateRange.all:
          break;
      }

      filtered = filtered.where((job) {
        if (job.jobDate == null) return false;
        final jobDay = ManilaTimezone.convert(job.jobDate!);
        final jobDateOnly = DateTime(jobDay.year, jobDay.month, jobDay.day);
        return !jobDateOnly.isBefore(cutoff);
      }).toList();
    }

    // Job type filter
    final typeFilter = historyTypeFilter.value;
    if (typeFilter != null) {
      filtered = filtered.where((job) => job.typeJob == typeFilter).toList();
    }

    // Sort
    filtered.sort((a, b) {
      final aDate = a.jobDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.jobDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return historySortOrder.value == HistorySortOrder.newestFirst
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });

    return filtered;
  }
}
