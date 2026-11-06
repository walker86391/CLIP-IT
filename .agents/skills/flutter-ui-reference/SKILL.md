---
name: flutter-ui-reference
description: Practical Flutter UI reference for building ClipIt — layout, theming, Material 3 vs Cupertino, animation, focus/keyboard, gestures, desktop patterns, and runnable code examples. Use whenever implementing or reviewing any ClipIt UI.
---

# Flutter UI Reference (ClipIt)

Use this skill whenever building or reviewing ClipIt UI. It exists so UI work
starts from **verified patterns and runnable code** rather than guesswork.

**Docs version:** Flutter **3.47** (matches this project's toolchain).
Re-read https://docs.flutter.dev when you need detail beyond this file.

Companion skill: `premium-windows-ui` holds the *design taste* rules
(hierarchy, restraint, anti-generic-AI). This file holds the *implementation
reference*. Use both.

---

## ⚠️ CRITICAL: verified import paths (read before copying doc examples)

Flutter's docs contain examples that **will not compile as-is**. This project
is verified working — follow these, not the docs:

| Docs sometimes show | Use this (verified in this repo) |
|---|---|
| `package:material_ui/material_ui.dart` | `package:flutter/material.dart` |
| `import 'package:material_ui/material_ui.dart'` | `import 'package:flutter/material.dart'` |
| `WidgetsApp` for basic apps | `MaterialApp` |

Everything else in the docs' Dart samples is sound.

Also verified in this project's Flutter build:

- `StateProvider` **does not exist** (Riverpod 3). Use `Notifier`/`NotifierProvider`.
- `ThemeData.animations` / `Animations` **do not exist** in this build.
  Reduce-motion is implemented via the custom `ReduceMotion` InheritedWidget in
  `lib/ui/tokens/motion.dart` (`AppMotion.fastOf/mediumOf/disabled(context)`).
- `collection`'s `sortedByCompare` takes **one** type argument only.
- `flutter build windows` requires Developer Mode enabled (already done).
- The `animations` package was deliberately skipped — Flutter built-ins suffice.

---

## 1. Three-tier widget architecture

Flutter splits UI into tiers. Choosing the right tier is the first decision.

| Tier | Import | Design system | Use when |
|---|---|---|---|
| **widgets** | `package:flutter/widgets.dart` | none (style-neutral) | custom design system, reusable pub.dev package, embedded/kiosk |
| **Material 3** | `package:flutter/material.dart` | Google M3 | Android + cross-platform + desktop. **ClipIt's default.** |
| **Cupertino** | `package:flutter/cupertino.dart` | Apple HIG | iOS/macOS-native feel, or adaptive per-platform rendering |

Material 3 gives you `Scaffold`, `AppBar`, `NavigationBar`, `ColorScheme.fromSeed`,
dark/light switching, ripples, and accessibility for free. For a Windows desktop
product, Material is the right base — then override its opinions with ClipIt's
own tokens.

**Third-party design systems** (real options, not defaults):
- `fluent_ui` — Windows Fluent: `NavigationView`, content dialogs, flyouts,
  tree views. Closest to native Windows. Big dependency; only add deliberately.
- `macos_ui`, `yaru` — macOS / Ubuntu.
- `bitsdojo_window` — custom ("owner draw") Windows title bars.

---

## 2. Layout

Everything is a widget, including the layout models. `Row`/`Column` are flexbox;
`Stack` is absolute positioning.

### Core primitives

```dart
// Flexbox-style linear layout. Row = horizontal, Column = vertical.
// Main axis = the flex direction. Cross axis = perpendicular.
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // start/end/center/
                                                     // spaceBetween/Evenly/Around
  crossAxisAlignment: CrossAxisAlignment.center,
  children: <Widget>[
    Expanded(child: Image.asset('images/pic1.jpg')),
    Expanded(flex: 2, child: Image.asset('images/pic2.jpg')), // 2x the space
    Expanded(child: Image.asset('images/pic3.jpg')),
  ],
)

// mainAxisSize.min packs children closely instead of filling the axis.
Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    Icon(Icons.star, color: Colors.green[500]),
    Text('170 Reviews'),
  ],
)
```

### Stack + Positioned (absolute positioning)

```dart
Stack(
  fit: StackFit.expand,          // fill the parent, or use StackFit.loose
  children: <Widget>[
    Image.asset('bg.png', fit: BoxFit.cover),
    // Right-side zone, 55% of available width
    Positioned(
      top: 0, bottom: 0, right: 0,
      width: constraints.maxWidth * 0.55,
      child: const MyOverlay(),
    ),
    // Fill everything
    Positioned.fill(child: const Scrim()),
    Align(alignment: Alignment.centerRight, child: const Panel()),
  ],
)
```

> **ClipIt gotcha (real bug, fixed):** `Stack` children overlap and all receive
> pointer events. A full-screen `Positioned.fill` overlay will intercept taps
> meant for widgets beneath it unless you use `IgnorePointer` or keep the
> overlay non-interactive. This is also why the auth blur must be scoped to a
> right-side `Positioned`, not `Positioned.fill`.

### Sizing & constraints

```dart
SizedBox(width: 440, height: 32, child: ...)   // hard constraint
ConstrainedBox(
  constraints: BoxConstraints(maxHeight: panelMaxHeight),
  child: SingleChildScrollView(child: ...),     // never overflow
)
Flexible(child: ...)   // flex, looser than Expanded (allows child to be smaller)
FittedBox(child: ...)  // scale down to fit
AspectRatio(aspectRatio: 16 / 9, child: ...)
```

### Layout selection guidance

- `Row`/`Column` = maximum customization, low-level.
- **Prefer higher-level widgets when they fit:** `ListTile` over a hand-built
  Row for list rows; `ListView` over `Column` so content scrolls.
- Avoid deep nesting — build pieces into variables/functions for readability.
- Yellow/black stripes = overflow. Fix with `Expanded`/`Flexible`/`SizedBox`.

### Responsive (desktop windows resize!)

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isWide = constraints.maxWidth >= 1100;
    final isCompact = constraints.maxWidth < 760;
    return isWide ? WideLayout() : (isCompact ? CompactLayout() : MediumLayout());
  },
)
```
Design for compact / normal / large and preserve hierarchy across all three.
ClipIt's `AppSizes.minWindow` is 960×600 — design to that floor.

---

## 3. Theming

Styling precedence: **specific widget → nearest parent `Theme` → app `Theme`.**

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F6BED),
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(/* ... */),
  ),
  darkTheme: ThemeData(/* ... */),
  themeMode: ThemeMode.system,
  home: const Home(),
)

// Read nearest theme
Theme.of(context).colorScheme.primary
Theme.of(context).textTheme.bodyMedium

// Extend for a subtree (preferred over a full override)
Theme(
  data: Theme.of(context).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
  ),
  child: const FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
)

// Fully independent instance
Theme(
  data: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink)),
  child: const FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
)
```

