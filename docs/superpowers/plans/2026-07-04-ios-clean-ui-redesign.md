# iOS-Clean UI/UX Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the entire SCMS Flutter client into a polished, cohesive iOS/Apple-clean app (Apple system-blue accent, grouped inset cards, large collapsing titles, subtle motion) without changing any backend, BLoC, repository, routing, or data-model behavior.

**Architecture:** Presentation-layer only. Phase A rewrites the theme tokens and builds a shared iOS-style component library (grouped sections, list rows, large-title scaffold, segmented tabs, blurred tab bar, buttons, status pill, stat tile, press-scale, Cupertino page transitions). Phases B–D re-express every screen on top of those components. Because most screens already compose shared widgets, screen work is largely swapping composition, not rewriting logic.

**Tech Stack:** Flutter (Material 3, `useMaterial3: true`), `google_fonts` (Inter), `flutter_bloc`, `go_router`. Blur via `dart:ui` `BackdropFilter`; motion via built-in `PageTransitionsBuilder` + `AnimatedScale`/`TweenAnimationBuilder`. No new dependencies.

## Global Constraints

- **Presentation only.** Do not modify `lib/data/`, `lib/domain/`, any BLoC/Cubit logic (events/states), repositories, datasources, `go_router` route *targets/names*, the Node backend, or the Python AI service.
- Preserve `DioClient` envelope behavior and all backend field-name conventions from `CLAUDE.md` (`title`, multipart `media`, `tags` JSON string, `status`, `ratingComment`, optional `departmentId`).
- Keep the **public API** of `AppColors` and `AppTextStyles` stable where referenced (same constant/method names); only values change. New tokens may be added.
- Accent: `#007AFF` (light) / `#0A84FF` (dark). Backgrounds: light base `#F2F2F7`, card `#FFFFFF`; dark base `#000000`, elevated `#1C1C1E`/`#2C2C2E`. Separator `#C6C6C8` / `#38383A`.
- **Verification is `flutter analyze` (must print "No issues found.") + `flutter build apk --debug` sanity + a visual check in light AND dark mode.** There is no widget-test suite; do not invent one. UI tasks are "done" when analyze is clean, the build succeeds, and the screen renders correctly in both themes.
- Run every `flutter` command from `scms_flutter/`.
- After each phase, append a dated entry to `CONTEXT.md`'s changelog (do not rewrite history).
- Respect `TEAM_WORKDIVISION.md`; this is a cross-cutting UI change — note it in `CONTEXT.md`.

---

## Verification convention (applies to every task)

Because these are presentation changes, each task's verification steps are:

