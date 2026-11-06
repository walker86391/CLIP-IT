// Compile-check for the code examples in the flutter-ui-reference skill.
//
// This file exists so the snippets in .agents/skills/flutter-ui-reference/SKILL.md
// are verified to actually compile against THIS project's Flutter version,
// rather than being documentation that has silently drifted out of date.
//
// If you update the skill's examples, update this file to match.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs [build] inside a real MaterialApp at desktop size and pumps a few
/// frames, so any build-time error or layout overflow fails the test.
Future<void> pumpExample(
  WidgetTester tester,
  Widget Function() build, {
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F6BED),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(body: build()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  // ── Layout ───────────────────────────────────────────────────────────────

  testWidgets('skill §2: Row/Column flex with Expanded and flex', (tester) async {
    await pumpExample(tester, () {
      return Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const <Widget>[
              Expanded(child: Text('one')),
              Expanded(flex: 2, child: Text('two')),
              Expanded(child: Text('three')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Icon(Icons.star, color: Colors.green),
              Text('170 Reviews'),
            ],
          ),
        ],
      );
    });
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('skill §2: Stack + Positioned zone and Positioned.fill', (tester) async {
    await pumpExample(tester, () {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const ColoredBox(color: Color(0xFF223344)),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: constraints.maxWidth * 0.55,
                child: const ColoredBox(color: Color(0x664F6BED)),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('panel ${(1280 * 0.55).round()}px zone'),
                ),
              ),
            ],
          );
        },
      );
    });
    expect(find.textContaining('panel'), findsOneWidget);
  });

  testWidgets('skill §2: ConstrainedBox + scroll never overflows', (tester) async {
    // Small window on purpose: proves the constrained/scrolled pattern holds
    // at ClipIt's 960x600 minimum.
    await pumpExample(
      tester,
      () {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(
                  40,
                  (int i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('row $i'),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      size: const Size(960, 600),
    );
    expect(find.text('row 0'), findsOneWidget);
  });

  testWidgets('skill §2: LayoutBuilder responsive breakpoints', (tester) async {
    await pumpExample(tester, () {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 1100;
          final bool isCompact = constraints.maxWidth < 760;
          final String label = isWide
              ? 'wide'
              : (isCompact ? 'compact' : 'medium');
          return Center(child: Text(label, style: Theme.of(context).textTheme.bodyMedium));
        },
      );
    });
    expect(find.text('wide'), findsOneWidget);
  });

  // ── Theming ──────────────────────────────────────────────────────────────

  testWidgets('skill §3: theme read, copyWith extension, independent instance',
      (tester) async {
    await pumpExample(tester, () {
      // A Builder gives us a BuildContext inside this closure, which is what
      // Theme.of(context) needs. (In a real widget this is just the build
      // method's own context.)
      return Builder(
        builder: (BuildContext context) {
          return Column(
            children: <Widget>[
              Text(
                'themed',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
                ),
                child: const Text('extended'),
              ),
              Theme(
                data: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
                ),
                child: const Text('independent'),
              ),
            ],
          );
        },
      );
    });
    expect(find.text('themed'), findsOneWidget);
    expect(find.text('extended'), findsOneWidget);
    expect(find.text('independent'), findsOneWidget);
  });

  testWidgets('skill §3: DefaultTextStyle.merge inherits down a subtree',
      (tester) async {
    await pumpExample(tester, () {
      return DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 18, height: 2),
        child: Column(
          children: const <Widget>[Text('inherited one'), Text('inherited two')],
        ),
      );
    });
    expect(find.text('inherited one'), findsOneWidget);
  });

  // ── Animation ────────────────────────────────────────────────────────────

  testWidgets('skill §4: implicit animations (opacity/container/size/switcher)',
      (tester) async {
    await pumpExample(tester, () {
      return Column(
        children: <Widget>[
          const AnimatedOpacity(
            opacity: 0.8,
            duration: Duration(milliseconds: 200),
            child: Text('faded'),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            decoration: BoxDecoration(
              color: const Color(0xFF4F6BED),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text('contained'),
            ),
          ),
          const AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: Text('sized'),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: const Text('switched', key: ValueKey<String>('a')),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 200),
            builder: (BuildContext context, double t, Widget? child) {
              return Opacity(opacity: t, child: child);
            },
            child: const Text('tweened'),
          ),
        ],
      );
    });
    expect(find.text('faded'), findsOneWidget);
    expect(find.text('tweened'), findsOneWidget);
  });

  testWidgets('skill §4: explicit AnimationController + CurvedAnimation',
      (tester) async {
    await pumpExample(tester, () {
      return const _ExplicitAnimationExample();
    });
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('fading in'), findsOneWidget);
  });

  // ── Focus & keyboard ─────────────────────────────────────────────────────

  testWidgets('skill §5: Focus onFocusChange toggles focusable state',
      (tester) async {
    await pumpExample(tester, () {
      return const _FocusableExample();
    });
    expect(find.text('Unfocused'), findsOneWidget);

    // Click it, then it should report focused. The example calls
    // requestFocus() from its tap handler, matching the documented pattern of
    // focusing a node when the user interacts with the widget.
    await tester.tap(find.byType(_FocusableExample));
    await tester.pump();
    expect(find.text('Focused'), findsOneWidget);
  });

  testWidgets('skill §5: FocusTraversalGroup keeps Tab inside the form',
      (tester) async {
    await pumpExample(tester, () {
      return FocusTraversalGroup(
        child: Column(
          children: const <Widget>[
            TextField(decoration: InputDecoration(labelText: 'first')),
            TextField(decoration: InputDecoration(labelText: 'second')),
          ],
        ),
      );
    });
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('skill §5: onKeyEvent handles Enter and Space', (tester) async {
    await pumpExample(tester, () {
      return const _KeyEventExample();
    });
    expect(find.text('not pressed'), findsOneWidget);

    await tester.tap(find.byType(_KeyEventExample));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('pressed'), findsOneWidget);
  });

  // ── Shortcuts ────────────────────────────────────────────────────────────

  testWidgets('skill §6: Shortcuts + Actions + SingleActivator', (tester) async {
    int saved = 0;

    await pumpExample(tester, () {
      return Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              const _SaveIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _SaveIntent: CallbackAction<_SaveIntent>(
              onInvoke: (_SaveIntent intent) {
                saved++;
                // CallbackAction.onInvoke returns Object? (the result is
                // passed to any .then() on the invoked action), so the
                // branch must return explicitly.
                return null;
              },
            ),
          },
          child: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: Actions.handler<_SaveIntent>(
                  context,
                  const _SaveIntent(),
                ),
                child: const Text('Save'),
              );
            },
          ),
        ),
      );
    });

    expect(find.text('Save'), findsOneWidget);
    // The shortcut must be bound and enabled.
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(saved, 1);
  });

  testWidgets('skill §6: CallbackShortcuts lightweight binding', (tester) async {
    await pumpExample(tester, () {
      return const _CallbackShortcutsExample();
    });

    expect(find.text('count: 0'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(find.text('count: 1'), findsOneWidget);
  });

  // ── Gestures ─────────────────────────────────────────────────────────────

  testWidgets('skill §7: GestureDetector tap family', (tester) async {
    int taps = 0;

    await pumpExample(tester, () {
      return GestureDetector(
        onTap: () {
          taps++;
        },
        // NOTE: registering onDoubleTap alongside onTap puts the tap into the
        // gesture arena against the double-tap recognizer, so onTap is NOT
        // called immediately — it waits out the double-tap timeout. This is a
        // real behaviour worth knowing, hence the extra pump below.
        onDoubleTap: () {},
        onLongPress: () {},
        child: const ColoredBox(
          color: Color(0xFF4F6BED),
          child: SizedBox(width: 200, height: 80, child: Center(child: Text('tap me'))),
        ),
      );
    });

    await tester.tap(find.text('tap me'));
    // Pump past the double-tap deadline so the single tap resolves.
    await tester.pump(const Duration(milliseconds: 400));
    expect(taps, 1);
  });

  testWidgets('skill §7: MouseRegion hover feedback', (tester) async {
    await pumpExample(tester, () {
      return const _HoverExample();
    });

    expect(find.text('idle'), findsOneWidget);

    // MouseRegion hover needs an actual mouse pointer move — a plain touch
    // gesture does not fire onEnter. Use createGesture with PointerDeviceKind
    // .mouse, which is exactly how desktop hover behaves.
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.byType(_HoverExample)));
    await tester.pumpAndSettle();
    expect(find.text('hovered'), findsOneWidget);

    // Move away from the region to trigger onExit.
    await gesture.moveTo(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('idle'), findsOneWidget);
  });

  // ── Scrolling & desktop widgets ──────────────────────────────────────────

  testWidgets('skill §8/§10: Scrollbar-wrapped lazy ListView with ListTile',
      (tester) async {
    await pumpExample(tester, () {
      return Scrollbar(
        child: ListView.builder(
          itemCount: 50,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              leading: const Icon(Icons.star),
              title: Text('item $index'),
              trailing: const Icon(Icons.chevron_right),
            );
          },
        ),
      );
    });
    expect(find.text('item 0'), findsOneWidget);
    expect(find.byType(Scrollbar), findsOneWidget);
  });

  testWidgets('skill §10: DataTable renders rows', (tester) async {
    await pumpExample(tester, () {
      return DataTable(
        columns: const <DataColumn>[
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Value')),
        ],
        rows: const <DataRow>[
          DataRow(cells: <DataCell>[DataCell(Text('alpha')), DataCell(Text('1'))]),
          DataRow(cells: <DataCell>[DataCell(Text('beta')), DataCell(Text('2'))]),
        ],
      );
    });
    expect(find.text('alpha'), findsOneWidget);
  });

  testWidgets('skill §10: SelectableText + ReorderableListView exist', (tester) async {
    await pumpExample(tester, () {
      return Column(
        children: <Widget>[
          const SelectableText('copy me'),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: 3,
              // onReorderItem is the current API (onReorder is deprecated as
              // of v3.41): it hands over the newIndex already adjusted for
              // the item removed from oldIndex.
              onReorderItem: (int oldIndex, int newIndex) {},
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  key: ValueKey<int>(index),
                  title: Text('row $index'),
                );
              },
            ),
          ),
        ],
      );
    });
    expect(find.text('copy me'), findsOneWidget);
    expect(find.text('row 0'), findsOneWidget);
  });

  // ── Painting & effects ───────────────────────────────────────────────────

  testWidgets('skill §11: BackdropFilter + ClipRRect glass panel', (tester) async {
    await pumpExample(tester, () {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: Color(0xFF223344)),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFFFFF),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('glass'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
    expect(find.text('glass'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);
  });

  testWidgets('skill §11: flat blur overlay scoped to a right-side zone',
      (tester) async {
    await pumpExample(tester, () {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const ColoredBox(color: Color(0xFF223344)),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: constraints.maxWidth * 0.55,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 18,
                      sigmaY: 18,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  // ── Accessibility ────────────────────────────────────────────────────────

  testWidgets('skill §13: Semantics and MergeSemantics compile and apply',
      (tester) async {
    // Semantics are only produced once the platform accessibility bridge is
    // enabled in the test binding, otherwise find.bySemanticsLabel sees none.
    //
    // IMPORTANT (verified against this SDK's flutter_test source): the binding
    // runs `invariantTester()` — which includes the "SemanticsHandle was
    // active" check — at the END of the test BODY, but `addTearDown`
    // callbacks only run AFTER that check. So the handle MUST be disposed
    // inline on the last line of the body (this is exactly how the official
    // docs.flutter.dev accessibility-testing examples do it), otherwise the
    // test fails with "A SemanticsHandle was active at the end of the test."
    final SemanticsHandle handle = tester.ensureSemantics();

    await pumpExample(tester, () {
      return Column(
        children: <Widget>[
          // container: true forces its own semantics node so `label` is the
          // node's label. Without it, this merges with the child Text and the
          // child's own label is what assistive tech reads.
          Semantics(
            container: true,
            button: true,
            label: 'Custom action',
            child: const Text('semantic'),
          ),
          const MergeSemantics(
            child: Text('merged'),
          ),
          const ExcludeSemantics(
            child: Text('decorative'),
          ),
        ],
      );
    });

    expect(find.text('semantic'), findsOneWidget);

    // Read the generated semantics node directly. This is more reliable than
    // find.bySemanticsLabel, which depends on how nodes are merged/labeled
    // across the whole subtree.
    final SemanticsNode buttonNode = tester.getSemantics(
      find.byWidgetPredicate((Widget w) => w is Semantics && w.properties.label == 'Custom action'),
    );
    // With container: true the node keeps BOTH its own label and the child's
    // text, joined by a newline — so use contains, not equality.
    expect(buttonNode.label, contains('Custom action'));
    // flagsCollection is the current accessor (SemanticsNode.hasFlag was
    // deprecated in favor of it after v3.32).
    expect(buttonNode.flagsCollection.isButton, isTrue);

    // ExcludeSemantics removes the child's semantics entirely: the Text is
    // still in the widget tree, but contributes no semantics node.
    expect(find.bySemanticsLabel('decorative'), findsNothing);
    expect(find.text('decorative'), findsOneWidget);

    // Release the handle BEFORE the test body returns — see the comment at
    // the top of this test for why it cannot go in addTearDown.
    handle.dispose();
  });

  // ── State → UI ───────────────────────────────────────────────────────────

  testWidgets('skill §12: dumb view / dumb trigger / smart parent', (tester) async {
    await pumpExample(tester, () {
      return const _CounterExample();
    });

    expect(find.text('Count: 0'), findsOneWidget);
    await tester.tap(find.text('Increment'));
    await tester.pump();
    expect(find.text('Count: 1'), findsOneWidget);
  });

  // ── Performance primitives referenced by the skill ───────────────────────

  testWidgets('skill §14: const constructors + AnimatedBuilder/ListenableBuilder',
      (tester) async {
    await pumpExample(tester, () {
      return Column(
        children: <Widget>[
          AnimatedBuilder(
            animation: const AlwaysStoppedAnimation<double>(1.0),
            builder: (BuildContext context, Widget? child) {
              return const Text('animated builder');
            },
          ),
          ListenableBuilder(
            listenable: const AlwaysStoppedAnimation<double>(1.0),
            builder: (BuildContext context, Widget? child) {
              return const Text('listenable builder');
            },
          ),
        ],
      );
    });
    expect(find.text('animated builder'), findsOneWidget);
    expect(find.text('listenable builder'), findsOneWidget);
  });
}

// ── Example widgets used by the tests above ────────────────────────────────

/// Skill §4 — explicit controller usage, including correct disposal.
class _ExplicitAnimationExample extends StatefulWidget {
  const _ExplicitAnimationExample();

  @override
  State<_ExplicitAnimationExample> createState() =>
      _ExplicitAnimationExampleState();
}

class _ExplicitAnimationExampleState extends State<_ExplicitAnimationExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: const Center(child: Text('fading in')),
    );
  }
}

/// Skill §5 — a custom control that participates in focus traversal.
class _FocusableExample extends StatefulWidget {
  const _FocusableExample();

  @override
  State<_FocusableExample> createState() => _FocusableExampleState();
}

class _FocusableExampleState extends State<_FocusableExample> {
  // Own the node so the tap handler can request focus on it, which is the
  // documented pattern: "combined with a gesture detector that calls
  // requestFocus, it can receive focus when tapped".
  final FocusNode _node = FocusNode(debugLabel: 'focusable-example');

  @override
  void dispose() {
    // FocusNodes MUST be disposed — they outlive builds.
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Focus(
        focusNode: _node,
        // Focus widgets manage their own node; onFocusChange drives the UI.
        onFocusChange: (bool focused) => setState(() => _focused = focused),
        child: GestureDetector(
          onTap: () {
            // Prefer node.requestFocus() over
            // FocusScope.of(context).requestFocus(node) — equivalent, cheaper.
            _node.requestFocus();
          },
          child: Container(
            width: 300,
            height: 50,
            alignment: Alignment.center,
            color: _focused ? Colors.black26 : Colors.white,
            child: Text(_focused ? 'Focused' : 'Unfocused'),
          ),
        ),
      ),
    );
  }

  bool _focused = false;
}

/// Skill §5 — Enter/Space activation via onKeyEvent.
class _KeyEventExample extends StatefulWidget {
  const _KeyEventExample();

  @override
  State<_KeyEventExample> createState() => _KeyEventExampleState();
}

class _KeyEventExampleState extends State<_KeyEventExample> {
  final FocusNode _node = FocusNode(debugLabel: 'key-event-example');
  bool _pressed = false;

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Focus(
        focusNode: _node,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            setState(() => _pressed = true);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () {
            // Key events are delivered to the PRIMARY focus node, so the
            // widget must hold focus before Enter/Space do anything.
            _node.requestFocus();
          },
          child: ColoredBox(
            color: const Color(0xFF4F6BED),
            child: SizedBox(
              width: 200,
              height: 60,
              child: Center(child: Text(_pressed ? 'pressed' : 'not pressed')),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skill §7 — hover feedback via MouseRegion.
class _HoverExample extends StatefulWidget {
  const _HoverExample();

  @override
  State<_HoverExample> createState() => _HoverExampleState();
}

class _HoverExampleState extends State<_HoverExample> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (PointerEnterEvent event) => setState(() => _hovered = true),
        onExit: (PointerExitEvent event) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 200,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF4F6BED) : const Color(0xFF303540),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_hovered ? 'hovered' : 'idle'),
        ),
      ),
    );
  }
}