`ColorScheme` exposes ~45 semantic roles (`primary`/`onPrimary`,
`surface`/`onSurface`, `error`/`onError`, …). **Always prefer roles over raw
hex.** ClipIt's auth flow uses its own `AuthColors` because it deliberately
breaks from the app theme; the main app uses `lib/ui/tokens/colors.dart`.

`DefaultTextStyle.merge()` inherits a style down a subtree — useful for
repeated label/description blocks.

---

## 4. Animation

### Implicit (declare target, framework animates) — prefer these

```dart
AnimatedOpacity(opacity: isVisible ? 1.0 : 0.0, duration: AppMotion.medium)
AnimatedContainer(
  duration: AppMotion.fastOf(context),
  curve: Curves.fastOutSlowIn,
  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(9)),
  child: child,
)
AnimatedAlign(alignment: Alignment(x, 0), duration: ..., curve: ...)
AnimatedSize(...)      // animates size changes
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: value),
  duration: const Duration(milliseconds: 200),
  builder: (context, t, _) => Opacity(opacity: t, child: child),
)
AnimatedSwitcher(  // crossfade when child changes
  duration: const Duration(milliseconds: 200),
  child: Text(key: ValueKey(label), label),
)
```
`ImplicitlyAnimatedWidget` subclasses manage their own controller.

### Explicit (AnimationController) — for gesture-driven / sequenced work

