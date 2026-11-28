import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

/// Where the sweep below reads, and with `--dart-define=RECORD_PLACEMENT=true`
/// writes, what the tooltips looked like before the placement changes.
///
/// Record it by running this same file, with that define, on the commit
/// before them (77d1384). To keep it small it holds which cases fit there and
/// a digest of their rects per [_chunk] cases, not the rects themselves: to
/// see what moved, record on both commits and compare, or print the cases of
/// the chunk the failure names.
const _baselinePath = 'test/fixtures/tooltip_placement_baseline.json';
const _record = bool.fromEnvironment('RECORD_PLACEMENT');
const _chunk = 64;

/// The phone-sized screen most of the sweep runs on, in logical pixels.
const _screen = Size(412, 915);

const _shortText = 'Tap here';
const _longText =
    'A much longer description that is far too wide for one line, so the tooltip is capped at the screen width';

/// The device a sweep case runs on.
typedef _Env = ({String name, Size screen, double textScale, double keyboard});

const _Env _phone = (name: 'phone', screen: _screen, textScale: 1, keyboard: 0);
const List<_Env> _otherEnvs = [
  (name: 'small', screen: Size(320, 480), textScale: 1, keyboard: 0),
  (name: 'text2x', screen: _screen, textScale: 2, keyboard: 0),
  (name: 'keyboard', screen: _screen, textScale: 1, keyboard: 300),
];

/// The part of [env]'s screen the keyboard leaves visible.
Rect _visible(_Env env) => Offset.zero & Size(env.screen.width, env.screen.height - env.keyboard);

/// One configuration of the placement sweep.
class _Case {
  const _Case({
    required this.env,
    required this.custom,
    required this.position,
    required this.alignment,
    required this.target,
    required this.rtl,
    this.longText = false,
    this.ellipsis = false,
    this.showArrow = true,
    this.actions,
    this.declared,
    this.actual,
  });

  final _Env env;

  /// `Showcase.withWidget` rather than the default tooltip.
  final bool custom;
  final TooltipPosition? position;
  final Alignment alignment;
  final Size target;
  final bool rtl;
  final bool longText;

  /// A description style that ellipsizes, which keeps it to one line.
  final bool ellipsis;
  final bool showArrow;

  /// Built-in actions inside or outside the default tooltip, or none.
  final TooltipActionPosition? actions;

  /// `Showcase.withWidget`'s `width`/`height`, and the container's real size.
  final Size? declared;
  final Size? actual;

  String get id => [
    env.name,
    custom ? 'custom' : 'default',
    position?.name ?? 'auto',
    '${alignment.x},${alignment.y}',
    '${target.width}x${target.height}',
    rtl ? 'rtl' : 'ltr',
    if (!custom) longText ? 'long' : 'short',
    if (!custom && ellipsis) 'ellipsis',
    if (!custom) showArrow ? 'arrow' : 'noarrow',
    if (!custom) actions?.name ?? 'noactions',
    if (custom) 'declared${declared!.width}x${declared!.height}',
    if (custom) 'actual${actual!.width}x${actual!.height}',
  ].join('|');
}

List<_Case> _sweep() {
  final alignments = [
    for (final y in [-1.0, -0.75, 0.0, 0.75, 1.0])
      for (final x in [-1.0, 0.0, 1.0]) Alignment(x, y),
  ];
  const containers = [
    (Size(140, 80), Size(140, 80)),
    (Size(300, 300), Size(300, 300)),
    // Declared sizes are trusted even when they are wrong, either way.
    (Size(140, 80), Size(200, 50)),
    (Size(200, 300), Size(200, 100)),
  ];
  final cases = <_Case>[];
  void add({
    required _Env env,
    required List<Size> targets,
    required List<bool> directions,
    required List<(bool, bool, bool)> texts,
    required List<(Size, Size)> customs,
  }) {
    for (final position in <TooltipPosition?>[null, ...TooltipPosition.values]) {
      for (final alignment in alignments) {
        for (final target in targets) {
          for (final rtl in directions) {
            for (final (longText, ellipsis, showArrow) in texts) {
              for (final actions in <TooltipActionPosition?>[null, ...TooltipActionPosition.values]) {
                cases.add(
                  _Case(
                    env: env,
                    custom: false,
                    position: position,
                    alignment: alignment,
                    target: target,
                    rtl: rtl,
                    longText: longText,
                    ellipsis: ellipsis,
                    showArrow: showArrow,
                    actions: actions,
                  ),
                );
              }
            }
            for (final (declared, actual) in customs) {
              cases.add(
                _Case(
                  env: env,
                  custom: true,
                  position: position,
                  alignment: alignment,
                  target: target,
                  rtl: rtl,
                  declared: declared,
                  actual: actual,
                ),
              );
            }
          }
        }
      }
    }
  }

  // The phone, in both directions: (long text, ellipsis, arrow).
  add(
    env: _phone,
    targets: const [Size(40, 40), Size(160, 56), Size(100, 600)],
    directions: const [false, true],
    texts: const [(false, false, true), (true, false, true), (false, false, false), (true, true, true)],
    customs: containers,
  );
  // Smaller, larger-text and keyboard-shortened screens, left to right.
  for (final env in _otherEnvs) {
    final visibleHeight = env.screen.height - env.keyboard;
    add(
      env: env,
      targets: [const Size(40, 40), Size(100, (visibleHeight * 0.65).roundToDouble())],
      directions: const [false],
      texts: const [(false, false, true), (true, false, true), (true, true, true)],
      customs: containers,
    );
  }
  return cases;
}

const _containerKey = ValueKey('container');

