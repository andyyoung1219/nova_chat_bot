import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareCardManager {

  /// 執行截圖與分享
  static Future<bool> captureAndShare(GlobalKey boundaryKey, String date) async {
    try {
      final renderObject = boundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return false;

      ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // 寫入手機暫存資料夾
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/starry_card_$date.png').create();
      await imagePath.writeAsBytes(pngBytes);

      // 呼叫系統分享
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath.path)],
          text: '看看我專屬的生日賀卡！日期：$date',
        ),
      );

      return true; //
    } catch (e) {
      debugPrint('分享星空卡發生錯誤: $e');
      return false; //
    }
  }
}