#### widget_test.dart
``` dart

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vid_downloader/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

```
#### avfoundation_video_player_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_avfoundation/src/messages.g.dart';
import 'package:video_player_avfoundation/video_player_avfoundation.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_api.g.dart';

class _ApiLogger implements TestHostVideoPlayerApi {
  final List<String> log = <String>[];
  int? textureId;
  CreationOptions? creationOptions;
  int? position;
  bool? looping;
  double? volume;
  double? playbackSpeed;
  bool? mixWithOthers;

  @override
  int create(CreationOptions options) {
    log.add('create');
    creationOptions = options;
    return 3;
  }

  @override
  void dispose(int textureId) {
    log.add('dispose');
    this.textureId = textureId;
  }

  @override
  void initialize() {
    log.add('init');
  }

  @override
  void pause(int textureId) {
    log.add('pause');
    this.textureId = textureId;
  }

  @override
  void play(int textureId) {
    log.add('play');
    this.textureId = textureId;
  }

  @override
  void setMixWithOthers(bool enabled) {
    log.add('setMixWithOthers');
    mixWithOthers = enabled;
  }

  @override
  int getPosition(int textureId) {
    log.add('position');
    this.textureId = textureId;
    return 234;
  }

  @override
  Future<void> seekTo(int position, int textureId) async {
    log.add('seekTo');
    this.position = position;
    this.textureId = textureId;
  }

  @override
  void setLooping(bool loop, int textureId) {
    log.add('setLooping');
    looping = loop;
    this.textureId = textureId;
  }

  @override
  void setVolume(double volume, int textureId) {
    log.add('setVolume');
    this.volume = volume;
    this.textureId = textureId;
  }

  @override
  void setPlaybackSpeed(double speed, int textureId) {
    log.add('setPlaybackSpeed');
    playbackSpeed = speed;
    this.textureId = textureId;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registration', () async {
    AVFoundationVideoPlayer.registerWith();
    expect(VideoPlayerPlatform.instance, isA<AVFoundationVideoPlayer>());
  });

  group('$AVFoundationVideoPlayer', () {
    final AVFoundationVideoPlayer player = AVFoundationVideoPlayer();
    late _ApiLogger log;

    setUp(() {
      log = _ApiLogger();
      TestHostVideoPlayerApi.setUp(log);
    });

    test('init', () async {
      await player.init();
      expect(
        log.log.last,
        'init',
      );
    });

    test('dispose', () async {
      await player.dispose(1);
      expect(log.log.last, 'dispose');
      expect(log.textureId, 1);
    });

    test('create with asset', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.asset,
        asset: 'someAsset',
        package: 'somePackage',
      ));
      expect(log.log.last, 'create');
      expect(log.creationOptions?.asset, 'someAsset');
      expect(log.creationOptions?.packageName, 'somePackage');
      expect(textureId, 3);
    });

    test('create with incorrect asset throws exception', () async {
      try {
        await player.create(DataSource(
          sourceType: DataSourceType.asset,
          asset: '/path/to/incorrect_asset',
        ));
        fail('should throw PlatformException');
      } catch (e) {
        expect(e, isException);
      }
    });

    test('create with network', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.network,
        uri: 'someUri',
        formatHint: VideoFormat.dash,
      ));
      expect(log.log.last, 'create');
      expect(log.creationOptions?.asset, null);
      expect(log.creationOptions?.uri, 'someUri');
      expect(log.creationOptions?.packageName, null);
      expect(log.creationOptions?.formatHint, 'dash');
      expect(log.creationOptions?.httpHeaders, <String, String>{});
      expect(textureId, 3);
    });

    test('create with network (some headers)', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.network,
        uri: 'someUri',
        httpHeaders: <String, String>{'Authorization': 'Bearer token'},
      ));
      expect(log.log.last, 'create');
      expect(log.creationOptions?.asset, null);
      expect(log.creationOptions?.uri, 'someUri');
      expect(log.creationOptions?.packageName, null);
      expect(log.creationOptions?.formatHint, null);
      expect(log.creationOptions?.httpHeaders,
          <String, String>{'Authorization': 'Bearer token'});
      expect(textureId, 3);
    });

    test('create with file', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.file,
        uri: 'someUri',
      ));
      expect(log.log.last, 'create');
      expect(log.creationOptions?.uri, 'someUri');
      expect(textureId, 3);
    });

    test('setLooping', () async {
      await player.setLooping(1, true);
      expect(log.log.last, 'setLooping');
      expect(log.textureId, 1);
      expect(log.looping, true);
    });

    test('play', () async {
      await player.play(1);
      expect(log.log.last, 'play');
      expect(log.textureId, 1);
    });

    test('pause', () async {
      await player.pause(1);
      expect(log.log.last, 'pause');
      expect(log.textureId, 1);
    });

    test('setMixWithOthers', () async {
      await player.setMixWithOthers(true);
      expect(log.log.last, 'setMixWithOthers');
      expect(log.mixWithOthers, true);

      await player.setMixWithOthers(false);
      expect(log.log.last, 'setMixWithOthers');
      expect(log.mixWithOthers, false);
    });

    test('setVolume', () async {
      await player.setVolume(1, 0.7);
      expect(log.log.last, 'setVolume');
      expect(log.textureId, 1);
      expect(log.volume, 0.7);
    });

    test('setPlaybackSpeed', () async {
      await player.setPlaybackSpeed(1, 1.5);
      expect(log.log.last, 'setPlaybackSpeed');
      expect(log.textureId, 1);
      expect(log.playbackSpeed, 1.5);
    });

    test('seekTo', () async {
      await player.seekTo(1, const Duration(milliseconds: 12345));
      expect(log.log.last, 'seekTo');
      expect(log.textureId, 1);
      expect(log.position, 12345);
    });

    test('getPosition', () async {
      final Duration position = await player.getPosition(1);
      expect(log.log.last, 'position');
      expect(log.textureId, 1);
      expect(position, const Duration(milliseconds: 234));
    });

    test('videoEventsFor', () async {
      const String mockChannel = 'flutter.io/videoPlayer/videoEvents123';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        mockChannel,
        (ByteData? message) async {
          final MethodCall methodCall =
              const StandardMethodCodec().decodeMethodCall(message);
          if (methodCall.method == 'listen') {
            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'initialized',
                      'duration': 98765,
                      'width': 1920,
                      'height': 1080,
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'completed',
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingUpdate',
                      'values': <List<dynamic>>[
                        <int>[0, 1234],
                        <int>[1235, 4000],
                      ],
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingStart',
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingEnd',
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'isPlayingStateUpdate',
                      'isPlaying': true,
                    }),
                    (ByteData? data) {});

            await TestDefaultBinaryMessengerBinding
                .instance.defaultBinaryMessenger
                .handlePlatformMessage(
                    mockChannel,
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'isPlayingStateUpdate',
                      'isPlaying': false,
                    }),
                    (ByteData? data) {});

            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else if (methodCall.method == 'cancel') {
            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else {
            fail('Expected listen or cancel');
          }
        },
      );
      expect(
          player.videoEventsFor(123),
          emitsInOrder(<dynamic>[
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(milliseconds: 98765),
              size: const Size(1920, 1080),
            ),
            VideoEvent(eventType: VideoEventType.completed),
            VideoEvent(
                eventType: VideoEventType.bufferingUpdate,
                buffered: <DurationRange>[
                  DurationRange(
                    Duration.zero,
                    const Duration(milliseconds: 1234),
                  ),
                  DurationRange(
                    const Duration(milliseconds: 1235),
                    const Duration(milliseconds: 4000),
                  ),
                ]),
            VideoEvent(eventType: VideoEventType.bufferingStart),
            VideoEvent(eventType: VideoEventType.bufferingEnd),
            VideoEvent(
              eventType: VideoEventType.isPlayingStateUpdate,
              isPlaying: true,
            ),
            VideoEvent(
              eventType: VideoEventType.isPlayingStateUpdate,
              isPlaying: false,
            ),
          ]));
    });
  });
}

```
#### integration_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();

```
#### video_player_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player_avfoundation/video_player_avfoundation.dart';
// TODO(stuartmorgan): Remove the use of MiniController in tests, as that is
// testing test code; tests should instead be written directly against the
// platform interface. (These tests were copied from the app-facing package
// during federation and minimally modified, which is why they currently use the
// controller.)
import 'package:video_player_example/mini_controller.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

const Duration _playDuration = Duration(seconds: 1);

const String _videoAssetKey = 'assets/Butterfly-209.mp4';

// Returns the URL to load an asset from this example app as a network source.
//
// TODO(stuartmorgan): Convert this to a local `HttpServer` that vends the
// assets directly, https://github.com/flutter/flutter/issues/95420
String getUrlForAssetAsNetworkSource(String assetKey) {
  return 'https://github.com/flutter/packages/blob/'
      // This hash can be rolled forward to pick up newly-added assets.
      '2e1673307ff7454aff40b47024eaed49a9e77e81'
      '/packages/video_player/video_player/example/'
      '$assetKey'
      '?raw=true';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MiniController controller;
  tearDown(() async => controller.dispose());

  group('asset videos', () {
    setUp(() {
      controller = MiniController.asset(_videoAssetKey);
    });

    testWidgets('registers expected implementation',
        (WidgetTester tester) async {
      AVFoundationVideoPlayer.registerWith();
      expect(VideoPlayerPlatform.instance, isA<AVFoundationVideoPlayer>());
    });

    testWidgets('can be initialized', (WidgetTester tester) async {
      await controller.initialize();

      expect(controller.value.isInitialized, true);
      expect(await controller.position, Duration.zero);
      expect(controller.value.duration,
          const Duration(seconds: 7, milliseconds: 540));
    });

    testWidgets('can be played', (WidgetTester tester) async {
      await controller.initialize();

      await controller.play();
      await tester.pumpAndSettle(_playDuration);

      expect(await controller.position, greaterThan(Duration.zero));
    });

    testWidgets(
      'can seek',
      (WidgetTester tester) async {
        await controller.initialize();

        await controller.seekTo(const Duration(seconds: 3));

        expect(controller.value.position, const Duration(seconds: 3));
      },
    );

    testWidgets(
      'can seek to end',
      (WidgetTester tester) async {
        await controller.initialize();

        await controller.seekTo(controller.value.duration);

        expect(controller.value.duration, controller.value.position);
      },
    );

    testWidgets('can be paused', (WidgetTester tester) async {
      await controller.initialize();

      // Play for a second, then pause, and then wait a second.
      await controller.play();
      await tester.pumpAndSettle(_playDuration);
      await controller.pause();
      final Duration pausedPosition = (await controller.position)!;
      await tester.pumpAndSettle(_playDuration);

      // Verify that we stopped playing after the pause.
      // TODO(stuartmorgan): Investigate why this has a slight discrepency, and
      // fix it if possible. Is AVPlayer's pause method internally async?
      const Duration allowableDelta = Duration(milliseconds: 10);
      expect(
          await controller.position, lessThan(pausedPosition + allowableDelta));
    });
  });

  group('file-based videos', () {
    setUp(() async {
      // Load the data from the asset.
      final String tempDir = (await getTemporaryDirectory()).path;
      final ByteData bytes = await rootBundle.load(_videoAssetKey);

      // Write it to a file to use as a source.
      final String filename = _videoAssetKey.split('/').last;
      final File file = File('$tempDir/$filename');
      await file.writeAsBytes(bytes.buffer.asInt8List());

      controller = MiniController.file(file);
    });

    testWidgets('test video player using static file() method as constructor',
        (WidgetTester tester) async {
      await controller.initialize();

      await controller.play();
      await tester.pumpAndSettle(_playDuration);

      expect(await controller.position, greaterThan(Duration.zero));
    });
  });

  group('network videos', () {
    setUp(() {
      final String videoUrl = getUrlForAssetAsNetworkSource(_videoAssetKey);
      controller = MiniController.network(videoUrl);
    });

    testWidgets('reports buffering status', (WidgetTester tester) async {
      await controller.initialize();

      final Completer<void> started = Completer<void>();
      final Completer<void> ended = Completer<void>();
      controller.addListener(() {
        if (!started.isCompleted && controller.value.isBuffering) {
          started.complete();
        }
        if (started.isCompleted &&
            !controller.value.isBuffering &&
            !ended.isCompleted) {
          ended.complete();
        }
      });

      await controller.play();
      await controller.seekTo(const Duration(seconds: 5));
      await tester.pumpAndSettle(_playDuration);
      await controller.pause();

      // TODO(stuartmorgan): Switch to _controller.position once seekTo is
      // fixed on the native side to wait for completion, so this is testing
      // the native code rather than the MiniController position cache.
      expect(controller.value.position, greaterThan(Duration.zero));

      await expectLater(started.future, completes);
      await expectLater(ended.future, completes);
    },
        // TODO(stuartmorgan): Skipped on iOS without explanation in main
        // package. Needs investigation.
        skip: true);

    testWidgets('live stream duration != 0', (WidgetTester tester) async {
      final MiniController livestreamController = MiniController.network(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/hls/bee.m3u8',
      );
      await livestreamController.initialize();

      expect(livestreamController.value.isInitialized, true);
      // Live streams should have either a positive duration or C.TIME_UNSET if the duration is unknown
      // See https://exoplayer.dev/doc/reference/com/google/android/exoplayer2/Player.html#getDuration--
      expect(livestreamController.value.duration,
          (Duration duration) => duration != Duration.zero);
    });

    testWidgets('rotated m3u8 has correct aspect ratio',
        (WidgetTester tester) async {
      // Some m3u8 files contain rotation data that may incorrectly invert the aspect ratio.
      // More info [here](https://github.com/flutter/flutter/issues/109116).
      final MiniController livestreamController = MiniController.network(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/hls/rotated_nail_manifest.m3u8',
      );
      await livestreamController.initialize();

      expect(livestreamController.value.isInitialized, true);
      expect(livestreamController.value.size.width,
          lessThan(livestreamController.value.size.height));
    });
  });
}

