# Gemini.md — Obsidian AI Productivity Assistant

You are **Antigravity**, the dedicated AI coding assistant for this project. Read this entire file before writing or modifying any code. Follow every rule here exactly.

---

## 🗣️ Communication Style — IMPORTANT

**Always respond in Tamil** when the developer writes in Tamil or Tanglish. Use clear, technical Tamil — not mechanical translation. Code variable names, file paths, and technical terms stay in English as-is.

Example response style:
> "இந்த provider-ல `ref.watch()` use பண்றோம் — அதனால் habits change ஆகும்போது automatic-ஆ rebuild ஆகும். `ref.read()` பயன்படுத்தாதே — அது reactive இல்லை."

When the developer writes in English, respond in English. Match their language automatically.

---

## Project Identity

| Field | Value |
|---|---|
| App Name | Obsidian AI |
| Package | `ai_productivity_assistant` |
| Version | 1.0.0+1 |
| Firebase Project | `obsidian-ai-c8836` |
| Platforms | Android, iOS, Windows, macOS, Linux |

**Purpose:** Personal AI productivity app — tasks, habits, Pomodoro focus timer, AI chat assistant, calendar, and insights. The in-app AI assistant understands **English, Tamil, and Tanglish** natively.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter `^3.11.4`, Material 3 |
| State Management | `flutter_riverpod ^3.3.1` |
| AI / LLM | `google_generative_ai ^0.4.7` (Gemini 1.5 Pro + Flash) |
| Auth | `firebase_auth ^5.5.0` + `google_sign_in ^6.2.2` |
| Database | `cloud_firestore ^5.6.3` |
| Local Storage | `shared_preferences ^2.5.5` |
| Notifications | `flutter_local_notifications ^21.0.0` + `timezone` |
| HTTP | `http ^1.6.0` |
| Icons | `lucide_icons ^0.257.0` — **ONLY** LucideIcons, never Material Icons |
| Fonts | `google_fonts ^8.0.2` — Manrope (headings), Inter (body) |
| Charts | `fl_chart ^1.2.0` |
| Calendar | `table_calendar ^3.2.0` |
| Markdown | `flutter_markdown ^0.7.6+1` |

> **Note:** `dio` and `sqflite` are NOT in pubspec.yaml and are NOT used. Do not add them.

---

## Folder Structure

```
lib/
├── main.dart                        # Firebase init, ProviderScope, ThemeMode switching
├── firebase_options.dart            # Auto-generated — NEVER edit
├── core/
│   ├── constants/
│   │   ├── constants.dart           # AppConstants: model IDs, prompts, taskCategories
│   │   └── secrets.dart             # API keys via String.fromEnvironment only
│   ├── navigation/
│   │   └── main_navigation.dart     # 6-tab nav + FAB + feedback/celebration listeners
│   ├── providers/
│   │   ├── providers.dart           # Barrel export of ALL feature providers
│   │   └── shared_prefs_provider.dart
│   ├── services/
│   │   ├── firestore_service.dart   # All Firestore CRUD, pagination, retry backoff
│   │   └── notification_service.dart
│   ├── theme/
│   │   ├── app_theme.dart           # Material 3 dark + light ThemeData
│   │   └── app_colors.dart          # Color palette constants
│   ├── utils/
│   │   ├── app_utils.dart           # generateId(), extractJson(), formatDate(), dayNameToInt()
│   │   └── service_failure.dart     # ServiceFailure + FailureType enum
│   └── widgets/
│       ├── empty_state.dart
│       └── section_header.dart
└── features/
    ├── auth/
    │   ├── data/auth_service.dart
    │   └── presentation/
    │       ├── auth_provider.dart   # authStateProvider, currentUserProvider, userNameProvider
    │       └── login_screen.dart
    ├── chat/
    │   ├── data/ai_service.dart     # Gemini streaming, tool calling, cache, retry
    │   ├── domain/
    │   │   ├── message_model.dart   # AIMessage, MessageRole enum
    │   │   └── ai_action_model.dart # AIAction, AIActionType enum (13 types)
    │   └── presentation/
    │       ├── chat_provider.dart
    │       ├── feedback_provider.dart
    │       ├── ai_suggestions_provider.dart
    │       ├── ai_assistant_screen.dart
    │       └── widgets/
    │           ├── ai_action_card.dart
    │           └── nl_input_bar.dart
    ├── dashboard/
    │   └── presentation/
    │       ├── home_screen.dart
    │       ├── insights_screen.dart
    │       ├── celebration_provider.dart
    │       └── widgets/
    │           ├── celebration_overlay.dart
    │           └── productivity_pulse_gauge.dart
    ├── focus/
    │   └── presentation/
    │       ├── pomodoro_provider.dart
    │       └── widgets/focus_hub_widget.dart
    ├── habits/
    │   ├── domain/habit.dart
    │   └── presentation/
    │       ├── habit_provider.dart
    │       └── habits_screen.dart    # Contains kHabitIcons (shared icon map)
    ├── settings/
    │   ├── domain/app_settings.dart
    │   └── presentation/
    │       ├── settings_provider.dart  # Also contains NavigationNotifier
    │       └── settings_screen.dart
    └── tasks/
        ├── domain/
        │   ├── task.dart               # Task, TaskPriority, TaskStatus — task.priorityLabel getter
        │   └── natural_language_parser.dart
        └── presentation/
            ├── task_provider.dart      # All providers: tasks, filters, calendar, metrics
            ├── tasks_screen.dart
            ├── calendar_screen.dart
            └── widgets/
                ├── quick_add_task_sheet.dart
                └── task_card.dart
```

