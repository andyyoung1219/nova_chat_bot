class NasaApiData {
  final String title;
  final String date;
  final String explanation;
  final String url;
  final String mediaType; // 回傳的是 "image" 或 "video"

  const NasaApiData({
    required this.title,
    required this.date,
    required this.explanation,
    required this.url,
    required this.mediaType,
  });

  // Json to obj
  factory NasaApiData.fromJson(Map<String, dynamic> json) {
    return NasaApiData(
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      explanation: json['explanation'] ?? '',
      url: json['url'] ?? '',
      mediaType: json['media_type'] ?? '',
    );
  }

  // obj to Json
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'explanation': explanation,
      'url': url,
      'media_type': mediaType,
    };
  }
}