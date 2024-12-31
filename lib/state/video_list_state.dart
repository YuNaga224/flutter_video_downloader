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
