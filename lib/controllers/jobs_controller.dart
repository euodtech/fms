import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/data/datasource/get_job_datasource.dart';
import 'package:fms/data/datasource/get_job_history_datasource.dart';
import 'package:fms/data/datasource/get_job_ongoing_datasource.dart';
import 'package:fms/data/models/response/get_job_response_model.dart';
import 'package:fms/data/models/response/get_job_history__response_model.dart'
    as history;

class JobsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final Rx<GetJobResponseModel?> allJobsResponse = Rx<GetJobResponseModel?>(
    null,
  );

  final RxnString errorAllJobs = RxnString();
  final RxnString errorHistoryJobs = RxnString();
  final RxnString errorOngoingJobs = RxnString();
  final Rx<history.GetJobHistoryResponseModel?> historyJobsResponse =
      Rx<history.GetJobHistoryResponseModel?>(null);

  final RxBool isLoadingAllJobs = true.obs;
  final RxBool isLoadingHistoryJobs = true.obs;
  final RxBool isLoadingOngoingJobs = true.obs;
  final Rx<GetJobResponseModel?> ongoingJobsResponse = Rx<GetJobResponseModel?>(
    null,
  );

  final RxMap<int, DateTime> rescheduledJobs = <int, DateTime>{}.obs;
  late TabController tabController;

  final _getJobDatasource = GetJobDatasource();
  final _getJobHistoryDatasource = GetJobHistoryDatasource();
  final _getJobOngoingDatasource = GetJobOngoingDatasource();

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    fetchAllJobs();
    fetchOngoingJobs();
    fetchHistoryJobs();
  }

  Future<void> fetchAllJobs() async {
    try {
      isLoadingAllJobs.value = true;
      errorAllJobs.value = null;
      allJobsResponse.value = await _getJobDatasource.getJob();
    } catch (e) {
      errorAllJobs.value = e.toString();
    } finally {
      isLoadingAllJobs.value = false;
    }
  }

  Future<void> fetchHistoryJobs() async {
    try {
      isLoadingHistoryJobs.value = true;
      errorHistoryJobs.value = null;
      historyJobsResponse.value = await _getJobHistoryDatasource
          .getJobHistory();
    } catch (e) {
      errorHistoryJobs.value = e.toString();
    } finally {
      isLoadingHistoryJobs.value = false;
    }
  }

  Future<void> fetchOngoingJobs() async {
    try {
      isLoadingOngoingJobs.value = true;
      errorOngoingJobs.value = null;
      ongoingJobsResponse.value = await _getJobOngoingDatasource
          .getOngoingJobs();
      final jobs = ongoingJobsResponse.value?.data ?? [];
      final activeIds = jobs.map((job) => job.jobId).whereType<int>().toSet();
      rescheduledJobs.removeWhere((jobId, _) => !activeIds.contains(jobId));
    } catch (e) {
      errorOngoingJobs.value = e.toString();
    } finally {
      isLoadingOngoingJobs.value = false;
    }
  }

  Future<void> refresh() async {
    await Future.wait([fetchAllJobs(), fetchOngoingJobs(), fetchHistoryJobs()]);
  }

  void markJobRescheduled(int jobId, DateTime scheduledDate) {
    rescheduledJobs[jobId] = scheduledDate;
  }

  void clearJobRescheduled(int jobId) {
    rescheduledJobs.remove(jobId);
  }
}
