#### video_list_notifier.dart
``` dart

// まず、VideoListNotifierクラスを定義します
import 'dart:convert';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'video_list_state.dart';

class VideoListNotifier extends StateNotifier<VideoListState> {
  final SharedPreferences _prefs;
  static const String _storageKey = 'saved_videos';

  VideoListNotifier(this._prefs) : super(const VideoListState()) {
    _loadSavedVideos();
  }

  Future<void> _loadSavedVideos() async {
    try {
      state = state.copyWith(isLoading: true);
      final savedVideosJson = _prefs.getStringList(_storageKey) ?? [];
      final videos = savedVideosJson
          .map((json) => VideoItem.fromJson(jsonDecode(json)))
          .toList();

      // 存在確認&不要ファイル削除
      final validVideos = <VideoItem>[];
      for (final video in videos) {
        if (await File(video.path).exists()) {
          validVideos.add(video);
        }
      }

      state = state.copyWith(
        videos: validVideos,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '動画の読み込みに失敗しました: $e',
      );
    }
  }

  Future<void> addVideo(String path, String title) async {
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      await controller.dispose();

      final newVideo = VideoItem(
        path: path,
        title: title,
        addedAt: DateTime.now(),
        duration: duration,
      );

      final updatedVideos = [...state.videos, newVideo];
      await _saveVideos(updatedVideos);

      state = state.copyWith(videos: updatedVideos);
    } catch (e) {
      state = state.copyWith(error: '動画の追加に失敗しました: $e');
    }
  }

  Future<void> removeVideo(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }

      final updatedVideos = state.videos.where((v) => v.path != path).toList();
      await _saveVideos(updatedVideos);

      state = state.copyWith(videos: updatedVideos);
    } catch (e) {
      state = state.copyWith(error: '動画の削除に失敗しました: $e');
    }
  }

  Future<void> _saveVideos(List<VideoItem> videos) async {
    final videosJson =
        videos.map((video) => jsonEncode(video.toJson())).toList();
    await _prefs.setStringList(_storageKey, videosJson);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final videoListProvider =
    StateNotifierProvider<VideoListNotifier, VideoListState>(
  (ref) => VideoListNotifier(ref.watch(sharedPreferencesProvider)),
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

  VideoDownloaderNotifier(this._videoListNotifier)
      : super(const VideoDownloaderState());

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

final videoListProvider =
    StateNotifierProvider<StateNotifier<VideoListState>, VideoListState>(
  (ref) => StateNotifier(const VideoListState()),
);

final videoDownloaderProvider =
    StateNotifierProvider<VideoDownloaderNotifier, VideoDownloaderState>(
  (ref) => VideoDownloaderNotifier(ref.watch(videoListProvider.notifier)),
);

```
#### video_list_state.dart
``` dart

import 'package:flutter/foundation.dart';

@immutable
class VideoItem {
  final String path;
  final String title;
  final DateTime addedAt;
  final String? thumbnail;
  final int duration; // 秒

  const VideoItem({
    required this.path,
    required this.title,
    required this.addedAt,
    this.thumbnail,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'addedAt': addedAt.toIso8601String(),
        'thumbnail': thumbnail,
        'duration': duration,
      };

  factory VideoItem.fromJson(Map<String, dynamic> json) => VideoItem(
        path: json['path'],
        title: json['title'],
        addedAt: DateTime.parse(json['addedAt']),
        thumbnail: json['thumbnail'],
        duration: json['duration'],
      );
}

@immutable
class VideoListState {
  final List<VideoItem> videos;
  final bool isLoading;
  final String? error;

  const VideoListState({
    this.videos = const [],
    this.isLoading = false,
    this.error,
  });

  VideoListState copyWith({
    List<VideoItem>? videos,
    bool? isLoading,
    String? error,
  }) {
    return VideoListState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vid_downloader/state/video_list_state.dart';
import 'package:video_player/video_player.dart';

import '../state/video_list_notifier.dart';

class VideoListScreen extends HookConsumerWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoListState = ref.watch(videoListProvider);

    return Scaffold(
        appBar: AppBar(
          title: const Text('保存済み動画'),
        ),
        body: videoListState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : videoListState.error != null
                ? Center(child: Text(videoListState.error!))
                : videoListState.videos.isEmpty
                    ? const Center(child: Text('保存済みの動画はありません'))
                    : ListView.builder(
                        itemCount: videoListState.videos.length,
                        itemBuilder: (context, index) {
                          final video = videoListState.videos[index];
                          return VideoListItem(
                            video: video,
                                                      onDeleteRequest: () {
                            // 削除機能をVideoListItemに渡す
                            ref.read(videoListProvider.notifier)
                                .removeVideo(video.path);
                          },
                            );
                        }));
  }
}

// ConsumerStatefulWidgetを使用
class VideoListItem extends ConsumerStatefulWidget {
  final VideoItem video;
  final VoidCallback onDeleteRequest;

  const VideoListItem({
    required this.video,
    required this.onDeleteRequest,
    super.key,
  });

  @override
  ConsumerState<VideoListItem> createState() => _VideoListItemState();
}

// ConsumerStateを使用
class _VideoListItemState extends ConsumerState<VideoListItem> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.file(File(widget.video.path));
    try {
      await _controller.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('動画の初期化に失敗しました: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(widget.video.title),
            subtitle: Text(
              '追加日時: ${widget.video.addedAt.toLocal()}',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('削除'),
                  onTap: widget.onDeleteRequest,
                ),
              ],
            ),
          ),
          if (_controller.value.isInitialized)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                  _isPlaying ? _controller.play() : _controller.pause();
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  if (!_isPlaying)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            padding: const EdgeInsets.all(8),
          ),
        ],
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

```
