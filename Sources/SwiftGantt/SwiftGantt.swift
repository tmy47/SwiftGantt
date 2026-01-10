import SwiftUI

/// SwiftGantt - A Gantt chart component for SwiftUI
public struct GanttChart<Item: GanttTask>: View {
    private let tasks: [Item]
    private let dateRange: ClosedRange<Date>
    private let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    @State private var hasScrolledToToday = false

    private var totalDays: Int {
        let start = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    private var timelineWidth: CGFloat {
        CGFloat(totalDays) * configuration.dayColumnWidth
    }

    private var contentHeight: CGFloat {
        CGFloat(tasks.count) * configuration.rowHeight
    }

    private var todayIndex: Int? {
        let today = calendar.startOfDay(for: Date())
        let rangeStart = calendar.startOfDay(for: dateRange.lowerBound)
        let rangeEnd = calendar.startOfDay(for: dateRange.upperBound)

        guard today >= rangeStart && today <= rangeEnd else { return nil }

        return calendar.dateComponents([.day], from: rangeStart, to: today).day
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
        ScrollViewReader { scrollProxy in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Dates header with today anchor
                    HStack(spacing: 0) {
                        ForEach(0..<totalDays, id: \.self) { dayIndex in
                            Color.clear
                                .frame(width: configuration.dayColumnWidth, height: configuration.headerHeight)
                                .id(dayIndex == todayIndex ? "today" : "day-\(dayIndex)")
                        }
                    }
                    .frame(width: timelineWidth, height: configuration.headerHeight)
                    .overlay {
                        GanttChartHeader(dateRange: dateRange, configuration: configuration)
                            .frame(width: timelineWidth, height: configuration.headerHeight)
                    }

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: timelineWidth, height: 1)

                    // Chart content
                    ZStack(alignment: .topLeading) {
                        // Grid
                        GanttChartGrid(
                            dateRange: dateRange,
                            rowCount: tasks.count,
                            configuration: configuration
                        )
                        .frame(width: timelineWidth, height: contentHeight)

                        // Task bars
                        VStack(spacing: 0) {
                            ForEach(tasks) { task in
                                GanttTaskBarRow(
                                    task: task,
                                    dateRange: dateRange,
                                    configuration: configuration
                                )
                            }
                        }

                        // Today marker
                        TodayMarkerLine(dateRange: dateRange, configuration: configuration)
                            .frame(height: contentHeight)
                    }
                    .frame(width: timelineWidth, height: contentHeight)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.98))
            .onAppear {
                if !hasScrolledToToday && todayIndex != nil {
                    hasScrolledToToday = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollProxy.scrollTo("today", anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Task Label View

struct TaskLabelView<Item: GanttTask>: View {
    let task: Item
    let configuration: GanttChartConfiguration

    var body: some View {
        HStack(spacing: 12) {
            CircularProgressView(
                progress: task.progress,
                color: task.color,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let subtitle = task.subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(width: configuration.labelColumnWidth, height: configuration.rowHeight)
    }
}

// MARK: - Task Bar Row

struct GanttTaskBarRow<Item: GanttTask>: View {
    let task: Item
    let dateRange: ClosedRange<Date>
    let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    private var totalDays: Int {
        let start = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 1
    }

    private var chartWidth: CGFloat {
        CGFloat(totalDays + 1) * configuration.dayColumnWidth
    }

    private var taskStartOffset: CGFloat {
        let rangeStart = calendar.startOfDay(for: dateRange.lowerBound)
        let taskStart = calendar.startOfDay(for: task.startDate)
        let days = calendar.dateComponents([.day], from: rangeStart, to: taskStart).day ?? 0
        return CGFloat(days) * configuration.dayColumnWidth
    }

    private var taskWidth: CGFloat {
        let taskStart = calendar.startOfDay(for: task.startDate)
        let taskEnd = calendar.startOfDay(for: task.endDate)
        let days = calendar.dateComponents([.day], from: taskStart, to: taskEnd).day ?? 0
        return CGFloat(days + 1) * configuration.dayColumnWidth
    }

    private var barHeight: CGFloat {
        configuration.rowHeight * configuration.barHeightRatio
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
                .frame(width: chartWidth, height: configuration.rowHeight)

            TaskBar(
                progress: task.progress,
                color: task.color,
                configuration: configuration,
                barHeight: barHeight
            )
            .frame(width: max(taskWidth, configuration.dayColumnWidth / 2), height: barHeight)
            .offset(x: taskStartOffset)
        }
        .frame(height: configuration.rowHeight)
    }
}

// MARK: - Task Bar

private struct TaskBar: View {
    let progress: Double
    let color: Color
    let configuration: GanttChartConfiguration
    let barHeight: CGFloat

    private var progressText: String {
        "\(Int(progress * 100))%"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: configuration.barCornerRadius)
                    .fill(color.opacity(0.3))

                if progress > 0 {
                    RoundedRectangle(cornerRadius: configuration.barCornerRadius)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                }

                if configuration.showProgressLabel && progress > 0 {
                    Text(progressText)
                        .font(configuration.progressLabelFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

// MARK: - Configuration Modifier

public extension GanttChart {
    func configuration(_ configuration: GanttChartConfiguration) -> GanttChart {
        GanttChart(tasks: tasks, dateRange: dateRange, configuration: configuration)
    }
}
