import 'package:clipit/features/projects/components/interactive_3d_device_preview.dart';
import 'package:clipit/features/projects/models/project_workflow_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Platform Blocks Device Preview Binding', () {
    testWidgets('Laptop platform blocks are tied to laptop device screen regardless of aspect ratio',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Test with 16:9 first
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 700,
                height: 500,
                child: Interactive3dDevicePreview(
                  deviceType: PreviewDeviceType.laptop,
                  aspectRatio: VideoAspectRatio.ratio16x9,
                  previewPlatformBlocks: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // YouTube Laptop overlay is present
      expect(
        find.text('ClipIt Masterclass • Cinematic 4K 60FPS Video Edit'),
        findsOneWidget,
      );
      expect(find.text('Subscribe'), findsOneWidget);

      // Re-pump with 9:16 ratio on the same laptop frame
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 700,
                height: 500,
                child: Interactive3dDevicePreview(
                  deviceType: PreviewDeviceType.laptop,
                  aspectRatio: VideoAspectRatio.ratio9x16,
                  previewPlatformBlocks: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The platform block remains rendered on the laptop frame
      expect(
        find.text('ClipIt Masterclass • Cinematic 4K 60FPS Video Edit'),
        findsOneWidget,
      );
      expect(find.text('Subscribe'), findsOneWidget);

      // Re-pump with 1:1 square ratio on the laptop frame
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 700,
                height: 500,
                child: Interactive3dDevicePreview(
                  deviceType: PreviewDeviceType.laptop,
                  aspectRatio: VideoAspectRatio.ratio1x1,
                  previewPlatformBlocks: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('ClipIt Masterclass • Cinematic 4K 60FPS Video Edit'),
        findsOneWidget,
      );
      expect(find.text('Subscribe'), findsOneWidget);
    });

    testWidgets('Phone platform blocks are tied to phone screen regardless of aspect ratio',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Test with 9:16 first
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 500,
                height: 700,
                child: Interactive3dDevicePreview(
                  deviceType: PreviewDeviceType.iPhone,
                  aspectRatio: VideoAspectRatio.ratio9x16,
                  previewPlatformBlocks: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile Shorts overlay is present
      expect(find.text('@ClipItOfficial'), findsOneWidget);
      expect(find.text('142K'), findsOneWidget);

      // Re-pump with 16:9 horizontal ratio on the phone frame
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 500,
                height: 700,
                child: Interactive3dDevicePreview(
                  deviceType: PreviewDeviceType.iPhone,
                  aspectRatio: VideoAspectRatio.ratio16x9,
                  previewPlatformBlocks: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile Shorts overlay remains anchored to phone screen
      expect(find.text('@ClipItOfficial'), findsOneWidget);
      expect(find.text('142K'), findsOneWidget);
    });
  });
}
