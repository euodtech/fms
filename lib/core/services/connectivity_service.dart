import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  final InternetConnectionChecker _checker;

  ConnectivityService({InternetConnectionChecker? checker})
    : _checker = checker ?? InternetConnectionChecker();

  Future<bool> get hasConnection => _checker.hasConnection;
}
