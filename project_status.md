# 🛡️ OBSIDIAN AI — Master Project Document

> **⚡ AI AGENT INSTRUCTIONS — READ THIS FIRST**
> இந்த file-ஐ படிச்சா project-ஓட எல்லா context-உம் கிடைக்கும்.
> Session முடிஞ்சதும் `## 🕰️ TIMELINE` section-ல் உன்னோட changes add பண்ணு.
> Format எப்படி update பண்றதுன்னு கடைசில் `## 📝 HOW TO UPDATE THIS FILE` பார்.

---

## 🪪 PROJECT IDENTITY

| Field | Value |
| :--- | :--- |
| **App Name** | Obsidian AI |
| **Package** | `ai_productivity_assistant` |
| **Tagline** | AI-powered Personal Productivity |
| **Version** | `1.0.0+1` |
| **Build Target** | Android — Play Store (AAB) |
| **Last Updated** | 2026-04-16 · 20:30 IST |
| **Status** | 🟢 Active Development |

---

## ⚙️ TECH STACK

| Layer | Technology |
| :--- | :--- |
| **UI Framework** | Flutter 3.11.4 · Material 3 |
| **State Management** | Riverpod 3.3.1 (Notifier + StreamProvider) |
| **Backend / DB** | Firebase Auth + Cloud Firestore |
| **AI Models** | Gemini 1.5 Flash (chat/action) · Gemini 1.5 Pro (reasoning) |
| **Icons** | `lucide_icons ^0.257.0` — LucideIcons.* ONLY |
| **Charts** | `fl_chart ^1.2.0` |
| **IAP** | `in_app_purchase` (Play Store + App Store) |
| **Local Storage** | `shared_preferences` |
| **Notifications** | `flutter_local_notifications` |
| **Markdown** | `flutter_markdown` |

---

## 🚨 ABSOLUTE RULES — NEVER BREAK

> These rules apply to ALL AI agents. Violating any of these will break the app.

| # | Rule | ✅ Correct | ❌ Wrong |
| :- | :--- | :--- | :--- |
| 1 | **Icons** | `LucideIcons.sparkles` | `Icons.star` |
| 2 | **ID Generation** | `AppUtils.generateId(prefix: 'task')` | `uuid.v4()` or manual string |
| 3 | **SnackBars / Feedback** | `ref.read(feedbackProvider.notifier).showMessage('...')` | `ScaffoldMessenger.of(context).showSnackBar(...)` |
| 4 | **Error feedback** | `ref.read(feedbackProvider.notifier).showError('...')` | throwing uncaught exceptions to UI |
| 5 | **Fonts / Text** | `theme.textTheme.bodyMedium` | `GoogleFonts.inter(...)` in widgets |
| 6 | **Task mutations** | `ref.read(tasksProvider.notifier).addTask(task)` | direct Firestore writes |
| 7 | **Habit mutations** | `ref.read(habitsProvider.notifier).addHabit(habit)` | direct Firestore writes |

---

## 🏗️ APP ARCHITECTURE

### Boot Flow
```
main() → Firebase.init() + SharedPreferences.init()
  └── ProviderScope
       └── MyApp (Consumer)
            ├── authStateProvider watch
            ├── [null user]  → LoginScreen (Google Sign-In)
            └── [logged in] → MainNavigation
                 ├── Tab 0 · Home       → HomeScreen
                 ├── Tab 1 · Tasks      → TasksScreen
                 ├── Tab 2 · Calendar   → CalendarScreen
                 ├── Tab 3 · AI         → AIAssistantScreen
                 ├── Tab 4 · Habits     → HabitsScreen
                 └── Tab 5 · Insights   → InsightsScreen
```

### Data Flow (Every User Action)
```
User taps UI
  → Notifier method called (e.g. tasksProvider.notifier.addTask)
  → State updated optimistically (UI reflects instantly)
  → FirestoreService writes to Cloud
  → On error: state rolled back + feedbackProvider shows error + retry offered
```

