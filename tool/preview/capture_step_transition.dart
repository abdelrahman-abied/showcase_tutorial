// Frame capture for `preview/step_transition.gif` — maintainer tooling, not a test.
//
// Renders the same four-step tour twice, once with `enableStepTransition: false`
// and once with `true`, and writes one PNG per frame to
// `build/preview_frames/<variant>/`. `tool/preview/make_gif.sh` stitches the two
// sequences side by side.
//
// It runs under `flutter test` purely to borrow the fake clock: `tester.pump`
// advances time by an exact amount, so frame N of both variants lands on the
// same millisecond and the two halves of the GIF stay in lockstep. Screen
// recording can't promise that (and would need macOS Screen Recording granted).
//
//   flutter test tool/preview/capture_step_transition.dart
//
// Lives outside `test/` so a plain `flutter test` doesn't run it.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

/// Logical size of the captured frame — a phone-ish portrait canvas.
const _size = Size(360, 640);

/// Captured at 2x, so the GIF still looks sharp after ffmpeg downscales it.
const _dpr = 2.0;

/// 50ms per frame = 20fps, and exactly 5 centiseconds — GIF frame delays are
/// stored in centiseconds, so this rate survives the encode without rounding.
const _frameStep = Duration(milliseconds: 50);

/// How long each step stays put before the tour advances.
const _holdPerStep = Duration(milliseconds: 1150);

/// The glide itself. Slower than the 300ms default so the travel reads clearly
/// at 20fps (a 300ms glide is only 6 frames).
const _glideDuration = Duration(milliseconds: 500);

const _brand = Color(0xff0077b6);
const _ink = Color(0xff123044);

void main() {
  setUpAll(_loadFonts);

  testWidgets('capture: instant (default)', (tester) async {
    await _capture(tester, glide: false);
  });

  testWidgets('capture: glide (enableStepTransition)', (tester) async {
    await _capture(tester, glide: true);
  });
}

Future<void> _capture(WidgetTester tester, {required bool glide}) async {
  final variant = glide ? 'glide' : 'instant';
  final outDir = Directory('build/preview_frames/$variant');
  if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  outDir.createSync(recursive: true);

  tester.view
    ..devicePixelRatio = _dpr
    ..physicalSize = _size * _dpr;
  addTearDown(tester.view.reset);

  final boundaryKey = GlobalKey();
  final scene = _SceneKeys();
  late ShowCaseWidgetState show;

  await tester.pumpWidget(
    RepaintBoundary(
      key: boundaryKey,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned.fill(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  useMaterial3: true,
                  fontFamily: 'Roboto',
                  colorScheme: ColorScheme.fromSeed(seedColor: _brand),
                ),
                home: ShowCaseWidget(
                  enableStepTransition: glide,
                  stepTransitionDuration: _glideDuration,
                  stepTransitionCurve: Curves.easeInOutCubic,
                  enableAutoScroll: false,
                  showProgress: true,
                  // Bumped from the defaults so the tooltip stays legible once
                  // the GIF is downscaled for the README.
                  style: const ShowcaseStyle(
                    titleTextStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                    descTextStyle: TextStyle(fontFamily: 'Roboto', fontSize: 13, height: 1.3, color: Color(0xff44606f)),
                  ),
                  builder: Builder(
                    builder: (ctx) {
                      show = ShowCaseWidget.of(ctx);
                      return _Scene(keys: scene);
                    },
                  ),
                ),
              ),
            ),
            // Sits above the app, so the scrim never dims the caption.
            Positioned(top: 0, left: 0, right: 0, child: _Caption(glide: glide)),
          ],
        ),
      ),
    ),
  );

  var frame = 0;
  Future<void> hold(Duration duration) async {
    for (var elapsed = Duration.zero; elapsed < duration; elapsed += _frameStep) {
      await tester.pump(_frameStep);
      await _writeFrame(tester, boundaryKey, outDir, frame++);
    }
  }

  // A beat on the bare screen, so the first cut-out has something to open onto.
  await hold(const Duration(milliseconds: 400));

  show.startShowCase(scene.order);
  await hold(_holdPerStep);

  for (var i = 1; i < scene.order.length; i++) {
    show.next();
    await hold(_holdPerStep);
  }

  // Let the last tooltip breathe before the GIF loops.
  await hold(const Duration(milliseconds: 500));

  show.dismiss();
  await tester.pumpAndSettle();

  debugPrint('captured $frame frames -> ${outDir.path}');
}

