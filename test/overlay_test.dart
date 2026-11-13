import 'package:dev_overlay_logger/dev_overlay_logger.dart';
import 'package:dev_overlay_logger/src/ui/dev_overlay_logger_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(DevLogger.reset);

  const enabled = DevLoggerConfig(
    enabled: true,
    captureFlutterErrors: false,
    capturePlatformErrors: false,
    startMinimized: false,
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    required Widget home,
    DevLoggerConfig config = enabled,
  }) async {
    DevLogger.init(config);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DevLoggerOverlay(child: child!),
        home: home,
      ),
    );
    await tester.pump();
  }

  testWidgets('locked mode lets a tap through the panel', (tester) async {
    var taps = 0;
    await pumpApp(
      tester,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: GestureDetector(
              onTap: () => taps++,
              child: const SizedBox(
                key: Key('under'),
                width: 120,
                height: 48,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('under')));
    expect(taps, 1);
  });

  testWidgets('holding the slab unlocks, and the lock button locks again', (tester) async {
    await pumpApp(tester, home: const Scaffold(body: SizedBox.expand()));

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(DevLoggerKeys.slab)));
    await tester.pump(const Duration(milliseconds: 520));
    await gesture.up();
    await tester.pump();

    expect(find.text('Logger interactive'), findsOneWidget);
    expect(find.byKey(DevLoggerKeys.lock), findsOneWidget);

    await tester.tap(find.byKey(DevLoggerKeys.lock));
    await tester.pump();
    expect(find.text('Hold or drag'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('dragging the slab below 18% minimises, and the button restores the height', (tester) async {
    await pumpApp(tester, home: const Scaffold(body: SizedBox.expand()));
    final before = tester.getSize(find.byKey(DevLoggerKeys.panel)).height;

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(DevLoggerKeys.slab)));
    await gesture.moveBy(const Offset(0, 400));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.byKey(DevLoggerKeys.fab), findsOneWidget);
    expect(find.byKey(DevLoggerKeys.panel), findsNothing);

    await tester.tap(find.byKey(DevLoggerKeys.fab));
    await tester.pump();
    expect(tester.getSize(find.byKey(DevLoggerKeys.panel)).height, before);
  });

  testWidgets('docking to the top anchors the panel there and inverts the drag', (tester) async {
    await pumpApp(tester, home: const Scaffold(body: SizedBox.expand()));
    await tester.tap(find.byKey(DevLoggerKeys.dock));
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(DevLoggerKeys.panel)).dy, 0);

    final before = tester.getSize(find.byKey(DevLoggerKeys.panel)).height;
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(DevLoggerKeys.slab)));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(tester.getSize(find.byKey(DevLoggerKeys.panel)).height, greaterThan(before));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('the logger opens minimised', (tester) async {
    await pumpApp(
      tester,
      config: const DevLoggerConfig(
        enabled: true,
        captureFlutterErrors: false,
        capturePlatformErrors: false,
      ),
      home: const Scaffold(body: SizedBox.expand()),
    );
    expect(find.byKey(DevLoggerKeys.fab), findsOneWidget);
    expect(find.byKey(DevLoggerKeys.panel), findsNothing);
  });

  testWidgets('a disabled logger renders only the child', (tester) async {
    await pumpApp(
      tester,
      config: const DevLoggerConfig(enabled: false),
      home: const Scaffold(body: Text('APP')),
    );
    expect(find.text('APP'), findsOneWidget);
    expect(find.byKey(DevLoggerKeys.slab), findsNothing);
  });
}
