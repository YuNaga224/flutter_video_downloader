import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vid_downloader/state/video_downloader_notifier.dart';
import 'package:vid_downloader/state/video_downloader_state.dart';
import 'package:vid_downloader/screens/video_list_screen.dart';

class VideoDownloaderScreen extends HookConsumerWidget {
  const VideoDownloaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoUrlController = useTextEditingController();
    final videoDownloaderState = ref.watch(videoDownloaderProvider);
    final videoDownloaderNotifier = ref.read(videoDownloaderProvider.notifier);



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
          ],
        ),
      ),
    );
  }
}
