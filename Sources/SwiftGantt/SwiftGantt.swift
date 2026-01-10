import SwiftUI

// MARK: - Directional Lock ScrollView

struct DirectionalLockScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    let contentSize: CGSize
    let initialOffset: CGPoint?
    let onOffsetChange: ((CGPoint) -> Void)?

    init(
        contentSize: CGSize,
        initialOffset: CGPoint? = nil,
        onOffsetChange: ((CGPoint) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.contentSize = contentSize
        self.initialOffset = initialOffset
        self.onOffsetChange = onOffsetChange
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.delegate = context.coordinator

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hostingController.view)
        context.coordinator.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalToConstant: contentSize.width),
            hostingController.view.heightAnchor.constraint(equalToConstant: contentSize.height)
        ])

        if let offset = initialOffset {
            DispatchQueue.main.async {
                scrollView.setContentOffset(offset, animated: false)
            }
        }

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content

        // Update content size constraints if needed
        if let hostingView = context.coordinator.hostingController?.view {
            for constraint in hostingView.constraints {
                if constraint.firstAttribute == .width {
                    constraint.constant = contentSize.width
                } else if constraint.firstAttribute == .height {
                    constraint.constant = contentSize.height
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onOffsetChange: onOffsetChange)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
        let onOffsetChange: ((CGPoint) -> Void)?

        init(onOffsetChange: ((CGPoint) -> Void)?) {
            self.onOffsetChange = onOffsetChange
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onOffsetChange?(scrollView.contentOffset)
        }
    }
}

/// SwiftGantt - A Gantt chart component for SwiftUI
public struct GanttChart<Item: GanttTask>: View {
    private let tasks: [Item]
    private let dateRange: ClosedRange<Date>
    private let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    @State private var scrollOffset: CGPoint = .zero

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
            let centeredOffset: CGPoint? = {
                guard let index = todayIndex else { return nil }
                let todayX = CGFloat(index) * configuration.dayColumnWidth
                let centerX = max(0, todayX - geometry.size.width / 2 + configuration.dayColumnWidth / 2)
                return CGPoint(x: centerX, y: 0)
            }()

            let chartAreaHeight = geometry.size.height - configuration.headerHeight - 1

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    // Fixed dates header (scrolls horizontally only, extends full width)
                    GanttChartHeader(dateRange: dateRange, configuration: configuration)
                        .frame(width: timelineWidth, height: configuration.headerHeight)
                        .offset(x: -scrollOffset.x)
                        .frame(width: geometry.size.width, alignment: .leading)
                        .clipped()

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)

                    // Scrollable chart content
                    DirectionalLockScrollView(
                        contentSize: CGSize(width: timelineWidth, height: contentHeight),
                        initialOffset: centeredOffset,
                        onOffsetChange: { offset in
                            scrollOffset = offset
                        }
                    ) {
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

                // Floating task labels column
                VStack(spacing: 0) {
                    // Header spacer
                    Color.clear
                        .frame(height: configuration.headerHeight + 1)

                    // Task labels (synced with vertical scroll)
                    VStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskLabelView(task: task, configuration: configuration)
                        }
                    }
                    .offset(y: -scrollOffset.y)
                    .frame(height: chartAreaHeight, alignment: .top)
                    .clipped()
                }
                .frame(width: configuration.labelColumnWidth)
                .background(
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: configuration.headerHeight + 1)
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    }
                )
            }
            .background(Color(white: 0.98))
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
