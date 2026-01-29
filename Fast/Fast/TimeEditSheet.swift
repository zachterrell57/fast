//
//  TimeEditSheet.swift
//  Fast
//
//  Sheet for editing fast start or end times.
//

import SwiftUI

struct TimeEditSheet: View {
    enum EditType {
        case start
        case end
    }

    let editType: EditType
    @Binding var date: Date
    let minDate: Date?
    let maxDate: Date?
    let onSave: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date

    init(
        editType: EditType,
        date: Binding<Date>,
        minDate: Date? = nil,
        maxDate: Date? = nil,
        onSave: @escaping (Date) -> Void
    ) {
        self.editType = editType
        self._date = date
        self.minDate = minDate
        self.maxDate = maxDate
        self.onSave = onSave
        self._selectedDate = State(initialValue: date.wrappedValue)
    }

    private var title: String {
        switch editType {
        case .start:
            return "Edit Start Time"
        case .end:
            return "Edit End Time"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    title,
                    selection: $selectedDate,
                    in: dateRange,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedDate)
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .presentationDetents([.height(300)])
    }

    private var dateRange: ClosedRange<Date> {
        let min = minDate ?? .distantPast
        let max = maxDate ?? Date()
        return min...max
    }
}

#Preview("Edit Start Time") {
    TimeEditSheet(
        editType: .start,
        date: .constant(Date()),
        maxDate: Date().addingTimeInterval(3600),
        onSave: { _ in }
    )
}

#Preview("Edit End Time") {
    TimeEditSheet(
        editType: .end,
        date: .constant(Date()),
        minDate: Date().addingTimeInterval(-3600),
        onSave: { _ in }
    )
}
