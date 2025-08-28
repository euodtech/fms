class Variables {
  static const String baseUrl =
      // 'http://192.168.1.11:8000'; //or replace with your website url as backend
      'http://quetraverse.pro/efms/api/myapi';
  static const String imageBaseUrl = '$baseUrl/public/storage//';

  // API endpoints
  static const String loginEndpoint = '$baseUrl/login'; 
  static const String logoutEndpoint = '$baseUrl/logout'; 

  // Shared Preferences keys
  static const String prefApiKey = 'apiKey';
  static const String prefFullname = 'fullname';
}