```
#### mini_controller.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(stuartmorgan): Consider extracting this to a shared local (path-based)
// package for use in all implementation packages.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

VideoPlayerPlatform? _cachedPlatform;

VideoPlayerPlatform get _platform {
  if (_cachedPlatform == null) {
    _cachedPlatform = VideoPlayerPlatform.instance;
    _cachedPlatform!.init();
  }
  return _cachedPlatform!;
}

/// The duration, current position, buffering state, error state and settings
/// of a [MiniController].
@immutable
class VideoPlayerValue {
  /// Constructs a video with the given values. Only [duration] is required. The
  /// rest will initialize with default values when unset.
  const VideoPlayerValue({
    required this.duration,
    this.size = Size.zero,
    this.position = Duration.zero,
    this.buffered = const <DurationRange>[],
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.playbackSpeed = 1.0,
    this.errorDescription,
  });

  /// Returns an instance for a video that hasn't been loaded.
  const VideoPlayerValue.uninitialized()
      : this(duration: Duration.zero, isInitialized: false);

  /// Returns an instance with the given [errorDescription].
  const VideoPlayerValue.erroneous(String errorDescription)
      : this(
            duration: Duration.zero,
            isInitialized: false,
            errorDescription: errorDescription);

  /// The total duration of the video.
  ///
  /// The duration is [Duration.zero] if the video hasn't been initialized.
  final Duration duration;

  /// The current playback position.
  final Duration position;

  /// The currently buffered ranges.
  final List<DurationRange> buffered;

  /// True if the video is playing. False if it's paused.
  final bool isPlaying;

  /// True if the video is currently buffering.
  final bool isBuffering;

  /// The current speed of the playback.
  final double playbackSpeed;

  /// A description of the error if present.
  ///
  /// If [hasError] is false this is `null`.
  final String? errorDescription;

  /// The [size] of the currently loaded video.
  final Size size;

  /// Indicates whether or not the video has been loaded and is ready to play.
  final bool isInitialized;

  /// Indicates whether or not the video is in an error state. If this is true
  /// [errorDescription] should have information about the problem.
  bool get hasError => errorDescription != null;

  /// Returns [size.width] / [size.height].
  ///
  /// Will return `1.0` if:
  /// * [isInitialized] is `false`
  /// * [size.width], or [size.height] is equal to `0.0`
  /// * aspect ratio would be less than or equal to `0.0`
  double get aspectRatio {
    if (!isInitialized || size.width == 0 || size.height == 0) {
      return 1.0;
    }
    final double aspectRatio = size.width / size.height;
    if (aspectRatio <= 0) {
      return 1.0;
    }
    return aspectRatio;
  }

  /// Returns a new instance that has the same values as this current instance,
  /// except for any overrides passed in as arguments to [copyWidth].
  VideoPlayerValue copyWith({
    Duration? duration,
    Size? size,
    Duration? position,
    List<DurationRange>? buffered,
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    double? playbackSpeed,
    String? errorDescription,
  }) {
    return VideoPlayerValue(
      duration: duration ?? this.duration,
      size: size ?? this.size,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoPlayerValue &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          position == other.position &&
          listEquals(buffered, other.buffered) &&
          isPlaying == other.isPlaying &&
          isBuffering == other.isBuffering &&
          playbackSpeed == other.playbackSpeed &&
          errorDescription == other.errorDescription &&
          size == other.size &&
          isInitialized == other.isInitialized;

  @override
  int get hashCode => Object.hash(
        duration,
        position,
        buffered,
        isPlaying,
        isBuffering,
        playbackSpeed,
        errorDescription,
        size,
        isInitialized,
      );
}

/// A very minimal version of `VideoPlayerController` for running the example
/// without relying on `video_player`.
class MiniController extends ValueNotifier<VideoPlayerValue> {
  /// Constructs a [MiniController] playing a video from an asset.
  ///
  /// The name of the asset is given by the [dataSource] argument and must not be
  /// null. The [package] argument must be non-null when the asset comes from a
  /// package and null otherwise.
  MiniController.asset(this.dataSource, {this.package})
      : dataSourceType = DataSourceType.asset,
        super(const VideoPlayerValue(duration: Duration.zero));

  /// Constructs a [MiniController] playing a video from obtained from
  /// the network.
  MiniController.network(this.dataSource)
      : dataSourceType = DataSourceType.network,
        package = null,
        super(const VideoPlayerValue(duration: Duration.zero));

  /// Constructs a [MiniController] playing a video from obtained from a file.
  MiniController.file(File file)
      : dataSource = Uri.file(file.absolute.path).toString(),
        dataSourceType = DataSourceType.file,
        package = null,
        super(const VideoPlayerValue(duration: Duration.zero));

  /// The URI to the video file. This will be in different formats depending on
  /// the [DataSourceType] of the original video.
  final String dataSource;

  /// Describes the type of data source this [MiniController]
  /// is constructed with.
  final DataSourceType dataSourceType;

  /// Only set for [asset] videos. The package that the asset was loaded from.
  final String? package;

  Timer? _timer;
  Completer<void>? _creatingCompleter;
  StreamSubscription<dynamic>? _eventSubscription;

  /// The id of a texture that hasn't been initialized.
  @visibleForTesting
  static const int kUninitializedTextureId = -1;
  int _textureId = kUninitializedTextureId;

  /// This is just exposed for testing. It shouldn't be used by anyone depending
  /// on the plugin.
  @visibleForTesting
  int get textureId => _textureId;

  /// Attempts to open the given [dataSource] and load metadata about the video.
  Future<void> initialize() async {
    _creatingCompleter = Completer<void>();

    late DataSource dataSourceDescription;
    switch (dataSourceType) {
      case DataSourceType.asset:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.asset,
          asset: dataSource,
          package: package,
        );
      case DataSourceType.network:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.network,
          uri: dataSource,
        );
      case DataSourceType.file:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.file,
          uri: dataSource,
        );
      case DataSourceType.contentUri:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.contentUri,
          uri: dataSource,
        );
    }

    _textureId = (await _platform.create(dataSourceDescription)) ??
        kUninitializedTextureId;
    _creatingCompleter!.complete(null);
    final Completer<void> initializingCompleter = Completer<void>();

    void eventListener(VideoEvent event) {
      switch (event.eventType) {
        case VideoEventType.initialized:
          value = value.copyWith(
            duration: event.duration,
            size: event.size,
            isInitialized: event.duration != null,
          );
          initializingCompleter.complete(null);
          _platform.setVolume(_textureId, 1.0);
          _platform.setLooping(_textureId, true);
          _applyPlayPause();
        case VideoEventType.completed:
          pause().then((void pauseResult) => seekTo(value.duration));
        case VideoEventType.bufferingUpdate:
          value = value.copyWith(buffered: event.buffered);
        case VideoEventType.bufferingStart:
          value = value.copyWith(isBuffering: true);
        case VideoEventType.bufferingEnd:
          value = value.copyWith(isBuffering: false);
        case VideoEventType.isPlayingStateUpdate:
          value = value.copyWith(isPlaying: event.isPlaying);
        case VideoEventType.unknown:
          break;
      }
    }

    void errorListener(Object obj) {
      final PlatformException e = obj as PlatformException;
      value = VideoPlayerValue.erroneous(e.message!);
      _timer?.cancel();
      if (!initializingCompleter.isCompleted) {
        initializingCompleter.completeError(obj);
      }
    }

    _eventSubscription = _platform
        .videoEventsFor(_textureId)
        .listen(eventListener, onError: errorListener);
    return initializingCompleter.future;
  }

  @override
  Future<void> dispose() async {
    if (_creatingCompleter != null) {
      await _creatingCompleter!.future;
      _timer?.cancel();
      await _eventSubscription?.cancel();
      await _platform.dispose(_textureId);
    }
    super.dispose();
  }

  /// Starts playing the video.
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
    await _applyPlayPause();
  }

  /// Pauses the video.
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
    await _applyPlayPause();
  }

  Future<void> _applyPlayPause() async {
    _timer?.cancel();
    if (value.isPlaying) {
      await _platform.play(_textureId);

      _timer = Timer.periodic(
        const Duration(milliseconds: 500),
        (Timer timer) async {
          final Duration? newPosition = await position;
          if (newPosition == null) {
            return;
          }
          _updatePosition(newPosition);
        },
      );
      await _applyPlaybackSpeed();
    } else {
      await _platform.pause(_textureId);
    }
  }

  Future<void> _applyPlaybackSpeed() async {
    if (value.isPlaying) {
      await _platform.setPlaybackSpeed(
        _textureId,
        value.playbackSpeed,
      );
    }
  }

  /// The position in the current video.
  Future<Duration?> get position async {
    return _platform.getPosition(_textureId);
  }

  /// Sets the video's current timestamp to be at [position].
  Future<void> seekTo(Duration position) async {
    if (position > value.duration) {
      position = value.duration;
    } else if (position < Duration.zero) {
      position = Duration.zero;
    }
    await _platform.seekTo(_textureId, position);
    _updatePosition(position);
  }

  /// Sets the playback speed.
  Future<void> setPlaybackSpeed(double speed) async {
    value = value.copyWith(playbackSpeed: speed);
    await _applyPlaybackSpeed();
  }

  void _updatePosition(Duration position) {
    value = value.copyWith(position: position);
  }
}

/// Widget that displays the video controlled by [controller].
class VideoPlayer extends StatefulWidget {
  /// Uses the given [controller] for all video rendered in this widget.
  const VideoPlayer(this.controller, {super.key});

  /// The [MiniController] responsible for the video being rendered in
  /// this widget.
  final MiniController controller;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  _VideoPlayerState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  late VoidCallback _listener;

  late int _textureId;

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    // Need to listen for initialization events since the actual texture ID
    // becomes available after asynchronous initialization finishes.
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(_listener);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == MiniController.kUninitializedTextureId
        ? Container()
        : _platform.buildView(_textureId);
  }
}

class _VideoScrubber extends StatefulWidget {
  const _VideoScrubber({
    required this.child,
    required this.controller,
  });

  final Widget child;
  final MiniController controller;

  @override
  _VideoScrubberState createState() => _VideoScrubberState();
}

class _VideoScrubberState extends State<_VideoScrubber> {
  MiniController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final RenderBox box = context.findRenderObject()! as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;
      controller.seekTo(position);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: widget.child,
      onTapDown: (TapDownDetails details) {
        if (controller.value.isInitialized) {
          seekToRelativePosition(details.globalPosition);
        }
      },
    );
  }
}

/// Displays the play/buffering status of the video controlled by [controller].
class VideoProgressIndicator extends StatefulWidget {
  /// Construct an instance that displays the play/buffering status of the video
  /// controlled by [controller].
  const VideoProgressIndicator(this.controller, {super.key});

  /// The [MiniController] that actually associates a video with this
  /// widget.
  final MiniController controller;

  @override
  State<VideoProgressIndicator> createState() => _VideoProgressIndicatorState();
}

class _VideoProgressIndicatorState extends State<VideoProgressIndicator> {
  _VideoProgressIndicatorState() {
    listener = () {
      if (mounted) {
        setState(() {});
      }
    };
  }

  late VoidCallback listener;

  MiniController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    const Color playedColor = Color.fromRGBO(255, 0, 0, 0.7);
    const Color bufferedColor = Color.fromRGBO(50, 50, 200, 0.2);
    const Color backgroundColor = Color.fromRGBO(200, 200, 200, 0.5);

    Widget progressIndicator;
    if (controller.value.isInitialized) {
      final int duration = controller.value.duration.inMilliseconds;
      final int position = controller.value.position.inMilliseconds;

      int maxBuffering = 0;
      for (final DurationRange range in controller.value.buffered) {
        final int end = range.end.inMilliseconds;
        if (end > maxBuffering) {
          maxBuffering = end;
        }
      }

      progressIndicator = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          LinearProgressIndicator(
            value: maxBuffering / duration,
            valueColor: const AlwaysStoppedAnimation<Color>(bufferedColor),
            backgroundColor: backgroundColor,
          ),
          LinearProgressIndicator(
            value: position / duration,
            valueColor: const AlwaysStoppedAnimation<Color>(playedColor),
            backgroundColor: Colors.transparent,
          ),
        ],
      );
    } else {
      progressIndicator = const LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(playedColor),
        backgroundColor: backgroundColor,
      );
    }
    return _VideoScrubber(
      controller: controller,
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: progressIndicator,
      ),
    );
  }
}

```
#### main.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import 'mini_controller.dart';

void main() {
  runApp(
    MaterialApp(
      home: _App(),
    ),
  );
}

class _App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: const ValueKey<String>('home_page'),
        appBar: AppBar(
          title: const Text('Video player example'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.cloud),
                text: 'Remote mp4',
              ),
              Tab(
                icon: Icon(Icons.favorite),
                text: 'Remote enc m3u8',
              ),
              Tab(icon: Icon(Icons.insert_drive_file), text: 'Asset mp4'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _BumbleBeeRemoteVideo(),
            _BumbleBeeEncryptedLiveStream(),
            _ButterFlyAssetVideo(),
          ],
        ),
      ),
    );
  }
}

