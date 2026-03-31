# To-Do Smart Blueprint

## Overview

A to-do list application that gamifies your tasks and helps you stay focused.

## Style, Design, and Features

*   **Modern, Tech-Inspired UI:** Dark theme with a neon-cyan accent color, futuristic fonts (`Orbitron`, `Jura`), and a clean, minimalist layout. A consistent design is applied across all screens.
*   **Gamification:** Users earn XP for completing tasks.
*   **Task Management:** Add, delete, and mark tasks as complete.
*   **Task Libraries:** Users can create "libraries" to categorize and organize their tasks. The library name is displayed on each task card for better organization.
*   **Focus Timer:** A countdown timer for each task to encourage focused work sessions.
*   **Motivational Quotes:** Displays a new motivational quote during each focus session.
*   **Leaderboard:** A social leaderboard to compare your XP with other users.
*   **Cross-Platform:** Works on web and desktop, with a background service for mobile.
*   **"Soft-Lock" Focus Mode:** Discourages switching to other apps during a focus session by showing a persistent notification.
*   **Robustness:** Added `mounted` checks to prevent errors when handling asynchronous operations.

## Current Plan

**Completed:**

*   **Re-implement the "Task Library" feature:**
    *   Created `lib/task_library.dart` to define the `TaskLibrary` data model.
    *   Updated the `Task` model to include a reference to a `TaskLibrary`.
    *   Created a `LibraryManagementScreen` to allow users to create, view, and manage their task libraries.
    *   Integrated libraries into the task flow, allowing users to assign tasks to libraries.
    *   Added navigation to the `LibraryManagementScreen`.
*   **Improved UI Consistency:**
    *   Redesigned the "Assign Tasks" screen to match the main screen's style.
    *   Updated the task cards to display the associated library name.
*   **Improved Code Quality:**
    *   Addressed `use_build_context_synchronously` warnings by adding `mounted` checks in `countdown_screen.dart` and `main.dart`.
