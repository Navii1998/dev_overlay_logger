import 'package:dev_overlay_logger/src/core/dev_logger.dart';
import 'package:dev_overlay_logger/src/core/network_entry.dart';
import 'package:dev_overlay_logger/src/network/curl_builder.dart';
import 'package:dev_overlay_logger/src/network/redactor.dart';
import 'package:dev_overlay_logger/src/ui/theme/logger_theme.dart';
import 'package:dev_overlay_logger/src/ui/widgets/json_viewer.dart';
import 'package:dev_overlay_logger/src/utils/size_format.dart';
import 'package:dev_overlay_logger/src/utils/time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Network call inspector. Covers the panel body. The slab stays visible.
class NetworkDetailSheet extends StatefulWidget {
  /// Creates a sheet for [entry].
  const NetworkDetailSheet({
    required this.entry,
    required this.onClose,
    required this.onToast,
    super.key,
  });

  /// The call being inspected.
  final NetworkEntry entry;

  /// Closes the sheet.
  final VoidCallback onClose;

  /// Shows a short confirmation.
  final ValueChanged<String> onToast;

  @override
  State<NetworkDetailSheet> createState() => _NetworkDetailSheetState();
}

enum _DetailTab { overview, request, response, headers }

class _NetworkDetailSheetState extends State<NetworkDetailSheet> {
  _DetailTab _tab = _DetailTab.overview;

  @override
  Widget build(BuildContext context) {
    final theme = LoggerThemeScope.of(context);
    final entry = widget.entry;
    final statusColor = _statusColor(theme, entry);
    return ColoredBox(
      color: theme.detailBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                _SmallButton(icon: Icons.arrow_back_rounded, onTap: widget.onClose),
                const SizedBox(width: 8),
                _Method(method: entry.method),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.pathAndQuery,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.mono.copyWith(fontSize: 12),
                  ),
                ),
                Text(
                  entry.status == null ? '…' : '${entry.status}',
                  style: theme.mono.copyWith(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                for (final tab in _DetailTab.values)
                  _DetailChip(
                    label: switch (tab) {
                      _DetailTab.overview => 'Overview',
                      _DetailTab.request => 'Request',
                      _DetailTab.response => 'Response',
                      _DetailTab.headers => 'Headers',
                    },
                    selected: _tab == tab,
                    onTap: () => setState(() => _tab = tab),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: _body(theme, entry),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: _SmallButton(
                      icon: Icons.terminal_rounded,
                      label: 'cURL',
                      onTap: () => _copyCurl(entry),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _SmallButton(
                      icon: Icons.copy_rounded,
                      label: 'Response',
                      onTap: () => _copyResponse(entry),
                    ),
                  ),
                  if (entry.retry != null) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: _SmallButton(
                        icon: Icons.refresh_rounded,
                        label: 'Retry',
                        onTap: () => _retry(entry),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(DevLoggerTheme theme, NetworkEntry entry) {
    final names = DevLogger.config.redactHeaders;
    return switch (_tab) {
      _DetailTab.overview => _Overview(entry: entry, theme: theme),
      _DetailTab.request => JsonViewer(
          value: entry.requestBody,
          maxChars: DevLogger.config.maxBodyChars,
        ),
      _DetailTab.response => JsonViewer(
          value: entry.responseBody ?? entry.errorMessage,
          maxChars: DevLogger.config.maxBodyChars,
          emptyText: entry.state == NetworkState.pending ? 'Waiting for response' : '(no body)',
        ),
      _DetailTab.headers => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REQUEST', style: theme.mono.copyWith(color: theme.textMuted, fontSize: 10)),
            const SizedBox(height: 6),
            JsonViewer(
              value: Redactor.forDisplay(entry.requestHeaders, names),
              maxChars: DevLogger.config.maxBodyChars,
              emptyText: '(no headers)',
            ),
            const SizedBox(height: 12),
            Text('RESPONSE', style: theme.mono.copyWith(color: theme.textMuted, fontSize: 10)),
            const SizedBox(height: 6),
            JsonViewer(
              value: Redactor.forDisplay(entry.responseHeaders, names),
              maxChars: DevLogger.config.maxBodyChars,
              emptyText: '(no headers)',
            ),
          ],
        ),
    };
  }

  void _copyCurl(NetworkEntry entry) {
    final curl = CurlBuilder.build(
      method: entry.method,
      uri: entry.uri,
      headers: entry.requestHeaders,
      body: entry.requestBody,
      redactHeaders: DevLogger.config.redactHeaders,
    );
    Clipboard.setData(ClipboardData(text: curl));
    widget.onToast('cURL copied');
  }

  void _copyResponse(NetworkEntry entry) {
    Clipboard.setData(ClipboardData(text: '${entry.responseBody ?? entry.errorMessage ?? ''}'));
    widget.onToast('Response copied');
  }

  Future<void> _retry(NetworkEntry entry) async {
    final retry = entry.retry;
    if (retry == null) return;
    widget.onClose();
    widget.onToast('Request replayed');
    try {
      await retry();
    } on Object catch (error, stack) {
      DevLogger.e('Retry failed', tag: entry.tag, error: error, stackTrace: stack);
    }
  }

  Color _statusColor(DevLoggerTheme theme, NetworkEntry entry) {
    final status = entry.status;
    if (status == null) return theme.pending;
    if (status < 300) return theme.ok;
    if (status < 400) return theme.warn;
    return theme.bad;
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.entry, required this.theme});

  final NetworkEntry entry;
  final DevLoggerTheme theme;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('URL', entry.uri.toString()),
      ('Method', entry.method),
      ('Status', entry.status?.toString() ?? 'pending'),
      ('Duration', entry.duration == null ? '…' : formatDuration(entry.duration)),
      ('Size', formatBytes(entry.responseSizeBytes, fractionDigits: 2)),
      ('Started', formatClock(entry.startTime)),
      if (entry.errorMessage != null) ('Error', entry.errorMessage!),
    ];
    return Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(label, style: theme.mono.copyWith(color: theme.textMuted)),
                ),
                Expanded(child: SelectableText(value, style: theme.mono)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0x403A7BFF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(method, style: const TextStyle(color: Color(0xFF9CC0FF), fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0x333A7BFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF9CC0FF) : const Color(0xFF7C8699),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.onTap, this.label});

  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: const Color(0xFFCFD5E1)),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: const TextStyle(color: Color(0xFFCFD5E1), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      );
}
