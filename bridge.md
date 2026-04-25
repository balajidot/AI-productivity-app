# BRIDGE -- Zeno by Yarzo

> **HOW THIS FILE WORKS**
> - CURRENT TASK = The one and only active task. Execute it completely before doing anything else.
> - When you finish: fill in the RESULT section accurately, then stop. Claude writes the next task.
> - Completed task history is in `bridge_archive.md`. Do not re-execute anything listed there.
> - Language: English only. No Tamil. No exceptions.
> - Do not invent tasks. Do not skip steps. Do not do work that is not listed here.

---

## ABSOLUTE RULES (always apply)

| Rule | Correct | Wrong |
|------|---------|-------|
| Icons | `LucideIcons.sparkles` | `Icons.star` |
| Navigation (secondary) | `showModalBottomSheet` | `Navigator.push(MaterialPageRoute(...))` |
| Feedback | `ref.read(feedbackProvider.notifier).showMessage(...)` | `ScaffoldMessenger...` or `showDialog(AlertDialog(...))` |
| IDs | `AppUtils.generateId(prefix: 'task')` | `uuid.v4()` |
| Fonts | `theme.textTheme.bodyMedium` | `GoogleFonts.inter(...)` |
| Providers in build | `ref.watch()` | `ref.read()` |

---

## CURRENT TASK
**Status:** PENDING
**ID:** BRIDGE-019

---

### TASK: WeeklyReportScreen Sheet Redesign + isPremiumProvider Watch Fix

**Step 0 -- Before you write a single line of code:**
Read `project_rules.md` fully.

**Context:** Two fixes. WeeklyReportScreen has a full Scaffold + AppBar but is opened via showModalBottomSheet -- same problem as SettingsScreen was. Also, insights_screen.dart reads isPremiumProvider with ref.read() in onTap instead of ref.watch() in build.
Do NOT run a build. Run `flutter analyze` only at the end.

---

## SECTION A -- WEEKLY REPORT SCREEN: REMOVE SCAFFOLD

### BUG-48
**File:** `lib/features/insights/presentation/weekly_report_screen.dart`

**Problem:** WeeklyReportScreen uses `Scaffold` with `AppBar`. It is opened via `showModalBottomSheet` (BUG-37 fix). The nested Scaffold creates a mis-aligned AppBar inside a bottom sheet, wrong back-button routing, and wrong SafeArea padding.

**Fix strategy:** Replace `Scaffold` + `AppBar` with a `Container` sheet wrapper. The AppBar's refresh button moves into a header Row. The AppBar's title becomes a Text widget in the header Row.

**Current `build()` return:**
```dart
return Scaffold(
  appBar: AppBar(
    title: const Text('Weekly Insight'),
    actions: [
      IconButton(
        icon: const Icon(LucideIcons.rotateCcw),
        onPressed: () {
          setState(() {
            _isLoading = true;
            _error = null;
          });
          _generateReport();
        },
      ),
    ],
  ),
  body: _buildBody(theme),
);
```

**Fix -- replace with sheet Container:**
```dart
return Container(
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
  ),
  child: SafeArea(
    top: false,
    child: Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header row (replaces AppBar)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Insight',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.rotateCcw),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _generateReport();
                },
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
        // Body
        Expanded(child: _buildBody(theme)),
      ],
    ),
  ),
);
```

**IMPORTANT:**
- `_buildBody(theme)` stays completely unchanged -- only the outer Scaffold wrapper is replaced.
- `Expanded(child: _buildBody(theme))` is needed so the scrollable body fills the remaining sheet height.
- The existing `SingleChildScrollView` inside `_buildBody` handles scrolling correctly.
- Do NOT change `_buildBody`, `_buildHeader`, `_buildScoreHero`, `_buildMetricGrid`, `_buildSection`, `_buildActionPlan`, or any other method.

---

## SECTION B -- isPremiumProvider: ref.read → ref.watch

### BUG-49
**File:** `lib/features/dashboard/presentation/insights_screen.dart`
**Location:** `_InsightsBody.build()` -- GestureDetector onTap for Weekly AI Report banner.

**Problem:** `ref.read(isPremiumProvider)` is called inside `onTap`. This means if the user upgrades to Pro mid-session, the button behavior does not update until a full rebuild. Rule 6: providers in build context must use `ref.watch()`.

**Find:** Inside `_InsightsBody.build()`, the GestureDetector:
```dart
onTap: () {
  final isPremium = ref.read(isPremiumProvider);
  if (isPremium) {
    showModalBottomSheet(
```

**Fix -- watch isPremiumProvider in build, use the variable in onTap:**

Add this line near the top of `_InsightsBody.build()`, alongside the existing watches:
```dart
final isPremium = ref.watch(isPremiumProvider);
```

Then update the onTap to use the watched variable instead of ref.read:
```dart
onTap: () {
  if (isPremium) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WeeklyReportScreen(),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallScreen(),
    );
  }
},
```

**Note:** Remove the `final isPremium = ref.read(isPremiumProvider);` line from inside the onTap callback after adding the watch at the top of build.

---

## SECTION C -- VERIFICATION ONLY

```bash
flutter analyze --no-fatal-infos
```
Expected: 0 errors, 0 warnings. **DO NOT run flutter build.**

---

## RESULT
**Status:** PENDING
- BUG-48 WeeklyReportScreen Scaffold → Container sheet redesign: ?
- BUG-49 isPremiumProvider ref.read → ref.watch in insights_screen.dart: ?
- flutter analyze: ?
- Any blockers: ?
