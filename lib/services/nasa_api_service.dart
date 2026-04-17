import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/nasa_api_data.dart';

class NasaApiService {
  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';

  Future<NasaApiData> getApod({String? date}) async {
    final String? apiKey = dotenv.env['NASA_API_KEY'];
    if (apiKey == null){
      throw Exception('沒有抓到api_key');
    }

    String requestUrl = '$_baseUrl?api_key=$apiKey';
    if (date != null && date.isNotEmpty) {
      requestUrl += '&date=$date';
    }

    try {
      final response = await http.get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(utf8.decode(response.bodyBytes));

        //轉成定義格式
        return NasaApiData.fromJson(jsonMap);
      } else {
        String errorMessage = '發生未知錯誤';
        try {
          final errorJson = json.decode(response.body);
          errorMessage = errorJson['error']['message'] ?? errorMessage;
        } catch (_) {
        }
        throw Exception('API 請求失敗 (狀態碼: ${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      throw Exception('網路連線異常，請檢查您的網路狀態。詳細錯誤: $e');
    }
  }
}