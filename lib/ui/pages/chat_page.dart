import 'package:flutter/material.dart';
import '../../data/message_model.dart';
import '../../services/nasa_api_service.dart';
import '../../services/storage_service.dart';
import '../../services/speech_service.dart';
import '../../services/theme_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NasaApiService _apiService = NasaApiService();
  final StorageService _storageService = StorageService();
  final SpeechService _speechService = SpeechService();

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
  bool _isListening = false; // 麥克風狀態

  @override
  void initState() {
    super.initState();
    _speechService.initSpeech(onStatus: (status) {
      if (mounted) {
        setState(() {
          // listening 為 true
          _isListening = (status == 'listening');
        });
      }
    });
  }

  void _toggleSpeechInput() async {
    if (_isListening) {
      await _speechService.stopListening();
    } else {
      _textController.clear();
      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _textController.text = text;
          });
        },
      );
    }
  }

  /// 解析字串以及判斷合理性
  String? _extractDate(String text) {
    final regex = RegExp(r'(\d{4})[年\-/\s]+(\d{1,2})[月\-/\s]+(\d{1,2})[日號]?');
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

  /// 顯示頂部懸浮通知
  void _showTopToast(BuildContext context, String text) {
    final overlayState = Overlay.of(context);

    // 建立 Overlay 實體
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // 設定位置：狀態列高度 + AppBar 預設高度 (kToolbarHeight) + 10px 緩衝
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
        left: 16.0,
        right: 16.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.95),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(0, 2)),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
        ),
      ),
    );

    // 將畫面插入到最頂層
    overlayState.insert(overlayEntry);

    // 2 秒後自動移除
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
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

      final nasaData = await _apiService.getApod(date: parsedDate, onTimeout: (){
        if (mounted) {
          _showTopToast(context, '網路請求逾時，已為您顯示快取資料');
        }
      });
      String novaReplyText;

      if (nasaData.isFromCache) {
        if (parsedDate != null && nasaData.date != parsedDate) {
          novaReplyText = '離線中快取無 $parsedDate 資料，顯示 ${nasaData.date} 歷史資訊';
        } else {
          novaReplyText = '顯示 ${nasaData.date} 的快取資料';
        }
      } else {
        novaReplyText = parsedDate != null ? '那天宇宙長這樣...' : '這是今天的 APOD：';
      }

      setState(() {
        messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: novaReplyText,
            isFromUser: false,
            nasaData: nasaData,
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
  void _handleLongPress(ChatMessage message) async {
    if (message.nasaData != null) {
      // 1. 儲存到 SQLite
      await _storageService.saveFavorite(message.nasaData!);

      // 2. 顯示成功提示
      if (!mounted) return;
      _showTopToast(context, '已收藏 ${message.nasaData!.title}');
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
        color: msg.isFromUser
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顯示對話文字
          Text(msg.text, style: const TextStyle(fontSize: 16.0)),

          // 多媒體區塊
          if (msg.nasaData != null) ...[
            const SizedBox(height: 8.0),
            if (msg.nasaData!.mediaType == 'video')
              Text(
                '影片連結: ${msg.nasaData!.url}',
                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child:CachedNetworkImage(
                  imageUrl: msg.nasaData!.url,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 8.0),
            Text(
              '${msg.nasaData!.title} (${msg.nasaData!.date})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4.0),
            Text(
              msg.nasaData!.explanation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.0, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ]
        ],
      ),
    ),
    ),
    );
  }
  Future<void> _pickDate(BuildContext context) async {
    // 日期選擇器
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1995, 6, 16),
      lastDate: DateTime.now(),
      helpText: '選擇想觀測的日期',
      cancelText: '取消',
      confirmText: '確定',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      final String formattedDate =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

      setState(() {
        _textController.text = formattedDate;
      });

      _sendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: '選擇日期',
            onPressed: () => _pickDate(context), // 觸發日期選擇邏輯
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? '切換為亮色模式' : '切換為深色模式',
            onPressed: () {
              ThemeService().toggleTheme();
            },
          ),
        ],
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
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: _isListening ? '聆聽中...請說出日期' : '輸入日期 (例如: 1995/06/20)...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        focusedBorder: _isListening
                            ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        )
                            : null,
                      ),
                      // 允許鍵盤送出
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleSpeechInput,
                    child: CircleAvatar(
                      backgroundColor: _isListening ? Colors.red : Colors.grey[200],
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.white : Colors.black87,
                      ),
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