### AI Routing Logic
```
User sends message → ChatNotifier.sendMessage()
  → AIService._detectComplexity() [Gemini Flash as router]
       ├── "CHAT"      → Gemini 1.5 Flash  — conversational reply
       ├── "ACTION"    → Gemini 1.5 Flash  — Tool Calling (create/delete tasks)
       └── "REASONING" → Gemini 1.5 Pro    — deep planning / breakdown
  → stream result → _updateAiMessage() → UI renders live
```

### State Persistence Layers
```
┌─────────────────────────────────────────────────┐
│  Firestore (Cloud, Real-time)                   │
│  tasks · habits · messages · user profile       │
├─────────────────────────────────────────────────┤
│  SharedPreferences (Local, Persistent)          │
│  AppSettings · theme · pomodoro config          │
├─────────────────────────────────────────────────┤
│  Riverpod In-Memory (Session only)              │
│  nav index · focus timer · loading flags        │
└─────────────────────────────────────────────────┘
```

---

## 📁 FILE MAP

> எந்த feature-க்கு எந்த file-ல் போகணும்னு quick reference.

```
lib/
│
├── main.dart                          ← App entry, Firebase + Prefs init
│
├── core/
│   ├── constants/
│   │   ├── constants.dart             ← AI prompts, model IDs, app constants
│   │   └── secrets.dart               ← API keys via --dart-define (never hardcode)
│   ├── navigation/
│   │   └── main_navigation.dart       ← 6-tab bottom nav + tab index logic
│   ├── providers/
│   │   ├── providers.dart             ← Barrel export of all major providers
│   │   └── shared_prefs_provider.dart ← SharedPreferences provider
│   ├── services/
│   │   ├── firestore_service.dart     ← ALL Firestore read/write methods
│   │   └── notification_service.dart  ← Local push notifications
│   ├── theme/
│   │   └── app_theme.dart             ← Light + Dark Material 3 themes
│   └── utils/
│       ├── app_utils.dart             ← generateId(), extractJson(), dayNameToInt()
│       └── service_failure.dart       ← Firestore error → human-readable message
│
└── features/
    │
    ├── auth/
    │   ├── data/auth_service.dart             ← Google Sign-In logic
    │   └── presentation/
    │       ├── auth_provider.dart             ← currentUserProvider, authStateProvider, userNameProvider
    │       └── login_screen.dart
    │
    ├── tasks/
    │   ├── domain/task.dart                   ← Task model, TaskPriority enum, TaskStatus enum
    │   └── presentation/
    │       └── task_provider.dart             ← tasksProvider, metricsTasksProvider,
    │                                             filteredTasksProvider, overdueTasksProvider,
    │                                             productivityMetricsProvider, insightsRangeProvider
    │
    ├── chat/
    │   ├── data/ai_service.dart               ← Gemini streaming, tool calling, decomposeGoal()
    │   ├── domain/
    │   │   ├── message_model.dart             ← AIMessage, MessageRole
    │   │   └── ai_action_model.dart           ← AIAction, AIActionType enum
    │   └── presentation/
    │       ├── chat_provider.dart             ← chatProvider, messagesStreamProvider,
    │       │                                     aiServiceProvider, aiLoadingProvider
    │       ├── feedback_provider.dart         ← feedbackProvider (showMessage / showError)
    │       ├── ai_assistant_screen.dart       ← Main AI chat screen
    │       └── goal_decomposer_sheet.dart     ← Premium: goal → tasks breakdown sheet
    │
    ├── focus/
    │   └── presentation/
    │       └── focus_screen.dart              ← Pomodoro timer, work/break cycles
    │
    ├── habits/
    │   ├── domain/habit.dart                  ← Habit model
    │   └── presentation/
    │       └── habit_provider.dart            ← habitsProvider, habitsStreamProvider
    │
    ├── insights/
    │   ├── data/weekly_report_service.dart    ← WeeklyReport model + Gemini report gen
    │   └── presentation/
    │       └── weekly_report_screen.dart      ← Premium: full weekly AI analysis screen
    │
    └── settings/
        ├── domain/app_settings.dart           ← AppSettings model (all toggles + config)
        ├── data/subscription_service.dart     ← in_app_purchase: fetch products, buy, restore
        └── presentation/
            ├── settings_provider.dart         ← appSettingsProvider, navigationProvider,
            │                                     isPremiumProvider
            ├── subscription_provider.dart     ← subscriptionProvider (SubscriptionState,
            │                                     SubscriptionNotifier)
            ├── settings_screen.dart           ← All settings UI
            └── paywall_screen.dart            ← Pro upgrade screen (real IAP products)
```