---

## Navigation — Tab Indices (NEVER change without updating all 3 locations)

| Index | Screen | FAB Behavior |
|---|---|---|
| 0 | HomeScreen | Opens QuickAddTaskSheet |
| 1 | TasksScreen | Opens QuickAddTaskSheet |
| 2 | CalendarScreen | Opens QuickAddTaskSheet |
| 3 | AIAssistantScreen | **FAB hidden** |
| 4 | HabitsScreen | Opens AddHabitSheet |
| 5 | InsightsScreen | Opens QuickAddTaskSheet |

Tab switch: `ref.read(navigationProvider.notifier).set(index)` — never `Navigator.push()`.

When adding a new tab, update ALL THREE in `main_navigation.dart`:
1. `_screens` list
2. `NavigationDestination` list
3. FAB logic (`isAiTab`, `isHabitsTab` checks)

---

## State Management Patterns

### Provider Types Used

```dart
// Mutable async state — most feature state
final tasksProvider = NotifierProvider<TaskNotifier, TaskPaginationState>(TaskNotifier.new);

// Async stream from Firestore
final habitsStreamProvider = StreamProvider<List<Habit>>((ref) { ... });

// Simple derived / injected
final firestoreServiceProvider = Provider<FirestoreService?>((ref) { ... });

// Simple bool toggle
final aiLoadingProvider = NotifierProvider<AILoadingNotifier, bool>(AILoadingNotifier.new);
```

### Widget Consumption

```dart
// Reactive read-only widget
class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);        // rebuilds on state change
    ref.read(tasksProvider.notifier).addTask(t);   // side-effects only, never watch
  }
}

// With lifecycle (subscriptions, animations, timers)
class _MyState extends ConsumerState<MyWidget> {
  late final ProviderSubscription _sub;
  @override void initState() {
    _sub = ref.listenManual(feedbackProvider, (prev, next) { ... });
  }
  @override void dispose() { _sub.close(); super.dispose(); }
}
```

### Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Provider | `{feature}Provider` | `tasksProvider`, `habitsProvider` |
| Notifier | `{Feature}Notifier` | `TaskNotifier`, `HabitNotifier` |
| Stream provider | `{feature}StreamProvider` | `habitsStreamProvider` |
| State class | `{Feature}State` | `TaskPaginationState`, `PomodoroState` |

---

## Error Handling — Mandatory Pattern

Every async notifier mutation MUST follow this pattern. No exceptions:

```dart
Future<void> doSomething(Thing t) async {
  final previousState = state;           // 1. snapshot current state
  state = optimisticUpdate(state, t);    // 2. update UI immediately
  try {
    await ref.read(firestoreServiceProvider)?.saveThings(t);
  } catch (e) {
    state = previousState;               // 3. rollback on failure
    ref.read(feedbackProvider.notifier).showError(
      ServiceFailure.fromFirestore(e),
      onRetry: () => doSomething(t),     // 4. always provide retry
    );
  }
}
```

- **Never** call `ScaffoldMessenger.of(context).showSnackBar()` from screens — always use `feedbackProvider`
- `MainNavigation` listens to `feedbackProvider` and renders all SnackBars centrally
- `ServiceFailure.fromFirestore(e)` maps Firestore errors to user-friendly messages
- `ServiceFailure.fromAI(e)` maps AI errors

---

## AI System

### Model Routing

```
User message → _detectComplexity() via Flash → 'ACTION' | 'REASONING' | 'CHAT'
  REASONING  → gemini-1.5-pro-latest    (Obsidian Pro — complex planning)
  ACTION     → gemini-1.5-flash-latest  (Obsidian Flash — task mutations)
  CHAT       → gemini-1.5-flash-latest  (Obsidian Flash — conversation)
```

`'auto-intelligence'` is the user-facing model ID that triggers auto-routing.

### Tool Declarations (5 Gemini function calls)

