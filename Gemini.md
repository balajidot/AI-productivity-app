# Gemini Guidelines - Obsidian AI Productivity Assistant

You are the Obsidian AI coding assistant. This file provides the essential context for maintaining and improving this project.

## Core Architectural Patterns

- **Framework:** Flutter 3.x using Riverpod 3.x for state management.
- **Backend:** Firebase (Auth, Firestore). All user data is nested under `users/{uid}/...`.
- **Navigation:** Tab-based (`MainNavigation`) with indices: 0:Home, 1:Tasks, 2:Calendar, 3:AI Chat, 4:Habits, 5:Insights.
- **State Management:** Use `NotifierProvider` for mutable state. Prefer `AsyncValue` patterns for data fetching.
- **AI Integration:** Google Gemini via `google_generative_ai`. Uses `auto-intelligence` to route between Pro and Flash models based on complexity.

## Code Standards

1. **Clean Architecture:** Domain/Data/Presentation separation within features.
2. **Immutability:** Always use `copyWith` for state updates in Notifiers.
3. **Error Handling:** Centralized through `feedbackProvider`. Use `ServiceFailure` for mapping backend errors.
4. **Icons:** Use `LucideIcons` exclusively. Map them via `static final`.
5. **ID Generation:** Use `AppUtils.generateId(prefix: '...')`.

## Common Tasks

- **Adding a Feature:** Create folder in `lib/features/`, define domain/data/presentation, and update `core/providers/providers.dart`.
- **Updating UI:** Follow Material 3 guidelines and use `AppTheme` colors.
- **Fixing Lints:** Always run `flutter analyze` before committing.

## System Prompts for AI Features

Located in `lib/core/constants/constants.dart`. The assistant should support English, Tamil, and Tanglish naturally.
