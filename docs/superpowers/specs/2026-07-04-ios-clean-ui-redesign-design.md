# SCMS UI/UX Redesign — iOS-Clean Design System

**Date:** 2026-07-04
**Scope:** Full-app visual/UX redesign of the Flutter client (`scms_flutter/`)
**Status:** Approved design — ready for implementation planning

---

## 1. Goal

Elevate the SCMS Flutter app from its current (already-decent) indigo/glassmorphism
Material 3 look into a genuinely polished, distinctive, **iOS / Apple-clean** modern app.
This is a **presentation-layer redesign only** — no backend, API, BLoC, repository, or
data-model changes. Business logic, routing targets, and network contracts are untouched.

### Reference direction
Apple's native iOS design language: grouped inset cards, large collapsing titles,
generous whitespace, soft depth, tasteful blur on chrome, and the Apple system color
palette. The app should feel like a first-party iOS app while remaining a
cross-platform Flutter build (Material `useMaterial3: true` retained).

### Locked decisions
- **Aesthetic:** iOS / Apple clean
- **Scope:** Full app — every screen and role (student, staff, SR, admin, auth, settings)
- **Signature accent:** Apple system blue — `#007AFF` (light) / `#0A84FF` (dark)
- **Motion:** Subtle & tasteful — Cupertino page transitions, press-scale feedback,
  count-up stat numbers, collapsing blurred large-title header

---

## 2. Design system / tokens

All tokens live in `lib/core/theme/` (`app_colors.dart`, `app_theme.dart`,
`app_text_styles.dart`). These are rewritten; the rest of the app inherits the new look
through `Theme.of(context)` and the shared component library.

### 2.1 Color

Adopt Apple's system palette. `AppColors` keeps its existing public API surface (same
constant/method names where they are referenced across the codebase) so screens compile,
but the underlying values change.

**Accent**
- `primary` (accent): `#007AFF` light / `#0A84FF` dark
- Tinted accent background: accent @ ~15% opacity for tinted buttons/chips

**Backgrounds — iOS grouped model**
- Light: base `#F2F2F7` (systemGroupedBackground), card surface `#FFFFFF`,
  secondary surface `#F2F2F7`
- Dark: base `#000000`, elevated surface `#1C1C1E`, secondary elevated `#2C2C2E`
- Separator (hairline): `#C6C6C8` light / `#38383A` dark, inset from the leading edge

**Semantic system colors**
- red `#FF3B30`, orange `#FF9500`, yellow `#FFCC00`, green `#34C759`,
  teal `#30B0C7`, indigo `#5E5CE6`, plus the iOS gray ramp for text/fills

**Status colors — remapped to the system palette** (kept behind
`AppColors.statusColor(String)` so it stays the single source of truth):
- `OPEN` → gray, `PENDING_SR_REVIEW` → indigo `#5E5CE6`, `ASSIGNED` → blue `#007AFF`,
  `IN_PROGRESS` → orange `#FF9500`, `RESOLVED` → green `#34C759`,
  `CLOSED` → dark gray, `REJECTED` → red `#FF3B30`
- Severity: high → red, medium → orange, low → yellow
- AI confidence: high → green, medium → orange, low → red (thresholds unchanged)

**Glass tokens:** the frosted-glass *content* tokens (`glassFillLight` etc.) are retired
from content surfaces. Blur is retained **only** where iOS uses it: the collapsing
nav-bar background and the floating bottom tab bar. Legacy gradient tokens are removed or
flattened; nothing on screen renders as a gradient.

### 2.2 Typography

Retain **Inter** via `google_fonts` (clean, close to SF Pro; avoids shipping SF).
Retune the type scale to iOS:

| Role         | Size / weight        | Usage                              |
|--------------|----------------------|------------------------------------|
| Large Title  | 34 / bold, -0.4 ls   | Collapsing screen headers          |
| Title 1      | 28 / bold            | Section heroes                     |
| Title 2      | 22 / bold            | Card/group headings                |
| Headline     | 17 / semibold        | List-row titles, emphasized body   |
| Body         | 17 / regular         | Default body text                  |
| Subhead      | 15 / regular         | Secondary row text                 |
| Footnote     | 13 / regular         | Metadata, timestamps               |
| Caption      | 12 / regular         | Labels, chips                      |

`app_text_styles.dart` and the `textTheme` in `app_theme.dart` are updated to match; the
Material `textTheme` slots are mapped so existing `Theme.of(context).textTheme.*` usages
pick up the new scale.

### 2.3 Shape & depth
- Cards / grouped sections: 10–12px corner radius (continuous/rounded), no heavy elevation
- Separators: hairline, inset ~16px from the leading edge (iOS grouped-list convention)
- Shadows: very soft, low-spread (replace the current 20px glassy shadows)
- Buttons: 12px radius, 50px min height

