import SwiftUI

// MARK: - Directional Lock ScrollView

// MARK: - Scroll State Controller

class ScrollStateController: ObservableObject {
    weak var scrollView: UIScrollView?

    func setVerticalOffset(_ y: CGFloat, animated: Bool = false) {
        guard let scrollView = scrollView else { return }
        let newOffset = CGPoint(x: scrollView.contentOffset.x, y: y)
        scrollView.setContentOffset(newOffset, animated: animated)
    }

    func setHorizontalOffset(_ x: CGFloat, animated: Bool = false) {
        guard let scrollView = scrollView else { return }
        let maxX = max(0, scrollView.contentSize.width - scrollView.bounds.width)
        let clampedX = max(0, min(x, maxX))
        let newOffset = CGPoint(x: clampedX, y: scrollView.contentOffset.y)
        scrollView.setContentOffset(newOffset, animated: animated)
    }
}

// MARK: - Directional Lock ScrollView

struct DirectionalLockScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    let contentSize: CGSize
    let initialOffset: CGPoint?
    let onOffsetChange: ((CGPoint) -> Void)?
    let horizontalPagingEnabled: Bool
    let scrollStateController: ScrollStateController?

    init(
        contentSize: CGSize,
        initialOffset: CGPoint? = nil,
        horizontalPagingEnabled: Bool = true,
        scrollStateController: ScrollStateController? = nil,
        onOffsetChange: ((CGPoint) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.contentSize = contentSize
        self.initialOffset = initialOffset
        self.horizontalPagingEnabled = horizontalPagingEnabled
        self.scrollStateController = scrollStateController
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

        // Reduce scroll event frequency for better performance
        scrollView.decelerationRate = .fast

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hostingController.view)
        context.coordinator.hostingController = hostingController
        context.coordinator.horizontalPagingEnabled = horizontalPagingEnabled

        // Store reference in controller for external access
        scrollStateController?.scrollView = scrollView

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
        context.coordinator.horizontalPagingEnabled = horizontalPagingEnabled
        scrollStateController?.scrollView = scrollView

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
        var horizontalPagingEnabled: Bool = true

        // Track scroll state for horizontal paging
        private var isScrollingHorizontally = false
        private var lastContentOffset: CGPoint = .zero

        init(onOffsetChange: ((CGPoint) -> Void)?) {
            self.onOffsetChange = onOffsetChange
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onOffsetChange?(scrollView.contentOffset)
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            lastContentOffset = scrollView.contentOffset
        }

        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            guard horizontalPagingEnabled else { return }

            // Determine if this is primarily horizontal scrolling
            let horizontalDelta = abs(scrollView.contentOffset.x - lastContentOffset.x)
            let verticalDelta = abs(scrollView.contentOffset.y - lastContentOffset.y)

            // Only apply horizontal paging if scrolling is more horizontal than vertical
            guard horizontalDelta > verticalDelta else { return }

            let pageWidth = scrollView.bounds.width
            guard pageWidth > 0 else { return }

            let currentPage = scrollView.contentOffset.x / pageWidth
            var targetPage: CGFloat

            // Determine target page based on velocity and position
            if velocity.x > 0.3 {
                // Swiping right - go to next page
                targetPage = ceil(currentPage)
            } else if velocity.x < -0.3 {
                // Swiping left - go to previous page
                targetPage = floor(currentPage)
            } else {
                // No significant velocity - snap to nearest page
                targetPage = round(currentPage)
            }

            // Clamp to valid range
            let maxPage = max(0, (scrollView.contentSize.width - pageWidth) / pageWidth)
            targetPage = max(0, min(targetPage, maxPage))

            // Set target offset (keeps vertical unchanged)
            targetContentOffset.pointee.x = targetPage * pageWidth
        }
    }
}

// MARK: - Vertical Sync ScrollView (for left column)

struct VerticalSyncScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    let contentHeight: CGFloat
    let currentOffset: CGFloat
    let scrollStateController: ScrollStateController?

    init(
        contentHeight: CGFloat,
        currentOffset: CGFloat,
        scrollStateController: ScrollStateController?,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.contentHeight = contentHeight
        self.currentOffset = currentOffset
        self.scrollStateController = scrollStateController
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
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
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: contentHeight)
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        context.coordinator.scrollStateController = scrollStateController

        // Update height constraint
        if let hostingView = context.coordinator.hostingController?.view {
            for constraint in hostingView.constraints {
                if constraint.firstAttribute == .height {
                    constraint.constant = contentHeight
                }
            }
        }

        // Sync offset from main scroll view (only if not currently being dragged)
        if !context.coordinator.isDragging {
            let clampedY = max(0, min(currentOffset, max(0, contentHeight - scrollView.bounds.height)))
            if abs(scrollView.contentOffset.y - clampedY) > 1 {
                scrollView.contentOffset.y = clampedY
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
        var scrollStateController: ScrollStateController?
        var isDragging = false

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isDragging = true
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if isDragging {
                scrollStateController?.setVerticalOffset(scrollView.contentOffset.y)
            }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                isDragging = false
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isDragging = false
        }
    }
}

