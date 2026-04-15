# CLAUDE.md — Obsidian AI Productivity Assistant

A complete reference for working in this codebase. Read this before exploring files.

---

## Project Overview

**App name:** Obsidian AI  
**Package:** `ai_productivity_assistant`  
**Version:** 1.0.0+1  
**Purpose:** Personal AI productivity app — tasks, habits, focus timer (Pomodoro), AI chat assistant, calendar scheduling, and insights/analytics. Targets Android, iOS, and desktop (Windows/macOS/Linux).

The AI assistant understands natural language in **English, Tamil, and Tanglish** (Tamil written in Latin script). Backend is Firebase (Auth + Firestore). AI is Google Gemini with streaming and tool calling.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter `^3.11.4`, Material 3 |
| State management | `flutter_riverpod: ^3.3.1` |
| AI/LLM | `google_generative_ai: ^0.4.7` (Gemini 1.5 Pro/Flash) |
| Auth | `firebase_auth: ^5.5.0` + `google_sign_in: ^6.2.2` |
| Database | `cloud_firestore: ^5.6.3` |
| Local storage | `shared_preferences: ^2.5.5`, `sqflite: ^2.4.2` |
| Notifications | `flutter_local_notifications: ^21.0.0` + `timezone` |
| HTTP | `http: ^1.6.0`, `dio: ^5.9.2` |
| UI | `lucide_icons: ^0.257.0`, `google_fonts: ^8.0.2`, `animations: ^2.1.2` |
| Charts | `fl_chart: ^1.2.0` |
| Calendar | `table_calendar: ^3.2.0` |
| Markdown | `flutter_markdown: ^0.7.6+1` |
| Environment | `flutter_dotenv: ^6.0.0` (for .env files, but API keys use `--dart-define`) |

---

## Folder Structure

```
lib/
├── main.dart                          # App entry: Firebase init, ProviderScope, theme switching
├── firebase_options.dart              # Auto-generated Firebase config (do not edit)
│
├── core/                              # Shared infrastructure
│   ├── constants/
│   │   ├── constants.dart             # AppConstants: model IDs, system prompts, task categories
│   │   └── secrets.dart               # API keys via String.fromEnvironment (--dart-define)
│   ├── navigation/
│   │   └── main_navigation.dart       # 6-tab bottom nav + FAB + feedback/celebration listeners
│   ├── providers/
│   │   ├── providers.dart             # Barrel export of all feature providers
│   │   └── shared_prefs_provider.dart # SharedPreferences injected at startup
│   ├── services/
│   │   ├── firestore_service.dart     # All Firestore CRUD, pagination, retry with backoff
│   │   ├── notification_service.dart  # Local notification scheduling
│   │   └── storage_service.dart       # File/image storage helpers
│   ├── theme/
│   │   ├── app_theme.dart             # Material 3 dark + light ThemeData
│   │   └── app_colors.dart            # Color palette constants
│   ├── utils/
│   │   ├── app_utils.dart             # generateId(), extractJson(), formatDate()
│   │   └── service_failure.dart       # ServiceFailure class + FailureType enum
│   └── widgets/
│       ├── empty_state.dart           # Reusable empty state widget
│       └── section_header.dart        # Consistent section title widget
│
└── features/                          # Feature modules (domain/data/presentation)
    ├── auth/
    │   ├── data/auth_service.dart
    │   └── presentation/
    │       ├── auth_provider.dart     # authStateProvider, currentUserProvider
    │       └── login_screen.dart
    ├── chat/
    │   ├── data/ai_service.dart       # Gemini streaming, tool calling, caching, retry
    │   ├── domain/
    │   │   ├── message_model.dart     # AIMessage, MessageRole enum
    │   │   └── ai_action_model.dart   # AIAction, AIActionType enum (13 action types)
    │   └── presentation/
    │       ├── chat_provider.dart     # ChatNotifier: sendMessage, executeAction, rejectAction
    │       ├── feedback_provider.dart # FeedbackNotifier: snackbar messages + retry callbacks
    │       ├── ai_suggestions_provider.dart
    │       ├── ai_assistant_screen.dart
    │       └── widgets/
    │           ├── ai_action_card.dart
    │           └── nl_input_bar.dart  # Natural language task input on home screen
    ├── dashboard/
    │   └── presentation/
    │       ├── home_screen.dart       # _PomodoroSection + NL input + AI suggestions + tasks
    │       ├── insights_screen.dart   # Charts and productivity analytics
    │       ├── celebration_provider.dart
    │       └── widgets/
    │           ├── celebration_overlay.dart
    │           └── productivity_pulse_gauge.dart
    ├── focus/
    │   └── presentation/
    │       ├── pomodoro_provider.dart # PomodoroNotifier: work/break phases, Timer.periodic
    │       └── widgets/
    │           └── focus_hub_widget.dart  # Semicircular arc progress painter
    ├── habits/
    │   ├── domain/habit.dart          # Habit model: completedDates, streak, completedToday
    │   └── presentation/
    │       ├── habit_provider.dart    # HabitNotifier: add/toggle/update/delete
    │       └── habits_screen.dart     # Stats row, 7-day strip, streak badge, AddHabitSheet
    ├── settings/
    │   ├── domain/app_settings.dart   # AppSettings model (theme, AI tone, Pomodoro durations)
    │   └── presentation/
    │       ├── settings_provider.dart # AppSettingsNotifier: persists via sharedPreferencesProvider
    │       └── settings_screen.dart   # Full settings UI with RadioGroup dialogs
    └── tasks/
        ├── domain/
        │   ├── task.dart              # Task model: TaskPriority, TaskStatus enums
        │   └── natural_language_parser.dart
        └── presentation/
            ├── task_provider.dart     # TaskNotifier: pagination, filtering, CRUD with retry
            ├── tasks_screen.dart
            ├── calendar_screen.dart
            └── widgets/
                ├── quick_add_task_sheet.dart
                └── task_card.dart
```

