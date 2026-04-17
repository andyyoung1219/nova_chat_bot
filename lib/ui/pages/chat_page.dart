import 'package:flutter/material.dart';
import '../../data/message_model.dart';
import '../../data/nasa_api_data.dart';
import '../../services/nasa_api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NasaApiService _apiService = NasaApiService();

  // 訊息狀態清單
  List<ChatMessage> messages = [
    ChatMessage(
      id: '0',
      text: '歡迎！輸入日期我會告訴你那天宇宙長什麼樣子。',
      isFromUser: false,
      timestamp: DateTime.now(),
    )
  ];

  bool _isLoading = false; // 是否正在等待 API 回覆

  /// 解析字串以及判斷合理性
  String? _extractDate(String text) {
    final regex = RegExp(r'(\d{4})[-/](\d{2})[-/](\d{2})');
    final match = regex.firstMatch(text);

    if (match != null) {
      try {
        final int year = int.parse(match.group(1)!);
        final int month = int.parse(match.group(2)!);
        final int day = int.parse(match.group(3)!);

        if (month < 1 || month > 12 || day < 1 || day > 31) {
          throw const FormatException('日期格式似乎有點奇怪，請確認是否有這一天！');
        }

        final parsedDate = DateTime(year, month, day);

        // 檢查是否被自動進位
        if (parsedDate.year != year || parsedDate.month != month || parsedDate.day != day) {
          throw const FormatException('這個月份沒有這一天喔，請重新確認！');
        }

        final earliestDate = DateTime(1995, 6, 16);
        final today = DateTime.now();

        if (parsedDate.isBefore(earliestDate)) {
          throw const FormatException('NASA APOD 最早的紀錄是 1995-06-16，請輸入這天之後的日期喔！');
        }
        if (parsedDate.isAfter(today)) {
          throw const FormatException('我們還無法觀測未來的宇宙，請輸入今天以前的日期！');
        }

        // 包裝成呼叫格式
        return '${year.toString()}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

      } catch (e) {
        if (e is FormatException) rethrow;
        throw const FormatException('解析日期時發生未知錯誤！');
      }
    }
    return null;
  }

  /// 處理發送訊息
  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 新增使用者訊息到畫面
    setState(() {
      messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isFromUser: true,
          timestamp: DateTime.now()
      ));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      String? parsedDate = _extractDate(text);

      final nasaData = await _apiService.getApod(date: parsedDate);

      setState(() {
        messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: parsedDate != null ? '那天宇宙長這樣...' : '這是今天的 APOD：',
            isFromUser: false,
            nasaData: nasaData, // 塞入 API 資料
            timestamp: DateTime.now()
        ));
      });
    } on FormatException catch (e) {
      setState(() {
        messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: e.message,
            isFromUser: false,
            timestamp: DateTime.now()
        ));
      });
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: '抱歉，無法取得資料。詳細資訊：$e',
            isFromUser: false,
            timestamp: DateTime.now()
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  /// 平滑滾動到底部的
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 長按收藏
  void _handleLongPress(ChatMessage message) {
    if (message.nasaData != null) {
      // TODO: 呼叫 StorageService 將 message.nasaData 存入資料庫
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已加入收藏！'),
          action: SnackBarAction(
            label: '復原',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// 繪製單一氣泡
  Widget _buildChatBubble(ChatMessage msg) {
    return GestureDetector(
      onLongPress: () => _handleLongPress(msg),
      child: Align(
          alignment: msg.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75, // 限制氣泡最大寬度
      ),
      decoration: BoxDecoration(
        color: msg.isFromUser ? Colors.blue[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顯示對話文字
          Text(msg.text, style: const TextStyle(fontSize: 16.0)),

          // 如果有 NASA 資料，顯示多媒體區塊
          if (msg.nasaData != null) ...[
            const SizedBox(height: 8.0),
            // 判斷是圖片還是影片
            if (msg.nasaData!.mediaType == 'video')
              Text(
                '影片連結: ${msg.nasaData!.url}',
                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  msg.nasaData!.url,
                  fit: BoxFit.cover,
                  // 加入載入中的佔位符號，提升體驗
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                ),
              ),
            const SizedBox(height: 8.0),
            // 顯示標題與日期
            Text(
              '${msg.nasaData!.title} (${msg.nasaData!.date})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4.0),
            // 顯示說明文字 (限制行數避免洗版)
            Text(
              msg.nasaData!.explanation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.0, color: Colors.black54),
            ),
          ]
        ],
      ),
    ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova'),
        elevation: 1,
      ),
      body: Column(
        children: [
          // 聊天訊息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(messages[index]);
              },
            ),
          ),
          // 讀取api中
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Nova 正在觀測宇宙...', style: TextStyle(color: Colors.grey)),
              ),
            ),
          // 輸入區域
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '輸入日期 (例如: 1995/06/20)...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      // 允許鍵盤送出
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage, // 載入中禁用按鈕
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}