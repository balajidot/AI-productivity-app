# Zeno by Yarzo -- Project Rules & Architecture

> This is the single source of truth for all decisions about this codebase.
> Read this file completely before writing a single line of code.
> Timeline -> `project_status.md` | Communication -> `bridge.md`

---

## IDENTITY

| Field | Value |
| :--- | :--- |
| **App Name** | Zeno |
| **Company** | Yarzo |
| **Package ID** | `com.yarzo.zeno` |
| **Version** | `1.0.0+1` |
| **Project Path** | `C:\Users\acer\.gemini\antigravity\scratch\ai_productivity_assistant` |
| **Build Target** | Android -- Play Store AAB |
| **Stack** | Flutter 3.11.4 . Riverpod 3.3.1 . Firebase . Gemini 1.5 Pro/Flash |

---

## ABSOLUTE RULES

These rules are non-negotiable. Violating any of them will cause bugs, crashes, or inconsistent behavior. There are no exceptions.

### Rule 1 -- Icons
Always use `LucideIcons`. Never use `Icons.*` from the Material library.
```dart
// CORRECT
Icon(LucideIcons.sparkles)

// WRONG -- will break visual consistency
Icon(Icons.star)
```

### Rule 2 -- ID Generation
Always use `AppUtils.generateId()` with a meaningful prefix. Never use `uuid` directly.
```dart
// CORRECT
final id = AppUtils.generateId(prefix: 'task');
final id = AppUtils.generateId(prefix: 'habit');
final id = AppUtils.generateId(prefix: 'msg');

// WRONG
final id = const Uuid().v4();
```

### Rule 3 -- User Feedback (Snackbars)
All user-facing messages must go through `feedbackProvider`. Never call `ScaffoldMessenger` directly from a widget.
```dart
// CORRECT
ref.read(feedbackProvider.notifier).showMessage('Task created.');
ref.read(feedbackProvider.notifier).showError('Failed to save.', onRetry: () => save());

// WRONG -- bypasses the centralized feedback system
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task created.')));
```

### Rule 4 -- Error Handling
All errors must be surfaced through `feedbackProvider.showError()`. Never swallow exceptions silently. Never use `.ignore()` on futures unless you have explicitly documented why it is safe.
```dart
// CORRECT
try {
  await someOperation();
} catch (e) {
  ref.read(feedbackProvider.notifier).showError(ServiceFailure.fromFirestore(e), onRetry: retry);
}

// WRONG -- hides failures from the user
someOperation().ignore();
try { ... } catch (_) {}
```

### Rule 5 -- Typography
Always use theme text styles. Never instantiate `GoogleFonts` directly in a widget.
```dart
// CORRECT
style: theme.textTheme.bodyMedium
style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)

// WRONG -- breaks theming and causes inconsistent fonts
style: GoogleFonts.inter(fontSize: 16)
```

### Rule 6 -- Task Mutations
All task create/update/delete operations must go through `tasksProvider`. Never write to Firestore directly from a screen or widget.
```dart
// CORRECT
ref.read(tasksProvider.notifier).addTask(task);
ref.read(tasksProvider.notifier).updateTask(task);
ref.read(tasksProvider.notifier).deleteTask(id);

// WRONG -- bypasses optimistic UI, retry logic, and notification scheduling
FirebaseFirestore.instance.collection('tasks').doc(id).set(data);
```

### Rule 7 -- Habit Mutations
Same principle as Rule 6. All habit operations go through `habitsProvider`.
```dart
// CORRECT
ref.read(habitsProvider.notifier).addHabit(habit);
ref.read(habitsProvider.notifier).toggleHabitDay(id, date);
ref.read(habitsProvider.notifier).deleteHabit(id);

// WRONG
FirebaseFirestore.instance.collection('habits').doc(id).set(data);
```

### Rule 8 -- API Keys
API keys must never be hardcoded in source files. They are injected at build time via `--dart-define` and accessed only through the `Secrets` class.
```dart
// CORRECT -- access via Secrets class
final key = Secrets.geminiApiKey;

// WRONG -- hardcoded key will be exposed in APK
final key = 'AIzaSy...';
```

### Rule 9 -- Navigation Patterns
Use `navigationProvider` for main tab switching. Use `showModalBottomSheet` for secondary screens (paywall, task editor, habit editor). Use `Navigator.push` only for full standalone screens (settings, weekly report).
```dart
// Switch main tab
ref.read(navigationProvider.notifier).set(3); // Go to AI tab

// Secondary screen
showModalBottomSheet(context: context, builder: (_) => const PaywallScreen());

// Full standalone screen
Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
```