/// Skill §12 — the dumb view / dumb trigger / smart parent split.
class _CounterDisplay extends StatelessWidget {
  const _CounterDisplay({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Text('Count: $count');
}

class _CounterIncrementor extends StatelessWidget {
  const _CounterIncrementor({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Increment'),
    );
  }
}

class _CounterExample extends StatefulWidget {
  const _CounterExample();

  @override
  State<_CounterExample> createState() => _CounterExampleState();
}

class _CounterExampleState extends State<_CounterExample> {
  int _counter = 0;

  void _increment() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _CounterIncrementor(onPressed: _increment),
        const SizedBox(width: 16),
        _CounterDisplay(count: _counter),
      ],
    );
  }
}

/// Skill §6 — a minimal Intent type for the shortcut example.
class _SaveIntent extends Intent {
  const _SaveIntent();
}

/// Skill §6 — CallbackShortcuts. Note the `setState`: mutating a plain local
/// variable would not rebuild the Text showing the count.
class _CallbackShortcutsExample extends StatefulWidget {
  const _CallbackShortcutsExample();

  @override
  State<_CallbackShortcutsExample> createState() =>
      _CallbackShortcutsExampleState();
}

class _CallbackShortcutsExampleState extends State<_CallbackShortcutsExample> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          setState(() => _count++);
        },
      },
      child: Focus(
        // autofocus makes this the primary focus, so the key event reaches
        // the ShortcutManager bound above it.
        autofocus: true,
        child: Column(
          children: <Widget>[
            const Text('press up'),
            Text('count: $_count'),
          ],
        ),
      ),
    );
  }
}