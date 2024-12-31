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