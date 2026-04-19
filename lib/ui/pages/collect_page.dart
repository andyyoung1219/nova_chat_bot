import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../data/nasa_api_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cards/sky_card.dart';
import '../../services/share_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        elevation: 1,
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
                        color: Colors.grey[200],
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      item.date,
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.black54,
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('已取消收藏')),
                                      );
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
                            style: const TextStyle(fontSize: 14.0, color: Colors.black87),
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