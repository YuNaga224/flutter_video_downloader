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
