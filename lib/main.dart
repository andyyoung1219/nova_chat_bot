import 'package:flutter/material.dart';
import 'UI/main_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('找不到 .env 檔案或載入失敗');
  }

  // 5. 啟動 App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NASA Cosmos Messenger',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainLayout(),
    );
  }
}