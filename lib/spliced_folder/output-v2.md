#### video_list_notifier.dart
``` dart

// まず、VideoListNotifierクラスを定義します
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'video_list_state.dart';

class VideoListNotifier extends StateNotifier<VideoListState> {
  VideoListNotifier() : super(const VideoListState());
  
  // ここに状態を更新するメソッドを実装します
  void addVideo(String path) {
    // 例: 新しい動画をリストに追加する処理
    state = state.copyWith(
      videos: [...state.videos, path]
    );
  }
}

// そして、プロバイダーの定義を修正します
final videoListProvider = StateNotifierProvider<VideoListNotifier, VideoListState>(
  (ref) => VideoListNotifier(),
);
```
#### video_downloader_notifier.dart
``` dart

// lib/state/video_downloader_notifier.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as parser;
import 'package:vid_downloader/state/video_downloader_state.dart';
import 'package:vid_downloader/state/video_list_state.dart';

class VideoDownloaderNotifier extends StateNotifier<VideoDownloaderState> {
  final StateNotifier<VideoListState> _videoListNotifier;

  VideoDownloaderNotifier(this._videoListNotifier) : super(const VideoDownloaderState());

  // URLからファイル名を生成するヘルパーメソッド
  String _generateFileName(String url, [String? customName]) {
    if (customName != null) {
      return '${customName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.mp4';
    }
    final uri = Uri.parse(url);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'video_$timestamp.mp4';
  }

  // プログレス付きダウンロードの実装
  Future<void> _downloadWithProgress(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      final contentLength =
          int.parse(response.headers['content-length'] ?? '0');

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      List<int> bytes = [];
      int downloaded = 0;

      for (var byte in response.bodyBytes) {
        bytes.add(byte);
        downloaded++;

        if (contentLength > 0) {
          final progress = downloaded / contentLength;
          state = state.copyWith(progress: progress);
        }
      }

      await file.writeAsBytes(bytes);
      print("###########");
      print(file.path);
      print(bytes);
      print("############");
      state = state.copyWith(
        downloadStatus: DownloadStatus.success,
        localFilePath: file.path,
      );
    } catch (e) {
      state = state.copyWith(
        downloadStatus: DownloadStatus.error,
        errorMessage: 'ダウンロード中にエラーが発生しました: $e',
      );
    }
  }

  // Twitter動画のダウンロード処理
  Future<void> downloadTwitterVideo(String url) async {
    state = state.copyWith(
      downloadStatus: DownloadStatus.loading,
      progress: 0.0,
      videoSource: VideoSource.twitter,
    );

    try {
      // Twitter動画の情報を取得
      final apiUrl = 'https://twitsave.com/info?url=$url';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode != 200) {
        throw Exception('動画情報の取得に失敗しました');
      }

      final document = parser.parse(response.body);
      final downloadButton =
          document.getElementsByClassName('origin-top-right')[0];
      final qualityButtons = downloadButton.getElementsByTagName('a');

      final videoUrl = qualityButtons[0].attributes['href'];
      if (videoUrl == null) {
        throw Exception('動画URLが取得できません');
      }

      if (qualityButtons.isEmpty) {
        throw Exception('動画URLが見つかりません');
      }

      final title = document
          .getElementsByClassName('leading-tight')[0]
          .getElementsByClassName('m-2')[0]
          .text;

      final fileName = _generateFileName(url, title);
      await _downloadWithProgress(videoUrl!, fileName);
    } catch (e) {
      state = state.copyWith(
        downloadStatus: DownloadStatus.error,
        errorMessage: '動画のダウンロードに失敗しました: $e',
      );
    }
  }

  // 汎用的な動画ダウンロード処理
  Future<void> downloadVideo(String videoUrl) async {
    state = state.copyWith(
      downloadStatus: DownloadStatus.loading,
      progress: 0.0,
      videoSource: VideoSource.other,
    );

    try {
      final fileName = _generateFileName(videoUrl);
      await _downloadWithProgress(videoUrl, fileName);
    } catch (e) {
      state = state.copyWith(
        downloadStatus: DownloadStatus.error,
        errorMessage: 'ダウンロード中にエラーが発生しました: $e',
      );
    }
  }
}

final videoDownloaderProvider =
    StateNotifierProvider<VideoDownloaderNotifier, VideoDownloaderState>(
  (ref) => VideoDownloaderNotifier(ref.watch(videoListProvider.notifier)),
);

```
#### video_list_state.dart
``` dart

import 'package:flutter/foundation.dart';

@immutable
class VideoListState {
  final List<String> downloadedVideoPaths;

  const VideoListState({
    this.downloadedVideoPaths = const [],
  });

  VideoListState copyWith({
    List<String>? downloadedVideoPaths,
  }) {
    return VideoListState(
      downloadedVideoPaths: downloadedVideoPaths ?? this.downloadedVideoPaths,
    );
  }
}

```
#### video_downloader_state.dart
``` dart

import 'package:flutter/foundation.dart';

enum DownloadStatus { initial, loading, success, error }

// 動画ソースの種類特定
enum VideoSource { twitter, other }

@immutable
class VideoDownloaderState {
  final DownloadStatus downloadStatus;
  final double progress;
  final String? errorMessage;
  final String? localFilePath;
  final VideoSource videoSource;

  const VideoDownloaderState({
    this.downloadStatus = DownloadStatus.initial,
    this.progress = 0.0,
    this.errorMessage,
    this.localFilePath,
    this.videoSource = VideoSource.other,
  });

  VideoDownloaderState copyWith({
    DownloadStatus? downloadStatus,
    double? progress,
    String? errorMessage,
    String? localFilePath,
    VideoSource? videoSource,
  }) {
    return VideoDownloaderState(
      downloadStatus: downloadStatus ?? this.downloadStatus,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      localFilePath: localFilePath ?? this.localFilePath,
      videoSource: videoSource ?? this.videoSource,
    );
  }
}

```
#### video_list_screen.dart
``` dart

import 'package:flutter/material.dart';

class VideoListScreen extends StatelessWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Videos'),
      ),
      body: const Center(
        child: Text('List of saved videos will be displayed here'),
      ),
    );
  }
}

```
#### video_downloader_screen.dart
``` dart

// lib/screens/video_downloader_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vid_downloader/state/video_downloader_notifier.dart';
import 'package:vid_downloader/state/video_downloader_state.dart';
import 'package:video_player/video_player.dart';
import 'package:vid_downloader/screens/video_list_screen.dart';

class VideoDownloaderScreen extends HookConsumerWidget {
  const VideoDownloaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoUrlController = useTextEditingController();
    final videoDownloaderState = ref.watch(videoDownloaderProvider);
    final videoDownloaderNotifier = ref.read(videoDownloaderProvider.notifier);
    final videoPlayerController = useState<VideoPlayerController?>(null);

    // ビデオプレーヤーの初期化
    useEffect(() {
      if (videoDownloaderState.localFilePath != null) {
        Future.delayed(const Duration(milliseconds: 100), () async {
          final controller = VideoPlayerController.file(
            File(videoDownloaderState.localFilePath!),
          );

          try {
            await controller.initialize();
            videoPlayerController.value = controller;
            controller.play();
          } catch (e) {
            print('VideoPlayer初期化エラー: $e');
          }
        });
      }
      return () {
        videoPlayerController.value?.dispose();
      };
    }, [videoDownloaderState.localFilePath]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Downloader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: videoUrlController,
              decoration: const InputDecoration(
                labelText: 'Enter Video URL',
                hintText: 'Paste Twitter or other video URL here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ダウンロードボタン
            ElevatedButton.icon(
              onPressed: videoDownloaderState.downloadStatus ==
                      DownloadStatus.loading
                  ? null
                  : () async {
                      final videoUrl = videoUrlController.text.trim();
                      if (videoUrl.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a URL')),
                        );
                        return;
                      }

                      if (videoUrl.contains('x.com')) {
                        await videoDownloaderNotifier
                            .downloadTwitterVideo(videoUrl);
                      } else {
                        await videoDownloaderNotifier.downloadVideo(videoUrl);
                      }
                    },
              icon: const Icon(Icons.download),
              label: const Text('Download Video'),
            ),

            const SizedBox(height: 16),

            // 進捗表示
            if (videoDownloaderState.downloadStatus == DownloadStatus.loading)
              Column(
                children: [
                  LinearProgressIndicator(value: videoDownloaderState.progress),
                  const SizedBox(height: 8),
                  Text(
                    '${(videoDownloaderState.progress * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

            // エラー表示
            if (videoDownloaderState.downloadStatus == DownloadStatus.error)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text(
                  'Error: ${videoDownloaderState.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VideoListScreen()),
                );
              },
              child: const Text('View Saved Videos'),
            ),
            const SizedBox(height: 16),
            // ビデオプレーヤー
            if (videoDownloaderState.localFilePath != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: videoPlayerController.value?.value.isInitialized ==
                            true
                        ? AspectRatio(
                            aspectRatio:
                                videoPlayerController.value!.value.aspectRatio,
                            child: VideoPlayer(videoPlayerController.value!),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

```
#### main.dart
``` dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'screens/video_downloader_screen.dart';

void main() {
  runApp(const ProviderScope(
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

```
