import 'nasa_api_data.dart';
/// 定義對話訊息
class ChatMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final NasaApiData? nasaData;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    this.nasaData,
    required this.timestamp,
  });
}

