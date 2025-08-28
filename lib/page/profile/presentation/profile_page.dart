import 'package:flutter/material.dart';
import 'package:fms/core/services/subscription.dart';

import '../../../data/datasource/auth_remote_datasource.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final isPro = subscriptionService.currentPlan == Plan.pro;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(radius: 26, child: Icon(Icons.person)),
              title: const Text('Theresa'),
              subtitle: const Text('Lineman\n+63 977-123-456'),
              isThreeLine: true,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPro ? Colors.blue.withOpacity(0.08) : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isPro ? 'PRO' : 'BASIC', style: TextStyle(color: isPro ? Colors.blue.shade700 : Colors.grey.shade700)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subscription', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  SegmentedButton<Plan>(
                    segments: const [
                      ButtonSegment(value: Plan.basic, label: Text('Basic')),
                      ButtonSegment(value: Plan.pro, label: Text('Pro')),
                    ],
                    selected: {subscriptionService.currentPlan},
                    onSelectionChanged: (s) => setState(() => subscriptionService.currentPlan = s.first),
                  ),
                  const SizedBox(height: 8),
                  Text('Pro unlocks Jobs page', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Support'),
              subtitle: const Text('help@efms.app'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red,),
              title: const Text('Logout', style: TextStyle(color: Colors.red),),
              onTap: () {
                //show dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          AuthRemoteDataSource().logout();
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red),),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
