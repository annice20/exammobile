import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_data.dart';

class DashboardService {
  static const String baseUrl = 'http://localhost:5207/api/dashboardapi';

  static Future<DashboardData> fetch() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return DashboardData.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erreur ${response.statusCode}');
  }
}
