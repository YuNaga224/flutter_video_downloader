import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/video_downloader_screen.dart';
import 'state/video_list_notifier.dart';


// SharedPreferencesの初期化を行う非同期関数
Future<SharedPreferences> initializeSharedPreferences() async {
  // SharedPreferencesのインスタンスを取得
  final prefs = await SharedPreferences.getInstance();
  return prefs;
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await initializeSharedPreferences();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Video Downloader",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VideoDownloaderScreen(),
    );
  }
}
