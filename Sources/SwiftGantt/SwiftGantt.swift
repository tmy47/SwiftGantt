import SwiftUI

/// SwiftGantt - A Gantt chart component for SwiftUI
public struct GanttChart<Item: GanttTask>: View {
    private let tasks: [Item]
    private let dateRange: ClosedRange<Date>
    private let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    @State private var verticalScrollOffset: CGFloat = 0
    @State private var horizontalScrollOffset: CGFloat = 0
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
        GeometryReader { geometry in
            let availableHeight = geometry.size.height - configuration.headerHeight

            ZStack(alignment: .topLeading) {
                // Main scrollable content (timeline + bars)
                VStack(spacing: 0) {
                    // Header
                    ScrollView(.horizontal, showsIndicators: false) {
                        GanttChartHeader(dateRange: dateRange, configuration: configuration)
                            .frame(width: timelineWidth, height: configuration.headerHeight)
                            .offset(x: horizontalScrollOffset)
                    }
                    .frame(height: configuration.headerHeight)
                    .disabled(true)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }

                    // Chart content
                    ScrollViewReader { scrollProxy in
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            ZStack(alignment: .topLeading) {
                                // Grid background
                                GanttChartGrid(
                                    dateRange: dateRange,
                                    rowCount: tasks.count,
                                    configuration: configuration
                                )
                                .frame(width: timelineWidth, height: contentHeight)

                                // Today anchor for scrolling
                                if let index = todayIndex {
                                    Color.clear
                                        .frame(width: 1, height: 1)
                                        .offset(x: CGFloat(index) * configuration.dayColumnWidth + configuration.dayColumnWidth / 2)
                                        .id("today")
                                }

                                // Task bars only (no labels)
                                VStack(spacing: 0) {
                                    ForEach(tasks) { task in
                                        GanttTaskBarRow(
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
                            .frame(width: timelineWidth, height: contentHeight)
                            .background(GeometryReader { proxy in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: ScrollOffset(
                                            x: proxy.frame(in: .named("scroll")).origin.x,
                                            y: proxy.frame(in: .named("scroll")).origin.y
                                        )
                                    )
                            })
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            verticalScrollOffset = value.y
                            horizontalScrollOffset = value.x
                        }
                        .onAppear {
                            if !hasScrolledToToday, todayIndex != nil {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.none) {
                                        scrollProxy.scrollTo("today", anchor: .center)
                                    }
                                    hasScrolledToToday = true
                                }
                            }
                        }
                    }
                }
                .background(Color(white: 0.98))

                // Floating task labels column (below header)
                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        TaskLabelView(task: task, configuration: configuration)
                            .frame(height: configuration.rowHeight)
                    }
                }
                .offset(y: verticalScrollOffset)
                .frame(width: configuration.labelColumnWidth, height: availableHeight, alignment: .top)
                .clipped()
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 2, y: 0)
                )
                .offset(y: configuration.headerHeight)
            }
        }
    }
}

// MARK: - Scroll Offset Tracking

private struct ScrollOffset: Equatable {
    var x: CGFloat
    var y: CGFloat
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: ScrollOffset = ScrollOffset(x: 0, y: 0)
    static func reduce(value: inout ScrollOffset, nextValue: () -> ScrollOffset) {
        value = nextValue()
    }
}

// MARK: - Task Label View (for floating column)

struct TaskLabelView<Item: GanttTask>: View {
    let task: Item
    let configuration: GanttChartConfiguration

    var body: some View {
        HStack(spacing: 12) {
            // Circular progress indicator
            CircularProgressView(
                progress: task.progress,
                color: task.color,
                size: 36
            )

            // Task info
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
        .frame(height: configuration.rowHeight)
    }
}

// MARK: - Task Bar Row (bars only, no labels)

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
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: configuration.barCornerRadius)
                    .fill(color.opacity(0.3))

                // Progress fill
                if progress > 0 {
                    RoundedRectangle(cornerRadius: configuration.barCornerRadius)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                }

                // Progress label
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

// MARK: - View Modifier for Configuration

public extension GanttChart {
    /// Customize the Gantt chart configuration
    func configuration(_ configuration: GanttChartConfiguration) -> GanttChart {
        GanttChart(tasks: tasks, dateRange: dateRange, configuration: configuration)
    }
}
