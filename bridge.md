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
**ID:** BRIDGE-023

---

### TASK: Firestore Security Rules

**Context:**
The app is going to production. The current Firestore rules are likely open (allow read, write: if true) or default test rules. This is a critical security fix before Play Store submission. We need to lock down all Firestore data so only authenticated users can access their own documents.

The data structure is:
- `users/{uid}` — user profile document (isPremium, displayName, expiryDate)
- `users/{uid}/tasks/{taskId}` — tasks subcollection
- `users/{uid}/habits/{habitId}` — habits subcollection
- `users/{uid}/messages/{messageId}` — AI chat messages subcollection

---

## STEP 1 -- Create firestore.rules file

Create the file `firestore.rules` at the project root with this exact content:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Block all access by default
    match /{document=**} {
      allow read, write: if false;
    }

    // User profile document
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;

      // Tasks subcollection
      match /tasks/{taskId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }

      // Habits subcollection
      match /habits/{habitId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }

      // AI Chat messages subcollection
      match /messages/{messageId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

---

## STEP 2 -- Create firebase.json if missing

Check if `firebase.json` exists at the project root.

If it does NOT exist, create it:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

If `firestore.indexes.json` does NOT exist, create it too:

```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

---

## STEP 3 -- Attempt deploy via Firebase CLI

Run:
```powershell
firebase deploy --only firestore:rules
```

If this succeeds: record "CLI deploy: SUCCESS" in the RESULT section.

If this fails with "not logged in" or "project not found": record the exact error message in RESULT. Do NOT attempt to fix auth issues — the user will deploy manually via Firebase Console.

---

## STEP 4 -- Verify rules file is complete

Read the `firestore.rules` file back and confirm:
1. Default deny rule exists (`allow read, write: if false`)
2. All 4 paths covered: users/{uid}, tasks, habits, messages
3. All rules check `request.auth.uid == uid`

---

## RESULT
**Status:** COMPLETED
- firestore.rules created: YES ( granular per-user access )
- firebase.json exists/created: YES ( existing verified )
- CLI deploy: SUCCESS ( Deploy complete to obsidian-ai-c8836 )
- Rules verification: SUCCESS ( default deny + 4 specific paths verified )
- Notes: Security locked down for production.
