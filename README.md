# InOut ⏱️

![Flutter](https://img.shields.io/badge/Flutter-3.50-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.14-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Storage](https://img.shields.io/badge/Storage-SQLite%20(Drift)-003B57?logo=sqlite&logoColor=white)
![Local only](https://img.shields.io/badge/Backend-none-lightgrey)

> **A personal office punch in/out tracker: tap to clock in, tap to clock out, and see your hours by day and month.**

InOut is a local-only Flutter app for tracking how long you spend in the office. It records the device time when you clock in and out, adds up your sessions per day, and shows the result in a color-coded calendar with a monthly total. It has no backend, no account and no network access. Everything stays on your phone.

It is built for one person: me, tracking my own office hours.

---

## 📖 Context

> *Office hours add up quietly, and a spreadsheet is too much effort to keep daily.*

I wanted a one-tap way to record in and out times, without maintaining a sheet or trusting my memory at the end of the month. The app is deliberately small: two actions, one calendar, one total.

Design constraints:

- **Personal use only**, so no server, login or sync
- **Device time is trusted**, because this is a self-tracker and not an attendance system
- **Day shifts only**, so a session must start and end on the same day

---

## ✨ Features

### Core Capabilities

- One-tap **Clock In / Clock Out** with the current device time
- **Multiple sessions per day** (lunch breaks, stepping out)
- **Live daily total** with a progress ring toward a fixed **9 hour** target
- **Calendar view** with hours per day and color coding
- **Monthly total** that follows the visible month
- **Add, edit and delete sessions** manually
- **CSV export** straight to `Downloads/InOut/`
- Light and dark themes

### Data / Integrity / UX / Reliability

- An open session survives the app being killed or the phone restarting
- Overlapping sessions, future times, and clock-out before clock-in are rejected
- A session left open from an earlier day is flagged, and clocking out opens the editor so you can enter the real time
- Weekends are never marked as missed, but hours logged on them still count
- Data stays on the device. Uninstalling the app deletes it, so use CSV export as a backup

### Calendar Colors (Mon-Fri)

| Color | Meaning |
|---|---|
| 🟩 Green | 9h or more |
| 🟨 Amber | 6h to under 9h |
| 🟥 Red | Under 6h |
| 🩷 Pale red | Past weekday with no hours |
| 🟦 Blue | Clocked in right now |

---

## 🧠 Engineering Highlights

### 1. An open session is just a `NULL` clock-out

The `sessions` table has three columns: `id`, `clock_in`, and a nullable `clock_out`. "Currently clocked in" is simply "a row with no clock-out". There is no separate flag to drift out of sync, and the state survives restarts for free.

### 2. Validation lives in the database layer

Punching, adding and editing all go through the same checks inside a single transaction (overlap, same-day, future times, one open session at a time). The UI can't skip a rule, and a check-then-write can't be interleaved with another write.

### 3. Derived data is never stored

Daily totals, month totals and calendar colors are computed from the sessions. One Drift `watch()` query per month feeds the calendar cells, the month total and the day list through Riverpod stream providers, so they cannot disagree.

### 4. Honest handling of forgotten clock-outs

A session left open on a past day counts as zero hours until it is corrected, instead of silently inflating the day to 20+ hours. The Home screen shows a warning, and the calendar marks that day so it can be fixed.

### 5. Ready-made packages, chosen for Flutter 3.50

Flutter 3.50 splits Material into a separate `material_ui` package. `table_calendar` still depends on the old library and failed at runtime, so the calendar uses `flutter_calendar_carousel`, driven through its own theme, style resolver and marker APIs rather than custom cell widgets.

---

## 🧑‍💼 What This Project Demonstrates

- Reactive UI driven by database streams (Drift `watch()` + Riverpod)
- Data integrity rules enforced at the persistence layer
- Designing for real-world mistakes, such as forgotten clock-outs and device clock changes
- Making dependency decisions under a framework migration (the Flutter 3.50 Material split)
- Keeping scope small: no backend, no accounts, no feature creep

---

## 🏗 Tech Stack

### Core

- **Dart / Flutter** 3.50
- **Riverpod** for state management
- **Drift** (SQLite) for local storage

### Packages

- `material_ui`: Material widgets (Flutter 3.50 split)
- `flutter_calendar_carousel`: calendar grid
- `percent_indicator`: daily progress ring
- `csv`, `path_provider`, `intl`: export and formatting
- `flutter_launcher_icons`, `launcher_name`: app icon and name

---

## 🗂 Architecture

```
lib/
├── main.dart                  # App + light/dark theme (deepPurple seed, orange accent)
├── data/
│   └── app_database.dart      # Drift table, queries, validation rules
├── providers/
│   └── providers.dart         # Riverpod stream providers (open session, today, month)
├── screens/
│   ├── app_shell.dart         # Bottom navigation
│   ├── home_screen.dart       # Clock button, progress ring, today's sessions
│   └── calendar_screen.dart   # Calendar, month total, day sessions, CSV export
├── widgets/
│   └── session_editor.dart    # Add / edit / delete dialog
└── utils/
    ├── time_utils.dart        # Durations, daily totals, day status rules
    └── csv_export.dart        # CSV builder and Downloads writer
```

### CSV export

Saved to `Downloads/InOut/inout_sessions_<timestamp>.csv`:

```csv
ID,Date,Day,Clock In,Clock Out,Minutes,Hours,Status
12,2026-11-18,Wed,09:05,13:00,235,3.92,Completed
13,2026-11-18,Wed,14:00,18:30,270,4.50,Completed
14,2026-11-19,Thu,09:10,,,,Open
```

An unfinished session has an empty clock-out and is marked `Open`.

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.50.0 (Dart 3.14)
- An Android device or emulator

### Setup

```bash
# Clone
git clone https://github.com/Sourish-Kanna/InOut.git
cd InOut

# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build

# Run locally
flutter run
```

Optional, to regenerate the app icon and launcher name:

```bash
dart run flutter_launcher_icons
dart run launcher_name:main
```

---

## 🌿 Project Status

- **Current state:** active, personal use
- **Known limitations:**
  - Android is the target platform
  - No night shifts: a session cannot cross midnight
  - Device time is trusted, so changing the phone clock changes the data
  - No in-app backup or restore, only CSV export (no import yet)
  - No automated tests

---

## ⚠️ Disclaimer

A personal project for tracking my own hours. It is not an attendance or payroll system, and it comes with no guarantees. Your data lives only on your device.

---

<div align="center">
  <small>Two taps a day. Everything else is calculated.</small>
</div>
