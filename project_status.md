# 📋 Zeno — Project Timeline

> GitHub-style tracking. Timeline மட்டும் இங்க இருக்கும்.
> Rules + Architecture → `project_rules.md`
> Claude ↔ Antigravity communication → `bridge.md`

---

## ✅ FEATURE STATUS

| Feature | Status | Stability |
| :--- | :---: | :---: |
| Auth — Google Sign-In | ✅ Done | 🟢 High |
| Task CRUD + Calendar | ✅ Done | 🟢 High |
| AI Chat — Flash/Pro routing | ✅ Done | 🟢 High |
| Goal Decomposer | ✅ Done | 🟡 Medium |
| Pomodoro Focus Timer | ✅ Done | 🟢 High |
| Habits + Streak | ✅ Done | 🟢 High |
| Insights + FL Charts | ✅ Done | 🟢 High |
| Weekly AI Report | ✅ Done | 🟡 Medium |
| Hide Completed Tasks | ✅ Done | 🟢 High |
| Subscription IAP | ✅ Done | 🟢 High |
| App Signing + ProGuard | ✅ Done | 🟢 High |
| AAB Build | ✅ Done | 🟢 High |
| Onboarding Screen | ✅ Done | 🟢 High |
| Premium Empty States | ✅ Done | 🟢 High |
| Premium Visibility UI | ✅ Done | 🟢 High |
| App Logo | ✅ Done | 🟢 High |
| Play Console Setup | 🔲 Todo | — |
| Real Device Testing | ✅ Done | 🟢 High |
| Subscription Expiry Check | ✅ Done | 🟢 High |
| Deep Bug Audit + Fix | ✅ Done | 🟢 High |
| Tasks UI (Pill Redesign) | ✅ Done | 🟢 High |
| Production APK | ✅ Done | 🟢 High |

---

## 🎯 ROADMAP

### 🔴 P0 — Immediate
- [x] App Signing + ProGuard
- [x] AAB Build (54MB -> 36.6MB)
- [x] App Logo — flutter_launcher_icons
- **2026-04-19**: Final production build (v1.0.0+1) generated. New professional app icon integrated. All P0 rebranding and bug fixes complete.
- **2026-04-18**: APK size optimized (64MB -> 25MB). Google Sign-In fixes.
- **2026-04-17**: Core features (Tasks, Habits, Focus, AI Chat) finalized.
- [ ] Play Console — product IDs create + AAB upload

### 🟡 P1 — Post Launch
- [x] Onboarding screen
- [x] Morning push notification
- [ ] Subscription expiry auto-revoke

### 🟢 P2 — Future
- [ ] Home screen widget
- [ ] iOS release

---

## ⚠️ KNOWN ISSUES

| ID | Issue | Priority |
| :- | :--- | :--- |
| L-01 | IAP emulator-ல் work ஆகாது — real device only | Low |
| L-02 | Subscription expiry auto-revoke இல்லை | Medium |
| L-03 | Play Console product IDs create பண்ணல | High |

---

## 🕰️ CHANGE TIMELINE

### 2026-04-16

| Time | Agent | Type | Change | Files |
| :--- | :--- | :--- | :--- | :--- |
| 18:25 | Antigravity | ✨ | `hideCompletedTasks` added to AppSettings | `app_settings.dart` |
| 18:35 | Antigravity | ✨ | Eye toggle — Home Screen Today section | `home_screen.dart` |
| 18:42 | Antigravity | ✨ | Hide logic — all Tasks tabs | `tasks_screen.dart` |
| 18:50 | Antigravity | ✨ | Settings toggle switch | `settings_screen.dart` |
| 18:55 | Antigravity | ✨ | WeeklyReportService + WeeklyReportScreen | `weekly_report_service.dart`, `weekly_report_screen.dart` |
| 19:00 | Antigravity | ✨ | GoalDecomposerSheet created | `goal_decomposer_sheet.dart`, `ai_assistant_screen.dart` |
| 19:05 | Antigravity | ✨ | Weekly AI Report banner — Insights screen | `insights_screen.dart` |
| 19:25 | Antigravity | ✨ | in_app_purchase + SubscriptionService | `subscription_service.dart`, `pubspec.yaml` |
| 19:32 | Antigravity | ✨ | SubscriptionNotifier + PaywallScreen upgraded | `subscription_provider.dart`, `paywall_screen.dart` |
| 19:42 | Antigravity | ✨ | updatePremiumStatus() — FirestoreService | `firestore_service.dart` |
| 19:45 | Antigravity | ✅ | flutter analyze — clean | — |
| 20:00 | Claude | 🐛 | DropdownButtonFormField initialValue → value | `goal_decomposer_sheet.dart` |
| 20:05 | Claude | 🔧 | ScaffoldMessenger × 3 → feedbackProvider | `goal_decomposer_sheet.dart`, `weekly_report_screen.dart` |
| 20:20 | Claude | 🐛 | Premium lost on restart — Firestore read on init | `subscription_provider.dart` |
| 20:25 | Claude | ✨ | getUserProfile() — FirestoreService | `firestore_service.dart` |
| 20:45 | Antigravity | ✨ | Onboarding Flow 3 screens + Daily Reminder | `onboarding_screen.dart`, `main.dart` |
| 21:00 | Antigravity | ✨ | Empty States — Tasks, Habits, Insights, Home | `tasks_screen.dart`, `habits_screen.dart`, `insights_screen.dart`, `home_screen.dart` |
| 21:05 | Antigravity | ✨ | Premium badge Settings + AI nudge card | `settings_screen.dart`, `ai_assistant_screen.dart` |
| 21:15 | Antigravity | 📦 | Keystore + ProGuard + build.gradle.kts | `build.gradle.kts`, `proguard-rules.pro` |
| 21:20 | Antigravity | 📦 | AAB Build Success — 54MB | `app-release.aab` |

