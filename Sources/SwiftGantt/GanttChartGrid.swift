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

    var body: some View {
        Canvas { context, size in
            let totalHeight = CGFloat(rowCount) * configuration.rowHeight

            // Weekend shading
            if configuration.showWeekendHighlight {
                for (index, date) in days.enumerated() {
                    let weekday = calendar.component(.weekday, from: date)
                    let isWeekend = weekday == 1 || weekday == 7

                    if isWeekend {
                        let x = CGFloat(index) * configuration.dayColumnWidth
                        let rect = CGRect(
                            x: x,
                            y: 0,
                            width: configuration.dayColumnWidth,
                            height: totalHeight
                        )
                        context.fill(Path(rect), with: .color(configuration.weekendColor))
                    }
                }
            }

            // Today column highlight
            if configuration.showTodayMarker {
                for (index, date) in days.enumerated() {
                    if calendar.isDateInToday(date) {
                        let x = CGFloat(index) * configuration.dayColumnWidth
                        let rect = CGRect(
                            x: x,
                            y: 0,
                            width: configuration.dayColumnWidth,
                            height: totalHeight
                        )
                        context.fill(Path(rect), with: .color(configuration.todayMarkerColor.opacity(0.1)))
                    }
                }
            }

            // Vertical grid lines
            if configuration.showVerticalGrid {
                for index in 0...days.count {
                    let x = CGFloat(index) * configuration.dayColumnWidth

                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: totalHeight))

                    context.stroke(path, with: .color(configuration.gridColor), lineWidth: 0.5)
                }
            }

            // Horizontal grid lines
            if configuration.showHorizontalGrid {
                for row in 0...rowCount {
                    let y = CGFloat(row) * configuration.rowHeight

                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))

                    context.stroke(path, with: .color(configuration.gridColor), lineWidth: 0.5)
                }
            }
        }
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
