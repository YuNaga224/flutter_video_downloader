// lib/screens/video_downloader_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vid_downloader/state/video_downloader_notifier.dart';
import 'package:vid_downloader/state/video_downloader_state.dart';
import 'package:video_player/video_player.dart';

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
