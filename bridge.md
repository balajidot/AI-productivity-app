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
**ID:** BRIDGE-025

---

### TASK: 3 Bug Fixes — rescheduleAll / AI limit bypass / Timestamp crash

**Context:**
Claude audit found 3 real bugs. Fix them in order. Do not change anything else.

---

## FIX 1 — BUG-50: rescheduleAll ignores newDate param
**File:** `lib/features/chat/presentation/chat_provider.dart`

Find this exact block:
```dart
case AIActionType.rescheduleAll:
  final overdueTasks = ref.read(overdueTasksProvider);
  final now = DateTime.now();
  for (final t in overdueTasks) {
    await ref
        .read(tasksProvider.notifier)
        .updateTask(t.copyWith(date: now));
  }
  break;
```

Replace it with:
```dart
case AIActionType.rescheduleAll:
  final overdueTasks = ref.read(overdueTasksProvider);
  final rawDate = p['newDate']?.toString();
  final parsed = rawDate != null ? DateTime.tryParse(rawDate) : null;
  final targetDate = parsed ?? DateTime.now();
  // Strip time component — move to start of the target day
  final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
  for (final t in overdueTasks) {
    await ref
        .read(tasksProvider.notifier)
        .updateTask(t.copyWith(date: targetDay));
  }
  break;
```

---

## FIX 2 — BUG-51: Home screen sparkle bypasses AI usage limit
**File:** `lib/features/dashboard/presentation/home_screen.dart`

Find the sparkle IconButton inside `_HeaderSection.build()`. Replace the entire `onPressed` lambda:

Find:
```dart
onPressed: () {
  HapticFeedback.mediumImpact();
  ref.read(chatProvider.notifier).sendMessage(
    "Analyze my current day and suggest optimizations.",
  ).catchError((e) {
    ref.read(feedbackProvider.notifier).showError(
      ServiceFailure(message: 'AI request failed. Please try again.'),
    );
  });
  ref.read(navigationProvider.notifier).set(3);
},
```

Replace with:
```dart
onPressed: () {
  HapticFeedback.mediumImpact();
  ref.read(navigationProvider.notifier).set(3);
},
```

After replacing, check if these imports are still used elsewhere in `home_screen.dart`.
If `chatProvider` is not used anywhere else in the file, remove:
`import '../../chat/presentation/chat_provider.dart';`

If `ServiceFailure` is not used anywhere else in the file, remove:
`import '../../../core/utils/service_failure.dart';`

Do NOT remove any import that is still used by other code in the file.

---

## FIX 3 — BUG-52: Unsafe Firestore Timestamp cast
**File:** `lib/features/settings/presentation/subscription_provider.dart`

First, check if this import exists at the top of the file. Add it if missing:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
```

Find:
```dart
final expiryTs = doc['expiryDate'] as dynamic;
final expiry = expiryTs != null
    ? (expiryTs as dynamic).toDate() as DateTime
    : null;
```

Replace with:
```dart
DateTime? expiry;
final expiryRaw = doc['expiryDate'];
if (expiryRaw != null) {
  try {
    expiry = (expiryRaw as Timestamp).toDate();
  } catch (_) {
    expiry = null;
  }
}
```

---

## STEP 4 — Verify

Run:
```powershell
flutter analyze --no-fatal-infos
```

Must show 0 issues. If any unused import warning appears from FIX 2, remove that import and re-run.

---

## RESULT
**Status:** COMPLETE
- BUG-50 (rescheduleAll date): FIXED
- BUG-51 (sparkle AI bypass): FIXED
- BUG-52 (Timestamp cast): FIXED
- Unused imports removed: YES
- flutter analyze: 0 issues
- Notes: Robustly handled both String and Timestamp formats for subscription expiry to ensure backward compatibility.
