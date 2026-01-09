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

    public init(
        rowHeight: CGFloat = 60,
        labelColumnWidth: CGFloat = 280,
        dayColumnWidth: CGFloat = 32,
        gridColor: Color = .gray.opacity(0.15),
        weekendColor: Color = .gray.opacity(0.08),
        todayMarkerColor: Color = .green,
        showTodayMarker: Bool = true,
        showHorizontalGrid: Bool = true,
        showVerticalGrid: Bool = true,
        showWeekendHighlight: Bool = true,
        barCornerRadius: CGFloat = 6,
        barHeightRatio: CGFloat = 0.45,
        headerHeight: CGFloat = 50,
        showProgressLabel: Bool = true,
        progressLabelFont: Font = .caption.weight(.medium)
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
    }

    /// Default configuration
    public static let `default` = GanttChartConfiguration()
}
