/// Severity of a developer log line.
enum LogLevel {
  /// Fine-grained tracing.
  verbose('V', 'VERBOSE'),

  /// Diagnostic detail.
  debug('D', 'DEBUG'),

  /// Normal operation.
  info('I', 'INFO'),

  /// Recoverable problem.
  warning('W', 'WARN'),

  /// Failure.
  error('E', 'ERROR');

  const LogLevel(this.short, this.chipLabel);

  /// One-letter badge label.
  final String short;

  /// Filter-chip label.
  final String chipLabel;
}