1. **Analyze:** `flutter analyze` → expect `No issues found!`
2. **Build sanity (once per phase, at the phase's last task):** `flutter build apk --debug` → expect `✓ Built build\app\outputs\flutter-apk\app-debug.apk`
3. **Visual check:** `flutter run` (or hot-reload) and confirm the touched screen(s) render correctly in **light and dark** mode, and that navigation/actions still work.
4. **Commit** with the message shown in the task.

When a step below says "Verify", run steps 1, 3, 4 (and 2 where noted).

---

# PHASE A — Foundation (tokens + shared component library)

No screen is rewritten in Phase A, but every screen must still compile and render after each task (the existing screens import these files). Keep existing public symbols alive.

### Task A1: Rewrite color tokens to the Apple system palette

**Files:**
- Modify: `scms_flutter/lib/core/theme/app_colors.dart`

**Interfaces:**
- Produces: `AppColors` with the SAME public names as today plus new tokens: `groupedBackground`, `groupedBackgroundDark`, `separator`, `separatorDark`, `fillTinted(Color)`, `systemRed/Orange/Yellow/Green/Teal/Indigo/Blue/Gray`. `statusColor(String)`, `severityColor(String)`, `confidenceColor(double)` keep their signatures.

- [ ] **Step 1: Replace the brand + neutral + status values** (keep every existing constant name so dependents compile). Set:

```dart
// Primary accent — Apple system blue
static const Color primary = Color(0xFF007AFF);       // light accent
static const Color primaryLight = Color(0xFF0A84FF);  // dark-mode accent
static const Color primaryDark = Color(0xFF0060DF);
static const Color accent = Color(0xFF5E5CE6);        // system indigo

// System palette
static const Color systemRed = Color(0xFFFF3B30);
static const Color systemOrange = Color(0xFFFF9500);
static const Color systemYellow = Color(0xFFFFCC00);
static const Color systemGreen = Color(0xFF34C759);
static const Color systemTeal = Color(0xFF30B0C7);
static const Color systemIndigo = Color(0xFF5E5CE6);
static const Color systemBlue = Color(0xFF007AFF);
static const Color systemGray = Color(0xFF8E8E93);

// Status (remapped to system palette)
static const Color statusOpen = Color(0xFF8E8E93);
static const Color statusPendingSrReview = systemIndigo;
static const Color statusAssigned = systemBlue;
static const Color statusInProgress = systemOrange;
static const Color statusResolved = systemGreen;
static const Color statusClosed = Color(0xFF636366);
static const Color statusRejected = systemRed;

// Severity
static const Color severityHigh = systemRed;
static const Color severityMedium = systemOrange;
static const Color severityLow = systemYellow;

// Confidence
static const Color confidenceHigh = systemGreen;
static const Color confidenceMedium = systemOrange;
static const Color confidenceLow = systemRed;

// Neutrals — iOS grouped model (light)
static const Color background = Color(0xFFF2F2F7);        // systemGroupedBackground
static const Color groupedBackground = Color(0xFFF2F2F7);
static const Color surface = Color(0xFFFFFFFF);
static const Color surfaceVariant = Color(0xFFF2F2F7);
static const Color border = Color(0xFFC6C6C8);
static const Color separator = Color(0xFFC6C6C8);
static const Color textPrimary = Color(0xFF000000);
static const Color textSecondary = Color(0xFF8E8E93);
static const Color textDisabled = Color(0xFFC7C7CC);

// Neutrals — dark
static const Color backgroundDark = Color(0xFF000000);
static const Color groupedBackgroundDark = Color(0xFF000000);
static const Color surfaceDark = Color(0xFF1C1C1E);
static const Color surfaceVariantDark = Color(0xFF2C2C2E);
static const Color border_Dark = Color(0xFF38383A); // if borderDark exists, keep name
static const Color separatorDark = Color(0xFF38383A);
static const Color textPrimaryDark = Color(0xFFFFFFFF);
static const Color textSecondaryDark = Color(0xFF98989F);
```

Keep the existing `borderDark`, `primarySurface`, `primaryDeep`, `glass*`, `backdrop*`, and `*Gradient` names present so nothing breaks; repoint them: `primarySurface = primary`, `primaryDeep = primaryDark`, backdrops flattened to the new base colors (`backdropLight` → `#F2F2F7` both stops, `backdropDark` → `#000000` both stops). Leave `statusColor`/`severityColor`/`confidenceColor` method bodies unchanged (they reference the constants above).

- [ ] **Step 2: Add a tinted-fill helper**

```dart
/// Translucent tint of [c] for iOS "tinted" buttons/chips/backgrounds.
static Color fillTinted(Color c, [double opacity = 0.15]) =>
    c.withValues(alpha: opacity);
```

- [ ] **Step 3: Verify** — `flutter analyze` clean. Commit:

```bash
git add scms_flutter/lib/core/theme/app_colors.dart
git commit -m "feat(ui): remap color tokens to Apple system palette"
```

---

### Task A2: Retune typography + theme to the iOS type scale and grouped surfaces

**Files:**
- Modify: `scms_flutter/lib/core/theme/app_text_styles.dart`
- Modify: `scms_flutter/lib/core/theme/app_theme.dart`

**Interfaces:**
- Produces: updated `AppTextStyles` (same names, iOS sizes) and `AppTheme.light`/`AppTheme.dark` with a Cupertino `PageTransitionsTheme`, grouped `scaffoldBackgroundColor`, blurred-nav-ready `AppBarTheme` (transparent, no elevation), 12px buttons, hairline dividers.

- [ ] **Step 1: Retune `app_text_styles.dart`** to iOS sizes/weights (keep all names): `displayLarge` 34/w700/-0.4, `headlineLarge` 28/w700, `headlineMedium` 22/w700, `titleLarge` 17/w600, `titleMedium` 17/w600, `titleSmall` 15/w600, `bodyLarge` 17/w400, `bodyMedium` 15/w400, `bodySmall` 13/w400, `labelLarge` 15/w500, `labelMedium` 13/w500, `labelSmall` 12/w500, `caption` 12/w400. Keep `AppSpacing` as-is.

- [ ] **Step 2: Update `AppTheme.light` and `AppTheme.dark`:**
  - `scaffoldBackgroundColor`: `AppColors.background` / `AppColors.backgroundDark`.
  - `colorScheme`: `primary` = `AppColors.primary` (light) / `AppColors.primaryLight` (dark); `surface` = `AppColors.surface`/`surfaceDark`; `surfaceContainerHighest`/`outlineVariant` → separators.
  - `appBarTheme`: `backgroundColor: Colors.transparent`, `elevation: 0`, `scrolledUnderElevation: 0`, `centerTitle: true`, title uses `titleLarge`.
  - `cardTheme`: color `surface`/`surfaceDark`, `elevation: 0`, radius 12, very soft shadow (`shadowColor` black @ 0.04), margin `EdgeInsets.zero`.
  - Buttons: radius 12, `minimumSize Size(double.infinity, 50)`, elevation 0. `elevatedButton` bg = accent. `textButton`/`outlinedButton` foreground = accent.
  - `inputDecorationTheme`: fill = `surfaceVariant`/`surfaceVariantDark`, radius 12, border hairline `separator`, focused 1.5px accent.
  - `chipTheme`: radius 100 (pill), bg = `surfaceVariant`, selected = accent.
  - `dividerTheme`: color `separator`/`separatorDark`, thickness `0.5`, space `0.5`.
  - Add to BOTH themes:

```dart
pageTransitionsTheme: const PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
),
```

  - Replace any `.withOpacity(` you touch with `.withValues(alpha: )`.

- [ ] **Step 3: Verify** — `flutter analyze` clean; run app, confirm existing screens now render on the light-gray grouped background with blue accent and don't crash. Commit:

```bash
git add scms_flutter/lib/core/theme/app_text_styles.dart scms_flutter/lib/core/theme/app_theme.dart
git commit -m "feat(ui): retune typography + theme to iOS scale and grouped surfaces"
```

---

### Task A3: `PressableScale` motion primitive

**Files:**
- Create: `scms_flutter/lib/presentation/widgets/common/pressable_scale.dart`

**Interfaces:**
- Produces: `PressableScale({required Widget child, VoidCallback? onTap, double pressedScale = 0.98, BorderRadius? borderRadius})`.

- [ ] **Step 1: Implement**

```dart
import 'package:flutter/material.dart';

/// Wraps a tappable surface with a subtle iOS-style press-scale animation.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
    this.borderRadius,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;
  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTapCancel: widget.onTap == null ? null : () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 2: Verify** — `flutter analyze` clean. Commit:

```bash
git add scms_flutter/lib/presentation/widgets/common/pressable_scale.dart
git commit -m "feat(ui): add PressableScale motion primitive"
```

---

### Task A4: `InsetGroupedSection` + `InsetListRow` (the core iOS grouped list)

**Files:**
- Create: `scms_flutter/lib/presentation/widgets/common/inset_grouped_section.dart`
- Create: `scms_flutter/lib/presentation/widgets/common/inset_list_row.dart`

**Interfaces:**
- Produces:
  - `InsetGroupedSection({String? header, String? footer, required List<Widget> children})` — a rounded (12px) surface card with an uppercase caption header, and inset (leading 16px) hairline dividers between children.
  - `InsetListRow({Widget? leading, required String title, String? subtitle, Widget? trailing, bool showChevron = false, VoidCallback? onTap})`.

- [ ] **Step 1: Implement `inset_grouped_section.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// iOS "inset grouped" list section: optional header caption, a rounded card
/// containing [children] separated by leading-inset hairline dividers.
class InsetGroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;

  const InsetGroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final sep = isDark ? AppColors.separatorDark : AppColors.separator;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Divider(height: 0.5, thickness: 0.5, color: sep),
        ));
      }
      rows.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(header!.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(color: secondary)),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: surface,
            child: Column(children: rows),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(footer!,
                style: AppTextStyles.caption.copyWith(color: secondary)),
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Implement `inset_list_row.dart`** (uses `PressableScale` when tappable)

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'pressable_scale.dart';

