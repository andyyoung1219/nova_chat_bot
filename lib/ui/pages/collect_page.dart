import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../data/nasa_api_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cards/sky_card.dart';
import '../../services/share_service.dart';
import '../../services/theme_service.dart';

class CollectPage extends StatefulWidget {
  const CollectPage({super.key});

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> {
  final StorageService _storageService = StorageService();

  void _showSharePreviewDialog(BuildContext context, NasaApiData item) {
    final GlobalKey boundaryKey = GlobalKey();
    bool isProcessing = false;
    String inputName = '';

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
        context: context,
        barrierDismissible: false, //
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  scrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkyCard(
                        boundaryKey: boundaryKey,
                        title: item.title,
                        date: item.date,
                        imageUrl: item.url,
                        userName: inputName,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: '輸入壽星名字 (選填)',
                            border: InputBorder.none,
                            icon: Icon(Icons.person_outline, color: Colors.grey),
                          ),
                          maxLength: 15, //
                          onChanged: (value) {
                            setState(() {
                              inputName = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                      child: const Text('取消', style: TextStyle(color: Colors.white70)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                      ),
                      icon: isProcessing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                          : const Icon(Icons.share),
                      label: Text(isProcessing ? '產生中...' : '分享星空卡'),
                      onPressed: isProcessing ? null : () async {
                        setState(() => isProcessing = true);

                        // 執行分享並取得結果
                        final success = await ShareCardManager.captureAndShare(boundaryKey, item.date);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }

                        if (success) {
                          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('已分享星空卡！')));
                        } else {
                          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('分享失敗')));
                        }
                      },
                    )
                  ],
                );
              }
          );
        }
    );
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        elevation: 1,
        actions: [
          // 新增：深色模式切換按鈕
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? '切換為亮色模式' : '切換為深色模式',
            onPressed: () {
              ThemeService().toggleTheme();
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _storageService.updateNotifier,
        builder: (context, value, child) {
          return FutureBuilder<List<NasaApiData>>(
            future: _storageService.getAllFavorites(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final favorites = snapshot.data ?? [];

              if (favorites.isEmpty) {
                return const Center(
                  child: Text(
                    '目前沒有收藏的太空圖喔！\n快去和 Nova 聊天吧！',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16.0),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20.0),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final item = favorites[index];

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      item.date,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.mediaType != 'video')
                                IconButton(
                                  icon: const Icon(Icons.cake, color: Colors.orangeAccent),
                                  tooltip: '製作星空卡',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(right: 8.0),
                                  onPressed: () => _showSharePreviewDialog(context, item),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  final bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      return AlertDialog(
                                        title: const Text('確認刪除'),
                                        content: Text('確定要將「${item.title}」從收藏中移除嗎？'),
                                        actions: [
                                          // 取消按鈕
                                          TextButton(
                                            onPressed: () => Navigator.of(dialogContext).pop(false),
                                            child: const Text('取消', style: TextStyle(color: Colors.grey)),
                                          ),
                                          // 確認刪除按鈕
                                          TextButton(
                                            onPressed: () => Navigator.of(dialogContext).pop(true),
                                            child: const Text('刪除', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirm == true) {
                                    await _storageService.deleteFavorite(item.date);

                                    if (context.mounted) {
                                      _showTopToast(context, '已取消收藏');
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),

                          if (item.mediaType == 'video')
                            Text(
                              '影片連結: ${item.url}',
                              style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CachedNetworkImage(
                                imageUrl: item.url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(
                                  height: 150,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => const SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                        SizedBox(height: 8),
                                        Text('圖片載入失敗', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12.0),

                          Text(
                            item.explanation,
                            style: TextStyle(fontSize: 14.0, color: Theme.of(context).colorScheme.onSurfaceVariant,),

                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}