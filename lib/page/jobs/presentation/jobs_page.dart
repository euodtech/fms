import 'package:flutter/material.dart';
import 'package:fms/data/mock_data.dart';

import 'job_details_page.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: MockData.jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final j = MockData.jobs[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(j.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(j.address, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobDetailsPage(job: j),
                          ),
                        );
                      },
                      child: const Text('DETAILS'),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