/// A single row inside an [InsetGroupedSection].
class InsetListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const InsetListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyLarge.copyWith(color: primary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (showChevron) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 20, color: secondary),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return PressableScale(onTap: onTap, child: row);
  }
}
```

- [ ] **Step 3: Verify** — `flutter analyze` clean. Commit:

```bash
git add scms_flutter/lib/presentation/widgets/common/inset_grouped_section.dart scms_flutter/lib/presentation/widgets/common/inset_list_row.dart
git commit -m "feat(ui): add InsetGroupedSection and InsetListRow components"
```

---

### Task A5: `LargeTitleScaffold` (collapsing large title + blurred inline nav bar)

**Files:**
- Create: `scms_flutter/lib/presentation/widgets/common/large_title_scaffold.dart`

**Interfaces:**
- Produces: `LargeTitleScaffold({required String title, List<Widget>? actions, Widget? leading, required List<Widget> slivers, Widget? floatingActionButton, Widget? bottomNavigationBar})`. Renders a `CustomScrollView` with a `SliverAppBar` (`pinned: true`, `expandedHeight: 96`) whose large title collapses into a centered inline title, with a blurred translucent background via `flexibleSpace`.

- [ ] **Step 1: Implement**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// iOS large-title scaffold. Provide content as [slivers]; the large title
/// collapses to a blurred inline nav bar on scroll.
class LargeTitleScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final List<Widget> slivers;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const LargeTitleScaffold({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    required this.slivers,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            leading: leading,
            actions: actions,
            expandedHeight: 96,
            centerTitle: true,
            title: Text(title,
                style: AppTextStyles.titleLarge.copyWith(color: primary)),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.only(left: 16, bottom: 12, right: 16),
                  title: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(title,
                        style: AppTextStyles.displayLarge
                            .copyWith(color: primary)),
                  ),
                  // Hide the big title once collapsed; the pinned inline title
                  // (above) takes over.
                  expandedTitleScale: 1.0,
                ),
              ),
            ),
          ),
          ...slivers,
        ],
      ),
    );
  }
}
```

