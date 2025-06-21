# Fast

A **minimal**, **free**, *on‑device* fasting tracker for iPhone, built with SwiftUI. Fast shows a large count‑up timer for your current fast and logs past fasts in a month‑view calendar. No accounts, no cloud, no ads—just tap **Start**, tap **End**, done.

---

## MVP Specification

### Objective

Deliver the simplest useful fasting app: manual start/stop, local history, monochrome UI. Everything else (notifications, HealthKit, sync, goal targets) is deferred.

### Core Features

1. **Manual Start / End Fast** – exactly one active fast at a time.
2. **Large Timer Screen** – count‑up only; no goal countdown in MVP.
3. **History Calendar** – month grid highlighting fasting days; tap a date for details, edit, or delete.
4. **Local Persistence** – SwiftData (Core Data) on device.
5. **Imperial‑Only Units** – no metric toggle needed yet.
6. **Minimal Monochrome UI** – native SF font & symbols; system dark/light modes.

### Backlog (Post‑MVP)

* Goal duration picker & progress nudges
* Local push notifications
* HealthKit write/read
* iCloud sync
* Preset fasting protocols
* Accessibility polish beyond system defaults

### Data Model

```swift
struct FastSession: Identifiable {
    var id: UUID = .init()
    var startAt: Date
    var endAt: Date? // nil while active
    // computed duration when endAt != nil
}
```

### Screens & Navigation

| Tab | Screen        | Key Elements                                    |
| --- | ------------- | ----------------------------------------------- |
| 1   | **TimerView** | Large digital timer, Start/End button           |
| 2   | **History**   | SwiftUI `Calendar` month grid, FastDetail sheet |

Navigation via `TabView`; shared `@Observable` `AppState` holds active fast.


### Risks & Mitigations

| Risk                 | Mitigation                                            |
| -------------------- | ----------------------------------------------------- |
| Timer drift / resume | Compute elapsed = `Date().timeIntervalSince(startAt)` |
| Calendar perf        | Fetch only displayed month via predicate              |

### Success Metrics

* Time‑to‑first‑fast < 30 s
* Crash‑free sessions > 99.5%

---

## Repository Layout

```
Fast/           ← Xcode project
README.md       ← This spec (static, rarely edited)
TRACKER.md      ← Living kanban board (update often)
```

## Contributing

Background agents: commit code changes **and** update `TRACKER.md` in the same PR to keep plan and reality aligned.

## License

MIT