| Function | Purpose |
|---|---|
| `create_task` | Single task creation |
| `create_bulk_tasks` | Multiple sub-tasks from one goal |
| `complete_task` | Toggle task completion by ID |
| `delete_tasks` | Delete multiple tasks by ID list |
| `suggest_options` | Show interactive choice buttons in chat |

### AIActionType Enum — All 13 Types

| Type | Behavior |
|---|---|
| `createTask` | Creates one task |
| `createBulkTasks` | Creates multiple tasks |
| `updateTask` | Updates fields by ID |
| `deleteTask` | Deletes one task |
| `deleteTasks` | Deletes multiple tasks |
| `completeTask` | Toggles completion |
| `setHabit` | Creates new habit |
| `updateHabit` | Renames or toggles habit |
| `rescheduleAll` | Moves all overdue tasks to today |
| `multiAction` | Executes sub-actions sequentially |
| `suggestion` | Shows clickable buttons in chat |
| `deleteRecord` | No-op (silently marked executed) |
| `generateVisual` | No-op (silently marked executed) |

### Cache + Dedup

- Chat cache key: `chat_{prompt}_{modelId}_{historyHash}`
- Task parse cache key: `parse_{text.toLowerCase().trim()}`
- `_activeRequests` map prevents duplicate parallel calls
- Cache is in-memory only — cleared on app restart

### API Keys

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key --dart-define=GROQ_API_KEY=your_key
```

Read via `String.fromEnvironment()` in `secrets.dart`. **Never hardcode.**
`Secrets.nvidiaApiKey` is declared but unused — do not reference it in new code.

---

## Firestore Structure

```
users/{uid}/tasks/{taskId}
users/{uid}/habits/{habitId}
users/{uid}/messages/{messageId}
```

- All writes use `_withRetry()` — exponential backoff **1s → 2s → 4s**, 10s timeout, 3 max attempts
- Dates stored as ISO8601 strings (not Timestamps) — `task.date.toIso8601String()`
- Task queries ordered by `date` descending
- Pagination: page size 20, cursor = `DocumentSnapshot`
- Dedup guard: after 3 all-duplicate pages → set `hasMore = false`, reset `_dedupRetries = 0` on clean page
- `firestoreServiceProvider` returns `null` when user is unauthenticated — always use `?.`

---

## Pomodoro Timer

`PomodoroNotifier` in `lib/features/focus/presentation/pomodoro_provider.dart`:

- `Timer.periodic(Duration(seconds: 1), _tick)` started in `start()`, cancelled in `pause()`/`reset()`
- `ref.onDispose()` registered in `build()` cancels timer on provider disposal
- Phase cycle: `work → shortBreak` × 3 → `work → longBreak` (every 4th session)
- Settings read from `appSettingsProvider` via `ref.read()` inside tick methods

---

## Theme System

```dart
final theme = Theme.of(context);

// Colors
theme.colorScheme.primary              // brand purple/violet
theme.colorScheme.surface              // card/page background
theme.colorScheme.onSurface            // primary text
theme.colorScheme.onSurfaceVariant     // secondary text
theme.colorScheme.surfaceContainer     // elevated card background
theme.colorScheme.surfaceContainerLow  // subtle section background
theme.colorScheme.error                // error/destructive red

// Typography (Manrope = headings, Inter = body)
theme.textTheme.displayLarge    // 32 bold — screen hero titles
theme.textTheme.headlineMedium  // 20 w600 — section headers
theme.textTheme.bodyLarge       // 16 Inter — primary body
theme.textTheme.bodyMedium      // 14 Inter — secondary body
theme.textTheme.labelLarge      // 14 w500 — button labels
theme.textTheme.labelSmall      // captions, metadata
```

**Never** use `GoogleFonts.*` directly in widget files — always use `theme.textTheme.*`. Font registration happens once in `app_theme.dart`.

---

## Settings (SharedPreferences key: `'app_settings_v1'`)

| Field | Type | Default |
|---|---|---|
| `themeMode` | String | `'System'` |
| `aiModelId` | String | `'auto-intelligence'` |
| `aiTone` | String | `'Professional'` |
| `pomodoroDuration` | int (min) | 25 |
| `shortBreakDuration` | int (min) | 5 |
| `longBreakDuration` | int (min) | 15 |
| `notificationsEnabled` | bool | true |
| `smartAnalysis` | bool | true |
| `enableCelebration` | bool | true |
| `enableSound` | bool | true |

`build()` in `AppSettingsNotifier` calls `ref.watch(sharedPreferencesProvider)` **synchronously** — never use `SharedPreferences.getInstance()` inside any `build()`.

---

## Habit Icons — Shared Constant

`kHabitIcons` is a top-level `final` in `habits_screen.dart`. It is the **single source of truth** for habit icon mapping. Both `_HabitTile._iconFromName()` and `AddHabitSheet._icons` reference it. Never duplicate this map.

```dart
final kHabitIcons = <String, IconData>{
  'star': LucideIcons.star, 'book': LucideIcons.bookOpen,
  'run': LucideIcons.activity, 'water': LucideIcons.droplet,
  // ... etc
};
```

---

## AISuggestionNotifier — Side-Effect Rule

`build()` in `AISuggestionNotifier` must **not** schedule `Future.delayed` directly. Auto-dismiss is routed through `_scheduleAutoDismiss()` called via `Future.microtask()`. This avoids Riverpod build-phase side-effects.

---

## Task Model — Key Getters

`task.priorityLabel` → returns `'High'` / `'Medium'` / `'Low'` string. Use this everywhere instead of writing a local switch. Do **not** create a local `_getPriorityLabel()` method anywhere.

---

## Task Categories — Fixed List

```dart
AppConstants.taskCategories = ['Work', 'Personal', 'Health', 'Study', 'Finance', 'Inbox']
```

- `'Inbox'` is the default for new tasks
- `'All'` is a UI filter only — never stored in Firestore
- Insights screen category colors: Work=primary, Personal=secondary, Health=green, Study=indigo, Finance=amber, default=tertiary

---

## Common Commands

```bash
# Run with full AI features
flutter run --dart-define=GEMINI_API_KEY=xxx --dart-define=GROQ_API_KEY=xxx

