Premium Windows UI

Use this skill whenever designing or implementing ClipIt UI.

Companion skill: `flutter-ui-reference` (`.agents/skills/flutter-ui-reference/SKILL.md`)
holds the implementation reference — layout, theming, Material vs Cupertino,
animation, focus/shortcuts, gestures, desktop widgets, and runnable code
examples, plus this project's verified API gotchas. Load BOTH: this file is
the design taste, that file is the implementation knowledge.

The goal is to produce a premium desktop interface rather than generic AI-generated Flutter UI.

Core Principle

Do not ask:

"What widgets can I put on this screen?"

Ask:

"What is the clearest and most beautiful interaction for this task?"

Design the experience first, then choose the Flutter implementation.

Desktop Composition

Use the available horizontal space intelligently.

Avoid automatically stacking everything vertically.

Prefer:

side navigation when appropriate
command/navigation areas
resizable content regions
strong primary content areas
contextual panels
intelligent whitespace
desktop-scale typography
meaningful alignment

The UI should look designed specifically for a PC.

Visual Hierarchy

Every screen should have:

One obvious primary purpose.
A clear primary action.
Secondary actions that do not compete visually.
Consistent spacing.
A recognizable visual hierarchy.

Do not make every element equally loud.

Surfaces

Use surfaces deliberately.

Good examples:

subtle background layers
thin borders
restrained shadows
slight elevation
controlled transparency
carefully chosen panels

Avoid turning every component into a floating rounded card.

Not everything needs a border.

Not everything needs a shadow.

Not everything needs rounded corners.

Color

Use a coherent palette.

Do not automatically use:

purple gradients
blue neon
rainbow gradients
cyberpunk colors
black backgrounds with glowing accents

Color should support the ClipIt brand and hierarchy.

Accent colors should be meaningful.

Typography

Typography should establish hierarchy through:

size
weight
spacing
contrast
grouping

Avoid excessive font weights and excessive text sizes.

Large typography should be used intentionally.

Motion

Motion should feel smooth and purposeful.

Use animation for:

navigation
hover feedback
state changes
expanding/collapsing content
selection
loading
transitions
drag interactions

Prefer subtle interpolation and easing over abrupt changes.

Avoid:

excessive bouncing
cartoon-like effects
constant floating animations
random particles
animations that slow down normal work

Motion should make the application feel responsive, not like a game.

Hover States

Desktop applications should react to the pointer.

Consider:

subtle surface changes
slight elevation
icon movement
underline/indicator transitions
contextual controls appearing on hover
smooth color/opacity transitions

Do not make hover effects huge or distracting.

Interaction Feedback

Every meaningful interaction should communicate what happened.

Examples:

selected navigation item
focused input
active control
successful action
disabled action
loading state
empty state
error state

Avoid silent interactions where the user cannot tell whether something happened.

Keyboard

Desktop users should not be forced to use the mouse for everything.

When appropriate, support:

keyboard shortcuts
Enter
Escape
arrow navigation
Ctrl/Cmd-style shortcuts where appropriate
visible keyboard focus
Windows Feel

The application should feel natural on Windows while still having its own visual identity.

Respect:

mouse precision
keyboard workflows
window resizing
desktop density
context menus where useful
familiar interaction patterns

Do not simply copy a mobile interface.

Layout Responsiveness

The window may be resized.

Do not hardcode one fixed screen size.

Design sensible behavior for:

compact window
normal window
large window

Preserve hierarchy as the window changes size.

Empty States

Empty states are part of the product design.

Do not show:

"Nothing here."

Instead explain:

what this area is
why it is empty
what the user can do next

Keep the visual treatment polished and restrained.

Loading

Loading states should feel intentional.

Prefer:

skeletons
progressive content
subtle transitions
meaningful progress indicators

Avoid generic spinning loaders everywhere.

Component Quality

Create reusable components when a pattern appears repeatedly.

Examples:

buttons
navigation items
toolbars
panels
dialogs
inputs
menus
media controls

Do not abstract tiny one-off widgets unnecessarily.

Performance

Avoid expensive animations and rebuilds when unnecessary.

Prefer:

localized state updates
efficient lists
controlled animation controllers
const widgets where appropriate
avoiding unnecessary rebuilds

Visual quality must not destroy responsiveness.

Final Quality Check

Before considering a UI complete, check:

Does it look like a desktop application?
Is the hierarchy obvious?
Does the spacing feel intentional?
Are hover/focus states polished?
Does resizing work?
Does the interface feel responsive?
Are animations useful?
Are there unnecessary cards or gradients?
Does it still look good without animation?
Would this look believable as a commercial product?

If not, refine it.