---

## 🔌 PROVIDER QUICK REFERENCE

> Provider-ஓட பெயர் தெரியல? இங்க பாரு.

| Provider | Type | What it gives | Where defined |
| :--- | :--- | :--- | :--- |
| `tasksProvider` | `NotifierProvider<TaskNotifier, TaskPaginationState>` | Paginated task list + CRUD methods | `task_provider.dart` |
| `metricsTasksProvider` | `StreamProvider<List<Task>>` | Last 90 days tasks (for charts) | `task_provider.dart` |
| `filteredTasksProvider` | `Provider<List<Task>>` | Filtered + sorted task list | `task_provider.dart` |
| `overdueTasksProvider` | `Provider<List<Task>>` | Tasks past due date | `task_provider.dart` |
| `productivityMetricsProvider` | `Provider<Map<String,dynamic>>` | Chart data, scores, growth % | `task_provider.dart` |
| `insightsRangeProvider` | `NotifierProvider<..., int>` | Selected range: 7 / 30 / 90 days | `task_provider.dart` |
| `habitsProvider` | `NotifierProvider<HabitNotifier, List<Habit>>` | Habit list + CRUD | `habit_provider.dart` |
| `chatProvider` | `NotifierProvider<ChatNotifier, List<AIMessage>>` | Chat messages + sendMessage() | `chat_provider.dart` |
| `messagesStreamProvider` | `StreamProvider<List<AIMessage>>` | Firestore chat stream | `chat_provider.dart` |
| `aiServiceProvider` | `Provider<AIService>` | AIService instance | `chat_provider.dart` |
| `aiLoadingProvider` | `NotifierProvider<..., bool>` | AI is generating? | `chat_provider.dart` |
| `feedbackProvider` | `NotifierProvider<FeedbackNotifier, FeedbackState>` | showMessage() / showError() | `feedback_provider.dart` |
| `appSettingsProvider` | `NotifierProvider<AppSettingsNotifier, AppSettings>` | All app settings | `settings_provider.dart` |
| `navigationProvider` | `NotifierProvider<NavigationNotifier, int>` | Current tab index | `settings_provider.dart` |
| `isPremiumProvider` | `Provider<bool>` | Is user Pro? | `settings_provider.dart` |
| `subscriptionProvider` | `NotifierProvider<SubscriptionNotifier, SubscriptionState>` | IAP products, buy, restore | `subscription_provider.dart` |
| `firestoreServiceProvider` | `Provider<FirestoreService?>` | Firestore instance (null if logged out) | `task_provider.dart` |
| `currentUserProvider` | `Provider<User?>` | Firebase current user | `auth_provider.dart` |
| `authStateProvider` | `StreamProvider<User?>` | Auth state stream | `auth_provider.dart` |
| `sharedPreferencesProvider` | `Provider<SharedPreferences>` | SharedPreferences instance | `shared_prefs_provider.dart` |

---

## 🗂️ TASK CATEGORIES & CONSTANTS

```dart
// Valid task categories (use exactly these strings):
['Work', 'Personal', 'Health', 'Study', 'Finance', 'Inbox']

// Tab indices (MainNavigation):
// 0 = Home · 1 = Tasks · 2 = Calendar · 3 = AI · 4 = Habits · 5 = Insights

// Subscription Product IDs:
// Monthly : 'obsidian_pro_monthly_199'  → ₹199/month
// Yearly  : 'obsidian_pro_yearly_1499' → ₹1499/year

// API Keys (injected via --dart-define, never hardcode):
// GEMINI_API_KEY · NVIDIA_API_KEY · GROQ_API_KEY
```

---

## ✅ FEATURE STATUS MATRIX

