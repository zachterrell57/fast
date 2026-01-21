//
//  CalendarView.swift
//  Fast
//
//  Created by Zachary Terrell on 6/21/25.
//

import SwiftUI

// MARK: - Calendar Section (Expandable Container)

struct CalendarSection: View {
    let fastedDates: Set<DateComponents>
    @Binding var selectedDate: Date?
    let onDateSelected: (Date) -> Void
    @State private var isExpanded = false

    private var contentAnimation: Animation {
        .spring(response: 0.35, dampingFraction: 0.85)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isExpanded {
                    CalendarView(fastedDates: fastedDates, selectedDate: $selectedDate, onDateSelected: onDateSelected)
                        .transition(.modifier(
                            active: BlurScaleModifier(blur: 8, scale: 0.95, opacity: 0),
                            identity: BlurScaleModifier(blur: 0, scale: 1, opacity: 1)
                        ))
                } else {
                    CompactWeekView(fastedDates: fastedDates, selectedDate: $selectedDate, onDateSelected: onDateSelected)
                        .transition(.modifier(
                            active: BlurScaleModifier(blur: 8, scale: 1.05, opacity: 0),
                            identity: BlurScaleModifier(blur: 0, scale: 1, opacity: 1)
                        ))
                }
            }
            .animation(contentAnimation, value: isExpanded)

            // Chevron button
            Button {
                withAnimation(contentAnimation) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(contentAnimation, value: isExpanded)
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - Blur/Scale Transition Modifier

struct BlurScaleModifier: ViewModifier {
    let blur: CGFloat
    let scale: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

// MARK: - Compact 7-Day View

struct CompactWeekView: View {
    let fastedDates: Set<DateComponents>
    @Binding var selectedDate: Date?
    let onDateSelected: (Date) -> Void

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    private var last7Days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(last7Days, id: \.self) { date in
                VStack(spacing: 6) {
                    Text(dayLetter(for: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    DayCell(
                        date: date,
                        isFasted: isFasted(date),
                        isToday: isToday(date),
                        isSelected: isSelected(date),
                        onTap: { onDateSelected(date) }
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func dayLetter(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        return daysOfWeek[weekday - 1]
    }

    private func isFasted(_ date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return fastedDates.contains(components)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }
}

// MARK: - Full Calendar View

struct CalendarView: View {
    let fastedDates: Set<DateComponents>
    @Binding var selectedDate: Date?
    let onDateSelected: (Date) -> Void
    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            .padding(.horizontal)

            // Day of week headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Calendar days
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isFasted: isFasted(date),
                            isToday: isToday(date),
                            isSelected: isSelected(date),
                            onTap: { onDateSelected(date) }
                        )
                    } else {
                        Text("")
                            .frame(height: 32)
                    }
                }
            }
        }
        .padding()
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        let firstDayOfMonth = monthInterval.start
        let startOfFirstWeek = firstWeek.start

        // Add empty cells for days before the first of the month
        var current = startOfFirstWeek
        while current < firstDayOfMonth {
            days.append(nil)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        // Add all days in the month
        current = firstDayOfMonth
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        return days
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    private func isFasted(_ date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return fastedDates.contains(components)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }
}

struct DayCell: View {
    let date: Date
    let isFasted: Bool
    let isToday: Bool
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil

    private let calendar = Calendar.current

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack {
                if isSelected {
                    // Selected state - ring around the day
                    Circle()
                        .stroke(Color.primary, lineWidth: 3)
                }

                if isFasted {
                    Circle()
                        .fill(Color.primary)
                        .padding(isSelected ? 3 : 0)
                } else if isToday {
                    Circle()
                        .stroke(Color.primary, lineWidth: 1)
                        .padding(isSelected ? 3 : 0)
                }

                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .foregroundStyle(isFasted ? .white : .primary)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 32)
        .disabled(date > Date())  // Only disable future dates
    }
}