class _ButterFlyAssetVideo extends StatefulWidget {
  @override
  _ButterFlyAssetVideoState createState() => _ButterFlyAssetVideoState();
}

class _ButterFlyAssetVideoState extends State<_ButterFlyAssetVideo> {
  late MiniController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MiniController.asset('assets/Butterfly-209.mp4');

    _controller.addListener(() {
      setState(() {});
    });
    _controller.initialize().then((_) => setState(() {}));
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(top: 20.0),
          ),
          const Text('With assets mp4'),
          Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BumbleBeeRemoteVideo extends StatefulWidget {
  @override
  _BumbleBeeRemoteVideoState createState() => _BumbleBeeRemoteVideoState();
}

class _BumbleBeeRemoteVideoState extends State<_BumbleBeeRemoteVideo> {
  late MiniController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MiniController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    );

    _controller.addListener(() {
      setState(() {});
    });
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(padding: const EdgeInsets.only(top: 20.0)),
          const Text('With remote mp4'),
          Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BumbleBeeEncryptedLiveStream extends StatefulWidget {
  @override
  _BumbleBeeEncryptedLiveStreamState createState() =>
      _BumbleBeeEncryptedLiveStreamState();
}

class _BumbleBeeEncryptedLiveStreamState
    extends State<_BumbleBeeEncryptedLiveStream> {
  late MiniController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MiniController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/hls/encrypted_bee.m3u8',
    );

    _controller.addListener(() {
      setState(() {});
    });
    _controller.initialize();

    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(padding: const EdgeInsets.only(top: 20.0)),
          const Text('With remote encrypted m3u8'),
          Container(
            padding: const EdgeInsets.all(20),
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const Text('loading...'),
          ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final MiniController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : const ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}

```
#### messages.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  dartTestOut: 'test/test_api.g.dart',
  objcHeaderOut:
      'darwin/video_player_avfoundation/Sources/video_player_avfoundation/include/video_player_avfoundation/messages.g.h',
  objcSourceOut:
      'darwin/video_player_avfoundation/Sources/video_player_avfoundation/messages.g.m',
  objcOptions: ObjcOptions(
    prefix: 'FVP',
    headerIncludePath: './include/video_player_avfoundation/messages.g.h',
  ),
  copyrightHeader: 'pigeons/copyright.txt',
))
class CreationOptions {
  CreationOptions({required this.httpHeaders});
  String? asset;
  String? uri;
  String? packageName;
  String? formatHint;
  Map<String, String> httpHeaders;
}

@HostApi(dartHostTestHandler: 'TestHostVideoPlayerApi')
abstract class AVFoundationVideoPlayerApi {
  @ObjCSelector('initialize')
  void initialize();
  @ObjCSelector('createWithOptions:')
  // Creates a new player and returns its ID.
  int create(CreationOptions creationOptions);
  @ObjCSelector('disposePlayer:')
  void dispose(int textureId);
  @ObjCSelector('setLooping:forPlayer:')
  void setLooping(bool isLooping, int textureId);
  @ObjCSelector('setVolume:forPlayer:')
  void setVolume(double volume, int textureId);
  @ObjCSelector('setPlaybackSpeed:forPlayer:')
  void setPlaybackSpeed(double speed, int textureId);
  @ObjCSelector('playPlayer:')
  void play(int textureId);
  @ObjCSelector('positionForPlayer:')
  int getPosition(int textureId);
  @async
  @ObjCSelector('seekTo:forPlayer:')
  void seekTo(int position, int textureId);
  @ObjCSelector('pausePlayer:')
  void pause(int textureId);
  @ObjCSelector('setMixWithOthers:')
  void setMixWithOthers(bool mixWithOthers);
}

```
#### video_player_avfoundation.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export 'src/avfoundation_video_player.dart';

```
#### avfoundation_video_player.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'messages.g.dart';

/// An iOS implementation of [VideoPlayerPlatform] that uses the
/// Pigeon-generated [VideoPlayerApi].
class AVFoundationVideoPlayer extends VideoPlayerPlatform {
  final AVFoundationVideoPlayerApi _api = AVFoundationVideoPlayerApi();

  /// Registers this class as the default instance of [VideoPlayerPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = AVFoundationVideoPlayer();
  }

  @override
  Future<void> init() {
    return _api.initialize();
  }

  @override
  Future<void> dispose(int textureId) {
    return _api.dispose(textureId);
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    String? asset;
    String? packageName;
    String? uri;
    String? formatHint;
    Map<String, String> httpHeaders = <String, String>{};
    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        asset = dataSource.asset;
        packageName = dataSource.package;
      case DataSourceType.network:
        uri = dataSource.uri;
        formatHint = _videoFormatStringMap[dataSource.formatHint];
        httpHeaders = dataSource.httpHeaders;
      case DataSourceType.file:
        uri = dataSource.uri;
      case DataSourceType.contentUri:
        uri = dataSource.uri;
    }
    final CreationOptions options = CreationOptions(
      asset: asset,
      packageName: packageName,
      uri: uri,
      httpHeaders: httpHeaders,
      formatHint: formatHint,
    );

    return _api.create(options);
  }

  @override
  Future<void> setLooping(int textureId, bool looping) {
    return _api.setLooping(looping, textureId);
  }

  @override
  Future<void> play(int textureId) {
    return _api.play(textureId);
  }

  @override
  Future<void> pause(int textureId) {
    return _api.pause(textureId);
  }

  @override
  Future<void> setVolume(int textureId, double volume) {
    return _api.setVolume(volume, textureId);
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) {
    assert(speed > 0);

    return _api.setPlaybackSpeed(speed, textureId);
  }

  @override
  Future<void> seekTo(int textureId, Duration position) {
    return _api.seekTo(position.inMilliseconds, textureId);
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    final int position = await _api.getPosition(textureId);
    return Duration(milliseconds: position);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return _eventChannelFor(textureId)
        .receiveBroadcastStream()
        .map((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      switch (map['event']) {
        case 'initialized':
          return VideoEvent(
            eventType: VideoEventType.initialized,
            duration: Duration(milliseconds: map['duration'] as int),
            size: Size((map['width'] as num?)?.toDouble() ?? 0.0,
                (map['height'] as num?)?.toDouble() ?? 0.0),
          );
        case 'completed':
          return VideoEvent(
            eventType: VideoEventType.completed,
          );
        case 'bufferingUpdate':
          final List<dynamic> values = map['values'] as List<dynamic>;

          return VideoEvent(
            buffered: values.map<DurationRange>(_toDurationRange).toList(),
            eventType: VideoEventType.bufferingUpdate,
          );
        case 'bufferingStart':
          return VideoEvent(eventType: VideoEventType.bufferingStart);
        case 'bufferingEnd':
          return VideoEvent(eventType: VideoEventType.bufferingEnd);
        case 'isPlayingStateUpdate':
          return VideoEvent(
            eventType: VideoEventType.isPlayingStateUpdate,
            isPlaying: map['isPlaying'] as bool,
          );
        default:
          return VideoEvent(eventType: VideoEventType.unknown);
      }
    });
  }

  @override
  Widget buildView(int textureId) {
    return Texture(textureId: textureId);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) {
    return _api.setMixWithOthers(mixWithOthers);
  }

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter.io/videoPlayer/videoEvents$textureId');
  }

  static const Map<VideoFormat, String> _videoFormatStringMap =
      <VideoFormat, String>{
    VideoFormat.ss: 'ss',
    VideoFormat.hls: 'hls',
    VideoFormat.dash: 'dash',
    VideoFormat.other: 'other',
  };

  DurationRange _toDurationRange(dynamic value) {
    final List<dynamic> pair = value as List<dynamic>;
    return DurationRange(
      Duration(milliseconds: pair[0] as int),
      Duration(milliseconds: pair[1] as int),
    );
  }
}

```
#### path_provider_foundation_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_foundation/messages.g.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';

import 'messages_test.g.dart';
import 'path_provider_foundation_test.mocks.dart';

@GenerateMocks(<Type>[TestPathProviderApi])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathProviderFoundation', () {
    late MockTestPathProviderApi mockApi;
    // These unit tests use the actual filesystem, since an injectable
    // filesystem would add a runtime dependency to the package, so everything
    // is contained to a temporary directory.
    late Directory testRoot;

    setUp(() async {
      testRoot = Directory.systemTemp.createTempSync();
      mockApi = MockTestPathProviderApi();
      TestPathProviderApi.setUp(mockApi);
    });

    tearDown(() {
      testRoot.deleteSync(recursive: true);
    });

    test('getTemporaryPath', () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      final String temporaryPath = p.join(testRoot.path, 'temporary', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.temp))
          .thenReturn(temporaryPath);

      final String? path = await pathProvider.getTemporaryPath();

      verify(mockApi.getDirectoryPath(DirectoryType.temp));
      expect(path, temporaryPath);
    });

    test('getApplicationSupportPath', () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      final String applicationSupportPath =
          p.join(testRoot.path, 'application', 'support', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.applicationSupport))
          .thenReturn(applicationSupportPath);

      final String? path = await pathProvider.getApplicationSupportPath();

      verify(mockApi.getDirectoryPath(DirectoryType.applicationSupport));
      expect(path, applicationSupportPath);
    });

    test('getApplicationSupportPath creates the directory if necessary',
        () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      final String applicationSupportPath =
          p.join(testRoot.path, 'application', 'support', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.applicationSupport))
          .thenReturn(applicationSupportPath);

      final String? path = await pathProvider.getApplicationSupportPath();

      expect(Directory(path!).existsSync(), isTrue);
    });

    test('getLibraryPath', () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      final String libraryPath = p.join(testRoot.path, 'library', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.library))
          .thenReturn(libraryPath);

      final String? path = await pathProvider.getLibraryPath();

      verify(mockApi.getDirectoryPath(DirectoryType.library));
      expect(path, libraryPath);
    });

    test('getApplicationDocumentsPath', () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      final String applicationDocumentsPath =
          p.join(testRoot.path, 'application', 'documents', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.applicationDocuments))
          .thenReturn(applicationDocumentsPath);

      final String? path = await pathProvider.getApplicationDocumentsPath();

      verify(mockApi.getDirectoryPath(DirectoryType.applicationDocuments));
      expect(path, applicationDocumentsPath);
    });

    test('getApplicationCachePath', () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      final String applicationCachePath =
          p.join(testRoot.path, 'application', 'cache', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.applicationCache))
          .thenReturn(applicationCachePath);

      final String? path = await pathProvider.getApplicationCachePath();

      verify(mockApi.getDirectoryPath(DirectoryType.applicationCache));
      expect(path, applicationCachePath);
    });

    test('getApplicationCachePath creates the directory if necessary',
        () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      final String applicationCachePath =
          p.join(testRoot.path, 'application', 'cache', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.applicationCache))
          .thenReturn(applicationCachePath);

      final String? path = await pathProvider.getApplicationCachePath();

      expect(Directory(path!).existsSync(), isTrue);
    });

    test('getDownloadsPath', () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      final String downloadsPath = p.join(testRoot.path, 'downloads', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.downloads))
          .thenReturn(downloadsPath);

      final String? result = await pathProvider.getDownloadsPath();

      verify(mockApi.getDirectoryPath(DirectoryType.downloads));
      expect(result, downloadsPath);
    });

    test('getExternalCachePaths throws', () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      expect(pathProvider.getExternalCachePaths(), throwsA(isUnsupportedError));
    });

    test('getExternalStoragePath throws', () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      expect(
          pathProvider.getExternalStoragePath(), throwsA(isUnsupportedError));
    });

    test('getExternalStoragePaths throws', () async {
      final PathProviderFoundation pathProvider = PathProviderFoundation();
      expect(
          pathProvider.getExternalStoragePaths(), throwsA(isUnsupportedError));
    });

    test('getContainerPath', () async {
      final PathProviderFoundation pathProvider =
          PathProviderFoundation(platform: FakePlatformProvider(isIOS: true));
      const String appGroupIdentifier = 'group.example.test';

      final String containerPath = p.join(testRoot.path, 'container', 'path');
      when(mockApi.getContainerPath(appGroupIdentifier))
          .thenReturn(containerPath);

      final String? result = await pathProvider.getContainerPath(
          appGroupIdentifier: appGroupIdentifier);

      verify(mockApi.getContainerPath(appGroupIdentifier));
      expect(result, containerPath);
    });

    test('getContainerPath throws on macOS', () async {
      final PathProviderFoundation pathProvider =
          PathProviderFoundation(platform: FakePlatformProvider(isIOS: false));
      expect(
          pathProvider.getContainerPath(
              appGroupIdentifier: 'group.example.test'),
          throwsA(isUnsupportedError));
    });
  });
}

/// Fake implementation of PathProviderPlatformProvider that returns iOS is true
class FakePlatformProvider implements PathProviderPlatformProvider {
  FakePlatformProvider({required this.isIOS});
  @override
  bool isIOS;
}

```
#### path_provider_foundation_test.mocks.dart
``` dart

// Mocks generated by Mockito 5.4.4 from annotations
// in path_provider_foundation/test/path_provider_foundation_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:mockito/mockito.dart' as _i1;
import 'package:path_provider_foundation/messages.g.dart' as _i3;