/// SwiftGantt - A Gantt chart component for SwiftUI
public struct GanttChart<Item: GanttTask>: View where Item.ID: Hashable {
    private let tasks: [Item]
    private let dependencies: [GanttDependency<Item.ID>]
    private let dateRange: ClosedRange<Date>
    private let configuration: GanttChartConfiguration
    private let onTaskTap: ((Item) -> Void)?

    private let calendar = Calendar.current

    @State private var scrollOffset: CGPoint = .zero
    @State private var selectedTaskId: Item.ID?
    @StateObject private var scrollStateController = ScrollStateController()

    /// Extended date range with 1-year buffer before and after
    private var extendedDateRange: ClosedRange<Date> {
        let extendedStart = calendar.date(byAdding: .year, value: -1, to: dateRange.lowerBound)!
        let extendedEnd = calendar.date(byAdding: .year, value: 1, to: dateRange.upperBound)!
        return extendedStart...extendedEnd
    }

    private var totalDays: Int {
        let start = calendar.startOfDay(for: extendedDateRange.lowerBound)
        let end = calendar.startOfDay(for: extendedDateRange.upperBound)
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
        let rangeStart = calendar.startOfDay(for: extendedDateRange.lowerBound)
        let rangeEnd = calendar.startOfDay(for: extendedDateRange.upperBound)

        guard today >= rangeStart && today <= rangeEnd else { return nil }

        return calendar.dateComponents([.day], from: rangeStart, to: today).day
    }

    /// Calculate the X offset for a task's start date
    private func taskStartOffset(for task: Item) -> CGFloat {
        let rangeStart = calendar.startOfDay(for: extendedDateRange.lowerBound)
        let taskStart = calendar.startOfDay(for: task.taskStartDate)
        let days = calendar.dateComponents([.day], from: rangeStart, to: taskStart).day ?? 0
        return CGFloat(days) * configuration.dayColumnWidth
    }

    public init(
        tasks: [Item],
        dependencies: [GanttDependency<Item.ID>] = [],
        dateRange: ClosedRange<Date>,
        configuration: GanttChartConfiguration = .default,
        onTaskTap: ((Item) -> Void)? = nil
    ) {
        self.tasks = tasks
        self.dependencies = dependencies
        self.dateRange = dateRange
        self.configuration = configuration
        self.onTaskTap = onTaskTap
    }

    public var body: some View {
        GeometryReader { geometry in
            let initialOffset: CGPoint? = {
                guard let index = todayIndex else { return nil }
                let todayX = CGFloat(index) * configuration.dayColumnWidth
                // Position today at the right edge of the label column
                let offsetX = todayX - configuration.labelColumnWidth
                // Clamp to valid scroll range
                let maxOffsetX = timelineWidth - geometry.size.width
                let clampedX = max(0, min(offsetX, maxOffsetX))
                return CGPoint(x: clampedX, y: 0)
            }()

            let chartAreaHeight = max(0, geometry.size.height - configuration.headerHeight - 1)

            // Calculate minimum rows to fill the viewport
            let minRowsToFillViewport = Int(ceil(chartAreaHeight / configuration.rowHeight))
            let displayRowCount = max(tasks.count, minRowsToFillViewport)
            let displayContentHeight = CGFloat(displayRowCount) * configuration.rowHeight

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    // Fixed dates header (scrolls horizontally only, virtualized)
                    GanttChartHeader(
                        dateRange: extendedDateRange,
                        configuration: configuration,
                        scrollOffset: scrollOffset.x,
                        viewportWidth: geometry.size.width
                    )
                    .frame(width: timelineWidth, height: configuration.headerHeight)
                    .offset(x: -scrollOffset.x)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .clipped()

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)

                    // Scrollable chart content
                    DirectionalLockScrollView(
                        contentSize: CGSize(width: timelineWidth, height: displayContentHeight),
                        initialOffset: initialOffset,
                        scrollStateController: scrollStateController,
                        onOffsetChange: { offset in
                            scrollOffset = offset
                        }
                    ) {
                        ZStack(alignment: .topLeading) {
                            // Task bars (virtualized - only renders visible rows + buffer)
                            VirtualizedRowContainer(
                                items: tasks,
                                scrollOffset: scrollOffset.y,
                                viewportHeight: chartAreaHeight,
                                rowHeight: configuration.rowHeight,
                                bufferCount: configuration.virtualizationBuffer
                            ) { task, _ in
                                GanttTaskBarRow(
                                    task: task,
                                    dateRange: extendedDateRange,
                                    configuration: configuration
                                ) {
                                    onTaskTap?(task)
                                }
                            }

                            // Dependency lines (always present to avoid layout shifts)
                            DependencyLayer(
                                dependencies: configuration.showDependencies ? dependencies : [],
                                tasks: tasks,
                                dateRange: extendedDateRange,
                                configuration: configuration
                            )
                            .frame(width: timelineWidth, height: displayContentHeight)
                            .allowsHitTesting(false)

                        }
                        .frame(width: timelineWidth, height: displayContentHeight)
                        .background(
                            GanttChartGrid(
                                dateRange: extendedDateRange,
                                rowCount: displayRowCount,
                                configuration: configuration
                            )
                        )
                    }
                }

