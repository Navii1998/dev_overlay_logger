# Changelog

## 0.2.0

- Hosts can hide the floating pill with `showMinimizedButton: false`. `DevLogger.show()` still opens the panel. `DevLogger.panelOpen` is true while that panel is locked or interactive.
- `DevLogger.setCaptureEnabled(false)` stops capture without discarding the store. `DevLogger.setCaptureEnabled(true)` records into the same store. `DevLogger.captureEnabled` reports the switch.

## 0.1.0

- Overlay with locked, interactive and minimised modes.
- Log ring buffer, network ring buffer, Dio interceptor, cURL copy and header masking.
- Pass-through taps while locked. Hold to unlock, drag to resize, dock top or bottom.
