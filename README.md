# Fast

A **minimal**, **free**, *on‑device* fasting tracker for iPhone, built with SwiftUI. Fast features a countdown timer with goal selection, an expandable history calendar, and local notifications. No accounts, no cloud, no ads—just select your goal, tap **Start**, and track your progress.

---

## Features

### Core Functionality

1. **Goal Duration Selection** – choose via circular dial or preset buttons (12h, 16h, 18h)
2. **Countdown Timer** – circular progress indicator with target duration countdown
3. **Smart History Calendar** – compact 7-day view that expands to full month grid; highlights fasting days
4. **Local Persistence** – SwiftData for all session data stored on device
5. **Push Notifications** – local notification when your fast completes
6. **Minimal UI** – monochrome design with SF Symbols; respects system dark/light modes

### In Development

See `TRACKER.md` for current work:
* Fast detail modal (view, edit, delete individual sessions)
* Design polish & app icon
* Manual test plan / QA checklist

### Future Roadmap

* HealthKit integration (read/write fasting data)
* iCloud sync across devices
* Additional preset protocols
* Accessibility enhancements

### Data Model

```swift
@Model
class FastSession {
    var id: UUID
    var startAt: Date
    var endAt: Date? // nil while active
    var targetDuration: TimeInterval // goal duration in seconds
    // computed: elapsedDuration, remainingDuration, isActive, isComplete
}
```

### Architecture

* **Single-screen UI** – expandable calendar section + timer/controls in one view
* **SwiftData** – persistence with @Query and @Environment(\.modelContext)
* **TimerEngine** – handles countdown refresh and background/foreground transitions
* **NotificationManager** – schedules local notification for fast completion

---

## Repository Layout

```
Fast/           ← Xcode project & source files
fastlane/       ← CI/CD automation scripts
README.md       ← Project overview (this file)
TRACKER.md      ← Living kanban board (update often)
CLAUDE.md       ← AI agent workflow instructions
```

## Contributing

Background agents: commit code changes **and** update `TRACKER.md` in the same PR to keep plan and reality aligned.

## License

MIT
