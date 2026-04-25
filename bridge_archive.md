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

---

## BRIDGE-019 -- WeeklyReport Redesign + Reactive Premium Fix
**Status:** DONE
- BUG-48: WeeklyReportScreen Scaffold ? Container sheet (weekly_report_screen.dart)
- BUG-49: isPremiumProvider reactive fix (insights_screen.dart)
- Git Backup: All changes pushed to main.
- Production APK build (63.4MB).
- flutter analyze: 0 issues.

---

## BRIDGE-020 -- APK Size Optimization + Security Fixes
**Status:** DONE
- ITEM 1: Removed nimations package (zero usages).
- ITEM 2: Deleted duplicate pp_icon_new.png.
- ITEM 5: Set uses-material-design: false (Material Icons tree-shaking).
- ITEM 6: Removed PII (emails) from uth_service.dart debug logs.
- ITEM 7: Added 500-char length guard to 
atural_language_parser.dart.
- ITEM 8: Implemented safe JSON casting in weekly_report_service.dart.
- flutter analyze: 0 issues.

---

## BRIDGE-021 -- Final Release Build (APK + AAB)
**Status:** DONE
- APK Build: Success (23.8 MB, arm64).
- AAB Build: Success (48.7 MB).
- Obfuscation and split-debug-info enabled.
- All API keys injected via dart-define.
- Verification: APK is ready for deployment.

---

## BRIDGE-022 -- Subscription Expiry Auto-Revoke & Doc Cleanup
**Status:** DONE
- STEP 1: Added revokePremiumStatus() to firestore_service.dart.
- STEP 2: SubscriptionNotifier detects expired plan and updates Firestore.
- STEP 3: Rebranded "Obsidian AI" to "Zeno" in Gemini.md and CLAUDE.md.
- flutter analyze: 0 issues.
- Git Backup: Successful push to origin main.