| Feature | Status | Stability | Notes |
| :--- | :---: | :---: | :--- |
| Auth — Google Sign-In | ✅ Done | 🟢 High | Firebase Auth, session persistence |
| Task CRUD + Calendar | ✅ Done | 🟢 High | Pagination, NLP parse, recurrence |
| AI Chat — Flash/Pro routing | ✅ Done | 🟡 Medium | Tool calling, streaming |
| Goal Decomposer | ✅ Done | 🟡 Medium | Premium-gated bottom sheet |
| Pomodoro Focus Timer | ✅ Done | 🟢 High | Custom cycles, nav-safe |
| Habits + Streak | ✅ Done | 🟢 High | Firestore sync |
| Insights + FL Charts | ✅ Done | 🟢 High | Category breakdown, activity wave |
| Weekly AI Report | ✅ Done | 🟡 Medium | Premium-gated, Gemini analysis |
| Hide Completed Tasks | ✅ Done | 🟢 High | Global toggle in Settings |
| Subscription (IAP) | ✅ Done | 🟡 Medium | Real Play Store flow + Firestore |
| App Signing (Keystore) | 🔲 Todo | — | Needed for release build |
| ProGuard Config | 🔲 Todo | — | Release optimisation |
| Play Store AAB Build | 🔲 Todo | — | Final release artifact |
| Subscription Expiry Check | 🔲 Todo | — | Daily revoke if expired |
| Onboarding Screen | 🔲 Todo | — | First-launch 3-slide walkthrough |
| Morning Reminder Push | 🔲 Todo | — | Daily 8am task count notification |

---

## ⚠️ KNOWN ISSUES & LIMITATIONS

| ID | Issue | Impact | Status |
| :- | :--- | :--- | :--- |
| L-01 | IAP only works on real device — emulator shows "Store not available" | Testing only | Expected, won't fix |
| L-02 | Subscription expiry not auto-revoked — manual Firestore only | Post-purchase | 🔲 Pending |
| L-03 | Play Console product IDs not yet created — IAP live untested | Pre-launch | 🔲 Pending |
| L-04 | AI features require internet — no offline fallback | UX | By design |

---

## 🕰️ CHANGE TIMELINE

> ⚡ AI: Session முடிஞ்சதும் இந்த table-ல் உன்னோட rows add பண்ணு. Format பாக்க: `## 📝 HOW TO UPDATE`

### 2026-04-16

| Time (IST) | Agent | Type | Change Summary | Files Changed |
| :--- | :--- | :--- | :--- | :--- |
| 18:15 | Antigravity | ✨ Feature | Hide Completed Tasks — planning | — |
| 18:25 | Antigravity | ✨ Feature | `hideCompletedTasks` bool added to AppSettings, SharedPrefs wired | `app_settings.dart` |
| 18:35 | Antigravity | ✨ Feature | Eye toggle added to Home Screen Today section | `home_screen.dart` |
| 18:42 | Antigravity | ✨ Feature | Hide logic applied to all Tasks tabs + Grouped View | `tasks_screen.dart` |
| 18:50 | Antigravity | ✨ Feature | Global Settings toggle switch added | `settings_screen.dart` |
| 18:55 | Antigravity | ✨ Feature | `WeeklyReportService` + `WeeklyReportScreen` created | `weekly_report_service.dart`, `weekly_report_screen.dart` |
| 19:00 | Antigravity | ✨ Feature | `GoalDecomposerSheet` created, wired to AI screen | `goal_decomposer_sheet.dart`, `ai_assistant_screen.dart` |
| 19:05 | Antigravity | ✨ Feature | Weekly AI Report banner added to Insights screen | `insights_screen.dart` |
| 19:10 | Antigravity | 🔧 Infra | Git push — all changes committed to main | — |
| 19:25 | Antigravity | ✨ Feature | `in_app_purchase` added to pubspec | `pubspec.yaml` |
| 19:28 | Antigravity | ✨ Feature | `SubscriptionService` — product fetch, buy, restore | `subscription_service.dart` |
| 19:32 | Antigravity | ✨ Feature | `SubscriptionNotifier` — purchase stream + state mgmt | `subscription_provider.dart` |
| 19:35 | Antigravity | ✨ Feature | `PaywallScreen` — real prices from store, restore button | `paywall_screen.dart` |
| 19:38 | Antigravity | 🔧 Refactor | `isPremiumProvider` now reads real `SubscriptionNotifier` | `settings_provider.dart` |
| 19:42 | Antigravity | ✨ Feature | `updatePremiumStatus()` added to FirestoreService | `firestore_service.dart` |
| 19:45 | Antigravity | ✅ QA | `flutter analyze` — all errors resolved | — |
| 20:00 | Claude | 🐛 Bug Fix | `DropdownButtonFormField(initialValue:)` → `value:` — Flutter compile error | `goal_decomposer_sheet.dart` |
| 20:05 | Claude | 🔧 Rule Fix | `ScaffoldMessenger` × 3 → `feedbackProvider.notifier` (project rule) | `goal_decomposer_sheet.dart`, `weekly_report_screen.dart` |
| 20:08 | Claude | 📦 Import | `feedback_provider.dart` import added to both files | `goal_decomposer_sheet.dart`, `weekly_report_screen.dart` |
| 20:20 | Claude | 🐛 Bug Fix | Premium lost on app restart — `_init()` now reads Firestore first | `subscription_provider.dart` |
| 20:25 | Claude | ✨ Feature | `getUserProfile()` added to FirestoreService for startup read | `firestore_service.dart` |
| 20:30 | Claude | 📄 Docs | `project_status.md` fully restructured as AI-friendly master doc | `project_status.md` |

