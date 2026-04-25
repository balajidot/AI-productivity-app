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
**Status:** COMPLETED
**ID:** BRIDGE-022

---

### TASK: Subscription Expiry Auto-Revoke & Doc Cleanup

**Step 0 -- Context:**
The app currently checks subscription expiry locally but doesn't sync the "expired" state back to Firestore. We need to ensure that if a user's plan has expired, Firestore is updated to `isPremium: false`. Also, some documentation still refers to "Obsidian AI" instead of "Zeno".

---

## STEP 1 -- Update FirestoreService

Add `revokePremiumStatus()` to `lib/core/services/firestore_service.dart`.

---

## STEP 2 -- Update SubscriptionNotifier

In `lib/features/settings/presentation/subscription_provider.dart`, inside `_init()`, detect if `isPremium` is true but `expiryDate` is in the past. If so, call `revokePremiumStatus()` and update local state.

---

## STEP 3 -- Documentation Cleanup

Replace all "Obsidian AI" occurrences with "Zeno" in:
- `Gemini.md`
- `CLAUDE.md`

---

## STEP 4 -- Verification

1. Run `flutter analyze`.
2. Verify logic via code review (cannot test IAP expiry easily in this environment).

---

## RESULT
**Status:** COMPLETED
- FirestoreService updated: YES
- SubscriptionNotifier updated: YES
- Docs cleaned up: YES
- flutter analyze: 0 issues