Future<void> _writeFrame(WidgetTester tester, GlobalKey boundaryKey, Directory outDir, int frame) async {
  await tester.runAsync(() async {
    final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _dpr);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final name = frame.toString().padLeft(4, '0');
    await File('${outDir.path}/frame_$name.png').writeAsBytes(png!.buffer.asUint8List());
  });
}

/// The four targets, in tour order. Spread to the corners so the glide has a
/// long, obvious distance to travel between every pair.
class _SceneKeys {
  final avatar = GlobalKey();
  final notifications = GlobalKey();
  final card = GlobalKey();
  final fab = GlobalKey();

  List<GlobalKey> get order => [avatar, notifications, card, fab];
}

class _Caption extends StatelessWidget {
  const _Caption({required this.glide});

  final bool glide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      color: _ink,
      child: Text(
        glide ? 'enableStepTransition: true' : 'enableStepTransition: false',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: glide ? const Color(0xff7fe0a8) : const Color(0xffbcc9d2),
        ),
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({required this.keys});

  final _SceneKeys keys;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fa),
      floatingActionButton: Showcase(
        key: keys.fab,
        title: 'Compose',
        description: 'The cut-out travelled all the way down here.',
        targetShapeBorder: const CircleBorder(),
        targetPadding: const EdgeInsets.all(6),
        disableMovingAnimation: true,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          // The drop shadow reads as a dark box once the scrim dims it.
          elevation: 0,
          child: const Icon(Icons.edit_outlined),
        ),
      ),
      body: Padding(
        // Clears the caption band painted above the app.
        padding: const EdgeInsets.only(top: 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Showcase(
                    key: keys.avatar,
                    title: 'Your profile',
                    description: 'Step one starts up here, top-left.',
                    targetShapeBorder: const CircleBorder(),
                    targetPadding: const EdgeInsets.all(4),
                    disableMovingAnimation: true,
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: _brand,
                      child: Text(
                        'AO',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good morning', style: TextStyle(fontSize: 13, color: Color(0xff6b7f8c))),
                        Text(
                          'Abdulrahman',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _ink),
                        ),
                      ],
                    ),
                  ),
                  Showcase(
                    key: keys.notifications,
                    title: 'Alerts',
                    description: 'Then jumps to the far corner.',
                    targetShapeBorder: const CircleBorder(),
                    targetPadding: const EdgeInsets.all(4),
                    disableMovingAnimation: true,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded, color: _ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Showcase(
                key: keys.card,
                title: 'Balance',
                description: 'And glides back into the middle.',
                targetShapeBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                targetPadding: const EdgeInsets.all(6),
                disableMovingAnimation: true,
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_brand, Color(0xff00b4d8)],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        r'$12,480.00',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const _Row(icon: Icons.local_cafe_outlined, label: 'Blue Bottle', amount: r'-$6.40'),
            const _Row(icon: Icons.directions_bus_outlined, label: 'Transit', amount: r'-$2.75'),
            const _Row(icon: Icons.shopping_bag_outlined, label: 'Groceries', amount: r'-$54.10'),
            const _Row(icon: Icons.bolt_outlined, label: 'Utilities', amount: r'-$88.00'),
            const _Row(icon: Icons.subscriptions_outlined, label: 'Subscriptions', amount: r'-$14.99'),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.amount});

  final IconData icon;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(color: const Color(0xffe4edf3), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: _ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _ink),
            ),
          ),
          Text(amount, style: const TextStyle(fontSize: 14, color: Color(0xff6b7f8c))),
        ],
      ),
    );
  }
}

/// `flutter test` ships a font that renders every glyph as a box, so the real
/// Roboto and MaterialIcons files are loaded out of the SDK's font cache.
Future<void> _loadFonts() async {
  final fontsDir = Directory('${_flutterRoot()}/bin/cache/artifacts/material_fonts');
  if (!fontsDir.existsSync()) {
    throw StateError('Material fonts not found at ${fontsDir.path} — run `flutter precache`.');
  }

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(File('${fontsDir.path}/$file').readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  }

  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// FLUTTER_ROOT isn't guaranteed in the test environment, so fall back to the
/// resolved location of the `flutter` package in this project's package config.
String _flutterRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) {
    throw StateError('Run `flutter pub get` first — .dart_tool/package_config.json is missing.');
  }
  final packages = (jsonDecode(config.readAsStringSync()) as Map<String, dynamic>)['packages'] as List;
  final flutter = packages.firstWhere((p) => p['name'] == 'flutter') as Map<String, dynamic>;
  // rootUri points at <flutter_root>/packages/flutter
  return File.fromUri(Uri.parse(flutter['rootUri'] as String)).parent.parent.path;
}