---

## 🎯 ROADMAP

### 🔴 P0 — Play Store Release (Do This Now)
- [ ] App Signing — keystore generate + `android/app/build.gradle` configure
- [ ] ProGuard — `proguard-rules.pro` setup for release
- [ ] `flutter build appbundle --release` — AAB generate
- [ ] Play Console — `obsidian_pro_monthly_199` + `obsidian_pro_yearly_1499` product IDs create
- [ ] Internal Testing track → Production rollout

### 🟡 P1 — Post-Launch (Next Sprint)
- [ ] Subscription expiry daily check → auto-revoke if expired
- [ ] Morning push notification (8am) — today's task count
- [ ] Onboarding screen — 3-slide first-launch walkthrough

### 🟢 P2 — Future
- [ ] AI context compression — old messages → summary (extend context window)
- [ ] Widget (Home screen glanceable tasks)
- [ ] iOS release (App Store)

---

## 📝 HOW TO UPDATE THIS FILE

> ⚡ AI Agent — session முடிஞ்சதும் இந்த exact steps follow பண்ணு:

### Step 1 — Timeline-ல் row add பண்ணு

`## 🕰️ CHANGE TIMELINE` section-ல் today's date header-கீழ் இந்த format-ல் add பண்ணு:

```
| HH:MM | YourName | TYPE | One-line description of what changed | `filename.dart` |
```

**Type options:**
| Tag | எப்ப use பண்றது |
| :--- | :--- |
| ✨ Feature | புதுசா ஒரு feature/method add பண்ணா |
| 🐛 Bug Fix | compile error அல்லது runtime bug fix பண்ணா |
| 🔧 Rule Fix / Refactor | code improvement, rule violation fix |
| 📦 Import | import மட்டும் add/fix பண்ணா |
| ✅ QA | analyze / test run பண்ணா |
| 🔧 Infra | pubspec, gradle, config files |
| 📄 Docs | documentation only |

### Step 2 — Feature Matrix update பண்ணு (if needed)

ஒரு feature முடிஞ்சா `🔲 Todo` → `✅ Done` மாத்து.
Stability மாறினா update பண்ணு.

### Step 3 — Known Issues update பண்ணு (if needed)

புதுசா bug கண்டுபிடிச்சா `## ⚠️ KNOWN ISSUES` table-ல் add பண்ணு.
Fix பண்ணா Status column-ல் `✅ Fixed` போடு.

### Step 4 — Roadmap tick பண்ணு (if needed)

Roadmap item முடிஞ்சா `- [ ]` → `- [x]` மாத்து.

### Step 5 — Last Updated மாத்து

File top-ல்:
```
**Last Updated:** YYYY-MM-DD · HH:MM IST
```

---

> [!IMPORTANT]
> **ஒரே ஒரு rule:** இந்த file-ஐ படிச்சா project context 100% புரியணும். படிக்காம code எழுதா bugs வரும். எந்த AI agent-உம் இந்த file-ஐ skip பண்ணக்கூடாது.
