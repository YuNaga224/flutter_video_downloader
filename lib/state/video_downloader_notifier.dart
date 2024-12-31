// lib/state/video_downloader_notifier.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as parser;
import 'package:vid_downloader/state/video_downloader_state.dart';
import 'package:vid_downloader/state/video_list_notifier.dart';
import 'package:vid_downloader/state/video_list_state.dart';

import '../utils/fix_url.dart';

class VideoDownloaderNotifier extends StateNotifier<VideoDownloaderState> {
  final StateNotifier<VideoListState> _videoListNotifier;

  VideoDownloaderNotifier(this._videoListNotifier)
      : super(const VideoDownloaderState());

  // URLからファイル名を生成するヘルパーメソッド
  String _generateFileName(String url, [String? customName]) {
    if (customName != null) {
      return '${customName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.mp4';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'video_$timestamp.mp4';
  }

  // プログレス付きダウンロードの実装
  Future<void> _downloadWithProgress(String url, String fileName) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      final contentLength = response.contentLength ?? 0;

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      final sink = file.openWrite();

      int downloaded = 0;

      // Completerを使用してストリーム完了を待つ
      final completer = Completer<void>();

      final subscription = response.stream.listen(
        (List<int> chunk) async {
          sink.add(chunk);
          downloaded += chunk.length;
          print(downloaded);
          if (contentLength > 0) {
            final progress = downloaded / contentLength;
            state = state.copyWith(progress: progress);
          }
        },
        onDone: () async {
          try {
            await sink.flush();
            await sink.close();
            state = state.copyWith(
              downloadStatus: DownloadStatus.success,
              localFilePath: file.path,
            );

            await (_videoListNotifier as VideoListNotifier).addVideo(
              state.localFilePath!,
              fileName,
            );
            completer.complete();
          } catch (e) {
            completer.completeError(e);
          }
        },
        onError: (error) {
          completer.completeError(error);
        },
        cancelOnError: true,
      );

      // ストリームの完了を待つ
      await completer.future;
      await subscription.cancel();

    } catch (e) {
      state = state.copyWith(
        downloadStatus: DownloadStatus.error,
        errorMessage: 'ダウンロード中にエラーが発生しました: $e',
      );
    } finally {
      client.close();
    }
  }

  // Twitter動画のダウンロード処理
  Future<void> downloadTwitterVideo(String url) async {
    final fixedUrl = fixUrl(url);

    state = state.copyWith(
      downloadStatus: DownloadStatus.loading,
      progress: 0.0,
      videoSource: VideoSource.twitter,
    );

    try {
      // Twitter動画の情報を取得
      final apiUrl = 'https://twitsave.com/info?url=$fixedUrl';
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
      await _downloadWithProgress(videoUrl, fileName);
    } catch (e) {
      state = state.copyWith(
        downloadStatus: DownloadStatus.error,
        errorMessage: '動画のダウンロードに失敗しました: $e',
      );
    }
  }

  // 汎用的な動画ダウンロード処理
  Future<void> downloadVideo(String videoUrl) async {
    final fixedUrl = fixUrl(videoUrl);
    state = state.copyWith(
      downloadStatus: DownloadStatus.loading,
      progress: 0.0,
      videoSource: VideoSource.other,
    );

    try {
      final fileName = _generateFileName(fixedUrl);
      await _downloadWithProgress(fixedUrl, fileName);
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