Note: the pinned `title` and the `FlexibleSpaceBar.title` both show `title`; when expanded the large one dominates, when collapsed the small centered one remains. If double-title overlap is visually distracting during review, set the `SliverAppBar.title` to fade in with a `LayoutBuilder`/opacity — acceptable to refine during the visual check, but the simple version above is the baseline.

- [ ] **Step 2: Verify** — `flutter analyze` clean. Commit:

```bash
git add scms_flutter/lib/presentation/widgets/common/large_title_scaffold.dart
git commit -m "feat(ui): add LargeTitleScaffold with collapsing blurred nav bar"
```

---

### Task A6: `CupertinoSegmentedTabs` filter control

**Files:**
- Create: `scms_flutter/lib/presentation/widgets/common/segmented_tabs.dart`

**Interfaces:**
- Produces: `CupertinoSegmentedTabs({required List<String> segments, required int selectedIndex, required ValueChanged<int> onChanged})`.

- [ ] **Step 1: Implement** an iOS segmented control (rounded pill track, sliding selected chip). Use a `Container` with `AppColors.surfaceVariant` background, radius 8, and an `AnimatedAlign`/`AnimatedContainer` white (or `surface`) selected segment. Selected label `titleSmall` accent-colored; unselected `bodyMedium` secondary. Each segment is a tappable `Expanded`.

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CupertinoSegmentedTabs extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const CupertinoSegmentedTabs({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final selectedFill = isDark ? AppColors.surfaceDark : Colors.white;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final segW = c.maxWidth / segments.length;
        return Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: segW * selectedIndex,
            top: 0,
            bottom: 0,
            width: segW,
            child: Container(
              decoration: BoxDecoration(
                color: selectedFill,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                ],
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < segments.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Center(
                      child: Text(segments[i],
                          style: (i == selectedIndex
                                  ? AppTextStyles.titleSmall
                                  : AppTextStyles.bodyMedium)
                              .copyWith(
                                  color: i == selectedIndex
                                      ? primary
                                      : secondary)),
                    ),
                  ),
                ),
            ],
          ),
        ]);
      }),
    );
  }
}
```

- [ ] **Step 2: Verify** — `flutter analyze` clean. Commit:

```bash
git add scms_flutter/lib/presentation/widgets/common/segmented_tabs.dart
git commit -m "feat(ui): add CupertinoSegmentedTabs filter control"
```

---

### Task A7: Refactor buttons, status pill, stat tile, and hero to the new system

**Files:**
- Modify: `scms_flutter/lib/presentation/widgets/common/scms_button.dart`
- Modify: `scms_flutter/lib/presentation/widgets/complaint/status_badge.dart`
- Modify: `scms_flutter/lib/presentation/widgets/analytics/stats_card.dart`
- Modify: `scms_flutter/lib/presentation/widgets/dashboard/dashboard_hero.dart`

**Interfaces:**
- Preserve every existing constructor signature (`ScmsButton`, `StatusBadge`, `StatsCard`, `DashboardHero`, `HeroStat`) so callers are untouched; only visuals change.

- [ ] **Step 1: `ScmsButton`** — keep `ScmsButtonVariant { primary, secondary, destructive, text }` and all params. Restyle:
  - `primary`: solid accent fill, radius 12, **remove the 18px glow shadow** (iOS buttons are flat) — use no shadow or a 2px @0.15 accent shadow. Wrap in `PressableScale`.
  - `secondary`: **tinted** — background `AppColors.fillTinted(accent)`, accent text, no border, radius 12.
  - `destructive`: solid `systemRed`.
  - `text`: plain accent text.
  - Height default 50.

- [ ] **Step 2: `StatusBadge`** — keep signature. Restyle to a solid-tinted pill: background `color.withValues(alpha: 0.12)`, no border, radius 100, text `color`, weight w600. (Remove the border line.)

- [ ] **Step 3: `StatsCard`** — keep signature. Wrap the numeric value in a count-up:

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: numericValue),
  duration: const Duration(milliseconds: 650),
  curve: Curves.easeOutCubic,
  builder: (_, v, __) => Text(v.round().toString(), style: /* existing */),
)
```

  where `numericValue` is parsed from the existing value; if the value is non-numeric, render it directly. Use `surface` card, radius 12, soft shadow.