---

## 3. Shared component library

Rebuilt once in `lib/presentation/widgets/`, reused across all screens. Existing widget
files are refactored in place where a 1:1 replacement exists so importing screens need
minimal churn; new primitives are added as new files.

| Component | File (new or refactor) | Purpose |
|-----------|------------------------|---------|
| `InsetGroupedSection` | new `common/inset_grouped_section.dart` | iOS grouped card container: optional header, rounded corners, inset hairline dividers between children |
| `InsetListRow` | new `common/inset_list_row.dart` | Row: leading icon/avatar, title + subtitle, trailing value + chevron; `PressableScale` tap feedback |
| `LargeTitleScaffold` | new `common/large_title_scaffold.dart` | `CustomScrollView` scaffold with a collapsing large title that shrinks to a blurred inline nav bar on scroll. Replaces `gradient_app_bar.dart` |
| `CupertinoSegmentedTabs` | new `common/segmented_tabs.dart` | iOS segmented control for filters (All / Mine / status) |
| `AppTabBar` | refactor `shell/main_shell.dart` bottom bar | Blurred floating bottom tab bar replacing `BottomNavigationBar` |
| Buttons | refactor `common/scms_button.dart` | Three iOS styles: **filled** (accent), **tinted** (accent @15% bg), **plain** (accent text) |
| `StatusPill` | refactor `complaint/status_badge.dart` | Rounded status pill using remapped status colors |
| `StatTile` | refactor `analytics/stats_card.dart` | Stat card with count-up animation |
| `ComplaintCard` | refactor `complaint/complaint_card.dart` | Re-expressed as an inset grouped row |
| `PressableScale` | new `common/pressable_scale.dart` | Wraps tappable surfaces with a 0.98 press-scale animation |
| `DashboardHero` | refactor `dashboard/dashboard_hero.dart` | Large-title greeting + stat row in the new system |

Motion is wired globally via a `PageTransitionsTheme` (Cupertino-style transition on all
platforms) added to both light and dark `ThemeData`.

---

## 4. Screens

All screens are redesigned. Backend calls, BLoC events/states, route names, and
navigation targets are preserved exactly — only widget trees and styling change.

**Student flow:** `splash`, `onboarding`, `auth/login`, `home` (dashboard),
`complaint/submit`, `complaint/my_complaints`, `complaints/all_complaints`,
`complaint/complaint_detail`, `complaint/rating`, `complaint/duplicate_complaints`.

**Staff / SR / Admin:** `staff/staff_dashboard`, `staff/staff_complaint_detail`,
`sr/sr_dashboard`, `sr/sr_review_detail`, `admin/admin_dashboard`,
`admin/admin_complaints_list`, `stats/stats_page`.

**Shell & settings:** `shell/main_shell` (tab shell), `settings/settings_page`,
`profile/profile_page`.

Every redesigned screen is verified in **both light and dark mode**.

---

## 5. Phasing

Each phase is independently reviewable; the app stays runnable and `flutter analyze`
stays clean between phases.

- **Phase A — Foundation:** rewrite tokens (`app_colors`, `app_theme`, `app_text_styles`);
  build/refactor the shared component library (Section 3); wire the global page transition
  and `PressableScale`. No screen rewrites yet, but screens must still compile and render.
- **Phase B — Student flow:** redesign all student-flow screens onto the new components.
- **Phase C — Staff / SR / Admin:** redesign staff, SR, admin, and analytics/stats screens.
- **Phase D — Shell & settings + polish:** redesign the tab shell (blurred tab bar),
  settings, and profile; final light/dark pass across the whole app.

---

## 6. Constraints & non-goals

- **Presentation only.** No changes to `data/`, `domain/`, BLoC logic, repositories,
  datasources, routing *targets*, backend, or the Python AI service.
- Preserve the response-envelope / DioClient behavior and all field-name conventions
  documented in `CLAUDE.md`.
- Keep `AppColors` / `AppTextStyles` public API stable where referenced, to limit churn.
- `flutter analyze` must show **"No issues found"** at the end of each phase.
- No new heavyweight dependencies beyond what Flutter/`google_fonts` already provide
  (blur via `BackdropFilter`, transitions via built-in `PageTransitionsBuilder`).
- Respect `TEAM_WORKDIVISION.md` boundaries; update `CONTEXT.md` changelog after each phase.

---

## 7. Success criteria

- Every listed screen visibly redesigned in the iOS-clean language, in light **and** dark.
- Consistent system: all screens share the same tokens, grouped-list components, buttons,
  status pills, and motion.
- `flutter analyze` clean; app builds and runs; no behavioral/logic regressions.
- The result reads as a cohesive, first-party-quality iOS-style app.
