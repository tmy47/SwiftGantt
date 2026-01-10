import SwiftUI

/// Configuration options for customizing the Gantt chart appearance
public struct GanttChartConfiguration {
    /// Height of each task row
    public var rowHeight: CGFloat

    /// Width of the task label column
    public var labelColumnWidth: CGFloat

    /// Width of each day column in the timeline
    public var dayColumnWidth: CGFloat

    /// Color of the grid lines
    public var gridColor: Color

    /// Background color for weekend columns
    public var weekendColor: Color

    /// Color of the today marker/highlight
    public var todayMarkerColor: Color

    /// Whether to show the today marker
    public var showTodayMarker: Bool

    /// Whether to show horizontal grid lines
    public var showHorizontalGrid: Bool

    /// Whether to show vertical grid lines
    public var showVerticalGrid: Bool

    /// Whether to highlight weekend columns
    public var showWeekendHighlight: Bool

    /// Corner radius for task bars
    public var barCornerRadius: CGFloat

    /// Height of task bars relative to row height (0.0 to 1.0)
    public var barHeightRatio: CGFloat

    /// Height of the header
    public var headerHeight: CGFloat

    /// Whether to show progress percentage inside bars
    public var showProgressLabel: Bool

    /// Font for the progress label
    public var progressLabelFont: Font

    /// Number of rows to render above/below visible area for smooth scrolling
    /// Higher values improve scroll smoothness but use more memory
    public var virtualizationBuffer: Int

    // MARK: - Dependency Settings

    /// Whether to show dependency lines
    public var showDependencies: Bool

    /// Color of dependency lines
    public var dependencyLineColor: Color

    /// Width of dependency lines
    public var dependencyLineWidth: CGFloat

    public init(
        rowHeight: CGFloat = 60,
        labelColumnWidth: CGFloat = 280,
        dayColumnWidth: CGFloat = 40,
        gridColor: Color = .gray.opacity(0.2),
        weekendColor: Color = .gray.opacity(0.15),
        todayMarkerColor: Color = .green,
        showTodayMarker: Bool = true,
        showHorizontalGrid: Bool = true,
        showVerticalGrid: Bool = true,
        showWeekendHighlight: Bool = true,
        barCornerRadius: CGFloat = 6,
        barHeightRatio: CGFloat = 0.45,
        headerHeight: CGFloat = 50,
        showProgressLabel: Bool = true,
        progressLabelFont: Font = .caption.weight(.medium),
        virtualizationBuffer: Int = 20,
        showDependencies: Bool = true,
        dependencyLineColor: Color = .gray,
        dependencyLineWidth: CGFloat = 1.5
    ) {
        self.rowHeight = rowHeight
        self.labelColumnWidth = labelColumnWidth
        self.dayColumnWidth = dayColumnWidth
        self.gridColor = gridColor
        self.weekendColor = weekendColor
        self.todayMarkerColor = todayMarkerColor
        self.showTodayMarker = showTodayMarker
        self.showHorizontalGrid = showHorizontalGrid
        self.showVerticalGrid = showVerticalGrid
        self.showWeekendHighlight = showWeekendHighlight
        self.barCornerRadius = barCornerRadius
        self.barHeightRatio = barHeightRatio
        self.headerHeight = headerHeight
        self.showProgressLabel = showProgressLabel
        self.progressLabelFont = progressLabelFont
        self.virtualizationBuffer = virtualizationBuffer
        self.showDependencies = showDependencies
        self.dependencyLineColor = dependencyLineColor
        self.dependencyLineWidth = dependencyLineWidth
    }

    /// Default configuration
    public static let `default` = GanttChartConfiguration()
}