- [ ] **Step 4: `DashboardHero`** — reframe from the solid-indigo rounded block to an iOS **large-title greeting on the grouped background**: greeting `bodyMedium` secondary, name `displayLarge` primary, avatar top-right, and the three stats as a row of `InsetGroupedSection`-style white stat tiles (reuse `StatsCard` look) instead of translucent-on-color cards. Keep `greeting/name/roleBadge/avatarUrl/stats` params and `HeroStat`. Remove white-on-primary text.

- [ ] **Step 5: Verify** — `flutter analyze` clean; run app and confirm dashboards, buttons, and status badges look correct in light + dark. Then **build sanity:** `flutter build apk --debug`. Commit:

```bash
git add scms_flutter/lib/presentation/widgets/common/scms_button.dart scms_flutter/lib/presentation/widgets/complaint/status_badge.dart scms_flutter/lib/presentation/widgets/analytics/stats_card.dart scms_flutter/lib/presentation/widgets/dashboard/dashboard_hero.dart
git commit -m "feat(ui): restyle buttons, status pill, stat tile, and hero to iOS-clean"
```

- [ ] **Step 6: Phase A changelog** — append a Phase A entry to `CONTEXT.md` changelog. Commit:

```bash
git add CONTEXT.md
git commit -m "docs: log Phase A (iOS-clean foundation) in CONTEXT.md"
```

---

# PHASE B — Student flow screens

Each task converts one (or a small cluster of) screen(s) onto the Phase A components. Do NOT change BLoC events, route names, or backend fields. For each: replace `AppScaffold`/`gradient_app_bar`/glass chrome with `LargeTitleScaffold` (list screens) or a standard `Scaffold` + transparent app bar (form/detail screens); express content as `InsetGroupedSection` + `InsetListRow`; use `CupertinoSegmentedTabs` for filters; wrap tappable cards in `PressableScale`.

### Task B1: Splash + Onboarding + Login

**Files:**
- Modify: `scms_flutter/lib/presentation/pages/splash/splash_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/onboarding/onboarding_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/auth/login_page.dart`

- [ ] **Step 1: Splash** — centered app icon/logo on `AppColors.background`, app name in `displayLarge`, a small `CupertinoActivityIndicator`-style spinner. Keep the existing navigation/redirect logic untouched.
- [ ] **Step 2: Onboarding** — full-bleed pages with large title (`displayLarge`), body (`bodyLarge` secondary), page dots in accent, and a bottom `ScmsButton` (primary) "Continue"/"Get started". Keep existing page controller/skip logic.
- [ ] **Step 3: Login** — centered logo + `displayLarge` welcome + subtitle, then the Google sign-in button styled as an iOS tinted/secondary button (keep the existing sign-in call and error handling exactly). Background `AppColors.background`.
- [ ] **Step 4: Verify** — analyze clean; visually check all three in light + dark; confirm sign-in still works. Commit:

```bash
git add scms_flutter/lib/presentation/pages/splash scms_flutter/lib/presentation/pages/onboarding scms_flutter/lib/presentation/pages/auth
git commit -m "feat(ui): redesign splash, onboarding, and login to iOS-clean"
```

---

### Task B2: Student home dashboard

**Files:**
- Modify: `scms_flutter/lib/presentation/pages/home/home_page.dart`