```dart
class _MyState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void dispose() { _c.dispose(); super.dispose(); }   // MUST dispose

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _fade, child: const Child());
}
```
- Controller methods: `forward()`, `reverse()`, `repeat()`, `animateTo(target)`,
  `fling(velocity)` (spring), `animateWith(simulation)`.
- `CurvedAnimation(parent, curve: forward, reverseCurve: ...)` reshapes values.
- `ReverseAnimation(parent)` mirrors 0→1 into 1→0.
- `Tween<T>` interpolates beyond 0..1 (`ColorTween`, `RectTween`, `Tween<double>`);
  combine with `parent.animate(tween)` or `tween.transform(parent.value)`.
- `AnimatedBuilder` rebuilds on value change; `ListenableBuilder` for any Listenable.
- **Always dispose controllers.** `vsync: this` with `SingleTickerProviderStateMixin`
  (or `TickerProviderStateMixin` for multiple controllers).

### Curves worth knowing
`Curves.easeInOut`, `easeOut`, `fastOutSlowIn` (Material standard),
`decelerate`, `elasticOut` (use sparingly).

### Motion principles for ClipIt
- Animate to communicate **state, hierarchy, interaction, navigation**.
- ~150–250 ms for hover/press, ~300–550 ms for page transitions.
- Never animate purely because it's possible. No idle floating, no particles.
- Respect reduce-motion (ClipIt: `AppMotion.disabled(context)` → `Duration.zero`).

---

## 5. Focus & keyboard (desktop-first — do not skip)

Glossary: **focus node**, **primary focus**, **focus chain**, **focus scope**,
**focus traversal** (Tab order). Focus events propagate from the primary focus
node **upward** to the root; return `KeyEventResult.handled` to stop them.

### Best practices (from the official docs)

- **Do NOT** allocate a `FocusNode` in `build()` — leaks memory and can drop
  focus mid-rebuild. Create them in a `State` and `dispose()` them.
- **Do NOT** reuse one `FocusNode` for multiple widgets — they fight over state.
- **Do NOT** set `onKeyEvent` on a node managed by a `Focus` widget — use the
  widget's `onKeyEvent` instead (the widget's value overwrites the node's).
- Set `debugLabel` on focus nodes to make focus bugs diagnosable.
- `canRequestFocus: false`, `skipTraversal: true`, `descendantsAreFocusable: false`
  control participation. `ExcludeFocus` is a `Focus` with the last one set.
- Prefer `focusNode.requestFocus()` over `FocusScope.of(context).requestFocus(node)`
  — equivalent and cheaper.

### Making a custom control focusable

```dart
Focus(
  onFocusChange: (focused) => setState(() => _color = focused ? Colors.black26 : Colors.white),
  child: Container(width: 300, height: 50, alignment: Alignment.center,
                   color: _color, child: Text(_label)),
)
```

### Key events — processed BEFORE text entry

```dart
Focus(
  onKeyEvent: (node, event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
         event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  },
  child: ...,
)
```
Because key events precede text input, a `Focus` wrapping a `TextField` can
swallow keystrokes. For *input validation* prefer `TextInputFormatter`; use
`onKeyEvent` for shortcuts.

### Unfocusing
`FocusNode.unfocus()` moves focus to the nearest `FocusScopeNode` (default) or the
previously focused child. If tab traversal breaks app-wide, a node likely
unfocused to `FocusManager.rootScope` — add an ancestor `FocusScope` to fix.
`MaterialApp`/`CupertinoApp` already provide one.

### FocusTraversalGroup — group a form so Tab cycles inside it
Wrap a form's fields so traversal doesn't wander to the rest of the app.

---

## 6. Actions & shortcuts (Ctrl+S, Ctrl+Z, …)

Three concepts:
- **Intent** — a generic user intent (`SelectAllIntent`). Knows nothing of UI.
- **Action** — implements the intent; has `isEnabled()` so a button/shortcut can
  be disabled properly.
- **Shortcut** — key combination bound to an Intent.

Why the indirection? One key combo adapts to whichever Action fulfils the
Intent in the focused context (e.g. text field vs canvas).

