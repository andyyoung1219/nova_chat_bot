class NasaApiData {
  final String title;
  final String date;
  final String explanation;
  final String url;
  final String mediaType; // 回傳的是 "image" 或 "video"
  final bool isFromCache;

  const NasaApiData({
    required this.title,
    required this.date,
    required this.explanation,
    required this.url,
    required this.mediaType,
    this.isFromCache = false,
  });

  // Json to obj
  factory NasaApiData.fromJson(Map<String, dynamic> json, {bool isCache = false}) {
    return NasaApiData(
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      explanation: json['explanation'] ?? '',
      url: json['url'] ?? '',
      mediaType: json['media_type'] ?? '',
      isFromCache: isCache,
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

  // 複製資料若有傳值強制修改
  NasaApiData copyWith({
    String? title,
    String? date,
    String? explanation,
    String? url,
    String? mediaType,
    bool? isFromCache,
  }) {
    return NasaApiData(
      // 如果呼叫時有傳入新的值，就用新的值；如果沒有，就沿用原本物件 (this) 的值
      title: title ?? this.title,
      date: date ?? this.date,
      explanation: explanation ?? this.explanation,
      url: url ?? this.url,
      mediaType: mediaType ?? this.mediaType,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}