- [ ] **Step 1:** Replace the `AppScaffold` + `SliverToBoxAdapter(_buildHeader)` structure with a `CustomScrollView` (or `LargeTitleScaffold`) whose first sliver is the redesigned `DashboardHero` (now grouped-style, from A7). Keep `QuickActionsRow`, `AttentionCard`, `StatusBreakdownRing`, `SectionHeader`, `ComplaintCard`, the `BlocBuilder`s, and the `LoadMyComplaints`/`RefreshComplaints` events **exactly**.
- [ ] **Step 2:** Restyle `QuickActionsRow` targets to iOS "tinted circle icon + caption" tiles (edit `quick_actions_row.dart` if needed, keeping its `QuickAction` API). Wrap quick actions and recent `ComplaintCard`s in `PressableScale` (or ensure `ComplaintCard` already does via B4). Keep the FAB → `Routes.submitComplaint`.
- [ ] **Step 3: Verify** — analyze clean; check home in light + dark; refresh + tap-through still work. Commit:

```bash
git add scms_flutter/lib/presentation/pages/home/home_page.dart scms_flutter/lib/presentation/widgets/dashboard/quick_actions_row.dart
git commit -m "feat(ui): redesign student home dashboard to iOS-clean"
```

---

### Task B3: Submit complaint

**Files:**
- Modify: `scms_flutter/lib/presentation/pages/complaint/submit_complaint_page.dart`

- [ ] **Step 1:** Convert the form to iOS grouped sections: a "Details" `InsetGroupedSection` (title field, description field), a "Category & Tags" section (`category_selector_widget`, `tag_selector_widget`), a "Photos" section (`media_capture_widget`), a "Location" row. Keep `scms_text_field`, the 800ms debounced grammar/categorize calls, `grammar_correction_banner`, `duplicate_warning_banner`, and the submit payload field names (`title`, `media`, `tags` JSON string, optional `departmentId`) **unchanged**.
- [ ] **Step 2:** App bar: transparent, centered title "New Complaint", a plain "Cancel" leading and a primary "Submit" action (or keep bottom `ScmsButton`). Preserve all `SubmitComplaintBloc` events.
- [ ] **Step 3: Verify** — analyze clean; submit a complaint end-to-end on device (grammar banner, duplicate banner, photo capture, submit succeeds); check light + dark. Commit:

```bash
git add scms_flutter/lib/presentation/pages/complaint/submit_complaint_page.dart
git commit -m "feat(ui): redesign submit-complaint form to iOS grouped layout"
```

---

### Task B4: Complaint card + My Complaints + All Complaints (list screens)

**Files:**
- Modify: `scms_flutter/lib/presentation/widgets/complaint/complaint_card.dart`
- Modify: `scms_flutter/lib/presentation/pages/complaint/my_complaints_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/complaints/all_complaints_page.dart`

- [ ] **Step 1: `ComplaintCard`** — re-express as an inset row: leading category/severity icon in a tinted circle, title (`bodyLarge`), subtitle (category · time, `bodySmall` secondary), trailing `StatusBadge` + chevron; wrap in `PressableScale`. Keep its constructor (`complaint`, `onTap`).
- [ ] **Step 2: My Complaints** — `LargeTitleScaffold` title "My Complaints"; a `CupertinoSegmentedTabs` filter (e.g. All / Active / Resolved) driven by existing filter state if present, else local `setState`; list rendered as `InsetGroupedSection`(s) of `ComplaintCard` rows. Keep the BLoC load/refresh events and `context.push('/complaint/:id')`.
- [ ] **Step 3: All Complaints** — same treatment, title "All Complaints"; keep existing pagination/search/filter logic and events.
- [ ] **Step 4: Verify** — analyze clean; both lists render, filter/segment works, tap → detail; light + dark. Commit:

```bash
git add scms_flutter/lib/presentation/widgets/complaint/complaint_card.dart scms_flutter/lib/presentation/pages/complaint/my_complaints_page.dart scms_flutter/lib/presentation/pages/complaints/all_complaints_page.dart
git commit -m "feat(ui): redesign complaint card and list screens to iOS-clean"
```

---

### Task B5: Complaint detail + Rating + Duplicate complaints

**Files:**
- Modify: `scms_flutter/lib/presentation/pages/complaint/complaint_detail_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/complaint/rating_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/complaint/duplicate_complaints_page.dart`

- [ ] **Step 1: Detail** — transparent centered app bar with the complaint number; body as grouped sections: a status header block (`StatusBadge` + `SlaTimerWidget`), "Details" section (description, category, department, location), a "Photos" horizontal gallery, and a "Timeline" section built from `ComplaintUpdate`s as `InsetListRow`s with a leading colored dot. Keep all data wiring and any action buttons' handlers.
- [ ] **Step 2: Rating** — grouped "Rate resolution" section with large star selector (accent) + a `scms_text_field` for `ratingComment` (keep the field name); primary `ScmsButton` submit. Keep the real repo call.
- [ ] **Step 3: Duplicate complaints** — `LargeTitleScaffold` "Possible Duplicates"; AI-powered list as `InsetGroupedSection` of `ComplaintCard`/`InsetListRow` with a similarity chip. Keep the existing AI list logic.
- [ ] **Step 4: Verify** — analyze clean; open a complaint (timeline, photos), rate it, view duplicates; light + dark. Then **build sanity:** `flutter build apk --debug`. Commit:

```bash
git add scms_flutter/lib/presentation/pages/complaint/complaint_detail_page.dart scms_flutter/lib/presentation/pages/complaint/rating_page.dart scms_flutter/lib/presentation/pages/complaint/duplicate_complaints_page.dart
git commit -m "feat(ui): redesign complaint detail, rating, and duplicates to iOS-clean"
```

- [ ] **Step 5: Phase B changelog** — append Phase B entry to `CONTEXT.md`. Commit:

```bash
git add CONTEXT.md
git commit -m "docs: log Phase B (student flow redesign) in CONTEXT.md"
```

---

# PHASE C — Staff / SR / Admin screens

Same conversion rules. These screens already use `DashboardHero`, `SrSummaryHeader`, `BreakdownBars`, `TrendSparkline`, `ComplaintsChart`, `StatsCard` — which Phase A already restyled, so much falls out for free. Focus on scaffold/chrome + grouping.

### Task C1: Staff dashboard + staff complaint detail

**Files:**
- Modify: `scms_flutter/lib/presentation/pages/staff/staff_dashboard_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/staff/staff_complaint_detail_page.dart`

- [ ] **Step 1: Staff dashboard** — grouped hero + `StatsCard` row + assigned-complaints list as `InsetGroupedSection` of `ComplaintCard`. Keep all BLoC events and status-update actions.
- [ ] **Step 2: Staff detail** — same grouped-detail treatment as B5 Step 1, plus the staff status-change controls styled as `ScmsButton`s / an iOS action row. Keep the `status` field name and update handlers.
- [ ] **Step 3: Verify** — analyze clean; staff can view + update a complaint; light + dark. Commit:

```bash
git add scms_flutter/lib/presentation/pages/staff
git commit -m "feat(ui): redesign staff dashboard and detail to iOS-clean"
```

---

### Task C2: SR dashboard + SR review detail

**Files:**
- Modify: `scms_flutter/lib/presentation/pages/sr/sr_dashboard_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/sr/sr_review_detail_page.dart`

- [ ] **Step 1: SR dashboard** — keep `SrSummaryHeader`/`BreakdownBars`; wrap the review queue as grouped `ComplaintCard` rows; keep the review-queue BLoC + auto-approve context.
- [ ] **Step 2: SR review detail** — grouped detail + approve/reject actions as `ScmsButton` (primary/destructive). Keep all `SrReviewBloc` events and payloads.
- [ ] **Step 3: Verify** — analyze clean; SR can approve/reject; light + dark. Commit:

```bash
git add scms_flutter/lib/presentation/pages/sr
git commit -m "feat(ui): redesign SR dashboard and review detail to iOS-clean"
```

---

### Task C3: Admin dashboard + admin list + stats

**Files:**
- Modify: `scms_flutter/lib/presentation/pages/admin/admin_dashboard_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/admin/admin_complaints_list_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/stats/stats_page.dart`

- [ ] **Step 1: Admin dashboard** — grouped hero + `StatsCard` grid + `ComplaintsChart`/`TrendSparkline` inside `InsetGroupedSection` cards. Keep analytics BLoC wiring.
- [ ] **Step 2: Admin list** — `LargeTitleScaffold` + `CupertinoSegmentedTabs` filters + grouped `ComplaintCard` rows. Keep filter/search/pagination logic.
- [ ] **Step 3: Stats page** — charts + KPIs in grouped sections; ensure chart colors pull from the remapped `AppColors` system palette (verify `complaints_chart.dart` uses tokens, not hardcoded hex; update to tokens if hardcoded).
- [ ] **Step 4: Verify** — analyze clean; admin screens render; charts readable in light + dark. Then **build sanity:** `flutter build apk --debug`. Commit:

```bash
git add scms_flutter/lib/presentation/pages/admin scms_flutter/lib/presentation/pages/stats scms_flutter/lib/presentation/widgets/analytics/complaints_chart.dart
git commit -m "feat(ui): redesign admin dashboard, list, and stats to iOS-clean"
```

- [ ] **Step 5: Phase C changelog** — append Phase C entry to `CONTEXT.md`. Commit:

```bash
git add CONTEXT.md
git commit -m "docs: log Phase C (staff/SR/admin redesign) in CONTEXT.md"
```

