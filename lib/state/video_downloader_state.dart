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