```dart
// Full stack: key → Intent → Action
Shortcuts(
  shortcuts: <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.keyS, control: true): const SaveIntent(),
    const SingleActivator(LogicalKeyboardKey.keyZ, control: true): const UndoIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{
      SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => _save()),
      UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => _undo()),
    },
    child: Builder(
      builder: (context) => TextButton(
        onPressed: Actions.handler<SaveIntent>(context, const SaveIntent()),
        child: const Text('Save'),
      ),
    ),
  ),
)
```

Use `SingleActivator(key, control: true)` / `CharacterActivator`. Prefer these
over plain `LogicalKeySet`. If you only need callbacks with no enable/disable
logic, `CallbackShortcuts(bindings: {...})` is the lightweight option.

`Actions.maybeInvoke<T>(context, intent)` invokes without a button;
`Actions.maybeFind<T>(context)` looks up an action.

**Wrap in `Builder`** when calling `Actions.handler` so lookup starts in the
same build scope.

---

## 7. Gestures

Two layers: raw **pointers** (`PointerDown/Move/Up/CancelEvent`) and semantic
**gestures** (tap, drag, scale) recognized from pointer streams.

```dart
GestureDetector(
  onTap: () {},
  onDoubleTap: () {},
  onLongPress: () {},
  onHorizontalDragStart/Update/End: ...,
  onVerticalDragStart/Update/End: ...,
  // Pan + horizontal/vertical drag together CRASH — pick one family.
  child: ...,
)
```

Which callbacks you set determines which gestures are attempted (only
non-null ones enter the arena). `onPan*` crashes if `onHorizontalDrag*` or
`onVerticalDrag*` is also set.

**Gesture arena:** when recognizers overlap, they compete; the first to declare
a win takes it (e.g. horizontal wins after enough horizontal movement). A lone
recognizer wins immediately — the first pixel of drag works.

For ink-splash on a custom tappable, use `InkWell` (needs a `Material` ancestor).
For hover/press visuals on desktop, use `MouseRegion` (enter/exit) + `Focus`
(keyboard) together — see ClipIt's `AuthButton`.

---

## 8. Scrolling & lists

```dart
ListView.builder(itemCount: n, itemBuilder: (context, i) => Row())  // lazy
ListView.separated(...)   // with dividers
CustomScrollView(slivers: [SliverAppBar(...), SliverList(...)])
Scrollbar(child: ListView(...))            // desktop: always show a scrollbar
ScrollConfiguration(behavior: ..., child: ...)
```
Build lazily with `.builder` for long content. Wrap in `Scrollbar` on desktop —
users expect a visible, draggable scrollbar.

---

## 9. Desktop / Windows specifics

- Run: `flutter run -d windows`. Release build: `flutter build windows`
  → `build\windows\x64\runner\Release\clipit.exe` **plus the whole `Release`
  folder** (DLLs + `data/`), not the exe alone.
- Runner C++ (`windows/runner/main.cpp`) sets the window title and initial
  size/position. Exe name via `BINARY_NAME` in `windows/CMakeLists.txt`.
  Icon: `windows/runner/resources/app_icon.ico`.
- Window management: `window_manager` (size, position, min/max size, always-on-top).
- Native menus: `flutter_menu_bar` / `menubar` packages.
- Tray: `tray_manager`. Multi-window: `desktop_multi_window`.
- Windows-native visuals: `fluent_ui` (+ `fluentui_system_icons`),
  `bitsdojo_window` for custom title bars.
- Raw Win32 via `dart:ffi` or the `win32` package (COM is easier through a wrapper).
- Distribution: MSIX via the `msix` package (Store handles signing), or a
  self-signed `.pfx` + zip, or `Inno Setup`/WiX for a classic installer.
  Redistributables: `msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`
  (or app-local copies next to the exe).

### Desktop interaction checklist
- Mouse **hover** states on every interactive element (`MouseRegion`).
- Visible keyboard **focus** rings; logical Tab order.
- **Keyboard shortcuts** for common actions (see §6).
- Handle **window resize** — never a single fixed size (§2).
- **Right-click context menus** where meaningful (`showMenu`).
- Precise cursor affordances: `SystemMouseCursors.click` for clickable,
  `resizeColumn`/`resizeRow`/`text` where appropriate.