---

# PHASE D — Shell, settings, profile + final polish

### Task D1: Blurred floating tab bar (main shell)

**Files:**
- Modify: `scms_flutter/lib/presentation/pages/shell/main_shell.dart`

- [ ] **Step 1:** Replace the `BottomNavigationBar` with a custom blurred tab bar: a `BackdropFilter`(blur 18) over a translucent `surface` @ ~0.7, hairline top separator, `SafeArea` bottom padding, tab items = icon + `labelSmall` caption, selected = accent, unselected = secondary, tap feedback via `PressableScale`. Keep the exact tab list, indices, and `go_router` branch-switching logic. Do NOT change which pages map to which tab.
- [ ] **Step 2: Verify** — analyze clean; tab switching works for every role; bar blurs over scrolled content; light + dark. Commit:

```bash
git add scms_flutter/lib/presentation/pages/shell/main_shell.dart
git commit -m "feat(ui): replace bottom nav with blurred floating iOS tab bar"
```

---

### Task D2: Settings + Profile

**Files:**
- Modify: `scms_flutter/lib/presentation/pages/settings/settings_page.dart`
- Modify: `scms_flutter/lib/presentation/pages/profile/profile_page.dart`

- [ ] **Step 1: Settings** — `LargeTitleScaffold` "Settings"; options as `InsetGroupedSection`s of `InsetListRow` (leading tinted icon, title, trailing switch/chevron/value). Group logically (Account, Notifications, Appearance, About). Keep every existing setting's handler (theme toggle, sign-out, etc.) and any BLoC calls.
- [ ] **Step 2: Profile** — large avatar header, name `displayLarge`, role pill, then grouped info rows + a destructive "Sign out" `ScmsButton`. Keep the sign-out handler and data wiring.
- [ ] **Step 3: Verify** — analyze clean; settings + profile render; theme toggle + sign-out work; light + dark. Commit:

```bash
git add scms_flutter/lib/presentation/pages/settings scms_flutter/lib/presentation/pages/profile
git commit -m "feat(ui): redesign settings and profile to iOS-clean grouped lists"
```

---

### Task D3: Final full-app polish pass

**Files:** any touched during review.

- [ ] **Step 1:** Walk every screen in **light and dark**, both a common and an edge role (student + admin). Check: consistent horizontal padding (16), grouped background everywhere, no leftover indigo/gradient chrome, no glass-on-content remnants, status pills readable, chevrons/tap targets consistent, empty/loading/error states (`EmptyStateWidget`, `error_widget`, `loading_overlay`) restyled to match.
- [ ] **Step 2:** Fix any inconsistencies found (spacing, stray `withOpacity`, hardcoded colors → tokens). Restyle `EmptyStateWidget`, `error_widget.dart`, and `loading_overlay.dart` if they still look pre-redesign.
- [ ] **Step 3: Verify** — `flutter analyze` → `No issues found!`; `flutter build apk --debug` succeeds. Commit:

```bash
git add -A
git commit -m "polish(ui): final iOS-clean consistency pass across all screens"
```

- [ ] **Step 4: Phase D changelog** — append Phase D entry + a redesign summary to `CONTEXT.md`. Commit:

```bash
git add CONTEXT.md
git commit -m "docs: log Phase D (shell/settings/polish) — iOS-clean redesign complete"
```

---

## Self-Review notes

- **Spec coverage:** tokens (A1–A2) ✓; component library — grouped section/row (A4), large-title scaffold (A5), segmented tabs (A6), tab bar (D1), buttons/pill/stat/hero (A7), press-scale (A3), Cupertino transitions (A2) ✓; all screens — student (B1–B5), staff/SR/admin/stats (C1–C3), shell/settings/profile (D1–D2) ✓; light+dark verified every task, final pass (D3) ✓; presentation-only + field-name preservation stated in Global Constraints and repeated per task ✓.
- **No logic drift:** every screen task explicitly says "keep BLoC events / route names / backend field names unchanged."
- **Verification adapted:** no fake widget tests invented; verification is analyze + build + visual (documented up front), matching this repo's reality (`CLAUDE.md`: no Flutter test suite requirement beyond `flutter analyze` clean).
- **Type consistency:** component constructor signatures defined in A3–A7 are the exact names referenced in B–D (`InsetGroupedSection`, `InsetListRow`, `LargeTitleScaffold`, `CupertinoSegmentedTabs`, `PressableScale`, `ScmsButton`, `StatusBadge`, `StatsCard`, `DashboardHero`/`HeroStat`).
