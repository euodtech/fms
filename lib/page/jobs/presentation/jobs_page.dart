import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fms/data/datasource/get_job_datasource.dart';
import 'package:fms/data/datasource/get_job_history_datasource.dart';
import 'package:fms/data/models/response/get_job_response_model.dart';
import 'package:fms/page/jobs/presentation/job_details_page.dart';
import 'package:fms/data/datasource/get_job_ongoing_datasource.dart';

import '../../../data/models/response/get_job_history__response_model.dart'
    as history;
import '../widget/job_summary_card.dart';
import 'job_history_detail_page.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingAllJobs = true;
  bool _isLoadingHistoryJobs = true;
  bool _isLoadingOngoingJobs = true;
  GetJobResponseModel? _allJobsResponse;
  history.GetJobHistoryResponseModel? _historyJobsResponse;
  GetJobResponseModel? _ongoingJobsResponse;
  String? _errorAllJobs;
  String? _errorHistoryJobs;
  String? _errorOngoingJobs;

  final GetJobDatasource _getJobDatasource = GetJobDatasource();
  final GetJobHistoryDatasource _getJobHistoryDatasource =
      GetJobHistoryDatasource();
  final GetJobOngoingDatasource _getJobOngoingDatasource =
      GetJobOngoingDatasource();

  Future<void> _fetchAllJobs() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingAllJobs = true;
          _errorAllJobs = null;
        });
      }
      _allJobsResponse = await _getJobDatasource.getJob();
    } catch (e) {
      _errorAllJobs = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAllJobs = false;
        });
      }
    }
  }

  Future<void> _fetchHistoryJobs() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingHistoryJobs = true;
          _errorHistoryJobs = null;
        });
      }
      _historyJobsResponse = await _getJobHistoryDatasource.getJobHistory();
    } catch (e) {
      _errorHistoryJobs = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistoryJobs = false;
        });
      }
    }
  }

  Future<void> _fetchOngoingJobs() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingOngoingJobs = true;
          _errorOngoingJobs = null;
        });
      }
      _ongoingJobsResponse = await _getJobOngoingDatasource.getOngoingJobs();
    } catch (e) {
      _errorOngoingJobs = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOngoingJobs = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _fetchAllJobs(),
      _fetchOngoingJobs(),
      _fetchHistoryJobs(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllJobs();
    _fetchOngoingJobs();
    _fetchHistoryJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // title: const Text(
        //   'Activity',
        //   style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        // ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All Job'),
            Tab(text: 'Ongoing'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_getAllJob(), _getOngoingJob(), _getHistoryJob()],
      ),
    );
  }

  Widget _buildRefreshableMessage(String message) {
    return RefreshIndicator(
      onRefresh: _refresh,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Center(child: Text(message)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _getAllJob() {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    if (_isLoadingAllJobs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorAllJobs != null) {
      return _buildRefreshableMessage('Error: $_errorAllJobs');
    }
    if (_allJobsResponse?.data == null || _allJobsResponse!.data!.isEmpty) {
      return _buildRefreshableMessage('No jobs found');
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _allJobsResponse!.data!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final job = _allJobsResponse!.data![index];
          return JobSummaryCard(
            title: job.jobName ?? 'Untitled Job',
            customerName: job.customerName,
            address: job.address,
            dateLabel: job.jobDate != null ? _formatDate(job.jobDate) : null,
            badges: [
              _buildJobTypeBadge(context, job.typeJob),
              _buildStatusBadge(
                label: 'Open',
                color: accent,
                icon: Icons.outlined_flag,
              ),
            ],
            accentColor: accent,
            onTap: () => _openJobDetails(job),
            onDetails: () => _openJobDetails(job),
            detailsLabel: 'Details',
          );
        },
      ),
    );
  }

  Widget _getOngoingJob() {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    if (_isLoadingOngoingJobs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorOngoingJobs != null) {
      return _buildRefreshableMessage('Error: $_errorOngoingJobs');
    }
    if (_ongoingJobsResponse?.data == null ||
        _ongoingJobsResponse!.data!.isEmpty) {
      return _buildRefreshableMessage('No ongoing jobs found');
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _ongoingJobsResponse!.data!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final job = _ongoingJobsResponse!.data![index];
          return JobSummaryCard(
            title: job.jobName ?? 'Untitled Job',
            customerName: job.customerName,
            address: job.address,
            dateLabel: job.jobDate != null ? _formatDate(job.jobDate) : null,
            badges: [
              _buildJobTypeBadge(context, job.typeJob),
              _buildStatusBadge(
                label: 'In Progress',
                color: accent,
                icon: Icons.timelapse,
              ),
            ],
            accentColor: accent,
            onTap: () => _openJobDetails(job, isOngoing: true),
            onDetails: () => _openJobDetails(job, isOngoing: true),
            detailsLabel: 'Resume',
          );
        },
      ),
    );
  }

  Widget _getHistoryJob() {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;
    if (_isLoadingHistoryJobs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorHistoryJobs != null) {
      return _buildRefreshableMessage('Error: $_errorHistoryJobs');
    }
    if (_historyJobsResponse?.data == null ||
        _historyJobsResponse!.data!.isEmpty) {
      return _buildRefreshableMessage('No history jobs found');
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _historyJobsResponse!.data!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final job = _historyJobsResponse!.data![index];
          return JobSummaryCard(
            title: job.jobName ?? 'Untitled Job',
            customerName: job.customerName,
            address: job.address,
            dateLabel: job.jobDate != null ? _formatDate(job.jobDate) : null,
            badges: [
              _buildJobTypeBadge(context, job.typeJob),
              _buildStatusBadge(
                label: 'Completed',
                color: Colors.green,
                icon: Icons.verified_outlined,
              ),
            ],
            accentColor: accent,
            onTap: () => _openHistoryDetails(job),
            onDetails: () => _openHistoryDetails(job),
            detailsLabel: 'Report',
          );
        },
      ),
    );
  }

  String _getJobTypeString(int? type) {
    switch (type) {
      case 1:
        return 'Line Interruption';
      case 2:
        return 'Reconnection';
      case 3:
        return 'Short Circuit';
      default:
        return 'Other';
    }
  }

  JobCardBadge _buildJobTypeBadge(BuildContext context, int? type) {
    final typeString = _getJobTypeString(type);
    final accent = Theme.of(context).colorScheme.primary;
    return JobCardBadge(
      label: typeString,
      icon: Icons.work_outline,
      backgroundColor: accent.withValues(alpha: 0.22),
      foregroundColor: accent,
      borderColor: accent.withValues(alpha: 0.4),
    );
  }

  JobCardBadge _buildStatusBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return JobCardBadge(
      label: label,
      icon: icon,
      backgroundColor: color.withValues(alpha: 0.14),
      foregroundColor: color,
      borderColor: color.withValues(alpha: 0.28),
    );
  }

  void _openJobDetails(Data job, {bool isOngoing = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsPage(job: job, isOngoing: isOngoing),
      ),
    );
    if (result == true && mounted) {
      _refresh();
    }
  }

  void _openHistoryDetails(history.Data job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobHistoryDetailPage(job: job)),
    );
  }

  String _formatDate(dynamic value) {
    final dateTime = _parseDate(value);
    if (dateTime == null) return 'N/A';
    return DateFormat('EEE, dd MMM yyyy').format(dateTime);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
