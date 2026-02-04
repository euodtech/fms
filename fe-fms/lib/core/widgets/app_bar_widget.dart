import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../page/profile/presentation/profile_page.dart';
import '../../core/constants/variables.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AppBarWidget({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// Get the stored company logo URL
  Future<String?> _getCompanyLogo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Variables.companyLogo);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<String?>(
            future: _getCompanyLogo(),
            builder: (context, snapshot) {
              final logoUrl = snapshot.data;

              // Use the logo if it exists and is not empty
              if (logoUrl != null && logoUrl.isNotEmpty) {
                final fullUrl = logoUrl.startsWith('http')
                    ? logoUrl
                    : '${Variables.imageBaseUrl}$logoUrl';
                return Image.network(
                  fullUrl,
                  width: 25,
                  height: 25,
                  fit: BoxFit.cover,
                  // Fallback to default if network fails
                  errorBuilder: (_, __, ___) => _defaultLogo(),
                );
              }

              // Otherwise, show default logo
              return _defaultLogo();
            },
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Get.to(() => const ProfilePage());
          },
        ),
      ],
    );
  }

  /// Default logo widget
  Widget _defaultLogo() {
    return Image.asset(
      'assets/images/logo.jpg',
      width: 25,
      height: 25,
      fit: BoxFit.cover,
    );
  }
}
