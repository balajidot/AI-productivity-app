# BRIDGE -- Zeno by Yarzo

> **HOW THIS FILE WORKS**
> - CURRENT TASK = The one and only active task. Execute it completely before doing anything else.
> - COMPLETED TASKS = Archive. Do not re-execute anything listed there.
> - When you finish: fill in the RESULT section accurately, then stop. Claude writes the next task.
> - Language: English only. No Tamil. No exceptions.
> - Do not invent tasks. Do not skip steps. Do not do work that is not listed here.

---

## COMPLETED TASKS ARCHIVE

### BRIDGE-005 to BRIDGE-013 -- ALL DONE
- Full rebranding, all bugs fixed, new icon, asset cleanup.
- APK: 24.7MB. AAB: 50.5MB. flutter analyze: 0 issues throughout.

### BRIDGE-014 -- Icon Rule Fixes + Light Theme Completion
**Status:** DONE
- BUG-29 & BUG-30 fixed: Replaced Material Icons with LucideIcons in calendar and celebration overlay.
- IMP-15 fixed: Completed textTheme for both light and dark themes.
- flutter analyze: 0 issues.
- Git Push: Completed and secrets redacted from history.

---

## CURRENT TASK
**Status:** PENDING
**ID:** BRIDGE-015

---

### TASK: [Awaiting next instructions]

---

### TASK: Icon Rule Fixes + Light Theme Completion

**Step 0 -- Before you write a single line of code:**
Read `project_rules.md` fully.

**Context:** Claude found 2 icon rule violations and incomplete light theme text styles.
Do NOT run a build. Run `flutter analyze` only at the end.

---

## SECTION A -- ICON RULE VIOLATIONS

### BUG-29
**File:** `lib/features/tasks/presentation/calendar_screen.dart`
**Location:** `_buildTimelineItem()` -- inside the timeline dot container.
**Problem:** `Icons.check` used instead of `LucideIcons.check`. Rule violation.

**Find:** Search `Icons.check` in `calendar_screen.dart`

**Current:**
```dart
child: isCompleted
    ? Icon(Icons.check, size: 8, color: theme.colorScheme.surface)
    : null,
```

**Fix:**
```dart
child: isCompleted
    ? Icon(LucideIcons.check, size: 8, color: theme.colorScheme.surface)
    : null,
```

---

### BUG-30
**File:** `lib/features/dashboard/presentation/widgets/celebration_overlay.dart`
**Location:** Center checkmark Icon widget inside `_CelebrationWidgetState.build()`
**Problem:** `Icons.check_rounded` used. Rule violation.

**Find:** Search `Icons.check_rounded` in `celebration_overlay.dart`

**Current:**
```dart
icon: Icons.check_rounded,
```

**Fix:**
```dart
icon: LucideIcons.checkCircle,
```

**Add import** if not present:
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

---

## SECTION B -- LIGHT + DARK THEME COMPLETION

### IMP-15
**File:** `lib/core/theme/app_theme.dart`

**Problem:** Both `darkTheme` and `lightTheme` are missing these text styles:
`displaySmall`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `labelSmall`, `labelMedium`, `bodySmall`

These are used throughout the app. Without them, Flutter falls back to defaults with wrong colors.

**Fix for `darkTheme`** -- add inside `textTheme: const TextTheme(...)`:
```dart
displaySmall: TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: AppColors.onSurface,
  letterSpacing: -0.5,
),
headlineSmall: TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: AppColors.onSurface,
),
titleLarge: TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: AppColors.onSurface,
),
titleMedium: TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: AppColors.onSurface,
),
titleSmall: TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: AppColors.onSurface,
),
labelSmall: TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  color: AppColors.onSurfaceVariant,
  letterSpacing: 0.5,
),
labelMedium: TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: AppColors.onSurfaceVariant,
),
bodySmall: TextStyle(
  fontSize: 12,
  color: AppColors.onSurfaceVariant,
  height: 1.4,
),
```

**Fix for `lightTheme`** -- add inside `textTheme: const TextTheme(...)`:
```dart
displaySmall: TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: AppColors.lightOnSurface,
  letterSpacing: -0.5,
),
headlineSmall: TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: AppColors.lightOnSurface,
),
titleLarge: TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: AppColors.lightOnSurface,
),
titleMedium: TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: AppColors.lightOnSurface,
),
titleSmall: TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: AppColors.lightOnSurface,
),
labelSmall: TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  color: AppColors.lightOnSurfaceVariant,
  letterSpacing: 0.5,
),
labelMedium: TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: AppColors.lightOnSurfaceVariant,
),
bodySmall: TextStyle(
  fontSize: 12,
  color: AppColors.lightOnSurfaceVariant,
  height: 1.4,
),
```

---

## SECTION C -- VERIFICATION ONLY

```bash
flutter analyze --no-fatal-infos
```
Expected: 0 errors, 0 warnings.

**DO NOT run flutter build. Analyze only.**

---

## ABSOLUTE RULES

| Rule | Correct | Wrong |
|------|---------|-------|
| Icons | `LucideIcons.sparkles` | `Icons.star` |
| Feedback | `ref.read(feedbackProvider.notifier).showMessage(...)` | `ScaffoldMessenger...` |
| IDs | `AppUtils.generateId(prefix: 'task')` | `uuid.v4()` |
| Fonts | `theme.textTheme.bodyMedium` | `GoogleFonts.inter(...)` |

---

## RESULT
**Status:** DONE
- BUG-29 Icons.check in calendar fixed: Yes
- BUG-30 Icons.check_rounded in celebration fixed: Yes
- IMP-15 Dark theme text styles added: Yes
- IMP-15 Light theme text styles added: Yes
- flutter analyze: No issues found!
- Any blockers: None

### PATHS FOR CLAUDE
- Implementation Plan: `C:\Users\acer\.gemini\antigravity\brain\142dfaf3-d3c7-4400-8641-76d000e61970\implementation_plan.md`
- Walkthrough: `C:\Users\acer\.gemini\antigravity\brain\142dfaf3-d3c7-4400-8641-76d000e61970\walkthrough.md`
