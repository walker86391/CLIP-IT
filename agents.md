# ClipIt — Project Instructions

## What is ClipIt?

ClipIt is a premium Windows desktop application built with Flutter.

ClipIt is NOT a basic demo, generic CRUD app, or mobile app stretched onto a desktop screen.

The goal is to create a polished, modern desktop product that feels like a real software product people would want to use every day.

The application should feel intentional, premium, fast, responsive, and highly designed.

## Platform

Primary target:

* Windows desktop
* Flutter
* Dart

Do not optimize the architecture around Android, iOS, or web unless explicitly requested.

Use Windows desktop conventions where appropriate.

## Product Quality

Never settle for:

* default Flutter-looking interfaces
* generic Material layouts
* giant collections of Card widgets
* excessive rounded rectangles
* random gradients
* unnecessary neon colors
* generic AI-generated dashboards
* excessive glassmorphism
* fake "futuristic" UI
* empty decorative animations
* mobile UI placed inside a desktop window

The interface must feel like a deliberate desktop application.

## Design Direction

ClipIt should have:

* strong visual hierarchy
* excellent spacing
* refined typography
* subtle depth
* smooth transitions
* thoughtful hover states
* keyboard-friendly interaction
* responsive desktop layouts
* polished empty states
* clear navigation
* meaningful animation
* restrained visual effects

Animations should communicate state, hierarchy, interaction, or navigation.

Do not add animation just because animation is possible.

## Desktop First

Design for mouse and keyboard first.

Important interactions should support:

* mouse hover
* mouse click
* keyboard shortcuts
* focus states
* scrolling
* drag interactions where appropriate
* window resizing

Do not design the UI like a phone application.

## Architecture

Keep the code modular.

Do NOT put the entire application inside `lib/main.dart`.

Use separate folders for appropriate concerns, for example:

lib/
main.dart
app/
core/
features/
shared/
widgets/
services/
theme/

Organize features logically as the application grows.

Before creating a large amount of code, inspect the existing architecture and choose the smallest clean structure that will scale.

## Dependencies

Do not install packages automatically unless they provide meaningful value.

Before adding a dependency:

1. Explain why it is needed.
2. Check whether Flutter/Dart already provides the required functionality.
3. Prefer stable, maintained packages.
4. Avoid dependency bloat.

## Implementation Behavior

Before major implementation:

1. Inspect the existing project.
2. Identify relevant files.
3. Explain the intended approach.
4. Implement incrementally.
5. Run Flutter analysis/tests when appropriate.
6. Run the Windows application when UI changes need visual validation.
7. Fix errors instead of leaving broken code.

Never rewrite unrelated parts of the application.

## UI Iteration

When building a screen:

1. Build the structural layout.
2. Establish typography and spacing.
3. Establish colors and surfaces.
4. Add interaction states.
5. Add animation.
6. Test the actual Windows application.
7. Refine visual problems.

Do not declare a UI finished merely because the code compiles.

## Visual Standard

The standard is:

"Would this look believable as a polished commercial desktop application?"

If the answer is no, continue refining.

Prefer fewer high-quality elements over many decorative elements.

## Important Rule

If the user asks for a visual change, preserve existing functionality unless the change explicitly requires modifying it.

Do not randomly redesign unrelated screens.

## Communication

When a task is ambiguous, inspect the project first.

For major changes, briefly explain:

* what you found
* what you plan to change
* which files will be affected

Then implement.

Do not generate huge amounts of unnecessary explanation.

## ClipIt Development Philosophy

Build ClipIt like a real product, not like an AI coding demonstration.

Prioritize:

* usability
* visual quality
* performance
* maintainability
* coherent interaction design
* polished details

Every new screen should feel like it belongs to the same product.

## Code Handling Rules (NON-NEGOTIABLE)

This codebase is a long-term project (10+ months). NEVER minify, compress,
or shorten code:

* Do not collapse multi-line code into one-liners to "save space".
* Do not delete comments, doc comments, or TODOs to shrink files.
* Do not rewrite/refactor existing code into "shorter" versions unless the
  user explicitly approves that specific change first.
* If a refactor/shortening genuinely matters, PROPOSE it, name the files and
  reason, and WAIT for approval.
* When replacement is unavoidable (e.g. a full-file rewrite), keep the
  original available: create a copy or show a clear before/after so nothing
  is lost or untraceable.
* Verbose, readable, well-commented code is always preferred over compact
  code.

User input assets: anything placed in `user-input-resources/` must be copied
into the project (e.g. `assets/`) before it is needed, because that folder is
deleted at the end of sessions.