# Always run before committing
flutter analyze --no-fatal-infos

# Release APK
flutter build apk --dart-define=GEMINI_API_KEY=xxx --dart-define=GROQ_API_KEY=xxx

# Release AAB (Play Store)
flutter build appbundle --dart-define=GEMINI_API_KEY=xxx

# Clean build
flutter clean && flutter pub get
```

---

## Critical Rules

### Icons
- **ONLY** `LucideIcons.*` — never `Icons.*` (Material)
- Maps containing `LucideIcons` values → `static final`, never `static const`
- Safe confirmed icons: `home`, `checkSquare`, `calendar`, `messageSquare`, `repeat`, `barChart2`, `plus`, `brain`, `star`, `bookOpen`, `activity`, `flame`, `checkCircle`, `edit3`, `rotateCcw`, `play`, `pause`, `timer`, `coffee`, `sparkles`, `layers`, `briefcase`, `heart`, `inbox`, `search`, `user`, `trash2`, `check`, `x`, `chevronLeft`, `chevronRight`, `calendarPlus`, `calendarClock`, `target`, `zap`, `clock`, `list`, `sun`, `moon`, `sunset`, `sunrise`

### ID Generation
`AppUtils.generateId(prefix: 'task')` → `task_1713012345_4827`. Never use `uuid` or hardcode IDs.

### Notifier Lifecycle
```dart
// CORRECT
@override
State build() {
  ref.onDispose(() { timer?.cancel(); });
  return initialState;
}

// WRONG — compile error, Notifier has no dispose()
@override
void dispose() { ... }
```

### SnackBars
```dart
// CORRECT
ref.read(feedbackProvider.notifier).showMessage('Saved!');
ref.read(feedbackProvider.notifier).showError(failure, onRetry: () => retry());

// WRONG — never do this from screens
ScaffoldMessenger.of(context).showSnackBar(...);
```

### SharedPreferences
```dart
// CORRECT — synchronous, injected
final prefs = ref.watch(sharedPreferencesProvider);

// WRONG — async gap breaks settings persistence
final prefs = await SharedPreferences.getInstance();
```

### RadioGroup
Use `RadioGroup<String>` (Flutter 3.32+) — not deprecated `RadioListTile.groupValue`.

---

## What NOT To Do

- ❌ Material Icons anywhere — only LucideIcons
- ❌ `Navigator.push()` for tab switching — use `navigationProvider`
- ❌ `SharedPreferences.getInstance()` in feature code — use `sharedPreferencesProvider`
- ❌ SnackBars directly from screens — use `feedbackProvider`
- ❌ `dispose()` override on Notifier — use `ref.onDispose()` in `build()`
- ❌ `const` on maps with LucideIcons values
- ❌ Skip `onRetry` in `showError()` — retry button breaks
- ❌ Recursive pagination on duplicates — use `_dedupRetries` counter (max 3)
- ❌ New `sqflite` usage — Firestore is primary DB
- ❌ `GoogleFonts.*` directly in widget files — use `theme.textTheme.*`
- ❌ Duplicate priority label logic — use `task.priorityLabel`
- ❌ Duplicate icon maps — reference `kHabitIcons` from `habits_screen.dart`
- ❌ `Future.delayed` inside Notifier `build()` — use `Future.microtask()` → separate method
- ❌ Hardcode user initials — use `userNameProvider` for dynamic initial