---

## 10. Desktop-friendly widgets (not mobile-only)

- `SelectableText` — selectable/copyable text.
- `DataTable` / `PaginatedDataTable` — desktop data grids (`PaginatedDataTable`
  adds rows-per-page + paging).
- `SplitView` (`flutter_split_view`) or `MultiChildLayout`/`CustomMultiChildLayout`
  — resizable panes (e.g. sidebar + content + inspector).
- `ReorderableListView` — drag to reorder.
- `ContextMenuButton` / `showMenu` — right-click menus.
- `TextField` with `TextInputAction.next/done` + `FocusTraversalGroup` — proper
  form tabbing.
- `ExpansionTile`, `ExpansionPanel` — collapsible sections.
- `Tooltip` — hover explanations (300ms `waitDuration` feels right).
- `ValueSlider`/`Slider`, `Switch`, `Checkbox`, `DropdownButton`/`MenuAnchor`.
- `showDialog`, `showModalBottomSheet`, `Overlay`-based toasts for feedback.

---

## 11. Painting & effects (visual polish, no layout change)

Apply visual effects **without** changing layout/size/position:

```dart
BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: ...)
ClipRRect(borderRadius: BorderRadius.circular(16), child: ...)
ClipPath(clipper: ..., child: ...)
Opacity(opacity: .06, child: ...)
ShaderMask(...)  CustomPaint(painter: ...)
Transform.rotate(...)  FractionalTranslation(...)
DecoratedBox(decoration: BoxDecoration(color:, border:, borderRadius:, boxShadow:, gradient:))
```