                // Floating task labels column
                VStack(spacing: 0) {
                    // Header spacer
                    Color.clear
                        .frame(height: configuration.headerHeight + 1)

                    // Task labels (synced with vertical scroll - virtualized)
                    VerticalSyncScrollView(
                        contentHeight: displayContentHeight,
                        currentOffset: scrollOffset.y,
                        scrollStateController: scrollStateController
                    ) {
                        VirtualizedRowContainer(
                            items: tasks,
                            scrollOffset: scrollOffset.y,
                            viewportHeight: chartAreaHeight,
                            rowHeight: configuration.rowHeight,
                            bufferCount: configuration.virtualizationBuffer
                        ) { task, _ in
                            TaskLabelView(
                                task: task,
                                configuration: configuration,
                                isSelected: selectedTaskId == task.id
                            ) {
                                // Select task and scroll to show task's start at right edge of label column
                                selectedTaskId = task.id
                                let offset = taskStartOffset(for: task) - configuration.labelColumnWidth
                                scrollStateController.setHorizontalOffset(offset)
                            }
                        }
                        .frame(height: displayContentHeight, alignment: .top)
                    }
                    .frame(height: chartAreaHeight)
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
    let isSelected: Bool
    let onTap: (() -> Void)?

    init(task: Item, configuration: GanttChartConfiguration, isSelected: Bool = false, onTap: (() -> Void)? = nil) {
        self.task = task
        self.configuration = configuration
        self.isSelected = isSelected
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: 12) {
            CircularProgressView(
                progress: task.progress,
                color: task.taskColor,
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
        .background(isSelected ? task.taskColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Task Bar Row

struct GanttTaskBarRow<Item: GanttTask>: View {
    let task: Item
    let dateRange: ClosedRange<Date>
    let configuration: GanttChartConfiguration
    let isSelected: Bool
    let onTap: (() -> Void)?

    init(task: Item, dateRange: ClosedRange<Date>, configuration: GanttChartConfiguration, isSelected: Bool = false, onTap: (() -> Void)? = nil) {
        self.task = task
        self.dateRange = dateRange
        self.configuration = configuration
        self.isSelected = isSelected
        self.onTap = onTap
    }

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
        let taskStart = calendar.startOfDay(for: task.taskStartDate)
        let days = calendar.dateComponents([.day], from: rangeStart, to: taskStart).day ?? 0
        return CGFloat(days) * configuration.dayColumnWidth
    }

    private var taskWidth: CGFloat {
        let taskStart = calendar.startOfDay(for: task.taskStartDate)
        let taskEnd = calendar.startOfDay(for: task.taskEndDate)
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

            Button {
                onTap?()
            } label: {
                TaskBar(
                    progress: task.progress,
                    color: task.taskColor,
                    configuration: configuration,
                    barHeight: barHeight
                )
            }
            .buttonStyle(.plain)
            .frame(width: max(taskWidth, configuration.dayColumnWidth / 2), height: barHeight)
            .offset(x: taskStartOffset)
        }
        .frame(height: configuration.rowHeight)
        .background(isSelected ? task.taskColor.opacity(0.15) : Color.clear)
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
        GanttChart(tasks: tasks, dependencies: dependencies, dateRange: dateRange, configuration: configuration, onTaskTap: onTaskTap)
    }
}