### Rule 10 -- Code Quality Gate
Before marking any task complete, run:
```bash
flutter analyze --no-fatal-infos
```
The output must show 0 errors and 0 warnings. Do not submit work that fails analysis.

---

## ARCHITECTURE

### Boot Flow
```
main()
  |-- Firebase.initializeApp()
  |-- NotificationService.init()
  |-- SharedPreferences.getInstance()
  |-- ProviderScope
       |-- MyApp
            |-- [Firebase failed]  -> ErrorScreen (with retry button)
            |-- [loading]          -> SplashScreen (Zeno logo + spinner)
            |-- [logged out]       -> LoginScreen
            |-- [new user]         -> OnboardingScreen
            |-- [logged in]        -> MainNavigation
                 |-- 0 . Home
                 |-- 1 . Tasks
                 |-- 2 . Calendar
                 |-- 3 . AI Chat
                 |-- 4 . Habits
                 |-- 5 . Insights
```

### AI Routing
```
User message
  |-- AIService._detectComplexity()  [Gemini Flash, fast classifier]
       |-- CHAT      -> Gemini 1.5 Flash  (conversational replies)
       |-- ACTION    -> Gemini 1.5 Flash  (tool calling: create/delete tasks)
       |-- REASONING -> Gemini 1.5 Pro    (strategic planning, goal decomposition)
```

### State Architecture
```
Firestore (persistent, cloud)
  |-- users/{uid}/tasks
  |-- users/{uid}/habits
  |-- users/{uid}/messages
  |-- users/{uid}           (premium status, profile)

SharedPreferences (persistent, local)
  |-- AppSettings  (theme, notifications, pomodoro config)
  |-- onboarding_complete

Riverpod (in-memory, session only)
  |-- navigationProvider
  |-- pomodoroProvider
  |-- loading flags, transient UI state
```

---

## FILE MAP

```
lib/
|-- main.dart                                    <- App entry point, boot logic, splash
|-- firebase_options.dart                        <- Auto-generated, do not edit
|-- core/
|   |-- constants/
|   |   |-- constants.dart                       <- AI prompts, model IDs, app constants
|   |   |-- secrets.dart                         <- API key accessors (--dart-define only)
|   |-- navigation/
|   |   |-- main_navigation.dart                 <- 6-tab scaffold, FAB logic, feedback wiring
|   |-- providers/
|   |   |-- providers.dart                       <- Barrel export for all providers
|   |   |-- shared_prefs_provider.dart           <- SharedPreferences provider
|   |-- services/
|   |   |-- firestore_service.dart               <- ALL Firestore read/write methods live here
|   |   |-- notification_service.dart            <- Local push notifications
|   |-- theme/
|   |   |-- app_theme.dart                       <- Light + dark theme definitions
|   |-- utils/
|       |-- app_utils.dart                       <- generateId(), extractJson(), helpers
|       |-- service_failure.dart                 <- Firestore error message parser
|-- features/
    |-- auth/presentation/
    |   |-- auth_provider.dart
    |   |-- login_screen.dart
    |-- tasks/
    |   |-- domain/task.dart
    |   |-- presentation/
    |       |-- task_provider.dart               <- Pagination, CRUD, filtering, metrics
    |       |-- tasks_screen.dart
    |       |-- calendar_screen.dart
    |       |-- widgets/
    |           |-- task_card.dart
    |           |-- quick_add_task_sheet.dart
    |-- chat/
    |   |-- data/ai_service.dart                 <- Gemini API, routing, tool calling, cache
    |   |-- domain/
    |   |   |-- message_model.dart
    |   |   |-- ai_action_model.dart
    |   |-- presentation/
    |       |-- chat_provider.dart
    |       |-- feedback_provider.dart           <- Centralized snackbar/feedback system
    |       |-- goal_decomposer_sheet.dart
    |       |-- ai_assistant_screen.dart
    |       |-- widgets/
    |-- focus/presentation/
    |   |-- focus_screen.dart
    |-- habits/
    |   |-- domain/habit.dart
    |   |-- presentation/
    |       |-- habit_provider.dart
    |       |-- habits_screen.dart
    |-- dashboard/presentation/
    |   |-- home_screen.dart
    |   |-- insights_screen.dart
    |   |-- widgets/
    |-- insights/
    |   |-- data/weekly_report_service.dart
    |   |-- presentation/weekly_report_screen.dart
    |-- onboarding/presentation/onboarding_screen.dart
    |-- settings/
        |-- domain/app_settings.dart
        |-- data/subscription_service.dart
        |-- presentation/
            |-- settings_provider.dart
            |-- settings_screen.dart
            |-- subscription_provider.dart
            |-- paywall_screen.dart
```

