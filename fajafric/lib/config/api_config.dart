class ApiConfig {
  // Change cette URL selon ton environnement
  static const String baseUrl = 'http://localhost:8000/api'; // Web / PC
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Émulateur Android
  // static const String baseUrl = 'http://192.168.1.X:8000/api'; // Vrai appareil (remplace X)
  
  static const Duration timeout = Duration(seconds: 15);

  static Map<String, String> headers(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
