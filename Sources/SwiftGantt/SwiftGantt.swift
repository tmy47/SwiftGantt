import SwiftUI

/// SwiftGantt - A Gantt chart component for SwiftUI
public struct GanttChart<Item: GanttTask>: View {
    private let tasks: [Item]
    private let dateRange: ClosedRange<Date>
    private let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    private var totalDays: Int {
        let start = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    private var chartWidth: CGFloat {
        configuration.labelColumnWidth + CGFloat(totalDays) * configuration.dayColumnWidth
    }

    private var contentHeight: CGFloat {
        CGFloat(tasks.count) * configuration.rowHeight
    }

    public init(
        tasks: [Item],
        dateRange: ClosedRange<Date>,
        configuration: GanttChartConfiguration = .default
    ) {
        self.tasks = tasks
        self.dateRange = dateRange
        self.configuration = configuration
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header (fixed)
            ScrollView(.horizontal, showsIndicators: false) {
                GanttChartHeader(dateRange: dateRange, configuration: configuration)
                    .frame(width: chartWidth)
            }
            .disabled(true)
            .overlay(alignment: .bottom) {
                Divider()
            }

            // Chart content (scrollable both ways)
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    // Grid background
                    GanttChartGrid(
                        dateRange: dateRange,
                        rowCount: tasks.count,
                        configuration: configuration
                    )
                    .frame(width: chartWidth, height: contentHeight)

                    // Task rows
                    VStack(spacing: 0) {
                        ForEach(tasks) { task in
                            GanttTaskRow(
                                task: task,
                                dateRange: dateRange,
                                configuration: configuration
                            )
                        }
                    }

                    // Today marker line
                    TodayMarkerLine(dateRange: dateRange, configuration: configuration)
                        .frame(height: contentHeight)
                }
                .frame(width: chartWidth, height: contentHeight)
            }
        }
        .background(Color(white: 0.98))
    }
}

// MARK: - View Modifier for Configuration

public extension GanttChart {
    /// Customize the Gantt chart configuration
    func configuration(_ configuration: GanttChartConfiguration) -> GanttChart {
        GanttChart(tasks: tasks, dateRange: dateRange, configuration: configuration)
    }
}
