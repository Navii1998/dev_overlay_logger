import 'package:dev_overlay_logger/src/network/curl_builder.dart';
import 'package:dev_overlay_logger/src/network/redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quotes the url, headers and body, and masks secrets', () {
    final curl = CurlBuilder.build(
      method: 'POST',
      uri: Uri.parse('https://api.example.com/v1/auth'),
      headers: const {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer abcdefghijkl',
      },
      body: const {'token': "a'b"},
      redactHeaders: const ['authorization'],
    );

    expect(curl, "curl -X POST 'https://api.example.com/v1/auth' -H 'Content-Type: application/json' -H 'Authorization: <redacted>' --data-raw '{\"token\":\"a'\\''b\"}'");
  });

  test('preview keeps the first 4 and last 3 characters', () {
    expect(Redactor.preview('Bearer super-secret-token'), 'Bear…ken');
    expect(Redactor.preview('short'), '••••');
  });
}
