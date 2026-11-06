import 'package:flutter_test/flutter_test.dart';

import 'package:clipit/features/video_look/models/video_look_state.dart';
import 'package:clipit/features/video_look/services/ffmpeg_filtergraph_generator.dart';

void main() {
  group('FfmpegFiltergraphGenerator Filter Tests', () {
    test('default state yields null / empty filtergraph', () {
      const state = VideoLookState();
      final filters = FfmpegFiltergraphGenerator.buildFilterList(state);
      expect(filters, isEmpty);

      final vfString = FfmpegFiltergraphGenerator.buildFiltergraphString(state);
      expect(vfString, equals('null'));
    });

    test('basic visual controls produce eq filter with calculated values', () {
      const state = VideoLookState(
        contrast: 20.0,
        brightness: 10.0,
        saturation: -15.0,
        gamma: 5.0,
      );

      final filters = FfmpegFiltergraphGenerator.buildFilterList(state);
      expect(filters.any((f) => f.startsWith('eq=')), isTrue);

      final eqFilter = filters.firstWhere((f) => f.startsWith('eq='));
      expect(eqFilter, contains('contrast=1.200'));
      expect(eqFilter, contains('saturation=0.850'));
    });

    test('temperature and tint produce colorbalance filter', () {
      const state = VideoLookState(
        temperature: 25.0,
        tint: -10.0,
      );

      final filters = FfmpegFiltergraphGenerator.buildFilterList(state);
      expect(filters.any((f) => f.startsWith('colorbalance=')), isTrue);
    });

    test('hue shift produces hue filter', () {
      const state = VideoLookState(hue: 45.0);
      final filters = FfmpegFiltergraphGenerator.buildFilterList(state);
      expect(filters.contains('hue=h=45.0'), isTrue);
    });

    test('film grain produces noise filter', () {
      const state = VideoLookState(filmGrainAmount: 20.0);
      final filters = FfmpegFiltergraphGenerator.buildFilterList(state);
      expect(filters.any((f) => f.startsWith('noise=alls=')), isTrue);
    });

    test('vignette produces vignette filter', () {
      const state = VideoLookState(vignetteAmount: 30.0);
      final filters = FfmpegFiltergraphGenerator.buildFilterList(state);
      expect(filters.any((f) => f.startsWith('vignette=angle=')), isTrue);
    });

    test('unsharp filter is generated for sharpen and clarity', () {
      const state = VideoLookState(sharpen: 40.0);
      final filters = FfmpegFiltergraphGenerator.buildFilterList(state);
      expect(filters.any((f) => f.startsWith('unsharp=')), isTrue);
    });


    test('buildFfmpegArgs generates complete command with options', () {
      const state = VideoLookState(
        contrast: 15.0,
        filmGrainAmount: 20.0,
      );

      final args = FfmpegFiltergraphGenerator.buildFfmpegArgs(
        inputVideoPath: 'input.mp4',
        outputVideoPath: 'output.mp4',
        state: state,
        audioPath: 'audio.wav',
      );

      expect(args.contains('-i'), isTrue);
      expect(args.contains('input.mp4'), isTrue);
      expect(args.contains('audio.wav'), isTrue);
      expect(args.contains('-vf'), isTrue);
      expect(args.contains('libx264'), isTrue);
      expect(args.contains('yuv420p'), isTrue);
      expect(args.last, equals('output.mp4'));
    });
  });
}