---

## Key Files and Their Roles

### `lib/main.dart`
- Calls `Firebase.initializeApp()` with retry
- Awaits `SharedPreferences.getInstance()` **before** `runApp()`
- Injects prefs into `ProviderScope` via `sharedPreferencesProvider.overrideWithValue(prefs)`
- Watches `appSettingsProvider` to switch `ThemeMode` reactively
- Shows `LoginScreen` when unauthenticated, `MainNavigation` when authenticated

### `lib/core/navigation/main_navigation.dart`
**Tab indices (never change these without updating all references):**
- 0 = HomeScreen
- 1 = TasksScreen
- 2 = CalendarScreen
- 3 = AIAssistantScreen
- 4 = HabitsScreen
- 5 = InsightsScreen

FAB behavior: hidden on tab 3 (AI), opens `_showAddHabitSheet()` on tab 4 (Habits), opens `_showAddTaskModal()` on all others.

### `lib/core/services/firestore_service.dart`
Single service class per authenticated user (`users/{uid}/...`). Collections:
- `users/{uid}/tasks/{taskId}`
- `users/{uid}/habits/{habitId}`
- `users/{uid}/messages/{messageId}`

All writes go through `_withRetry()` — exponential backoff: **1s → 2s → 4s**, 10s timeout, max 3 attempts.

### `lib/features/chat/data/ai_service.dart`
- Primary model: `gemini-1.5-pro-latest` (reasoning/actions)
- Fast model: `gemini-1.5-flash-latest` (chat/parsing)
- Auto-routing: `_detectComplexity()` classifies message as ACTION/REASONING/CHAT and picks model
- Tool calling: 5 function declarations (create_task, create_bulk_tasks, complete_task, delete_tasks, suggest_options)
- Result cache keyed by `chat_{prompt}_{modelId}_{historyHash}`
- Dedup guard: `_activeRequests` map prevents parallel identical requests

### `lib/features/chat/presentation/chat_provider.dart`
`executeAction()` handles all 13 `AIActionType` values:
`createTask`, `createBulkTasks`, `completeTask`, `deleteTasks`, `updateTask`, `deleteTask`, `setHabit`, `updateHabit`, `rescheduleAll`, `multiAction`, `suggestion`, `deleteRecord`, `generateVisual`

### `lib/features/settings/presentation/settings_provider.dart`
**Critical pattern:** `build()` calls `ref.watch(sharedPreferencesProvider)` synchronously. Never use `SharedPreferences.getInstance()` (async) inside `build()` — it causes settings to not persist.

### `lib/core/constants/secrets.dart`
API keys loaded via `String.fromEnvironment('GEMINI_API_KEY')`. Must be passed at build time:
```
flutter run --dart-define=GEMINI_API_KEY=xxx --dart-define=GROQ_API_KEY=xxx
```

---

## State Management Patterns

### Provider Types Used