import 'messages_test.g.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [TestPathProviderApi].
///
/// See the documentation for Mockito's code generation for more information.
class MockTestPathProviderApi extends _i1.Mock
    implements _i2.TestPathProviderApi {
  MockTestPathProviderApi() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String? getDirectoryPath(_i3.DirectoryType? type) =>
      (super.noSuchMethod(Invocation.method(
        #getDirectoryPath,
        [type],
      )) as String?);

  @override
  String? getContainerPath(String? appGroupIdentifier) =>
      (super.noSuchMethod(Invocation.method(
        #getContainerPath,
        [appGroupIdentifier],
      )) as String?);
}

```
#### integration_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();

```
#### path_provider_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getTemporaryDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getTemporaryPath();
    _verifySampleFile(result, 'temporaryDirectory');
  });

  testWidgets('getApplicationDocumentsDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getApplicationDocumentsPath();
    if (Platform.isMacOS) {
      // _verifySampleFile causes hangs in driver when sandboxing is disabled
      // because the path changes from an app specific directory to
      // ~/Documents, which requires additional permissions to access on macOS.
      // Instead, validate that a non-empty path was returned.
      expect(result, isNotEmpty);
    } else {
      _verifySampleFile(result, 'applicationDocuments');
    }
  });

  testWidgets('getApplicationSupportDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getApplicationSupportPath();
    _verifySampleFile(result, 'applicationSupport');
  });

  testWidgets('getApplicationCacheDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getApplicationCachePath();
    _verifySampleFile(result, 'applicationCache');
  });

  testWidgets('getLibraryDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getLibraryPath();
    _verifySampleFile(result, 'library');
  });

  testWidgets('getDownloadsDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getDownloadsPath();
    // _verifySampleFile causes hangs in driver for some reason, so just
    // validate that a non-empty path was returned.
    expect(result, isNotEmpty);
  });

  testWidgets('getContainerDirectory', (WidgetTester tester) async {
    if (Platform.isIOS) {
      final PathProviderFoundation provider = PathProviderFoundation();
      final String? result = await provider.getContainerPath(
          appGroupIdentifier: 'group.flutter.appGroupTest');
      _verifySampleFile(result, 'appGroup');
    }
  });
}

/// Verify a file called [name] in [directoryPath] by recreating it with test
/// contents when necessary.
///
/// If [createDirectory] is true, the directory will be created if missing.
void _verifySampleFile(String? directoryPath, String name) {
  expect(directoryPath, isNotNull);
  if (directoryPath == null) {
    return;
  }
  final Directory directory = Directory(directoryPath);
  final File file = File('${directory.path}${Platform.pathSeparator}$name');

  if (file.existsSync()) {
    file.deleteSync();
    expect(file.existsSync(), isFalse);
  }

  file.writeAsStringSync('Hello world!');
  expect(file.readAsStringSync(), 'Hello world!');
  expect(directory.listSync(), isNotEmpty);
  file.deleteSync();
}

```
#### main.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

/// Sample app
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _tempDirectory = 'Unknown';
  String? _downloadsDirectory = 'Unknown';
  String? _libraryDirectory = 'Unknown';
  String? _appSupportDirectory = 'Unknown';
  String? _documentsDirectory = 'Unknown';
  String? _containerDirectory = 'Unknown';
  String? _cacheDirectory = 'Unknown';

  @override
  void initState() {
    super.initState();
    initDirectories();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initDirectories() async {
    String? tempDirectory;
    String? downloadsDirectory;
    String? appSupportDirectory;
    String? libraryDirectory;
    String? documentsDirectory;
    String? containerDirectory;
    String? cacheDirectory;
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final PathProviderFoundation providerFoundation = PathProviderFoundation();

    try {
      tempDirectory = await provider.getTemporaryPath();
    } catch (exception) {
      tempDirectory = 'Failed to get temp directory: $exception';
    }
    try {
      downloadsDirectory = await provider.getDownloadsPath();
    } catch (exception) {
      downloadsDirectory = 'Failed to get downloads directory: $exception';
    }

    try {
      documentsDirectory = await provider.getApplicationDocumentsPath();
    } catch (exception) {
      documentsDirectory = 'Failed to get documents directory: $exception';
    }

    try {
      libraryDirectory = await provider.getLibraryPath();
    } catch (exception) {
      libraryDirectory = 'Failed to get library directory: $exception';
    }

    try {
      appSupportDirectory = await provider.getApplicationSupportPath();
    } catch (exception) {
      appSupportDirectory = 'Failed to get app support directory: $exception';
    }

    try {
      containerDirectory = await providerFoundation.getContainerPath(
          appGroupIdentifier: 'group.flutter.appGroupTest');
    } catch (exception) {
      containerDirectory =
          'Failed to get app group container directory: $exception';
    }

    try {
      cacheDirectory = await provider.getApplicationCachePath();
    } catch (exception) {
      cacheDirectory = 'Failed to get cache directory: $exception';
    }

    setState(() {
      _tempDirectory = tempDirectory;
      _downloadsDirectory = downloadsDirectory;
      _libraryDirectory = libraryDirectory;
      _appSupportDirectory = appSupportDirectory;
      _documentsDirectory = documentsDirectory;
      _containerDirectory = containerDirectory;
      _cacheDirectory = cacheDirectory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Path Provider example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('Temp Directory: $_tempDirectory\n'),
              Text('Documents Directory: $_documentsDirectory\n'),
              Text('Downloads Directory: $_downloadsDirectory\n'),
              Text('Library Directory: $_libraryDirectory\n'),
              Text('Application Support Directory: $_appSupportDirectory\n'),
              Text('App Group Container Directory: $_containerDirectory\n'),
              Text('Cache Directory: $_cacheDirectory\n'),
            ],
          ),
        ),
      ),
    );
  }
}

```
#### messages.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  input: 'pigeons/messages.dart',
  swiftOut:
      'darwin/path_provider_foundation/Sources/path_provider_foundation/messages.g.swift',
  dartOut: 'lib/messages.g.dart',
  dartTestOut: 'test/messages_test.g.dart',
  copyrightHeader: 'pigeons/copyright.txt',
))
enum DirectoryType {
  applicationDocuments,
  applicationSupport,
  downloads,
  library,
  temp,
  applicationCache,
}

@HostApi(dartHostTestHandler: 'TestPathProviderApi')
abstract class PathProviderApi {
  String? getDirectoryPath(DirectoryType type);
  String? getContainerPath(String appGroupIdentifier);
}

```
#### path_provider_foundation.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'messages.g.dart';

/// The iOS and macOS implementation of [PathProviderPlatform].
class PathProviderFoundation extends PathProviderPlatform {
  /// Constructor that accepts a testable PathProviderPlatformProvider.
  PathProviderFoundation({
    @visibleForTesting PathProviderPlatformProvider? platform,
  }) : _platformProvider = platform ?? PathProviderPlatformProvider();

  final PathProviderPlatformProvider _platformProvider;
  final PathProviderApi _pathProvider = PathProviderApi();

  /// Registers this class as the default instance of [PathProviderPlatform]
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderFoundation();
  }

  @override
  Future<String?> getTemporaryPath() {
    return _pathProvider.getDirectoryPath(DirectoryType.temp);
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final String? path =
        await _pathProvider.getDirectoryPath(DirectoryType.applicationSupport);
    if (path != null) {
      // Ensure the directory exists before returning it, for consistency with
      // other platforms.
      await Directory(path).create(recursive: true);
    }
    return path;
  }

  @override
  Future<String?> getLibraryPath() {
    return _pathProvider.getDirectoryPath(DirectoryType.library);
  }

  @override
  Future<String?> getApplicationDocumentsPath() {
    return _pathProvider.getDirectoryPath(DirectoryType.applicationDocuments);
  }

  @override
  Future<String?> getApplicationCachePath() async {
    final String? path =
        await _pathProvider.getDirectoryPath(DirectoryType.applicationCache);
    if (path != null) {
      // Ensure the directory exists before returning it, for consistency with
      // other platforms.
      await Directory(path).create(recursive: true);
    }
    return path;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    throw UnsupportedError(
        'getExternalStoragePath is not supported on this platform');
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    throw UnsupportedError(
        'getExternalCachePaths is not supported on this platform');
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    throw UnsupportedError(
        'getExternalStoragePaths is not supported on this platform');
  }

  @override
  Future<String?> getDownloadsPath() {
    return _pathProvider.getDirectoryPath(DirectoryType.downloads);
  }

  /// Returns the path to the container of the specified App Group.
  /// This is only supported for iOS.
  Future<String?> getContainerPath({required String appGroupIdentifier}) async {
    if (!_platformProvider.isIOS) {
      throw UnsupportedError(
          'getContainerPath is not supported on this platform');
    }
    return _pathProvider.getContainerPath(appGroupIdentifier);
  }
}

/// Helper class for returning information about the current platform.
@visibleForTesting
class PathProviderPlatformProvider {
  /// Specifies whether the current platform is iOS.
  bool get isIOS => Platform.isIOS;
}

```
#### path_provider_linux_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:xdg_directories/xdg_directories.dart' as xdg;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderLinux.registerWith();

  test('registered instance', () {
    expect(PathProviderPlatform.instance, isA<PathProviderLinux>());
  });

  test('getTemporaryPath defaults to TMPDIR', () async {
    final PathProviderPlatform plugin = PathProviderLinux.private(
      environment: <String, String>{'TMPDIR': '/run/user/0/tmp'},
    );
    expect(await plugin.getTemporaryPath(), '/run/user/0/tmp');
  });

  test('getTemporaryPath uses fallback if TMPDIR is empty', () async {
    final PathProviderPlatform plugin = PathProviderLinux.private(
      environment: <String, String>{'TMPDIR': ''},
    );
    expect(await plugin.getTemporaryPath(), '/tmp');
  });

  test('getTemporaryPath uses fallback if TMPDIR is unset', () async {
    final PathProviderPlatform plugin = PathProviderLinux.private(
      environment: <String, String>{},
    );
    expect(await plugin.getTemporaryPath(), '/tmp');
  });

  test('getApplicationSupportPath', () async {
    final PathProviderPlatform plugin = PathProviderLinux.private(
        executableName: 'path_provider_linux_test_binary',
        applicationId: 'com.example.Test');
    // Note this will fail if ${xdg.dataHome.path}/path_provider_linux_test_binary exists on the local filesystem.
    expect(await plugin.getApplicationSupportPath(),
        '${xdg.dataHome.path}/com.example.Test');
  });

  test('getApplicationSupportPath uses executable name if no application Id',
      () async {
    final PathProviderPlatform plugin = PathProviderLinux.private(
        executableName: 'path_provider_linux_test_binary');
    expect(await plugin.getApplicationSupportPath(),
        '${xdg.dataHome.path}/path_provider_linux_test_binary');
  });

  test('getApplicationDocumentsPath', () async {
    final PathProviderPlatform plugin = PathProviderPlatform.instance;
    expect(await plugin.getApplicationDocumentsPath(), startsWith('/'));
  });

  test('getApplicationCachePath', () async {
    final PathProviderPlatform plugin = PathProviderLinux.private(
        executableName: 'path_provider_linux_test_binary');
    expect(await plugin.getApplicationCachePath(),
        '${xdg.cacheHome.path}/path_provider_linux_test_binary');
  });

  test('getDownloadsPath', () async {
    final PathProviderPlatform plugin = PathProviderPlatform.instance;
    expect(await plugin.getDownloadsPath(), startsWith('/'));
  });
}

```
#### get_application_id_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_linux/src/get_application_id_real.dart';

class _FakeGioUtils implements GioUtils {
  int? application;
  Pointer<Utf8>? applicationId;

  @override
  bool libraryIsPresent = false;

  @override
  int gApplicationGetDefault() => application!;

  @override
  Pointer<Utf8> gApplicationGetApplicationId(int app) => applicationId!;
}

void main() {
  late _FakeGioUtils fakeGio;

  setUp(() {
    fakeGio = _FakeGioUtils();
    gioUtilsOverride = fakeGio;
  });

  tearDown(() {
    gioUtilsOverride = null;
  });

  test('returns null if libgio is not available', () {
    expect(getApplicationId(), null);
  });

  test('returns null if g_paplication_get_default returns 0', () {
    fakeGio.libraryIsPresent = true;
    fakeGio.application = 0;
    expect(getApplicationId(), null);
  });

  test('returns null if g_application_get_application_id returns nullptr', () {
    fakeGio.libraryIsPresent = true;
    fakeGio.application = 1;
    fakeGio.applicationId = nullptr;
    expect(getApplicationId(), null);
  });

  test('returns value if g_application_get_application_id returns a value', () {
    fakeGio.libraryIsPresent = true;
    fakeGio.application = 1;
    const String id = 'foo';
    final Pointer<Utf8> idPtr = id.toNativeUtf8();
    fakeGio.applicationId = idPtr;
    expect(getApplicationId(), id);
    calloc.free(idPtr);
  });
}

```
#### integration_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();

