import 'dart:async';

import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService extends GetxService {
  final InternetConnectionChecker _checker;
  final RxBool isConnected = false.obs;
  StreamSubscription? _subscription;

  ConnectivityService({InternetConnectionChecker? checker})
    : _checker = checker ?? InternetConnectionChecker();

  Future<bool> get hasConnection => _checker.hasConnection;

  Future<ConnectivityService> init() async {
    try {
      isConnected.value = await _checker.hasConnection;
    } catch (_) {
      isConnected.value = false;
    }
    _subscription = _checker.onStatusChange.listen((status) {
      isConnected.value = status == InternetConnectionStatus.connected;
    });
    return this;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