```dart
// Synchronous computed values
final firestoreServiceProvider = Provider<FirestoreService?>((ref) { ... });

// Mutable state with methods
final tasksProvider = NotifierProvider<TaskNotifier, TaskPaginationState>(TaskNotifier.new);

// Async streams
final authStateProvider = StreamProvider<User?>((ref) { ... });

// Simple bool/int toggle
final aiLoadingProvider = NotifierProvider<AILoadingNotifier, bool>(AILoadingNotifier.new);
```

### Widget Consumption

```dart
// Read-only widget
class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);  // reactive rebuild
    ref.read(tasksProvider.notifier).addTask(t);  // side effect only
  }
}

// With lifecycle (subscriptions, animations)
class MyWidget extends ConsumerStatefulWidget { ... }
class _MyState extends ConsumerState<MyWidget> {
  late final ProviderSubscription<FeedbackState> _sub;
  @override void initState() {
    _sub = ref.listenManual(feedbackProvider, (prev, next) { ... });
  }
  @override void dispose() { _sub.close(); super.dispose(); }
}
```

### Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Provider | `{feature}Provider` | `tasksProvider`, `habitsProvider` |
| Notifier | `{Feature}Notifier` | `TaskNotifier`, `HabitNotifier` |
| Stream provider | `{feature}StreamProvider` | `habitsStreamProvider` |
| Computed/derived | `{filter}TasksProvider` | `overdueTasksProvider`, `filteredTasksProvider` |
| State class | `{Feature}State` | `TaskPaginationState`, `PomodoroState`, `FeedbackState` |

---

## Error Handling Pattern

Every async operation in notifiers follows this pattern:

```dart
Future<void> doSomething(Thing t) async {
  final previousState = state;           // 1. snapshot
  state = optimisticUpdate(state, t);    // 2. optimistic update
  try {
    await ref.read(firestoreServiceProvider)?.saveThings(t);
  } catch (e) {
    state = previousState;               // 3. rollback on failure
    ref.read(feedbackProvider.notifier).showError(
      ServiceFailure.fromFirestore(e),
      onRetry: () => doSomething(t),     // 4. retry callback
    );
  }
}
```

The `feedbackProvider` feeds into `MainNavigation._feedbackSubscription`, which renders a SnackBar with optional RETRY button. Never show SnackBars directly from screens — always route through `feedbackProvider`.

`ServiceFailure` factory constructors:
- `ServiceFailure.fromFirestore(e)` — maps Firestore error codes to user-friendly messages
- `ServiceFailure.fromAI(e)` — maps AI service errors

---

## Firestore Pagination Pattern

`TaskNotifier` uses cursor-based pagination:

```dart
class TaskPaginationState {
  final List<Task> tasks;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;  // cursor
}
```

- `loadNextPage()` fetches 20 tasks from `lastDoc` cursor
- Dedup guard: `_dedupRetries` counter — after 3 consecutive all-duplicate pages, sets `hasMore = false`
- Always reset `_dedupRetries = 0` on a clean page

---

## Pomodoro Timer Pattern

`PomodoroNotifier` (in `lib/features/focus/presentation/pomodoro_provider.dart`):
- Uses `Timer.periodic(Duration(seconds: 1), ...)` started in `start()`, cancelled in `pause()`/`reset()`
- `ref.onDispose()` registered inside `build()` to cancel timer on provider disposal
- Phase cycle: `work → shortBreak → work → shortBreak → work → shortBreak → work → longBreak` (every 4 sessions)
- Settings (`pomodoroDuration`, `shortBreakDuration`, `longBreakDuration`) read from `appSettingsProvider`

**Do not** override `dispose()` on a `Notifier` — it doesn't exist. Use `ref.onDispose()` in `build()`.

---

## Theme System

```dart
// Access in widgets
final theme = Theme.of(context);
theme.colorScheme.primary       // main brand color
theme.colorScheme.surface       // card/container background
theme.colorScheme.onSurface     // text on surface
theme.colorScheme.surfaceContainerHighest  // elevated surface

// Typography (uses Google Fonts: Manrope for display, Inter for body)
theme.textTheme.headlineMedium  // screen titles
theme.textTheme.titleLarge      // section headers
theme.textTheme.bodyMedium      // body text
theme.textTheme.labelSmall      // captions, metadata
```

Theme mode is driven by `appSettingsProvider.themeMode` (`'Light'` / `'Dark'` / `'System'`). Switching theme saves to SharedPreferences and rebuilds immediately.

---