---

## PROVIDER REFERENCE

| Provider | Type | Purpose | Defined In |
| :--- | :--- | :--- | :--- |
| `tasksProvider` | NotifierProvider | All task CRUD + pagination state | `task_provider.dart` |
| `metricsTasksProvider` | StreamProvider | Last 90 days tasks for charts | `task_provider.dart` |
| `filteredTasksProvider` | Provider | Filtered + sorted task list | `task_provider.dart` |
| `overdueTasksProvider` | Provider | Overdue tasks only | `task_provider.dart` |
| `todayTasksProvider` | Provider | Today's tasks only | `task_provider.dart` |
| `productivityMetricsProvider` | Provider | Chart data map for Insights screen | `task_provider.dart` |
| `firestoreServiceProvider` | Provider | FirestoreService? instance | `task_provider.dart` |
| `habitsProvider` | NotifierProvider | All habit CRUD backed by stream | `habit_provider.dart` |
| `chatProvider` | NotifierProvider | AI message list + sendMessage() | `chat_provider.dart` |
| `feedbackProvider` | NotifierProvider | showMessage() / showError() | `feedback_provider.dart` |
| `appSettingsProvider` | NotifierProvider | All app toggles and preferences | `settings_provider.dart` |
| `isPremiumProvider` | Provider<bool> | Is the current user on Pro plan? | `settings_provider.dart` |
| `subscriptionProvider` | NotifierProvider | IAP products, purchase, restore | `subscription_provider.dart` |
| `currentUserProvider` | Provider | Firebase User? | `auth_provider.dart` |
| `authStateProvider` | StreamProvider | Firebase auth state stream | `auth_provider.dart` |
| `navigationProvider` | NotifierProvider | Current tab index (0-5) | `providers.dart` |
| `sharedPreferencesProvider` | Provider | SharedPreferences instance | `shared_prefs_provider.dart` |
| `pomodoroProvider` | NotifierProvider | Timer state + phase + controls | `focus_screen.dart` |

---

## CONSTANTS

```dart
// Task categories -- use exact strings, no variations
const taskCategories = ['Work', 'Personal', 'Health', 'Study', 'Finance', 'Inbox'];

// Navigation tab indices
// 0=Home | 1=Tasks | 2=Calendar | 3=AI Chat | 4=Habits | 5=Insights

// IAP Product IDs -- must match Play Console configuration exactly
const monthlyProductId = 'obsidian_pro_monthly_199';  // Rs.199/month
const yearlyProductId  = 'obsidian_pro_yearly_1499';  // Rs.1499/year

// API Keys -- injected at build time via --dart-define, never hardcode in source
// GEMINI_API_KEY | NVIDIA_API_KEY | GROQ_API_KEY

// Keystore
// Path:     android/app/obsidian-release.jks
// Alias:    obsidian
// Password: obsidian123  <- MUST BE CHANGED BEFORE PRODUCTION RELEASE
```

---

## CODE QUALITY STANDARDS

These standards apply to every file touched in every task. They are not optional.

**1. No dead code.**
Remove all commented-out blocks, unused imports, and unreachable branches before completing a task.

**2. Optimistic UI for all mutations.**
Update local Riverpod state immediately, then sync to Firestore. On failure, roll back to the previous state and show an error via `feedbackProvider`.

**3. Every async operation needs error handling.**
No naked `await` calls without try/catch in providers or services. Every failure path must be handled explicitly.

**4. No magic numbers.**
Extract padding values, durations, font sizes, and icon sizes into named constants or reference the design system. A reader should understand what a number means without guessing.

**5. Widgets must be small and focused.**
If a `build()` method exceeds approximately 80 lines, extract named sub-widgets. Widget names must clearly describe what they render (e.g., `_TaskCard`, `_EmptyState`, `_HeaderSection`).

**6. Use RepaintBoundary for expensive stable widgets.**
Wrap widgets that have stable children but live inside frequently-rebuilding parents. Examples: chart containers, header sections, avatar widgets.

**7. Streams and subscriptions must be cancelled.**
Any `StreamSubscription` or `ProviderSubscription` opened in `initState` must be closed in `dispose`. Use `ref.onDispose` in Riverpod notifiers.

**8. Pass the quality gate.**
`flutter analyze --no-fatal-infos` must return 0 errors and 0 warnings. This is the final step of every task before updating the RESULT section in bridge.md.