### 2026-04-17

| Time | Agent | Type | Change | Files |
| :--- | :--- | :--- | :--- | :--- |
| 10:00 | Claude | 📄 | project_status.md → timeline only, project_rules.md + bridge.md created | `project_status.md`, `project_rules.md`, `bridge.md` |
| 10:30 | Antigravity | ✨ | App Logo generated and configured | `pubspec.yaml`, `assets/images/*` |
| 10:35 | Antigravity | ✅ | flutter analyze — clean | — |
| 10:45 | Antigravity | 🔧 | Real Device Testing Prep: Icons fixed, debug banner confirmed, extractJson verified | `main.dart`, `app_utils.dart` |
| 10:55 | Antigravity | 📄 | Play Store Listing Prep: Permissions, version, mipmaps verified | `AndroidManifest.xml`, `pubspec.yaml` |
| 10:40 | Claude | 📄 | bridge.md simplified — ஒரே file system, PATHS FOR CLAUDE section added | `bridge.md` |
| 10:42 | Claude | 🔧 | claude.md workflow simplified — Tamil rule, readprompt trigger, minimal rules | `.agents/workflows/claude.md` |
| 10:45 | Claude | 📄 | project_rules.md created — static rules + architecture + providers | `project_rules.md` |

### 2026-04-19