/// Shows [c] and returns the tooltip's rect (the default tooltip's box, or the
/// custom container), the target's rect, and the "Next" button's rect when
/// the step has actions.
Future<({Rect tooltip, Rect target, Rect? next})> _probe(WidgetTester tester, _Case c) async {
  tester.view.physicalSize = c.env.screen * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.viewInsets = FakeViewPadding(bottom: c.env.keyboard * 3);
  final key = GlobalKey();
  late BuildContext pageContext;
  final actions = c.actions == null ? null : const ShowCaseDefaultActions();
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(c.env.textScale)),
        child: Directionality(textDirection: c.rtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
      ),
      home: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        builder: Builder(
          builder: (context) {
            pageContext = context;
            final target = SizedBox.fromSize(size: c.target, child: const Text('target'));
            return Scaffold(
              body: Align(
                alignment: c.alignment,
                child: c.custom
                    ? Showcase.withWidget(
                        key: key,
                        width: c.declared!.width,
                        height: c.declared!.height,
                        tooltipPosition: c.position,
                        container: SizedBox.fromSize(key: _containerKey, size: c.actual),
                        child: target,
                      )
                    : Showcase(
                        key: key,
                        title: 'Title',
                        description: c.longText ? _longText : _shortText,
                        descTextStyle: c.ellipsis ? const TextStyle(overflow: TextOverflow.ellipsis) : null,
                        showArrow: c.showArrow,
                        tooltipPosition: c.position,
                        actions: actions,
                        actionsPosition: c.actions,
                        child: target,
                      ),
              ),
            );
          },
        ),
      ),
    ),
  );
  ShowCaseWidget.of(pageContext).startShowCase([key]);
  await tester.pump();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final tooltip = c.custom
      ? tester.getRect(find.byKey(_containerKey))
      : tester.getRect(find.ancestor(of: find.text('Title'), matching: find.byType(ClipRRect)).first);
  final next = c.actions == null ? null : tester.getRect(find.text('Next'));
  return (tooltip: tooltip, target: tester.getRect(find.text('target')), next: next);
}

/// Whether [tooltip] is wholly on the part of the screen the keyboard leaves
/// visible, and clear of [target].
bool _fits(_Env env, Rect tooltip, Rect target) {
  const eps = 0.01;
  final visible = _visible(env);
  final onScreen =
      tooltip.left >= visible.left - eps &&
      tooltip.top >= visible.top - eps &&
      tooltip.right <= visible.right + eps &&
      tooltip.bottom <= visible.bottom + eps;
  final overlap = tooltip.intersect(target);
  final clear = overlap.width <= eps || overlap.height <= eps;
  return onScreen && clear;
}

/// The rects compared: the tooltip's, then the "Next" button's when the step
/// has actions, exactly as laid out.
String _rects(({Rect tooltip, Rect target, Rect? next}) r) =>
    [r.tooltip, ?r.next].map((rect) => '${rect.left},${rect.top},${rect.right},${rect.bottom}').join(';');

/// A 32-bit FNV-1a digest of [text], in hex.
String _digest(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

void main() {
  testWidgets('a tooltip that fits keeps the rect it had before the placement changes', (tester) async {
    addTearDown(tester.view.reset);
    final cases = _sweep();
    final chunks = (cases.length / _chunk).ceil();

    if (_record) {
      final fits = List.filled(cases.length, false);
      final digests = <String>[];
      for (var chunk = 0; chunk < chunks; chunk++) {
        final rects = StringBuffer();
        for (var i = chunk * _chunk; i < cases.length && i < (chunk + 1) * _chunk; i++) {
          final r = await _probe(tester, cases[i]);
          fits[i] = _fits(cases[i].env, r.tooltip, r.target);
          if (fits[i]) rects.writeln('${cases[i].id}=${_rects(r)}');
        }
        digests.add(_digest(rects.toString()));
      }
      File(_baselinePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '${jsonEncode({'cases': cases.length, 'fits': base64Encode(_pack(fits)), 'digests': digests})}\n',
        );
      return;
    }

    final stored = jsonDecode(File(_baselinePath).readAsStringSync()) as Map<String, Object?>;
    expect(stored['cases'], cases.length, reason: 'the sweep matches the recording');
    final fits = _unpack(base64Decode(stored['fits']! as String), cases.length);
    final digests = (stored['digests']! as List).cast<String>();
    var compared = 0;
    final moved = <String>[];
    for (var chunk = 0; chunk < chunks; chunk++) {
      final rects = StringBuffer();
      for (var i = chunk * _chunk; i < cases.length && i < (chunk + 1) * _chunk; i++) {
        if (!fits[i]) continue;
        compared++;
        rects.writeln('${cases[i].id}=${_rects(await _probe(tester, cases[i]))}');
      }
      if (_digest(rects.toString()) != digests[chunk]) moved.add('chunk $chunk, now:\n$rects');
    }
    expect(moved, isEmpty);
    // Most of the sweep fits; the rest is what the placement changes are for.
    expect(compared, greaterThan(cases.length ~/ 2));
    // Every kind of case is compared somewhere.
    for (final env in [_phone, ..._otherEnvs]) {
      expect(
        [
          for (var i = 0; i < cases.length; i++)
            if (fits[i] && cases[i].env == env) i,
        ],
        isNotEmpty,
        reason: env.name,
      );
    }
  });
}

/// [bits] packed eight to a byte.
List<int> _pack(List<bool> bits) => [
  for (var i = 0; i < bits.length; i += 8)
    [
      for (var b = 0; b < 8 && i + b < bits.length; b++)
        if (bits[i + b]) 1 << b,
    ].fold(0, (a, b) => a | b),
];

/// The first [length] bits packed by [_pack].
List<bool> _unpack(List<int> bytes, int length) => [
  for (var i = 0; i < length; i++) bytes[i ~/ 8] & (1 << (i % 8)) != 0,
];
