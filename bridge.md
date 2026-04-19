# BRIDGE -- Zeno by Yarzo

> **HOW THIS FILE WORKS**
> - CURRENT TASK = The one and only active task. Execute it completely before doing anything else.
> - COMPLETED TASKS = Archive. Do not re-execute anything listed there.
> - When you finish: fill in the RESULT section accurately, then stop. Claude writes the next task.
> - Language: English only. No Tamil. No exceptions.
> - Do not invent tasks. Do not skip steps. Do not do work that is not listed here.

---

## COMPLETED TASKS ARCHIVE

### BRIDGE-005 to BRIDGE-012 -- ALL DONE
- Full rebranding, all bugs fixed, icon updated, APK: 24.7MB.

### BRIDGE-013 -- Final Bug Fixes Round 5
**Status:** DONE
- BUG-26: ScaffoldMessenger -> feedbackProvider in nl_input_bar. ✅
- BUG-27: onChanged listener added to NL input bar. ✅
- BUG-28: Skipped -- initialValue is correct in Flutter 3.41+.
- IMP-14: Task card font size 18 -> 15. ✅
- flutter analyze: 0 issues.

---

## CURRENT TASK
**Status:** TODO
**ID:** BRIDGE-014

---

### TASK: Material Icon Rule Fixes + Light Theme Completion + Final Production Build

**Step 0 -- Before you write a single line of code:**
Read `project_rules.md` fully.

**Context:** Claude deep-reviewed `calendar_screen.dart`, `celebration_overlay.dart`, and `app_theme.dart` and found 2 icon rule violations and an incomplete light theme.

---

## SECTION A -- ICON RULE VIOLATIONS

### BUG-29
**File:** `lib/features/tasks/presentation/calendar_screen.dart`
**Location:** `_buildTimelineItem()` method -- inside the timeline dot container.
**Problem:** `Icons.check` (Material icon) used instead of `LucideIcons`. Violates Rule 1.

**How to find:** Search for `Icons.check` in `calendar_screen.dart`.

**Current code:**
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
**Location:** Inside `_CelebrationWidgetState.build()`, in the center checkmark `Icon` widget.
**Problem:** `Icons.check_rounded` (Material icon) used instead of `LucideIcons`. Violates Rule 1.

**How to find:** Search for `Icons.check_rounded` in `celebration_overlay.dart`.

**Current code:**
```dart
icon: Icons.check_rounded,
```

**Fix:**
```dart
icon: LucideIcons.checkCircle,
```

**Also add import** to `celebration_overlay.dart` if not already present:
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

---

## SECTION B -- LIGHT THEME COMPLETION

### IMP-15
**File:** `lib/core/theme/app_theme.dart`
**Location:** Inside `lightTheme`, the `textTheme:` block.

**Problem:** The light theme `textTheme` only defines 6 styles (`displayLarge`, `headlineLarge`, `headlineMedium`, `bodyLarge`, `bodyMedium`, `labelLarge`). Many styles used throughout the app (`displaySmall`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `labelSmall`, `labelMedium`, `bodySmall`) are missing. In light mode, these fall back to Flutter defaults with wrong colors.

**Fix:** Add the missing text styles to `lightTheme`. Add these entries inside the `textTheme: const TextTheme(...)` block of `lightTheme`:

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

**Also check `darkTheme`** and add the same missing styles there using `AppColors.onSurface` and `AppColors.onSurfaceVariant` for dark colors. Match the same pattern.

---

## SECTION C -- FINAL PRODUCTION BUILD

After all fixes:

### STEP-01: Analyze
```bash
flutter analyze --no-fatal-infos
```
Expected: 0 errors, 0 warnings.

### STEP-02: Build final AAB (Play Store)
```powershell
flutter build appbundle --release `
  --obfuscate `
  --split-debug-info=build/debug-info `
  --dart-define=GEMINI_API_KEY=[REDACTED] `
  --dart-define=NVIDIA_API_KEY=none `
  --dart-define=GROQ_API_KEY=[REDACTED]
```

### STEP-03: Build final APK (device testing)
```powershell
flutter build apk --release `
  --obfuscate `
  --split-debug-info=build/debug-info `
  --target-platform android-arm64 `
  --dart-define=GEMINI_API_KEY=[REDACTED] `
  --dart-define=NVIDIA_API_KEY=none `
  --dart-define=GROQ_API_KEY=[REDACTED]
```

### STEP-04: Measure sizes
```powershell
$aab = (Get-Item "build\app\outputs\bundle\release\app-release.aab").Length / 1MB
$apk = (Get-Item "build\app\outputs\flutter-apk\app-release.apk").Length / 1MB
Write-Host "FINAL -- AAB: $([math]::Round($aab, 1)) MB | APK: $([math]::Round($apk, 1)) MB"
```

---

## ABSOLUTE RULES

| Rule | Correct | Wrong |
|------|---------|-------|
| Icons | `LucideIcons.sparkles` | `Icons.star` |
| Feedback | `ref.read(feedbackProvider.notifier).showMessage(...)` | `ScaffoldMessenger...` |
| IDs | `AppUtils.generateId(prefix: 'task')` | `uuid.v4()` |
| Fonts | `theme.textTheme.bodyMedium` | `GoogleFonts.inter(...)` |
| Tasks | `ref.read(tasksProvider.notifier).addTask(task)` | Direct Firestore |

---

## RESULT
**Status:** PENDING

When complete, fill in every field:
- BUG-29 Icons.check in calendar fixed: Yes / No
- BUG-30 Icons.check_rounded in celebration fixed: Yes / No
- IMP-15 Light theme text styles completed: Yes / No
- Dark theme text styles completed: Yes / No
- flutter analyze: (paste exact output)
- AAB size: ___MB
- APK size: ___MB
- Any blockers: ___

### PATHS FOR CLAUDE
- Implementation Plan: `C:\Users\acer\.gemini\antigravity\brain\142dfaf3-d3c7-4400-8641-76d000e61970\implementation_plan.md`
- Walkthrough: `C:\Users\acer\.gemini\antigravity\brain\142dfaf3-d3c7-4400-8641-76d000e61970\walkthrough.md`