| Time | Agent | Type | Change | Files |
| :--- | :--- | :--- | :--- | :--- |
| 13:40 | Antigravity | 📦 | App Rebranding: "Obsidian AI" -> "Zeno" | `main.dart`, `pubspec.yaml`, `AndroidManifest.xml`, `build.gradle.kts` |
| 13:45 | Antigravity | 🐛 | BUG-03: Expiry check fix | `subscription_provider.dart` |
| 13:50 | Antigravity | 🐛 | BUG-04 & IMP-03: AI Cache limit + Connectivity fix | `ai_service.dart` |
| 13:55 | Antigravity | 🐛 | BUG-05: Message fetch limit (100) | `firestore_service.dart` |
| 14:00 | Antigravity | 🐛 | BUG-06: Streak calculation fix | `habit_provider.dart` |
| 14:05 | Antigravity | ✨ | IMP-01: Enhanced Loading Screen with Logo | `main.dart` |
| 14:10 | Antigravity | 🔧 | IMP-02: Bottom Nav Row + Expanded fix | `main_navigation.dart` |
| 14:15 | Antigravity | ✅ | flutter analyze — clean | — |
| 14:25 | Antigravity | 🔧 | BRIDGE-006: Feedback system fix, rebranding cleanup, paywall UX, collapsible Pomodoro | `home_screen.dart`, `ai_assistant_screen.dart` |
| 14:28 | Antigravity | ✅ | flutter analyze — clean | — |
| 14:45 | Antigravity | ⚡ | BRIDGE-007: App Size Optimization (53MB -> 36.6MB) | `pubspec.yaml`, `app_theme.dart` |
| 14:48 | Antigravity | ✅ | flutter analyze — clean | — |
| 19:15 | Antigravity | 🔑 | BRIDGE-007: Fixed Google Sign-In (SHA-1 registration) | `google-services.json` |
| 19:20 | Antigravity | ✅ | flutter analyze — clean | — |
| 14:15 | Antigravity | ⚡ | BRIDGE-008: APK Size Optimization (64.5MB -> 25.7MB) | `pubspec.yaml`, `build.gradle.kts` |
| 14:20 | Antigravity | 🔧 | Rebranding BUG-11 to BUG-16: Zeno Pro fixes, feedback system | `paywall_screen.dart`, `settings_screen.dart` |
| 14:25 | Antigravity | ✅ | flutter analyze — clean | — |
| 21:15 | Antigravity | 🎨 | BRIDGE-012: Paywall blank screen fix, Scrollable Bottom Nav, Asset Cleanup | `paywall_screen.dart`, `main_navigation.dart`, `home_screen.dart` |
| 21:30 | Antigravity | ⚡ | Asset Cleanup: Deleted 4 unused images (~2.3MB) | `assets/images/*` |
| 21:55 | Antigravity | 📦 | Production Build APK (24.7MB) | `app-release.apk` |
| 21:58 | Antigravity | ✅ | flutter analyze — clean | — |
| 22:10 | Antigravity | 🔧 | BRIDGE-013: Fixed feedback in NL bar, added onChanged listener, reduced TaskCard font size | `nl_input_bar.dart`, `task_card.dart`, `goal_decomposer_sheet.dart` |
| 22:15 | Antigravity | ✅ | flutter analyze — clean | — |
| 22:20 | Antigravity | 🎨 | BRIDGE-014: Fixed Lucide icon violations in calendar/celebration, completed light theme text styles | `calendar_screen.dart`, `app_theme.dart` |
| 22:25 | Antigravity | ✅ | flutter analyze — clean | — |
| 22:30 | Antigravity | 🚀 | Git Push: Main branch updated (Redacted secrets) | — |
| 22:45 | Antigravity | 🔧 | BRIDGE-015: Completed production navigation, async handling, and reactive build patterns | `home_screen.dart`, `settings_screen.dart`, `ai_assistant_screen.dart` |
| 22:50 | Antigravity | ✅ | flutter analyze — clean | — |
| 22:55 | Antigravity | 🔬 | DEEP AUDIT: Scanned all providers, domain models, screens — 22 bugs found across 4 severity levels | `deep_audit.md` |
| 23:00 | Antigravity | 🐛 | **FIX C1**: `SubscriptionNotifier.build()` — moved `_init()` to `Future.microtask()` | `subscription_provider.dart` |
| 23:01 | Antigravity | 🐛 | **FIX C2**: `PomodoroNotifier` — added `_isLifecycleInit` guard to stop stacked `dispose()` calls | `pomodoro_provider.dart` |
| 23:02 | Antigravity | 🐛 | **FIX C4**: `clearChat()` — optimistically clears UI state before awaiting Firestore | `chat_provider.dart` |
| 23:03 | Antigravity | 🐛 | **FIX H1**: `TaskNotifier.refresh()` — resets `_isInit` so build() can re-trigger initial fetch | `task_provider.dart` |
| 23:04 | Antigravity | 🐛 | **FIX H2**: `suggestion` AIAction — `sendMessage()` is now awaited (prevents race with _markActionExecuted) | `chat_provider.dart` |
| 23:05 | Antigravity | 🐛 | **FIX H3**: `HabitNotifier` — `_isMutating` guard added to all write methods; stream cannot overwrite optimistic state | `habit_provider.dart` |
| 23:06 | Antigravity | 🐛 | **FIX H5**: `PaywallScreen` — removed nested `Scaffold`/`AppBar`; replaced with BottomSheet-safe `Container` layout | `paywall_screen.dart` |
| 23:07 | Antigravity | 🐛 | **FIX H6**: `SubscriptionState.copyWith()` — sentinel pattern added so `error` field can be cleared to `null` | `subscription_provider.dart` |
| 23:08 | Antigravity | 🐛 | **FIX H7**: `PomodoroNotifier._onPhaseComplete()` — `updatedTask` captured in local var; second state uses same reference | `pomodoro_provider.dart` |
| 23:09 | Antigravity | 🐛 | **FIX M2**: `Task.copyWith()` — added `clearTime`, `clearDescription`, `clearRecurrence` booleans for nullifying optional fields | `task.dart` |
| 23:10 | Antigravity | 🐛 | **FIX M6**: `AuthService.signOut()` — clears `onboarding_complete` pref so new user sees onboarding | `auth_service.dart` |
| 23:12 | Antigravity | ✅ | flutter analyze — **0 issues** (after 10 bug fixes across 7 files) | — |
| 23:25 | Antigravity | 🔬 | Pro Monetization Research: Web search — real-world data from Todoist, Notion, Habitica, Duolingo, RevenueCat | — |
| 23:30 | Antigravity | ✨ | **PRO FEAT 1**: AI Message Limit — 15 messages/day for free users, resets midnight, Pro bypassed | `ai_usage_provider.dart` [NEW] |
| 23:35 | Antigravity | ✨ | **PRO FEAT 2**: Habit Streak Freeze — 3 tokens/month, `frozenDates` in Habit model, freezeStreak() in HabitNotifier | `habit.dart`, `habit_provider.dart`, `streak_freeze_provider.dart` [NEW] |
| 23:40 | Antigravity | ✨ | **PRO FEAT 3**: AI Morning Briefing — Gemini Flash generates personalized 8AM daily push notification | `morning_briefing_service.dart` [NEW] |
| 23:42 | Antigravity | ✨ | Added `isPremiumProvider` convenience derived Provider to `settings_provider.dart` | `settings_provider.dart` |
| 23:45 | Antigravity | ✅ | flutter analyze — **0 issues** (3 Pro features, 5 new files) | — |
| 23:55 | Antigravity | ✨ | **UI WIRE**: AI Message Limit — Added usage counter pill, limit warning banner, and paywall gating | `ai_assistant_screen.dart` |
| 23:57 | Antigravity | ✨ | **UI WIRE**: Streak Freeze — Added monthly token bar, freeze button, and snowflake streak badges | `habits_screen.dart` |
| 23:59 | Antigravity | ✨ | **UI WIRE**: Morning Briefing — Added premium AI briefing card to Home screen | `home_screen.dart` |
| 00:05 | Antigravity | ✅ | Final Audit — All Pro features verified and zero analysis issues | — |
| 23:11 | Antigravity | 🐛 | **FIX**: NL Input Bar usage gating + Habit Token refund logic | `nl_input_bar.dart`, `habit_provider.dart` |
| 23:12 | Antigravity | 🎨 | **UI**: Tasks Screen redesign — Pill-shaped categories & premium search bar | `tasks_screen.dart` |
| 23:15 | Antigravity | 📦 | **BUILD**: Release APK successfully generated (63.5MB) | `app-release.apk` |
| 23:20 | Antigravity | ✅ | flutter analyze — **0 issues** | — |

