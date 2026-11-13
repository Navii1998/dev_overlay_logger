import 'dart:async';

import 'package:dev_overlay_logger/dev_overlay_logger.dart';
import 'package:flutter/material.dart';

void main() {
  DevLogger.init(
    const DevLoggerConfig(
      captureFlutterErrors: false,
      capturePlatformErrors: false,
    ),
  );
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => DevLoggerOverlay(child: child!),
        home: const DemoHome(),
      );
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  var _tab = 'Home';
  Timer? _timer;
  var _tick = 0;

  static const _products = ['Product 1', 'Product 2', 'Product 3', 'Product 4'];

  @override
  void initState() {
    super.initState();
    DevLogger.i('Demo app started', tag: 'App');
    NetworkLogger.record(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/v1/products?page=1'),
      status: 200,
      elapsed: const Duration(milliseconds: 610),
      responseBody: const {
        'items': ['Product 1', 'Product 2'],
      },
    );
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _tick++;
      if (_tick.isEven) {
        DevLogger.d('ping → pong 38ms', tag: 'Socket');
      } else {
        NetworkLogger.record(
          method: 'GET',
          uri: Uri.parse('https://api.example.com/v1/notifications/unread'),
          status: 200,
          elapsed: const Duration(milliseconds: 140),
          responseBody: const {'unread': 0},
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _open(String name) {
    DevLogger.d('push /product/detail {name: "$name"}', tag: 'Router');
    NetworkLogger.record(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/v1/products/${Uri.encodeComponent(name)}'),
      status: 200,
      elapsed: const Duration(milliseconds: 180),
      responseBody: {'title': name, 'variants': 2},
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              color: const Color(0xFF122A6B),
              padding: EdgeInsets.fromLTRB(22, MediaQuery.paddingOf(context).top + 14, 22, 18),
              width: double.infinity,
              child: const Text(
                'Demo Shop',
                style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Search for products...', style: TextStyle(color: Color(0xFF6B7280))),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
                children: [
                  for (final name in _products)
                    GestureDetector(
                      onTap: () => _open(name),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D3FB0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.paddingOf(context).bottom + 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(38),
                  boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 6))],
                ),
                child: SizedBox(
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final tab in ['Home', 'Search', 'Live', 'Videos', 'Cart', 'Profile'])
                        GestureDetector(
                          onTap: () {
                            setState(() => _tab = tab);
                            DevLogger.i('tab → $tab', tag: 'Nav');
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _tab == tab ? const Color(0xFFE7E9EE) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(tab.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