## AI Actions System

`AIActionType` enum (13 types) in `lib/features/chat/domain/ai_action_model.dart`:

| Type | What it does |
|------|-------------|
| `createTask` | Creates a single task |
| `createBulkTasks` | Creates multiple tasks from a list |
| `updateTask` | Updates task fields by ID |
| `deleteTask` | Deletes a single task by ID |
| `deleteTasks` | Deletes multiple tasks by IDs |
| `completeTask` | Toggles task completion |
| `setHabit` | Creates a new habit |
| `updateHabit` | Renames habit or toggles today's completion |
| `rescheduleAll` | Moves all overdue tasks to today |
| `multiAction` | Executes a list of sub-actions sequentially |
| `suggestion` | Shows clickable suggestion buttons in chat |
| `deleteRecord` | No-op (silently marked executed) |
| `generateVisual` | No-op (silently marked executed) |

Actions rendered in chat via `AIActionCard` widget. User can accept (execute) or reject.

---

## Coding Conventions

### File naming
- Screens: `*_screen.dart`
- Providers: `*_provider.dart`
- Domain models: plain name, no suffix (`task.dart`, `habit.dart`)
- Services: `*_service.dart`
- Widgets: `*_widget.dart`, `*_card.dart`, `*_sheet.dart`, `*_overlay.dart`
- Private widget classes within a file: prefix with `_` (`_HabitTile`, `_StatsRow`)

### Class naming
- Models: PascalCase, no suffix (`Task`, `Habit`, `AIMessage`, `AppSettings`)
- Notifiers: `{Feature}Notifier` extends `Notifier<State>`
- State objects: `{Feature}State` (immutable, with `copyWith`)
- Enums: PascalCase (`TaskPriority`, `PomodoroPhase`, `AIActionType`)
- Screens: `{Feature}Screen`

### ID generation
Always use `AppUtils.generateId(prefix: 'task')` — format: `task_1713012345_4827`. Never hardcode or use `uuid` package.

### Imports order (per file)
1. `dart:*`
2. `package:flutter/*`
3. Third-party packages (`package:riverpod/*`, `package:firebase_*`, etc.)
4. Relative imports (`../../../core/...`, `../../features/...`)

### Icons
Only use `LucideIcons.*` (from `lucide_icons: ^0.257.0`). Confirmed working icons in this codebase: `home`, `checkSquare`, `calendar`, `messageSquare`, `repeat`, `barChart2`, `plus`, `brain`, `star`, `bookOpen`, `activity`, `moon`, `droplet`, `terminal`, `headphones`, `utensils`, `navigation`, `flame`, `checkCircle`, `edit3`, `rotateCcw`, `play`, `pause`, `timer`, `coffee`, `batteryCharging`, `sparkles`, `penLine` (avoid — may not exist), `pen` (avoid — may not exist).

**Important:** Maps containing `LucideIcons` values must be `static final`, NOT `static const` — `LucideIcons` getters are not compile-time constants.

### RadioGroup (Flutter 3.32+)
Use `RadioGroup<String>` widget (introduced in Flutter 3.32) — **not** the deprecated `RadioListTile.groupValue` pattern. The `settings_screen.dart` has the correct usage pattern with `StatefulBuilder`.

---

## Common Commands

```bash
# Run with API keys (required for AI features)
flutter run --dart-define=GEMINI_API_KEY=your_key --dart-define=GROQ_API_KEY=your_key

# Run without AI (limited functionality)
flutter run

# Analyze for errors
flutter analyze --no-fatal-infos

# Build release APK
flutter build apk --dart-define=GEMINI_API_KEY=xxx --dart-define=GROQ_API_KEY=xxx

# Build release AAB (Play Store)
flutter build appbundle --dart-define=GEMINI_API_KEY=xxx

# Clean build
flutter clean && flutter pub get
```

---

## Important Patterns & Gotchas

### 1. SharedPreferences must be synchronous in `build()`
```dart
// CORRECT — injected, synchronous
@override
AppSettings build() {
  final prefs = ref.watch(sharedPreferencesProvider); // sync
  final json = prefs.getString('settings');
  ...
}

// WRONG — async gap means state is lost on restart
@override
AppSettings build() {
  _loadSettings(); // async, not awaited — settings never loaded
  return const AppSettings();
}
```

