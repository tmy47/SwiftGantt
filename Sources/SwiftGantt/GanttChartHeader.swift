import SwiftUI

struct GanttChartHeader: View {
    let dateRange: ClosedRange<Date>
    let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    private var days: [Date] {
        var dates: [Date] = []
        var current = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)

        while current <= end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return dates
    }

    var body: some View {
        HStack(spacing: 0) {
            // Empty space for label column
            Color.clear
                .frame(width: configuration.labelColumnWidth)

            // Date columns
            ForEach(days, id: \.self) { date in
                DateColumnHeader(date: date, configuration: configuration)
            }
        }
        .frame(height: 50)
    }
}

private struct DateColumnHeader: View {
    let date: Date
    let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isFirstDayOfMonth: Bool {
        calendar.component(.day, from: date) == 1
    }

    private var isMonday: Bool {
        calendar.component(.weekday, from: date) == 2
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 2) {
            if isFirstDayOfMonth || isMonday {
                Text(isFirstDayOfMonth ? monthName : "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("")
                    .font(.caption2)
            }

            Text(dayNumber)
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)

            Text(dayOfWeek)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: configuration.dayColumnWidth)
        .background(isToday ? configuration.todayMarkerColor.opacity(0.1) : Color.clear)
    }
}
