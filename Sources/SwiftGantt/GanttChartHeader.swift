import SwiftUI

struct GanttChartHeader: View {
    let dateRange: ClosedRange<Date>
    let configuration: GanttChartConfiguration
    let scrollOffset: CGFloat
    let viewportWidth: CGFloat

    private static let calendar = Calendar.current

    // Pre-compute total days and start date for efficient index-based access
    private let startDate: Date
    private let totalDays: Int

    init(dateRange: ClosedRange<Date>, configuration: GanttChartConfiguration, scrollOffset: CGFloat = 0, viewportWidth: CGFloat = 0) {
        self.dateRange = dateRange
        self.configuration = configuration
        self.scrollOffset = scrollOffset
        self.viewportWidth = viewportWidth

        let calendar = Self.calendar
        self.startDate = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)
        self.totalDays = (calendar.dateComponents([.day], from: startDate, to: end).day ?? 0) + 1
    }

    /// Get date for a given day index
    private func date(at index: Int) -> Date {
        Self.calendar.date(byAdding: .day, value: index, to: startDate) ?? startDate
    }

    /// Calculate visible day range with buffer
    private var visibleDayRange: Range<Int> {
        guard totalDays > 0 && configuration.dayColumnWidth > 0 else { return 0..<0 }

        let bufferCount = 10
        let firstVisible = Int(floor(scrollOffset / configuration.dayColumnWidth))
        let lastVisible = Int(ceil((scrollOffset + viewportWidth) / configuration.dayColumnWidth))

        let firstWithBuffer = max(0, firstVisible - bufferCount)
        let lastWithBuffer = min(totalDays, lastVisible + bufferCount)

        return firstWithBuffer..<lastWithBuffer
    }

    /// Calculate visible week groups based on visible day range
    private var visibleWeekGroups: [(date: Date, dayCount: Int, startIndex: Int)] {
        let range = visibleDayRange
        guard !range.isEmpty else { return [] }

        var groups: [(Date, Int, Int)] = []
        var currentWeekStart: Date?
        var currentStartIndex = range.lowerBound
        var currentCount = 0

        for index in range {
            let day = date(at: index)
            let weekOfYear = Self.calendar.component(.weekOfYear, from: day)
            let year = Self.calendar.component(.yearForWeekOfYear, from: day)

            if let start = currentWeekStart {
                let startWeek = Self.calendar.component(.weekOfYear, from: start)
                let startYear = Self.calendar.component(.yearForWeekOfYear, from: start)

                if weekOfYear == startWeek && year == startYear {
                    currentCount += 1
                } else {
                    groups.append((start, currentCount, currentStartIndex))
                    currentWeekStart = day
                    currentStartIndex = index
                    currentCount = 1
                }
            } else {
                currentWeekStart = day
                currentStartIndex = index
                currentCount = 1
            }
        }

        if let start = currentWeekStart, currentCount > 0 {
            groups.append((start, currentCount, currentStartIndex))
        }

        return groups
    }

    var body: some View {
        let range = visibleDayRange
        let weekGroups = visibleWeekGroups
        let totalWidth = CGFloat(totalDays) * configuration.dayColumnWidth

        VStack(spacing: 0) {
            // Week groups row (virtualized)
            ZStack(alignment: .topLeading) {
                ForEach(weekGroups, id: \.startIndex) { group in
                    WeekGroupHeader(date: group.date, configuration: configuration)
                        .frame(width: CGFloat(group.dayCount) * configuration.dayColumnWidth)
                        .offset(x: CGFloat(group.startIndex) * configuration.dayColumnWidth)
                }
            }
            .frame(width: totalWidth, height: configuration.headerHeight * 0.5, alignment: .topLeading)

            // Day numbers row (virtualized)
            ZStack(alignment: .topLeading) {
                ForEach(Array(range), id: \.self) { index in
                    DayColumnHeader(date: date(at: index), configuration: configuration)
                        .offset(x: CGFloat(index) * configuration.dayColumnWidth)
                }
            }
            .frame(width: totalWidth, height: configuration.headerHeight * 0.5, alignment: .topLeading)
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
