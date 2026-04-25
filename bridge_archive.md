# BRIDGE ARCHIVE -- Zeno by Yarzo

Completed tasks history. Do not re-execute anything listed here.

---

## BRIDGE-005 to BRIDGE-013 -- ALL DONE
- Full rebranding, all bugs fixed, new icon, asset cleanup.
- APK: 24.7MB. AAB: 50.5MB. flutter analyze: 0 issues throughout.

---

## BRIDGE-014 -- Icon Rule Fixes + Light Theme Completion
**Status:** DONE
- BUG-29 & BUG-30: Replaced Material Icons with LucideIcons in calendar and celebration overlay.
- IMP-15: Completed textTheme for both light and dark themes.
- flutter analyze: 0 issues. Git Push: done, secrets redacted.

---

## BRIDGE-015 -- Navigation + Async + UI State Bug Fixes
**Status:** DONE
- BUG-31: Settings Navigator.push → showModalBottomSheet (home_screen.dart)
- BUG-32: sendMessage() unawaited → .catchError() + feedbackProvider
- BUG-34: AI send button disabled when TextField empty (ValueListenableBuilder)
- BUG-35: Upgrade Navigator.push → showModalBottomSheet (settings_screen.dart)
- BUG-36: ref.read(appSettingsProvider) in build → ref.watch
- flutter analyze: 0 issues.

---

## BRIDGE-016 -- Navigation Fix + Login Error + NL Bar + AI Cache + Goal Feedback
**Status:** DONE
- BUG-37: Weekly Report Navigator.push → showModalBottomSheet (insights_screen.dart)
- BUG-38: Login error showDialog → feedbackProvider.showError (login_screen.dart)
- BUG-39: NL bar send button disabled when empty (nl_input_bar.dart)
- BUG-40: AI chat caching removed from getChatStream (ai_service.dart)
- BUG-41: Goal decomposer empty result → feedbackProvider.showError (goal_decomposer_sheet.dart)
- flutter analyze: 0 issues.

---

## BRIDGE-017 -- Icon Cast Crash + Swipe Feedback + Recurrence + Polish
**Status:** DONE
- BUG-42: AISuggestion icon dynamic → IconData? (ai_suggestions_provider.dart + home_screen.dart)
- BUG-43: Swipe-complete error → try/catch + feedbackProvider (task_card.dart)
- BUG-44: Recurrence picker expanded to all 7 days + guard in task_provider.dart
- BUG-45: ClipRect removed from main_navigation.dart
- IMP-16: Submit buttons disabled when empty (quick_add_task_sheet.dart + habits_screen.dart)
- flutter analyze: 0 issues.

---

## BRIDGE-018 -- SettingsScreen Sheet Redesign + AI Tools Fix
**Status:** DONE
- BUG-46: SettingsScreen Scaffold → Container sheet (drag handle added, SafeArea top:false)
- BUG-47: update_task + reschedule_all FunctionDeclarations added to ai_service.dart
- BUG-47: _mapActionToType updated with update_task + reschedule_all cases
- flutter analyze: 0 issues.