**Glass panel recipe** (ClipIt's auth):
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),        // white 6%
        border: Border.all(color: const Color(0x1AFFFFFF)), // white 10%, 1px
      ),
      child: child,
    ),
  ),
)
```
- Prefer a **flat, uniform** sigma over a ramped/progressive blur. A
  multi-strip sigma ramp reads as a rendering artifact ("progressive smear").
- `BackdropFilter` blurs what's **behind** it in the same layer; scope it with
  `Positioned`/`ClipRect` and give it a child to size against.

---

## 12. State → UI

`StatelessWidget` for static; `StatefulWidget` + `State` for local mutable state
via `setState`. State flows **down** as data/args; changes flow **up** as
callbacks. The `State` is the usual redirect point.

```dart
class CounterDisplay extends StatelessWidget {         // dumb view
  const CounterDisplay({required this.count, super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Text('Count: $count');
}
class CounterIncrementor extends StatelessWidget {      // dumb trigger
  const CounterIncrementor({required this.onPressed, super.key});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: const Text('Increment'));
}
class Counter extends StatefulWidget { /* State holds _counter, setState rebuilds */ }
```
Splitting dumb view / dumb trigger / smart parent keeps complex UIs manageable.

ClipIt uses **Riverpod 3** for app state (not `setState`): `Notifier` +
`NotifierProvider`, `ref.watch` in build, override providers in tests.

---

## 13. Accessibility (build it in from the start)

- `Semantics(...)` / `MergeSemantics` for custom controls; `ExcludeSemantics`
  to hide decorative parts.
- `Tooltip` doubles as the accessible label for icon buttons (`IconButton(tooltip:)`).
- Respect `MediaQuery.of(context).disableAnimations` / reduce-motion.
- Maintain **contrast** (text vs background); don't rely on color alone —
  pair color with icon/text/shape.
- Label every meaningful image (`Image.asset(..., semanticLabel:)`).
- Keyboard reachability + visible focus are accessibility requirements.

---

## 14. Performance (keep it responsive)

- `const` constructors wherever possible (huge rebuild-skipping win).
- Push state down with `Builder`/local `State` so a change doesn't rebuild a
  whole subtree; prefer `ValueListenableBuilder`/`AnimatedBuilder` for
  fine-grained updates.
- Build long/lazy content with `ListView.builder` / `GridView.builder`.
- Avoid expensive work in `build()`; cache computations, dispose controllers.
- `BackdropFilter`/`ImageFilter` are GPU-costly — scope them tightly, prefer one
  filter over many stacked ones.
- Heavy CPU work → `compute()` (isolate) so the UI thread never stalls.

---

## 15. Testing UI (widget tests)

- `tester.pumpWidget(...)`, then `await tester.pumpAndSettle()` for animations.
- Set window size in tests: `tester.view.physicalSize = Size(1280, 800);`
  `tester.view.devicePixelRatio = 1.0;` — catches real-size overflow.
- Finders: `find.text`, `find.byType`, `find.byIcon`,
  `find.widgetWithText(T, 'label')`, `find.descendant(of: ..., matching: ...)`
  (scope when a string is ambiguous, e.g. "Sign In" as both a tab and a link).
- Interactions: `tester.tap`, `enterText`, `pumpAndSettle`.
- **Caveat:** under `flutter test`, real HTTP is blocked (all requests → 400)
  and plugins like `shared_preferences` are unavailable. Override providers with
  stubs and assert UI wiring; verify live networking in a real `flutter run`.
- Each test file runs in its own isolate — global flags set in `setUpAll` don't
  leak between files.

---

## 16. Quick recipes index

| Want | Reach for |
|---|---|
| Column/row layout | `Row`, `Column`, `Expanded`, `Flexible` |
| Overlap / absolute | `Stack` + `Positioned` / `Positioned.fill` / `Align` |
| Never overflow | `ConstrainedBox` + `SingleChildScrollView`, `SizedBox`, `FittedBox` |
| App colors/fonts | `Theme.of(context)`, `Theme(data: Theme.of(context).copyWith(...))` |
| Animate a change | `AnimatedContainer/Opacity/Align/Size`, `AnimatedSwitcher` |
| Sequence / gesture anim | `AnimationController` + `CurvedAnimation` + `FadeTransition` |
| Blur / glass | `BackdropFilter(ImageFilter.blur(...))` + `ClipRRect` |
| Hover feedback | `MouseRegion(onEnter/onExit)` + `AnimatedContainer` |
| Keyboard focus | `Focus(onFocusChange/onKeyEvent)`, `FocusTraversalGroup`, `FocusNode` |
| Shortcuts | `Shortcuts` + `Actions` + `CallbackShortcuts`, `SingleActivator` |
| Right-click menu | `showMenu` / `ContextMenuButton` |
| Dialog | `showDialog`, `AlertDialog` |
| Toast | `Overlay`-based custom toast (ClipIt has `app_toast`) |
| Resizable panes | `flutter_split_view` / `CustomMultiChildLayout` |
| Responsive | `LayoutBuilder` |
| Lazy long list | `ListView.builder` |
| Spinner / progress | `CircularProgressIndicator`, `LinearProgressIndicator` |

---

## 17. Debugging layout issues

- Run with `debugPaintSizeEnabled = true` (or `debugPaintSizeEnabled` in
  `WidgetsApp.showPerformanceOverlay`/`debugPaint...`) to visualize boxes.
- Yellow/black stripes = overflow; find the unconstrained axis, add
  `Expanded`/`Flexible`/`SizedBox`/`ConstrainedBox`.
- `flutter run` → `p` toggles the performance/widget inspector; DevTools is at
  the VM service URL printed on launch.
- `debugDumpApp()`, `debugDumpRenderTree()`, `debugDumpApp()` print trees.

---

## Source pages consulted (Flutter 3.47)
- https://docs.flutter.dev/ui — UI overview, three tiers
- https://docs.flutter.dev/ui/widgets — widget catalog
- https://docs.flutter.dev/ui/widgets/cupertino — Cupertino catalog
- https://docs.flutter.dev/ui/layout — layout/flex/Stack/constraints
- https://docs.flutter.dev/ui/animations/overview — animation architecture
- https://docs.flutter.dev/ui/interactivity/focus — focus system
- https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts — Intents/Actions/Shortcuts
- https://docs.flutter.dev/ui/interactivity/gestures — pointers/gestures/arena
- https://docs.flutter.dev/platform-integration/desktop — desktop support
- https://docs.flutter.dev/platform-integration/windows/building — Windows build/distribution
- https://docs.flutter.dev/cookbook/design/themes — theming recipes

When a section here is not enough, read the live page — the docs are current
for 3.47 and cover every widget with runnable examples.