```
#### path_provider_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider_linux/path_provider_linux.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getTemporaryDirectory', (WidgetTester tester) async {
    final PathProviderLinux provider = PathProviderLinux();
    final String? result = await provider.getTemporaryPath();
    _verifySampleFile(result, 'temporaryDirectory');
  });

  testWidgets('getDownloadDirectory', (WidgetTester tester) async {
    if (!Platform.isLinux) {
      return;
    }
    final PathProviderLinux provider = PathProviderLinux();
    final String? result = await provider.getDownloadsPath();
    _verifySampleFile(result, 'downloadDirectory');
  });

  testWidgets('getApplicationDocumentsDirectory', (WidgetTester tester) async {
    final PathProviderLinux provider = PathProviderLinux();
    final String? result = await provider.getApplicationDocumentsPath();
    _verifySampleFile(result, 'applicationDocuments');
  });

  testWidgets('getApplicationSupportDirectory', (WidgetTester tester) async {
    final PathProviderLinux provider = PathProviderLinux();
    final String? result = await provider.getApplicationSupportPath();
    _verifySampleFile(result, 'applicationSupport');
  });

  testWidgets('getApplicationCacheDirectory', (WidgetTester tester) async {
    final PathProviderLinux provider = PathProviderLinux();
    final String? result = await provider.getApplicationCachePath();
    _verifySampleFile(result, 'applicationCache');
  });
}

/// Verify a file called [name] in [directoryPath] by recreating it with test
/// contents when necessary.
void _verifySampleFile(String? directoryPath, String name) {
  expect(directoryPath, isNotNull);
  if (directoryPath == null) {
    return;
  }
  final Directory directory = Directory(directoryPath);
  final File file = File('${directory.path}${Platform.pathSeparator}$name');

  if (file.existsSync()) {
    file.deleteSync();
    expect(file.existsSync(), isFalse);
  }

  file.writeAsStringSync('Hello world!');
  expect(file.readAsStringSync(), 'Hello world!');
  expect(directory.listSync(), isNotEmpty);
  file.deleteSync();
}

```
#### main.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider_linux/path_provider_linux.dart';

void main() {
  runApp(const MyApp());
}

/// Sample app
class MyApp extends StatefulWidget {
  /// Default Constructor
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _tempDirectory = 'Unknown';
  String? _downloadsDirectory = 'Unknown';
  String? _appSupportDirectory = 'Unknown';
  String? _appCacheDirectory = 'Unknown';
  String? _documentsDirectory = 'Unknown';
  final PathProviderLinux _provider = PathProviderLinux();

  @override
  void initState() {
    super.initState();
    initDirectories();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initDirectories() async {
    String? tempDirectory;
    String? downloadsDirectory;
    String? appSupportDirectory;
    String? appCacheDirectory;
    String? documentsDirectory;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      tempDirectory = await _provider.getTemporaryPath();
    } on PlatformException {
      tempDirectory = 'Failed to get temp directory.';
    }
    try {
      downloadsDirectory = await _provider.getDownloadsPath();
    } on PlatformException {
      downloadsDirectory = 'Failed to get downloads directory.';
    }

    try {
      documentsDirectory = await _provider.getApplicationDocumentsPath();
    } on PlatformException {
      documentsDirectory = 'Failed to get documents directory.';
    }

    try {
      appSupportDirectory = await _provider.getApplicationSupportPath();
    } on PlatformException {
      appSupportDirectory = 'Failed to get documents directory.';
    }

    try {
      appCacheDirectory = await _provider.getApplicationCachePath();
    } on PlatformException {
      appCacheDirectory = 'Failed to get cache directory.';
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return;
    }

    setState(() {
      _tempDirectory = tempDirectory;
      _downloadsDirectory = downloadsDirectory;
      _appSupportDirectory = appSupportDirectory;
      _appCacheDirectory = appCacheDirectory;
      _documentsDirectory = documentsDirectory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Path Provider Linux example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('Temp Directory: $_tempDirectory\n'),
              Text('Documents Directory: $_documentsDirectory\n'),
              Text('Downloads Directory: $_downloadsDirectory\n'),
              Text('Application Support Directory: $_appSupportDirectory\n'),
              Text('Application Cache Directory: $_appCacheDirectory\n'),
            ],
          ),
        ),
      ),
    );
  }
}

```
#### path_provider_linux.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export 'src/path_provider_linux.dart';

```
#### path_provider_linux.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:xdg_directories/xdg_directories.dart' as xdg;

import 'get_application_id.dart';

/// The linux implementation of [PathProviderPlatform]
///
/// This class implements the `package:path_provider` functionality for Linux.
class PathProviderLinux extends PathProviderPlatform {
  /// Constructs an instance of [PathProviderLinux]
  PathProviderLinux() : _environment = Platform.environment;

  /// Constructs an instance of [PathProviderLinux] with the given [environment]
  @visibleForTesting
  PathProviderLinux.private(
      {Map<String, String> environment = const <String, String>{},
      String? executableName,
      String? applicationId})
      : _environment = environment,
        _executableName = executableName,
        _applicationId = applicationId;

  final Map<String, String> _environment;
  String? _executableName;
  String? _applicationId;

