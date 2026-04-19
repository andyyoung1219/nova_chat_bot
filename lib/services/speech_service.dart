import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  /// 初始化語音引擎
  Future<bool> initSpeech({required Function(String) onStatus}) async {
    if (!_isInitialized) {
      try {
        _isInitialized = await _speech.initialize(
          onError: (error) => debugPrint('語音辨識錯誤: $error'),
          onStatus: (status) {
            debugPrint('語音狀態變更: $status');
            onStatus(status); // 將狀態丟回給 UI 層
          },
        );
      } catch (e) {
        debugPrint('語音初始化失敗: $e');
        _isInitialized = false;
      }
    }
    return _isInitialized;
  }

  /// 開始聆聽語音
  Future<void> startListening({required Function(String) onResult}) async {
    if (_speech.isAvailable && !_speech.isListening) {
      await _speech.listen(
        onResult: (result) => onResult(result.recognizedWords),
        localeId: 'zh_TW',
      );
    }
  }

  /// 停止聆聽
  Future<void> stopListening() async {
    await _speech.stop();
  }
  /// 檢查目前是否正在聆聽
  bool get isListening => _speech.isListening;
}