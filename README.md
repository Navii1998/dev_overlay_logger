# dev_overlay_logger

In-app developer console. It draws over the app and shows log lines and API calls. It opens as a floating button. Tap the button for the panel. Locked mode lets taps pass through, so the app stays usable. Hold the slab for half a second to filter, search and copy.

No state-management dependency. The only third-party package is `dio`, and only `lib/src/network/dio_interceptor.dart` imports it.

## Use

```dart
void main() {
  DevLogger.init(const DevLoggerConfig()); // off in release builds
  runApp(const MyApp());
}

MaterialApp(
  builder: (context, child) => DevLoggerOverlay(child: child!),
);

dio.interceptors.add(DevLoggerDioInterceptor(client: dio));

DevLogger.d('Fetched 24 products', tag: 'Repo');
DevLogger.e('Payment failed', tag: 'Checkout', error: e, stackTrace: st);
```

`client:` is what makes the Retry button work. Leave it unset and the button stays hidden.

Other HTTP stacks call `NetworkLogger.start` / `complete` / `fail`, or `NetworkLogger.record` when the call is already finished.

Set `DevLoggerConfig.capturePrint` and wrap startup in `DevLogger.runZoned` to mirror `print`.

## Gesture

- Hold the slab 500 ms to unlock. A blue bar fills the slab while you hold.
- Drag the slab to resize. Releasing below 18% of the screen minimises it.
- Double-tap the slab, or tap ▾, to minimise.
- ⤒ / ⤓ docks the panel to the top or the bottom.
- The floating button snaps to the nearest side. Tap it to restore the last height.
- 🔒 returns to locked mode, where taps pass through.

## Install

```yaml
dependencies:
  dev_overlay_logger: ^0.1.0
```

The logger starts only in debug and profile builds by default. Release builds stay silent unless you set `enabled: true` yourself.
