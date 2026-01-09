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

    private var weekGroups: [(date: Date, dayCount: Int)] {
        var groups: [(Date, Int)] = []
        var currentWeekStart: Date?
        var currentCount = 0

        for day in days {
            let weekOfYear = calendar.component(.weekOfYear, from: day)
            let year = calendar.component(.yearForWeekOfYear, from: day)

            if let start = currentWeekStart {
                let startWeek = calendar.component(.weekOfYear, from: start)
                let startYear = calendar.component(.yearForWeekOfYear, from: start)

                if weekOfYear == startWeek && year == startYear {
                    currentCount += 1
                } else {
                    groups.append((start, currentCount))
                    currentWeekStart = day
                    currentCount = 1
                }
            } else {
                currentWeekStart = day
                currentCount = 1
            }
        }

        if let start = currentWeekStart, currentCount > 0 {
            groups.append((start, currentCount))
        }

        return groups
    }

    var body: some View {
        VStack(spacing: 0) {
            // Week groups row
            HStack(spacing: 0) {
                ForEach(weekGroups, id: \.date) { group in
                    WeekGroupHeader(date: group.date, configuration: configuration)
                        .frame(width: CGFloat(group.dayCount) * configuration.dayColumnWidth)
                }
            }
            .frame(height: configuration.headerHeight * 0.5)

            // Day numbers row
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { date in
                    DayColumnHeader(date: date, configuration: configuration)
                }
            }
            .frame(height: configuration.headerHeight * 0.5)
        }
    }
}

private struct WeekGroupHeader: View {
    let date: Date
    let configuration: GanttChartConfiguration

    private var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        Text(weekLabel)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }
}

private struct DayColumnHeader: View {
    let date: Date
    let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isWeekend: Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            if isWeekend && configuration.showWeekendHighlight {
                configuration.weekendColor
            }

            if isToday && configuration.showTodayMarker {
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.todayMarkerColor)
                    .padding(2)
            }

            Text(dayNumber)
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .white : (isWeekend ? .secondary : .primary))
        }
        .frame(width: configuration.dayColumnWidth)
    }
}