### 2. `firestoreServiceProvider` returns nullable
```dart
// Always null-check with ?. or guard
await ref.read(firestoreServiceProvider)?.saveTask(task);
```
It returns `null` when user is not authenticated. The `Provider` watches `currentUserProvider` — logs the user in automatically when auth state changes.

### 3. Never recurse in pagination on duplicates
If `loadNextPage()` gets all-duplicate results, use the `_dedupRetries` counter (max 3) then set `hasMore = false`. Do NOT call `loadNextPage()` recursively — it causes stack overflow.

### 4. `Notifier` has no `dispose()` method
```dart
// CORRECT
@override
State build() {
  ref.onDispose(() { myTimer?.cancel(); });
  ...
}

// WRONG — compile error
@override
void dispose() { ... }  // doesn't exist on Notifier
```

### 5. Feedback/SnackBars go through feedbackProvider
Never call `ScaffoldMessenger.of(context).showSnackBar()` directly from feature screens. Always:
```dart
ref.read(feedbackProvider.notifier).showMessage('Done!');
ref.read(feedbackProvider.notifier).showError(e, onRetry: () => retry());
```
The `MainNavigation` renders all SnackBars centrally.

### 6. Optimistic updates with rollback
All `HabitNotifier`, `TaskNotifier` mutations update state immediately, then persist. On failure they roll back to `previousState`. This keeps the UI snappy.

### 7. `build()` in `Notifier` is reactive
`ref.watch()` inside `build()` means the notifier rebuilds when watched providers change. Use this for derived state (e.g., `habitsProvider` watches `habitsStreamProvider`). Do NOT call async operations inside `build()`.

### 8. Task categories are fixed
`AppConstants.taskCategories = ['Work', 'Personal', 'Health', 'Study', 'Finance', 'Inbox']`. The `'Inbox'` category is the default for new tasks. Do not add a 'All' entry — that's a UI filter, not a stored category.

### 9. AI model routing
`'auto-intelligence'` is the user-facing model ID that auto-selects between Pro and Flash based on complexity detection. Other model IDs are mapped in `AppConstants.modelLabels`.

### 10. Celebration overlay
After completing tasks, trigger `CelebrationOverlay.show(context)` via `celebrationProvider`. Never call it directly from a task widget — route through the provider so `MainNavigation` fires it once centrally.

---

## Firebase / Firestore Notes

- Firebase project ID: `obsidian-ai-c8836`
- All user data is scoped to `users/{uid}/...` — no shared collections
- Firestore offline persistence is enabled by default (Flutter Firebase SDK)
- Firestore security rules: stored in `firestore.rules` at project root
- Indexes: stored in `firestore.indexes.json` at project root
- Task queries are ordered by `date` field (Timestamp) — always store dates as Firestore Timestamps, not strings

---

## Settings Stored in SharedPreferences

Key: `'app_settings'` (JSON string). Fields in `AppSettings`:

| Field | Type | Default |
|-------|------|---------|
| `smartAnalysis` | bool | true |
| `notificationsEnabled` | bool | true |
| `aiTone` | String | `'Professional'` |
| `themeMode` | String | `'System'` |
| `aiModelId` | String | `'auto-intelligence'` |
| `enableCelebration` | bool | true |
| `enableSound` | bool | true |
| `pomodoroDuration` | int (minutes) | 25 |
| `shortBreakDuration` | int (minutes) | 5 |
| `longBreakDuration` | int (minutes) | 15 |

---

## What NOT to Do

- **Don't** create new files unless necessary — prefer editing existing ones
- **Don't** add `package:shared_preferences/shared_preferences.dart` imports in feature code — use `sharedPreferencesProvider` from `lib/core/providers/shared_prefs_provider.dart`
- **Don't** use `Navigator.push()` for main tab switching — use `ref.read(navigationProvider.notifier).set(index)`
- **Don't** add `const` to maps that contain `LucideIcons` values — they're runtime getters, not compile-time constants
- **Don't** add `dispose()` override to `Notifier` subclasses — it doesn't exist; use `ref.onDispose()` in `build()`
- **Don't** call `SharedPreferences.getInstance()` anywhere in feature code — it's already injected
- **Don't** skip the `onRetry` callback in `showError()` calls inside notifiers — retry button on SnackBar won't work
- **Don't** show SnackBars from screens directly — always use `feedbackProvider`
- **Don't** use `sqflite` for new features — Firestore is the primary database; sqflite is present but largely unused
- **Don't** add new tab screens without updating both `_screens` list AND `NavigationDestination` list AND the FAB logic in `main_navigation.dart`
