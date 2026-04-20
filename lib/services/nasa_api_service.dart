import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/nasa_api_data.dart';
import 'storage_service.dart';

class NasaApiService {
  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';
  final StorageService _storage = StorageService();

  // 網路檢查
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      print("no internet");
      return false;
    }
  }

  Future<NasaApiData> getApod({String? date}) async {
    final String? apiKey = dotenv.env['NASA_API_KEY'];
    if (apiKey == null) {
      throw Exception('沒有抓到 api_key');
    }

    final String queryDate = date ?? DateTime.now().toString().substring(0, 10);

    final cachedData = await _storage.getCacheByDate(queryDate);
    if (cachedData != null) {
      return cachedData.copyWith(isFromCache: true);
    }

    String requestUrl = '$_baseUrl?api_key=$apiKey';
    if (date != null && date.isNotEmpty) {
      requestUrl += '&date=$date';
    }

    final bool hasInternet = await _hasInternetConnection();

    if (!hasInternet) {
      return _getFallbackData(queryDate);
    }

    try {
      final response = await http
          .get(Uri.parse(requestUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(utf8.decode(response.bodyBytes));
        final data = NasaApiData.fromJson(jsonMap);

        await _storage.saveToCache(data);

        return data;
      } else {
        throw Exception('API 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      return _getFallbackData(queryDate);
    }
  }

  // 存取快取
  Future<NasaApiData> _getFallbackData(String queryDate) async {
    final specificCache = await _storage.getCacheByDate(queryDate);
    if (specificCache != null) {
      return specificCache.copyWith(isFromCache: true);
    }

    final latestCache = await _storage.getLatestCache();
    if (latestCache != null) {
      return latestCache.copyWith(isFromCache: true);
    }

    throw Exception('目前無網路連線且無快取資料。');
  }
}