### 2026-04-20

| Time | Agent | Type | Change | Files |
| :--- | :--- | :--- | :--- | :--- |
| 03:50 | Antigravity | 🔧 | **BRIDGE-016**: Navigation Rule Fix (Rule 9) — WeeklyReport as BottomSheet | `insights_screen.dart` |
| 03:55 | Antigravity | 🐛 | **BUG-38**: Login Error Feedback — switched from showDialog to feedbackProvider | `login_screen.dart` |
| 03:56 | Antigravity | 🔧 | **BUG-39**: NL Input Bar Send Button — disabled when text field is empty | `nl_input_bar.dart` |
| 03:57 | Antigravity | ⚡ | **BUG-40**: AI Context-Awareness — removed chat result caching from getChatStream | `ai_service.dart` |
| 03:58 | Antigravity | 🐛 | **BUG-41**: Goal Decomposer Feedback — added error feedback for empty AI results | `goal_decomposer_sheet.dart` |
| 03:59 | Antigravity | ✅ | flutter analyze — **0 issues** | — |
| 04:12 | Antigravity | 🔧 | **BRIDGE-017**: 6 UI/UX fixes: Recurrence guard, ClipRect removal, Button disabling, Swipe feedback, and Icon casts. | `task_provider.dart`, `main_navigation.dart`, `quick_add_task_sheet.dart`, `habits_screen.dart`, `task_card.dart`, `home_screen.dart` |
| 04:15 | Antigravity | ✅ | flutter analyze — **0 issues** | — |
| 04:25 | Antigravity | 🔧 | **BRIDGE-018**: Settings redesign to BottomSheet (BUG-46) + Added missing AI tool declarations for `update_task` and `reschedule_all` (BUG-47). | `settings_screen.dart`, `ai_service.dart` |
| 04:30 | Antigravity | ✅ | flutter analyze — **0 issues** | — |

### 2026-04-25

| Time | Agent | Type | Change | Files |
| :--- | :--- | :--- | :--- | :--- |
| 19:10 | Antigravity | 🧹 | Git Cleanup: Verified `.gitignore`, excluded `scratch/` and unwanted artifacts | `.gitignore` |
| 19:12 | Antigravity | ✅ | flutter analyze — **0 issues** | — |
| 19:15 | Antigravity | 🚀 | Git Backup: Committed latest changes and pushed to origin main | — |
