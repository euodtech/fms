import 'package:flutter/material.dart';
import 'package:fms/core/services/subscription.dart';
import 'package:fms/page/jobs/presentation/jobs_page.dart';
import 'package:fms/page/upgrade_required/presentation/upgrade_required_page.dart';

class JobsGateTab extends StatelessWidget {
  const JobsGateTab({super.key});

  @override
  Widget build(BuildContext context) {
    // if (subscriptionService.hasJobsAccess) {
    //   return const JobsPage();
    // }
    // return const UpgradeRequiredPage();
    return const JobsPage();
  }
}
