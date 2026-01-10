import SwiftUI

struct GanttChartGrid: View {
    let dateRange: ClosedRange<Date>
    let rowCount: Int
    let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    private var totalDays: Int {
        let start = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

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

    private func isWeekend(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        let totalHeight = CGFloat(rowCount) * configuration.rowHeight
        let totalWidth = CGFloat(totalDays) * configuration.dayColumnWidth

        ZStack(alignment: .topLeading) {
            // Background with weekend shading
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                    Rectangle()
                        .fill(backgroundColor(for: date))
                        .frame(width: configuration.dayColumnWidth, height: totalHeight)
                }
            }

            // Vertical grid lines
            if configuration.showVerticalGrid {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(0..<totalDays, id: \.self) { index in
                        Rectangle()
                            .fill(configuration.gridColor)
                            .frame(width: 0.5, height: totalHeight)
                            .offset(x: CGFloat(index) * configuration.dayColumnWidth)
                    }
                }
                .frame(width: totalWidth, alignment: .leading)
            }

            // Horizontal grid lines
            if configuration.showHorizontalGrid {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<rowCount, id: \.self) { row in
                        Rectangle()
                            .fill(configuration.gridColor)
                            .frame(width: totalWidth, height: 0.5)
                            .offset(y: CGFloat(row) * configuration.rowHeight)
                    }
                }
                .frame(height: totalHeight, alignment: .top)
            }
        }
        .frame(width: totalWidth, height: totalHeight)
    }

    private func backgroundColor(for date: Date) -> Color {
        if configuration.showTodayMarker && isToday(date) {
            return configuration.todayMarkerColor.opacity(0.1)
        } else if configuration.showWeekendHighlight && isWeekend(date) {
            return configuration.weekendColor
        }
        return .clear
    }
}

struct TodayMarkerLine: View {
    let dateRange: ClosedRange<Date>
    let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    private var todayOffset: CGFloat? {
        let today = calendar.startOfDay(for: Date())
        let rangeStart = calendar.startOfDay(for: dateRange.lowerBound)
        let rangeEnd = calendar.startOfDay(for: dateRange.upperBound)

        guard today >= rangeStart && today <= rangeEnd else { return nil }

        let days = calendar.dateComponents([.day], from: rangeStart, to: today).day ?? 0
        return CGFloat(days) * configuration.dayColumnWidth + configuration.dayColumnWidth / 2
    }

    var body: some View {
        if configuration.showTodayMarker, let offset = todayOffset {
            Rectangle()
                .fill(configuration.todayMarkerColor)
                .frame(width: 2)
                .offset(x: offset)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
