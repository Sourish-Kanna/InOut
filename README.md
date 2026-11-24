# InOut ⏱️

<!-- Badges -->
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=Dart&logoColor=white)](https://dart.dev)
[![Drift](https://img.shields.io/badge/Drift-SQLite-blue)](https://drift.simonbinder.eu/)

> **A privacy-first, local-only Flutter application for tracking work hours, punch-in/punch-out sessions, daily targets, and monthly total hours.**

InOut is responsible for managing office attendance and shift tracking completely offline. It provides users with a frictionless way to monitor daily work durations against targets, visualize historical attendance on an interactive calendar, review monthly totals, and export session logs without relying on external cloud infrastructure or user accounts.

---

## 📖 Context

> *Manual time tracking on spreadsheets or subscription-based SaaS tools often introduces privacy risks, unnecessary cloud dependencies, and friction.*

- Solves the real-world problem of personal office hour tracking with absolute data ownership.
- Exists as a standalone, zero-config mobile and desktop application.
- Designed with strict offline-first and local storage constraints to ensure privacy and reliability.

---

## ✨ Features

### Core Capabilities

- **One-Tap Punch Clock**: Seamless clock in and out from the home dashboard with real-time live ticker updates.
- **Interactive Calendar View**: Monthly calendar display with color-coded day statuses (9h+ target met, 6-9h partial, under 6h short, missed, and in-progress).
- **Monthly Work Totals**: Cumulative monthly hour summaries calculated automatically.
- **CSV Data Export**: Cross-platform data export (Android, iOS, Web) for easy reporting and record-keeping.

### Data / Integrity / UX / Reliability

- **Strict Session Validation**: Database-level checks preventing session overlaps, future timestamps, and inverted intervals.
- **Stale Session Recovery**: Automatic detection and prompt resolution for unclosed shifts carried over from previous days.
- **Reactive State Management**: Powered by Flutter Riverpod and Drift reactive SQLite streams for instant UI updates.
- **Material 3 Theming**: Dynamic light and dark theme support adapted to system preferences.

---

## 🧠 Engineering Highlights

Explain the important design decisions, implementation details, or trade-offs relevant to this project.

### 1. Reactive SQLite Architecture with Drift

Using Drift combined with Flutter Riverpod streams ensures the UI remains fully synchronized with database mutations without manual polling or state boilerplate.

### 2. Transactional Business Rule Validation

All punch-in, punch-out, and session modification operations are wrapped in database transactions with strict constraint validation to maintain absolute time integrity.

### 3. Cross-Platform Export Abstraction

Platform-specific export helpers isolate I/O and web download behaviors, allowing uniform CSV generation across mobile, desktop, and web targets.

---

## 🧑‍💼 What This Project Demonstrates

This repository demonstrates:

- Local-first database design using Drift and SQLite in Flutter.
- Reactive state management architecture with Flutter Riverpod.
- Advanced calendar customisation and date/time manipulation in mobile apps.
- Robust validation strategies for time-sensitive productivity applications.

> Keep this factual and specific to the project.

---

## 🏗 Tech Stack

### Core

- **Language**: Dart (`^3.14.0`)
- **Framework**: Flutter
- **UI Toolkit**: Material 3

### Cloud / Data / Tooling

- **Database**: Drift (`drift`, `drift_flutter`) / SQLite
- **State Management**: Flutter Riverpod (`flutter_riverpod`)
- **UI Components**: `percent_indicator`, `flutter_calendar_carousel`
- **Export & Utils**: `csv`, `intl`, `path_provider`, `web`

🔗 Related Repositories *(if any)*:

- None (Standalone client application)

---

## 📡 API / Architecture / Usage *(Optional)*

Explain:

- Public interfaces, data models (`Sessions` table), and database repository methods (`punchIn`, `punchOut`, `addSession`, `updateSession`).
- Reactive streams (`watchOpenSession`, `watchSessionsBetween`).

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (compatible with Dart `^3.14.0`)
- Android Studio / VS Code with Flutter & Dart extensions

### Setup

```bash
# Clone
git clone <repo-url>
cd in_out

# Install dependencies
flutter pub get

# Generate database code (Drift)
dart run build_runner build --delete-conflicting-outputs

# Run locally
flutter run
```

---

## 🌿 Project Status

- **Current state**: Stable & Active
- **Known limitations**: Local storage only (no cloud synchronization by design).

---

## ⚠️ Disclaimer *(Optional)*

- Intended use: Personal productivity and office time tracking.
- No SLA or cloud guarantees; data resides entirely on the local device.

---

## 🤝 Contributing *(Optional)*

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License *(Optional)*

MIT License  
*(subject to personal project terms)*

---

<div align="center">
  <small>Built with Flutter & Drift for effortless time tracking.</small>
</div>
