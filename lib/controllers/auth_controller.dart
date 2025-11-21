import 'package:get/get.dart';
import 'package:fms/core/constants/variables.dart';
import 'package:fms/core/storage/secure_storage.dart';
import 'package:fms/page/auth/presentation/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fms/core/services/subscription.dart';
import 'package:fms/controllers/home_controller.dart';
import 'package:fms/controllers/vehicles_controller.dart';
import 'package:fms/controllers/jobs_controller.dart';
import 'package:fms/data/datasource/traxroot_datasource.dart';

class AuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxString apiKey = ''.obs;
  final _storage = SecureStorage();

  @override
  void onInit() {
    super.onInit();
    checkSession();
  }

  Future<void> checkSession() async {
    isLoading.value = true;
    try {
      final token = await _storage.read(Variables.prefApiKey);
      if (token != null && token.isNotEmpty) {
        apiKey.value = token;
        isAuthenticated.value = true;

        // Load CompanyType from SharedPreferences and update subscription service
        final prefs = await SharedPreferences.getInstance();
        final companyType = prefs.getInt(Variables.prefCompanyType);
        if (companyType != null) {
          subscriptionService.currentPlan = companyType == 2
              ? Plan.pro
              : Plan.basic;
        }
      } else {
        isAuthenticated.value = false;
      }
    } catch (e) {
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String token) async {
    await _storage.write(Variables.prefApiKey, token);
    apiKey.value = token;
    isAuthenticated.value = true;
  }

  Future<void> logout() async {
    // Clear all data
    await _storage.deleteAll();
    apiKey.value = '';
    isAuthenticated.value = false;

    // Clear Traxroot token cache
    await TraxrootAuthDatasource().clearCachedToken();

    // Clear controller caches
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>();
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<VehiclesController>()) {
        Get.delete<VehiclesController>();
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<JobsController>()) {
        Get.delete<JobsController>();
      }
    } catch (_) {}

    // Redirect to login page
    Get.offAll(() => const LoginPage());
  }
}