  /// Registers this class as the default instance of [PathProviderPlatform]
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderLinux();
  }

  @override
  Future<String?> getTemporaryPath() {
    final String environmentTmpDir = _environment['TMPDIR'] ?? '';
    return Future<String?>.value(
      environmentTmpDir.isEmpty ? '/tmp' : environmentTmpDir,
    );
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final Directory directory =
        Directory(path.join(xdg.dataHome.path, await _getId()));
    if (directory.existsSync()) {
      return directory.path;
    }

    // This plugin originally used the executable name as a directory.
    // Use that if it exists for backwards compatibility.
    final Directory legacyDirectory =
        Directory(path.join(xdg.dataHome.path, await _getExecutableName()));
    if (legacyDirectory.existsSync()) {
      return legacyDirectory.path;
    }

    // Create the directory, because mobile implementations assume the directory exists.
    await directory.create(recursive: true);
    return directory.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() {
    return Future<String?>.value(xdg.getUserDirectory('DOCUMENTS')?.path);
  }

  @override
  Future<String?> getApplicationCachePath() async {
    final Directory directory =
        Directory(path.join(xdg.cacheHome.path, await _getId()));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  @override
  Future<String?> getDownloadsPath() {
    return Future<String?>.value(xdg.getUserDirectory('DOWNLOAD')?.path);
  }

  // Gets the name of this executable.
  Future<String> _getExecutableName() async {
    _executableName ??= path.basenameWithoutExtension(
        await File('/proc/self/exe').resolveSymbolicLinks());
    return _executableName!;
  }

  // Gets the unique ID for this application.
  Future<String> _getId() async {
    _applicationId ??= getApplicationId();
    // If no application ID then fall back to using the executable name.
    return _applicationId ?? await _getExecutableName();
  }
}

```
#### get_application_id.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// getApplicationId() is implemented using FFI; export a stub for platforms
// that don't support FFI (e.g., web) to avoid having transitive dependencies
// break web compilation.
export 'get_application_id_stub.dart'
    if (dart.library.ffi) 'get_application_id_real.dart';

```
#### get_application_id_stub.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Gets the application ID for this app.
String? getApplicationId() => null;

```
#### get_application_id_real.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

// GApplication* g_application_get_default();
typedef _GApplicationGetDefaultC = IntPtr Function();
typedef _GApplicationGetDefaultDart = int Function();

// const gchar* g_application_get_application_id(GApplication* application);
typedef _GApplicationGetApplicationIdC = Pointer<Utf8> Function(IntPtr);
typedef _GApplicationGetApplicationIdDart = Pointer<Utf8> Function(int);

/// Interface for interacting with libgio.
@visibleForTesting
class GioUtils {
  /// Creates a default instance that uses the real libgio.
  GioUtils() {
    try {
      _gio = DynamicLibrary.open('libgio-2.0.so');
    } on ArgumentError {
      _gio = null;
    }
  }

  DynamicLibrary? _gio;

  /// True if libgio was opened successfully.
  bool get libraryIsPresent => _gio != null;

  /// Wraps `g_application_get_default`.
  int gApplicationGetDefault() {
    if (_gio == null) {
      return 0;
    }
    final _GApplicationGetDefaultDart getDefault = _gio!
        .lookupFunction<_GApplicationGetDefaultC, _GApplicationGetDefaultDart>(
            'g_application_get_default');
    return getDefault();
  }

  /// Wraps g_application_get_application_id.
  Pointer<Utf8> gApplicationGetApplicationId(int app) {
    if (_gio == null) {
      return nullptr;
    }
    final _GApplicationGetApplicationIdDart gApplicationGetApplicationId = _gio!
        .lookupFunction<_GApplicationGetApplicationIdC,
                _GApplicationGetApplicationIdDart>(
            'g_application_get_application_id');
    return gApplicationGetApplicationId(app);
  }
}

/// Allows overriding the default GioUtils instance with a fake for testing.
@visibleForTesting
GioUtils? gioUtilsOverride;

/// Gets the application ID for this app.
String? getApplicationId() {
  final GioUtils gio = gioUtilsOverride ?? GioUtils();
  if (!gio.libraryIsPresent) {
    return null;
  }

  final int app = gio.gApplicationGetDefault();
  if (app == 0) {
    return null;
  }
  final Pointer<Utf8> appId = gio.gApplicationGetApplicationId(app);
  if (appId == nullptr) {
    return null;
  }
  return appId.toDartString();
}

```
#### video_downloader_notifier.dart
``` dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vid_downloader/state/video_downloader_state.dart';

import 'video_downloader_state.dart';

class VideoDownloaderNotifier
    extends StateNotifier<VideoDownloaderState> {
  VideoDownloaderNotifier() : super(const VideoDownloaderState());

  Future<void> downloadVideo(String videoUrl) async {
    state = state.copyWith(downloadStatus: DownloadStatus.loading, progress: 0.0);
    try {
      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
        final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
      state = state.copyWith(
          downloadStatus: DownloadStatus.success, localFilePath: file.path);
      } else {
        state = state.copyWith(
            downloadStatus: DownloadStatus.error,
            errorMessage: 'Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(
          downloadStatus: DownloadStatus.error, errorMessage: 'Error: $e');
    }
  }
}

final videoDownloaderProvider =
    StateNotifierProvider<VideoDownloaderNotifier, VideoDownloaderState>(
        (ref) => VideoDownloaderNotifier());
```
#### video_downloader_state.dart
``` dart

import 'package:flutter/foundation.dart';

enum DownloadStatus { initial, loading, success, error }

@immutable
class VideoDownloaderState {
  final DownloadStatus downloadStatus;
  final double progress;
  final String? errorMessage;
  final String? localFilePath;

  const VideoDownloaderState({
    this.downloadStatus = DownloadStatus.initial,
    this.progress = 0.0,
    this.errorMessage,
    this.localFilePath,
  });

  VideoDownloaderState copyWith({
    DownloadStatus? downloadStatus,
    double? progress,
    String? errorMessage,
    String? localFilePath,
  }) {
    return VideoDownloaderState(
      downloadStatus: downloadStatus ?? this.downloadStatus,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
```
#### video_downloader_screen.dart
``` dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vid_downloader/state/video_downloader_state.dart';
import 'package:vid_downloader/state/video_downloader_notifier.dart';
import 'package:video_player/video_player.dart';

class VideoDownloaderScreen extends HookConsumerWidget {
  const VideoDownloaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoUrlController = useTextEditingController();
    final videoDownloaderState = ref.watch(videoDownloaderProvider);
    final videoDownloaderNotifier = ref.read(videoDownloaderProvider.notifier);
    final videoPlayerController = useState<VideoPlayerController?>(null);

    useEffect(() {
      if (videoDownloaderState.localFilePath != null) {
        videoPlayerController.value = VideoPlayerController.file(
            File(videoDownloaderState.localFilePath!))
          ..initialize().then((_) {
            videoPlayerController.value?.play();
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: videoUrlController,
              decoration: const InputDecoration(
                labelText: 'Enter Video URL',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final videoUrl = videoUrlController.text;
                if (videoUrl.isNotEmpty) {
                  await videoDownloaderNotifier.downloadVideo(videoUrl);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a URL')));
                }
              },
              child: const Text('Download Video'),
            ),
            const SizedBox(height: 20),
            if (videoDownloaderState.downloadStatus == DownloadStatus.loading)
              const CircularProgressIndicator()
            else if (videoDownloaderState.downloadStatus == DownloadStatus.error)
               Text('Error: ${videoDownloaderState.errorMessage}')
            else if (videoDownloaderState.localFilePath != null)
              AspectRatio(
                aspectRatio: videoPlayerController.value?.value.aspectRatio ?? 1,
                child: videoPlayerController.value != null &&
                    videoPlayerController.value!.value.isInitialized
                    ? VideoPlayer(videoPlayerController.value!)
                    : const Center(child: Text('Video Loading...'))
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
#### dart_plugin_registrant.dart
``` dart

//
// Generated file. Do not edit.
// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.
//

// @dart = 3.6

import 'dart:io'; // flutter_ignore: dart_io_import.
import 'package:path_provider_android/path_provider_android.dart';
import 'package:video_player_android/video_player_android.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:video_player_avfoundation/video_player_avfoundation.dart';
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:video_player_avfoundation/video_player_avfoundation.dart';
import 'package:path_provider_windows/path_provider_windows.dart';

@pragma('vm:entry-point')
class _PluginRegistrant {

  @pragma('vm:entry-point')
  static void register() {
    if (Platform.isAndroid) {
      try {
        PathProviderAndroid.registerWith();
      } catch (err) {
        print(
          '`path_provider_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        AndroidVideoPlayer.registerWith();
      } catch (err) {
        print(
          '`video_player_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isIOS) {
      try {
        PathProviderFoundation.registerWith();
      } catch (err) {
        print(
          '`path_provider_foundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        AVFoundationVideoPlayer.registerWith();
      } catch (err) {
        print(
          '`video_player_avfoundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isLinux) {
      try {
        PathProviderLinux.registerWith();
      } catch (err) {
        print(
          '`path_provider_linux` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isMacOS) {
      try {
        PathProviderFoundation.registerWith();
      } catch (err) {
        print(
          '`path_provider_foundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

      try {
        AVFoundationVideoPlayer.registerWith();
      } catch (err) {
        print(
          '`video_player_avfoundation` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isWindows) {
      try {
        PathProviderWindows.registerWith();
      } catch (err) {
        print(
          '`path_provider_windows` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    }
  }
}

```
#### web_plugin_registrant.dart
``` dart

// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:video_player_web/video_player_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  VideoPlayerPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}

```
#### path_provider_windows_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:path_provider_windows/src/path_provider_windows_real.dart'
    show encodingCP1252, encodingUnicode, languageEn;

// A fake VersionInfoQuerier that just returns preset responses.
class FakeVersionInfoQuerier implements VersionInfoQuerier {
  FakeVersionInfoQuerier(
    this.responses, {
    this.language = languageEn,
    this.encoding = encodingUnicode,
  });

  final String language;
  final String encoding;
  final Map<String, String> responses;

  // ignore: unreachable_from_main
  String? getStringValue(
    Pointer<Uint8>? versionInfo,
    String key, {
    required String language,
    required String encoding,
  }) {
    if (language == this.language && encoding == this.encoding) {
      return responses[key];
    } else {
      return null;
    }
  }
}

void main() {
  test('registered instance', () {
    PathProviderWindows.registerWith();
    expect(PathProviderPlatform.instance, isA<PathProviderWindows>());
  });

  test('getTemporaryPath', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    expect(await pathProvider.getTemporaryPath(), contains(r'C:\'));
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with no version info', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier =
        FakeVersionInfoQuerier(<String, String>{});
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, contains(r'C:\'));
    expect(path, contains(r'AppData'));
    // The last path component should be the executable name.
    expect(path, endsWith(r'flutter_tester'));
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with full version info in CP1252', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': 'A Company',
      'ProductName': 'Amazing App',
    }, encoding: encodingCP1252);
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(path, endsWith(r'AppData\Roaming\A Company\Amazing App'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with full version info in Unicode', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': 'A Company',
      'ProductName': 'Amazing App',
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(path, endsWith(r'AppData\Roaming\A Company\Amazing App'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test(
      'getApplicationSupportPath with full version info in Unsupported Encoding',
      () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': 'A Company',
      'ProductName': 'Amazing App',
    }, language: '0000', encoding: '0000');
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, contains(r'C:\'));
    expect(path, contains(r'AppData'));
    // The last path component should be the executable name.
    expect(path, endsWith(r'flutter_tester'));
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with missing company', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'ProductName': 'Amazing App',
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(path, endsWith(r'AppData\Roaming\Amazing App'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with problematic values', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': r'A <Bad> Company: Name.',
      'ProductName': r'A"/Terrible\|App?*Name',
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(
          path,
          endsWith(
              r'AppData\Roaming\A _Bad_ Company_ Name\A__Terrible__App__Name'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with a completely invalid company', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': r'..',
      'ProductName': r'Amazing App',
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(path, endsWith(r'AppData\Roaming\Amazing App'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with very long app name', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    final String truncatedName = 'A' * 255;
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': 'A Company',
      'ProductName': truncatedName * 2,
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, endsWith('\\$truncatedName'));
    // The directory won't exist, since it's longer than MAXPATH, so don't check
    // that here.
  }, skip: !Platform.isWindows);

  test('getApplicationDocumentsPath', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    final String? path = await pathProvider.getApplicationDocumentsPath();
    expect(path, contains(r'C:\'));
    expect(path, contains(r'Documents'));
  }, skip: !Platform.isWindows);

  test('getApplicationCachePath', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': 'A Company',
      'ProductName': 'Amazing App',
    }, encoding: encodingCP1252);
    final String? path = await pathProvider.getApplicationCachePath();
    expect(path, isNotNull);
    if (path != null) {
      expect(path, endsWith(r'AppData\Local\A Company\Amazing App'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test('getDownloadsPath', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    final String? path = await pathProvider.getDownloadsPath();
    expect(path, contains(r'C:\'));
    expect(path, contains(r'Downloads'));
  }, skip: !Platform.isWindows);
}

```
#### guid_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_windows/src/guid.dart';

void main() {
  test('has correct byte representation', () async {
    final Pointer<GUID> guid = calloc<GUID>()
      ..ref.parse('{00112233-4455-6677-8899-aabbccddeeff}');
    final ByteData data = ByteData(16)
      ..setInt32(0, guid.ref.data1, Endian.little)
      ..setInt16(4, guid.ref.data2, Endian.little)
      ..setInt16(6, guid.ref.data3, Endian.little)
      ..setInt64(8, guid.ref.data4, Endian.little);
    expect(data.getUint8(0), 0x33);
    expect(data.getUint8(1), 0x22);
    expect(data.getUint8(2), 0x11);
    expect(data.getUint8(3), 0x00);
    expect(data.getUint8(4), 0x55);
    expect(data.getUint8(5), 0x44);
    expect(data.getUint8(6), 0x77);
    expect(data.getUint8(7), 0x66);
    expect(data.getUint8(8), 0x88);
    expect(data.getUint8(9), 0x99);
    expect(data.getUint8(10), 0xAA);
    expect(data.getUint8(11), 0xBB);
    expect(data.getUint8(12), 0xCC);
    expect(data.getUint8(13), 0xDD);
    expect(data.getUint8(14), 0xEE);
    expect(data.getUint8(15), 0xFF);

    calloc.free(guid);
  });

  test('handles alternate forms', () async {
    final Pointer<GUID> guid1 = calloc<GUID>()
      ..ref.parse('{00112233-4455-6677-8899-aabbccddeeff}');
    final Pointer<GUID> guid2 = calloc<GUID>()
      ..ref.parse('00112233445566778899AABBCCDDEEFF');

    expect(guid1.ref.data1, guid2.ref.data1);
    expect(guid1.ref.data2, guid2.ref.data2);
    expect(guid1.ref.data3, guid2.ref.data3);
    expect(guid1.ref.data4, guid2.ref.data4);

    calloc.free(guid1);
    calloc.free(guid2);
  });

  test('throws for bad data', () async {
    final Pointer<GUID> guid = calloc<GUID>();

    expect(() => guid.ref.parse('{00112233-4455-6677-88'), throwsArgumentError);

    calloc.free(guid);
  });
}

```
#### integration_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();

```
#### path_provider_test.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider_windows/path_provider_windows.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getTemporaryDirectory', (WidgetTester tester) async {
    final PathProviderWindows provider = PathProviderWindows();
    final String? result = await provider.getTemporaryPath();
    _verifySampleFile(result, 'temporaryDirectory');
  });

  testWidgets('getApplicationDocumentsDirectory', (WidgetTester tester) async {
    final PathProviderWindows provider = PathProviderWindows();
    final String? result = await provider.getApplicationDocumentsPath();
    _verifySampleFile(result, 'applicationDocuments');
  });

  testWidgets('getApplicationSupportDirectory', (WidgetTester tester) async {
    final PathProviderWindows provider = PathProviderWindows();
    final String? result = await provider.getApplicationSupportPath();
    _verifySampleFile(result, 'applicationSupport');
  });

  testWidgets('getApplicationCacheDirectory', (WidgetTester tester) async {
    final PathProviderWindows provider = PathProviderWindows();
    final String? result = await provider.getApplicationCachePath();
    _verifySampleFile(result, 'applicationCache');
  });

  testWidgets('getDownloadsDirectory', (WidgetTester tester) async {
    final PathProviderWindows provider = PathProviderWindows();
    final String? result = await provider.getDownloadsPath();
    _verifySampleFile(result, 'downloads');
  });
}

/// Verify a file called [name] in [directoryPath] by recreating it with test
/// contents when necessary.
void _verifySampleFile(String? directoryPath, String name) {
  expect(directoryPath, isNotNull);
  if (directoryPath == null) {
    return;
  }
  final Directory directory = Directory(directoryPath);
  final File file = File('${directory.path}${Platform.pathSeparator}$name');

  if (file.existsSync()) {
    file.deleteSync();
    expect(file.existsSync(), isFalse);
  }

  file.writeAsStringSync('Hello world!');
  expect(file.readAsStringSync(), 'Hello world!');
  expect(directory.listSync(), isNotEmpty);
  file.deleteSync();
}

```
#### main.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:path_provider_windows/path_provider_windows.dart';

void main() {
  runApp(const MyApp());
}

/// Sample app
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _tempDirectory = 'Unknown';
  String? _downloadsDirectory = 'Unknown';
  String? _appSupportDirectory = 'Unknown';
  String? _documentsDirectory = 'Unknown';
  String? _cacheDirectory = 'Unknown';

  @override
  void initState() {
    super.initState();
    initDirectories();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initDirectories() async {
    String? tempDirectory;
    String? downloadsDirectory;
    String? appSupportDirectory;
    String? documentsDirectory;
    String? cacheDirectory;
    final PathProviderWindows provider = PathProviderWindows();

    try {
      tempDirectory = await provider.getTemporaryPath();
    } catch (exception) {
      tempDirectory = 'Failed to get temp directory: $exception';
    }
    try {
      downloadsDirectory = await provider.getDownloadsPath();
    } catch (exception) {
      downloadsDirectory = 'Failed to get downloads directory: $exception';
    }

    try {
      documentsDirectory = await provider.getApplicationDocumentsPath();
    } catch (exception) {
      documentsDirectory = 'Failed to get documents directory: $exception';
    }

    try {
      appSupportDirectory = await provider.getApplicationSupportPath();
    } catch (exception) {
      appSupportDirectory = 'Failed to get app support directory: $exception';
    }

    try {
      cacheDirectory = await provider.getApplicationCachePath();
    } catch (exception) {
      cacheDirectory = 'Failed to get cache directory: $exception';
    }

    setState(() {
      _tempDirectory = tempDirectory;
      _downloadsDirectory = downloadsDirectory;
      _appSupportDirectory = appSupportDirectory;
      _documentsDirectory = documentsDirectory;
      _cacheDirectory = cacheDirectory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Path Provider example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('Temp Directory: $_tempDirectory\n'),
              Text('Documents Directory: $_documentsDirectory\n'),
              Text('Downloads Directory: $_downloadsDirectory\n'),
              Text('Application Support Directory: $_appSupportDirectory\n'),
              Text('Cache Directory: $_cacheDirectory\n'),
            ],
          ),
        ),
      ),
    );
  }
}

```
#### path_provider_windows.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// path_provider_windows is implemented using FFI; export a stub for platforms
// that don't support FFI (e.g., web) to avoid having transitive dependencies
// break web compilation.
export 'src/folders_stub.dart' if (dart.library.ffi) 'src/folders.dart';
export 'src/path_provider_windows_stub.dart'
    if (dart.library.ffi) 'src/path_provider_windows_real.dart';

```
#### path_provider_windows_real.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'folders.dart';
import 'guid.dart';
import 'win32_wrappers.dart';

/// Constant for en-US language used in VersionInfo keys.
@visibleForTesting
const String languageEn = '0409';

/// Constant for CP1252 encoding used in VersionInfo keys
@visibleForTesting
const String encodingCP1252 = '04e4';

/// Constant for Unicode encoding used in VersionInfo keys
@visibleForTesting
const String encodingUnicode = '04b0';

/// Wraps the Win32 VerQueryValue API call.
///
/// This class exists to allow injecting alternate metadata in tests without
/// building multiple custom test binaries.
@visibleForTesting
class VersionInfoQuerier {
  /// Returns the value for [key] in [versionInfo]s in section with given
  /// language and encoding, or null if there is no such entry,
  /// or if versionInfo is null.
  ///
  /// See https://docs.microsoft.com/windows/win32/menurc/versioninfo-resource
  /// for list of possible language and encoding values.
  String? getStringValue(
    Pointer<Uint8>? versionInfo,
    String key, {
    required String language,
    required String encoding,
  }) {
    assert(language.isNotEmpty);
    assert(encoding.isNotEmpty);
    if (versionInfo == null) {
      return null;
    }
    final Pointer<Utf16> keyPath =
        '\\StringFileInfo\\$language$encoding\\$key'.toNativeUtf16();
    final Pointer<UINT> length = calloc<UINT>();
    final Pointer<Pointer<Utf16>> valueAddress = calloc<Pointer<Utf16>>();
    try {
      if (VerQueryValue(versionInfo, keyPath, valueAddress, length) == 0) {
        return null;
      }
      return valueAddress.value.toDartString();
    } finally {
      calloc.free(keyPath);
      calloc.free(length);
      calloc.free(valueAddress);
    }
  }
}

/// The Windows implementation of [PathProviderPlatform]
///
/// This class implements the `package:path_provider` functionality for Windows.
class PathProviderWindows extends PathProviderPlatform {
  /// Registers the Windows implementation.
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderWindows();
  }

  /// The object to use for performing VerQueryValue calls.
  @visibleForTesting
  VersionInfoQuerier versionInfoQuerier = VersionInfoQuerier();

  /// This is typically the same as the TMP environment variable.
  @override
  Future<String?> getTemporaryPath() async {
    final Pointer<Utf16> buffer = calloc<Uint16>(MAX_PATH + 1).cast<Utf16>();
    String path;

    try {
      final int length = GetTempPath(MAX_PATH, buffer);

      if (length == 0) {
        final int error = GetLastError();
        throw _createWin32Exception(error);
      } else {
        path = buffer.toDartString();

        // GetTempPath adds a trailing backslash, but SHGetKnownFolderPath does
        // not. Strip off trailing backslash for consistency with other methods
        // here.
        if (path.endsWith(r'\')) {
          path = path.substring(0, path.length - 1);
        }
      }

      // Ensure that the directory exists, since GetTempPath doesn't.
      final Directory directory = Directory(path);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      return path;
    } finally {
      calloc.free(buffer);
    }
  }

  @override
  Future<String?> getApplicationSupportPath() =>
      _createApplicationSubdirectory(WindowsKnownFolder.RoamingAppData);

  @override
  Future<String?> getApplicationDocumentsPath() =>
      getPath(WindowsKnownFolder.Documents);

  @override
  Future<String?> getApplicationCachePath() =>
      _createApplicationSubdirectory(WindowsKnownFolder.LocalAppData);

  @override
  Future<String?> getDownloadsPath() => getPath(WindowsKnownFolder.Downloads);

  /// Retrieve any known folder from Windows.
  ///
  /// folderID is a GUID that represents a specific known folder ID, drawn from
  /// [WindowsKnownFolder].
  Future<String?> getPath(String folderID) {
    final Pointer<Pointer<Utf16>> pathPtrPtr = calloc<Pointer<Utf16>>();
    final Pointer<GUID> knownFolderID = calloc<GUID>()..ref.parse(folderID);

    try {
      final int hr = SHGetKnownFolderPath(
        knownFolderID,
        KF_FLAG_DEFAULT,
        NULL,
        pathPtrPtr,
      );

      if (FAILED(hr)) {
        if (hr == E_INVALIDARG || hr == E_FAIL) {
          throw _createWin32Exception(hr);
        }
        return Future<String?>.value();
      }

      final String path = pathPtrPtr.value.toDartString();
      return Future<String>.value(path);
    } finally {
      calloc.free(pathPtrPtr);
      calloc.free(knownFolderID);
    }
  }

  String? _getStringValue(Pointer<Uint8>? infoBuffer, String key) =>
      versionInfoQuerier.getStringValue(infoBuffer, key,
          language: languageEn, encoding: encodingCP1252) ??
      versionInfoQuerier.getStringValue(infoBuffer, key,
          language: languageEn, encoding: encodingUnicode);

  /// Returns the relative path string to append to the root directory returned
  /// by Win32 APIs for application storage (such as RoamingAppDir) to get a
  /// directory that is unique to the application.
  ///
  /// The convention is to use company-name\product-name\. This will use that if
  /// possible, using the data in the VERSIONINFO resource, with the following
  /// fallbacks:
  /// - If the company name isn't there, that component will be dropped.
  /// - If the product name isn't there, it will use the exe's filename (without
  ///   extension).
  String _getApplicationSpecificSubdirectory() {
    String? companyName;
    String? productName;

    final Pointer<Utf16> moduleNameBuffer =
        calloc<WCHAR>(MAX_PATH + 1).cast<Utf16>();
    final Pointer<DWORD> unused = calloc<DWORD>();
    Pointer<BYTE>? infoBuffer;
    try {
      // Get the module name.
      final int moduleNameLength =
          GetModuleFileName(0, moduleNameBuffer, MAX_PATH);
      if (moduleNameLength == 0) {
        final int error = GetLastError();
        throw _createWin32Exception(error);
      }

      // From that, load the VERSIONINFO resource
      final int infoSize = GetFileVersionInfoSize(moduleNameBuffer, unused);
      if (infoSize != 0) {
        infoBuffer = calloc<BYTE>(infoSize);
        if (GetFileVersionInfo(moduleNameBuffer, 0, infoSize, infoBuffer) ==
            0) {
          calloc.free(infoBuffer);
          infoBuffer = null;
        }
      }
      companyName =
          _sanitizedDirectoryName(_getStringValue(infoBuffer, 'CompanyName'));
      productName =
          _sanitizedDirectoryName(_getStringValue(infoBuffer, 'ProductName'));

      // If there was no product name, use the executable name.
      productName ??=
          path.basenameWithoutExtension(moduleNameBuffer.toDartString());

      return companyName != null
          ? path.join(companyName, productName)
          : productName;
    } finally {
      calloc.free(moduleNameBuffer);
      calloc.free(unused);
      if (infoBuffer != null) {
        calloc.free(infoBuffer);
      }
    }
  }

  /// Makes [rawString] safe as a directory component. See
  /// https://docs.microsoft.com/windows/win32/fileio/naming-a-file#naming-conventions
  ///
  /// If after sanitizing the string is empty, returns null.
  String? _sanitizedDirectoryName(String? rawString) {
    if (rawString == null) {
      return null;
    }
    String sanitized = rawString
        // Replace banned characters.
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        // Remove trailing whitespace.
        .trimRight()
        // Ensure that it does not end with a '.'.
        .replaceAll(RegExp(r'[.]+$'), '');
    const int kMaxComponentLength = 255;
    if (sanitized.length > kMaxComponentLength) {
      sanitized = sanitized.substring(0, kMaxComponentLength);
    }
    return sanitized.isEmpty ? null : sanitized;
  }

  Future<String?> _createApplicationSubdirectory(String folderId) async {
    final String? baseDir = await getPath(folderId);
    if (baseDir == null) {
      return null;
    }
    final Directory directory =
        Directory(path.join(baseDir, _getApplicationSpecificSubdirectory()));
    // Ensure that the directory exists if possible, since it will on other
    // platforms. If the name is longer than MAXPATH, creating will fail, so
    // skip that step; it's up to the client to decide what to do with the path
    // in that case (e.g., using a short path).
    if (directory.path.length <= MAX_PATH) {
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
    }
    return directory.path;
  }
}

Exception _createWin32Exception(int errorCode) {
  return PlatformException(
      code: 'Win32 Error',
      // TODO(stuartmorgan): Consider getting the system error message via
      // FormatMessage if it turns out to be necessary for debugging issues.
      // Plugin-client-level usability isn't a major consideration since per
      // https://github.com/flutter/flutter/blob/master/docs/ecosystem/contributing/README.md#platform-exception-handling
      // any case that comes up in practice should be handled and returned
      // via a plugin-specific exception, not this fallback.
      message: 'Error code 0x${errorCode.toRadixString(16)}');
}

```
#### guid.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

/// Representation of the Win32 GUID struct.
// For the layout of this struct, see
// https://learn.microsoft.com/windows/win32/api/guiddef/ns-guiddef-guid
@Packed(4)
base class GUID extends Struct {
  /// Native Data1 field.
  @Uint32()
  external int data1;

  /// Native Data2 field.
  @Uint16()
  external int data2;

  /// Native Data3 field.
  @Uint16()
  external int data3;

  /// Native Data4 field.
  // This should be an eight-element byte array, but there's no such annotation.
  @Uint64()
  external int data4;

  /// Parses a GUID string, with optional enclosing "{}"s and optional "-"s,
  /// into data.
  void parse(String guid) {
    final String hexOnly = guid.replaceAll(RegExp(r'[{}-]'), '');
    if (hexOnly.length != 32) {
      throw ArgumentError.value(guid, 'guid', 'Invalid GUID string');
    }
    final ByteData bytes = ByteData(16);
    for (int i = 0; i < 16; ++i) {
      bytes.setUint8(
          i, int.parse(hexOnly.substring(i * 2, i * 2 + 2), radix: 16));
    }
    data1 = bytes.getInt32(0);
    data2 = bytes.getInt16(4);
    data3 = bytes.getInt16(6);
    // [bytes] is big endian, but the host is little endian, so a default
    // big-endian read would reverse the bytes. Since data4 is supposed to be
    // a byte array, the order should be preserved, so do a little-endian read.
    // https://en.wikipedia.org/wiki/Universally_unique_identifier#Encoding
    data4 = bytes.getInt64(8, Endian.little);
  }
}

```
#### folders_stub.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Stub version of the actual class.
class WindowsKnownFolder {}

```
#### win32_wrappers.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The types and functions here correspond directly to corresponding Windows
// types and functions, so the Windows docs are the definitive source of
// documentation.
// ignore_for_file: public_member_api_docs

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'guid.dart';

typedef BOOL = Int32;
typedef BYTE = Uint8;
typedef DWORD = Uint32;
typedef UINT = Uint32;
typedef HANDLE = IntPtr;
typedef HMODULE = HANDLE;
typedef HRESULT = Int32;
typedef LPCVOID = Pointer<NativeType>;
typedef LPCWSTR = Pointer<Utf16>;
typedef LPDWORD = Pointer<DWORD>;
typedef LPWSTR = Pointer<Utf16>;
typedef LPVOID = Pointer<NativeType>;
typedef PUINT = Pointer<UINT>;
typedef PWSTR = Pointer<Pointer<Utf16>>;
typedef WCHAR = Uint16;

const int NULL = 0;

// https://learn.microsoft.com/windows/win32/fileio/maximum-file-path-limitation?tabs=registry
const int MAX_PATH = 260;

// https://learn.microsoft.com/windows/win32/seccrypto/common-hresult-values
// ignore: non_constant_identifier_names
final int E_FAIL = 0x80004005.toSigned(32);
// ignore: non_constant_identifier_names
final int E_INVALIDARG = 0x80070057.toSigned(32);

// https://learn.microsoft.com/windows/win32/api/winerror/nf-winerror-failed#remarks
// ignore: non_constant_identifier_names
bool FAILED(int hr) => hr < 0;

// https://learn.microsoft.com/windows/win32/api/shlobj_core/ne-shlobj_core-known_folder_flag
const int KF_FLAG_DEFAULT = 0x00000000;

final DynamicLibrary _dllKernel32 = DynamicLibrary.open('kernel32.dll');
final DynamicLibrary _dllVersion = DynamicLibrary.open('version.dll');
final DynamicLibrary _dllShell32 = DynamicLibrary.open('shell32.dll');

// https://learn.microsoft.com/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath
typedef _FFITypeSHGetKnownFolderPath = HRESULT Function(
    Pointer<GUID>, DWORD, HANDLE, PWSTR);
typedef FFITypeSHGetKnownFolderPathDart = int Function(
    Pointer<GUID>, int, int, Pointer<Pointer<Utf16>>);
// ignore: non_constant_identifier_names
final FFITypeSHGetKnownFolderPathDart SHGetKnownFolderPath =
    _dllShell32.lookupFunction<_FFITypeSHGetKnownFolderPath,
        FFITypeSHGetKnownFolderPathDart>('SHGetKnownFolderPath');

// https://learn.microsoft.com/windows/win32/api/winver/nf-winver-getfileversioninfow
typedef _FFITypeGetFileVersionInfoW = BOOL Function(
    LPCWSTR, DWORD, DWORD, LPVOID);
typedef FFITypeGetFileVersionInfoW = int Function(
    Pointer<Utf16>, int, int, Pointer<NativeType>);
// ignore: non_constant_identifier_names
final FFITypeGetFileVersionInfoW GetFileVersionInfo = _dllVersion
    .lookupFunction<_FFITypeGetFileVersionInfoW, FFITypeGetFileVersionInfoW>(
        'GetFileVersionInfoW');

// https://learn.microsoft.com/windows/win32/api/winver/nf-winver-getfileversioninfosizew
typedef _FFITypeGetFileVersionInfoSizeW = DWORD Function(LPCWSTR, LPDWORD);
typedef FFITypeGetFileVersionInfoSizeW = int Function(
    Pointer<Utf16>, Pointer<Uint32>);
// ignore: non_constant_identifier_names
final FFITypeGetFileVersionInfoSizeW GetFileVersionInfoSize =
    _dllVersion.lookupFunction<_FFITypeGetFileVersionInfoSizeW,
        FFITypeGetFileVersionInfoSizeW>('GetFileVersionInfoSizeW');

// https://learn.microsoft.com/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror
typedef _FFITypeGetLastError = DWORD Function();
typedef FFITypeGetLastError = int Function();
// ignore: non_constant_identifier_names
final FFITypeGetLastError GetLastError = _dllKernel32
    .lookupFunction<_FFITypeGetLastError, FFITypeGetLastError>('GetLastError');

// https://learn.microsoft.com/windows/win32/api/libloaderapi/nf-libloaderapi-getmodulefilenamew
typedef _FFITypeGetModuleFileNameW = DWORD Function(HMODULE, LPWSTR, DWORD);
typedef FFITypeGetModuleFileNameW = int Function(int, Pointer<Utf16>, int);
// ignore: non_constant_identifier_names
final FFITypeGetModuleFileNameW GetModuleFileName = _dllKernel32.lookupFunction<
    _FFITypeGetModuleFileNameW,
    FFITypeGetModuleFileNameW>('GetModuleFileNameW');

// https://learn.microsoft.com/windows/win32/api/winver/nf-winver-verqueryvaluew
typedef _FFITypeVerQueryValueW = BOOL Function(LPCVOID, LPCWSTR, LPVOID, PUINT);
typedef FFITypeVerQueryValueW = int Function(
    Pointer<NativeType>, Pointer<Utf16>, Pointer<NativeType>, Pointer<Uint32>);
// ignore: non_constant_identifier_names
final FFITypeVerQueryValueW VerQueryValue =
    _dllVersion.lookupFunction<_FFITypeVerQueryValueW, FFITypeVerQueryValueW>(
        'VerQueryValueW');

// https://learn.microsoft.com/windows/win32/api/fileapi/nf-fileapi-gettemppathw
typedef _FFITypeGetTempPathW = DWORD Function(DWORD, LPWSTR);
typedef FFITypeGetTempPathW = int Function(int, Pointer<Utf16>);
// ignore: non_constant_identifier_names
final FFITypeGetTempPathW GetTempPath = _dllKernel32
    .lookupFunction<_FFITypeGetTempPathW, FFITypeGetTempPathW>('GetTempPathW');

```
#### path_provider_windows_stub.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// A stub implementation to satisfy compilation of multi-platform packages that
/// depend on path_provider_windows. This should never actually be created.
///
/// Notably, because path_provider needs to manually register
/// path_provider_windows, anything with a transitive dependency on
/// path_provider will also depend on path_provider_windows, not just at the
/// pubspec level but the code level.
class PathProviderWindows extends PathProviderPlatform {
  /// Errors on attempted instantiation of the stub. It exists only to satisfy
  /// compile-time dependencies, and should never actually be created.
  PathProviderWindows() : assert(false);

  /// Registers the Windows implementation.
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderWindows();
  }

  /// Stub; see comment on VersionInfoQuerier.
  VersionInfoQuerier versionInfoQuerier = VersionInfoQuerier();

  /// Match PathProviderWindows so that the analyzer won't report invalid
  /// overrides if tests provide fake PathProviderWindows implementations.
  Future<String> getPath(String folderID) async => '';
}

/// Stub to satisfy the analyzer, which doesn't seem to handle conditional
/// exports correctly.
class VersionInfoQuerier {}

```
#### folders.dart
``` dart

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

// ignore: avoid_classes_with_only_static_members
/// A class containing the GUID references for each of the documented Windows
/// known folders. A property of this class may be passed to the `getPath`
/// method in the [PathProvidersWindows] class to retrieve a known folder from
/// Windows.
// These constants come from
// https://learn.microsoft.com/windows/win32/shell/knownfolderid
class WindowsKnownFolder {
  /// The file system directory that is used to store administrative tools for
  /// an individual user. The MMC will save customized consoles to this
  /// directory, and it will roam with the user.
  static String get AdminTools => '{724EF170-A42D-4FEF-9F26-B60E846FBA4F}';

  /// The file system directory that acts as a staging area for files waiting to
  /// be written to a CD. A typical path is C:\Documents and
  /// Settings\username\Local Settings\Application Data\Microsoft\CD Burning.
  static String get CDBurning => '{9E52AB10-F80D-49DF-ACB8-4330F5687855}';

  /// The file system directory that contains administrative tools for all users
  /// of the computer.
  static String get CommonAdminTools =>
      '{D0384E7D-BAC3-4797-8F14-CBA229B392B5}';

  /// The file system directory that contains the directories for the common
  /// program groups that appear on the Start menu for all users. A typical path
  /// is C:\Documents and Settings\All Users\Start Menu\Programs.
  static String get CommonPrograms => '{0139D44E-6AFE-49F2-8690-3DAFCAE6FFB8}';

  /// The file system directory that contains the programs and folders that
  /// appear on the Start menu for all users. A typical path is C:\Documents and
  /// Settings\All Users\Start Menu.
  static String get CommonStartMenu => '{A4115719-D62E-491D-AA7C-E74B8BE3B067}';

  /// The file system directory that contains the programs that appear in the
  /// Startup folder for all users. A typical path is C:\Documents and
  /// Settings\All Users\Start Menu\Programs\Startup.
  static String get CommonStartup => '{82A5EA35-D9CD-47C5-9629-E15D2F714E6E}';

  /// The file system directory that contains the templates that are available
  /// to all users. A typical path is C:\Documents and Settings\All
  /// Users\Templates.
  static String get CommonTemplates => '{B94237E7-57AC-4347-9151-B08C6C32D1F7}';

  /// The virtual folder that represents My Computer, containing everything on
  /// the local computer: storage devices, printers, and Control Panel. The
  /// folder can also contain mapped network drives.
  static String get ComputerFolder => '{0AC0837C-BBF8-452A-850D-79D08E667CA7}';

  /// The virtual folder that represents Network Connections, that contains
  /// network and dial-up connections.
  static String get ConnectionsFolder =>
      '{6F0CD92B-2E97-45D1-88FF-B0D186B8DEDD}';

  /// The virtual folder that contains icons for the Control Panel applications.
  static String get ControlPanelFolder =>
      '{82A74AEB-AEB4-465C-A014-D097EE346D63}';

  /// The file system directory that serves as a common repository for Internet
  /// cookies. A typical path is C:\Documents and Settings\username\Cookies.
  static String get Cookies => '{2B0F765D-C0E9-4171-908E-08A611B84FF6}';

  /// The virtual folder that represents the Windows desktop, the root of the
  /// namespace.
  static String get Desktop => '{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}';

  /// The virtual folder that represents the My Documents desktop item.
  static String get Documents => '{FDD39AD0-238F-46AF-ADB4-6C85480369C7}';

  /// The file system directory that serves as a repository for Internet
  /// downloads.
  static String get Downloads => '{374DE290-123F-4565-9164-39C4925E467B}';

  /// The file system directory that serves as a common repository for the
  /// user's favorite items. A typical path is C:\Documents and
  /// Settings\username\Favorites.
  static String get Favorites => '{1777F761-68AD-4D8A-87BD-30B759FA33DD}';

  /// A virtual folder that contains fonts. A typical path is C:\Windows\Fonts.
  static String get Fonts => '{FD228CB7-AE11-4AE3-864C-16F3910AB8FE}';

  /// The file system directory that serves as a common repository for Internet
  /// history items.
  static String get History => '{D9DC8A3B-B784-432E-A781-5A1130A75963}';

  /// The file system directory that serves as a common repository for temporary
  /// Internet files. A typical path is C:\Documents and Settings\username\Local
  /// Settings\Temporary Internet Files.
  static String get InternetCache => '{352481E8-33BE-4251-BA85-6007CAEDCF9D}';

  /// A virtual folder for Internet Explorer.
  static String get InternetFolder => '{4D9F7874-4E0C-4904-967B-40B0D20C3E4B}';

  /// The file system directory that serves as a data repository for local
  /// (nonroaming) applications. A typical path is C:\Documents and
  /// Settings\username\Local Settings\Application Data.
  static String get LocalAppData => '{F1B32785-6FBA-4FCF-9D55-7B8E7F157091}';

  /// The file system directory that serves as a common repository for music
  /// files. A typical path is C:\Documents and Settings\User\My Documents\My
  /// Music.
  static String get Music => '{4BD8D571-6D19-48D3-BE97-422220080E43}';

  /// A file system directory that contains the link objects that may exist in
  /// the My Network Places virtual folder. A typical path is C:\Documents and
  /// Settings\username\NetHood.
  static String get NetHood => '{C5ABBF53-E17F-4121-8900-86626FC2C973}';

  /// The folder that represents other computers in your workgroup.
  static String get NetworkFolder => '{D20BEEC4-5CA8-4905-AE3B-BF251EA09B53}';

  /// The file system directory that serves as a common repository for image
  /// files. A typical path is C:\Documents and Settings\username\My
  /// Documents\My Pictures.
  static String get Pictures => '{33E28130-4E1E-4676-835A-98395C3BC3BB}';

  /// The file system directory that contains the link objects that can exist in
  /// the Printers virtual folder. A typical path is C:\Documents and
  /// Settings\username\PrintHood.
  static String get PrintHood => '{9274BD8D-CFD1-41C3-B35E-B13F55A758F4}';

  /// The virtual folder that contains installed printers.
  static String get PrintersFolder => '{76FC4E2D-D6AD-4519-A663-37BD56068185}';

  /// The user's profile folder. A typical path is C:\Users\username.
  /// Applications should not create files or folders at this level.
  static String get Profile => '{5E6C858F-0E22-4760-9AFE-EA3317B67173}';

  /// The file system directory that contains application data for all users. A
  /// typical path is C:\Documents and Settings\All Users\Application Data. This
  /// folder is used for application data that is not user specific. For
  /// example, an application can store a spell-check dictionary, a database of
  /// clip art, or a log file in the CSIDL_COMMON_APPDATA folder. This
  /// information will not roam and is available to anyone using the computer.
  static String get ProgramData => '{62AB5D82-FDC1-4DC3-A9DD-070D1D495D97}';

  /// The Program Files folder. A typical path is C:\Program Files.
  static String get ProgramFiles => '{905e63b6-c1bf-494e-b29c-65b732d3d21a}';

  /// The common Program Files folder. A typical path is C:\Program
  /// Files\Common.
  static String get ProgramFilesCommon =>
      '{F7F1ED05-9F6D-47A2-AAAE-29D317C6F066}';

  /// On 64-bit systems, a link to the common Program Files folder. A typical path is
  /// C:\Program Files\Common Files.
  static String get ProgramFilesCommonX64 =>
      '{6365D5A7-0F0D-45e5-87F6-0DA56B6A4F7D}';

  /// On 64-bit systems, a link to the 32-bit common Program Files folder. A
  /// typical path is C:\Program Files (x86)\Common Files. On 32-bit systems, a
  /// link to the Common Program Files folder.
  static String get ProgramFilesCommonX86 =>
      '{DE974D24-D9C6-4D3E-BF91-F4455120B917}';

  /// On 64-bit systems, a link to the Program Files folder. A typical path is
  /// C:\Program Files.
  static String get ProgramFilesX64 => '{6D809377-6AF0-444b-8957-A3773F02200E}';

  /// On 64-bit systems, a link to the 32-bit Program Files folder. A typical
  /// path is C:\Program Files (x86). On 32-bit systems, a link to the Common
  /// Program Files folder.
  static String get ProgramFilesX86 => '{7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E}';

  /// The file system directory that contains the user's program groups (which
  /// are themselves file system directories).
  static String get Programs => '{A77F5D77-2E2B-44C3-A6A2-ABA601054A51}';

  /// The file system directory that contains files and folders that appear on
  /// the desktop for all users. A typical path is C:\Documents and Settings\All
  /// Users\Desktop.
  static String get PublicDesktop => '{C4AA340D-F20F-4863-AFEF-F87EF2E6BA25}';

  /// The file system directory that contains documents that are common to all
  /// users. A typical path is C:\Documents and Settings\All Users\Documents.
  static String get PublicDocuments => '{ED4824AF-DCE4-45A8-81E2-FC7965083634}';

  /// The file system directory that serves as a repository for music files
  /// common to all users. A typical path is C:\Documents and Settings\All
  /// Users\Documents\My Music.
  static String get PublicMusic => '{3214FAB5-9757-4298-BB61-92A9DEAA44FF}';

  /// The file system directory that serves as a repository for image files
  /// common to all users. A typical path is C:\Documents and Settings\All
  /// Users\Documents\My Pictures.
  static String get PublicPictures => '{B6EBFB86-6907-413C-9AF7-4FC2ABF07CC5}';

  /// The file system directory that serves as a repository for video files
  /// common to all users. A typical path is C:\Documents and Settings\All
  /// Users\Documents\My Videos.
  static String get PublicVideos => '{2400183A-6185-49FB-A2D8-4A392A602BA3}';

  /// The file system directory that contains shortcuts to the user's most
  /// recently used documents. A typical path is C:\Documents and
  /// Settings\username\My Recent Documents.
  static String get Recent => '{AE50C081-EBD2-438A-8655-8A092E34987A}';

  /// The virtual folder that contains the objects in the user's Recycle Bin.
  static String get RecycleBinFolder =>
      '{B7534046-3ECB-4C18-BE4E-64CD4CB7D6AC}';

  /// The file system directory that contains resource data. A typical path is
  /// C:\Windows\Resources.
  static String get ResourceDir => '{8AD10C31-2ADB-4296-A8F7-E4701232C972}';

  /// The file system directory that serves as a common repository for
  /// application-specific data. A typical path is C:\Documents and
  /// Settings\username\Application Data.
  static String get RoamingAppData => '{3EB685DB-65F9-4CF6-A03A-E3EF65729F3D}';

  /// The file system directory that contains Send To menu items. A typical path
  /// is C:\Documents and Settings\username\SendTo.
  static String get SendTo => '{8983036C-27C0-404B-8F08-102D10DCFD74}';

  /// The file system directory that contains Start menu items. A typical path
  /// is C:\Documents and Settings\username\Start Menu.
  static String get StartMenu => '{625B53C3-AB48-4EC1-BA1F-A1EF4146FC19}';

  /// The file system directory that corresponds to the user's Startup program
  /// group. The system starts these programs whenever the associated user logs
  /// on. A typical path is C:\Documents and Settings\username\Start
  /// Menu\Programs\Startup.
  static String get Startup => '{B97D20BB-F46A-4C97-BA10-5E3608430854}';

  /// The Windows System folder. A typical path is C:\Windows\System32.
  static String get System => '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}';

  /// The 32-bit Windows System folder. On 32-bit systems, this is typically
  /// C:\Windows\system32. On 64-bit systems, this is typically
  /// C:\Windows\syswow64.
  static String get SystemX86 => '{D65231B0-B2F1-4857-A4CE-A8E7C6EA7D27}';

  /// The file system directory that serves as a common repository for document
  /// templates. A typical path is C:\Documents and Settings\username\Templates.
  static String get Templates => '{A63293E8-664E-48DB-A079-DF759E0509F7}';

  /// The file system directory that serves as a common repository for video
  /// files. A typical path is C:\Documents and Settings\username\My
  /// Documents\My Videos.
  static String get Videos => '{18989B1D-99B5-455B-841C-AB7C74E4DDFC}';

  /// The Windows directory or SYSROOT. This corresponds to the %windir% or
  /// %SYSTEMROOT% environment variables. A typical path is C:\Windows.
  static String get Windows => '{F38BF404-1D43-42F2-9305-67DE0B28FC23}';
}

```
