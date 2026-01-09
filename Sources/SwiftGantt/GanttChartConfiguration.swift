import SwiftUI

/// Configuration options for customizing the Gantt chart appearance
public struct GanttChartConfiguration {
    /// Height of each task row
    public var rowHeight: CGFloat

    /// Width of the task label column
    public var labelColumnWidth: CGFloat

    /// Width of each day column in the timeline
    public var dayColumnWidth: CGFloat

    /// Color of the task bars
    public var barColor: Color

    /// Color of the progress fill within task bars
    public var progressColor: Color

    /// Color of the grid lines
    public var gridColor: Color

    /// Color of the today marker line
    public var todayMarkerColor: Color

    /// Whether to show the today marker
    public var showTodayMarker: Bool

    /// Whether to show horizontal grid lines
    public var showHorizontalGrid: Bool

    /// Whether to show vertical grid lines
    public var showVerticalGrid: Bool

    /// Corner radius for task bars
    public var barCornerRadius: CGFloat

    /// Height of task bars relative to row height (0.0 to 1.0)
    public var barHeightRatio: CGFloat

    public init(
        rowHeight: CGFloat = 44,
        labelColumnWidth: CGFloat = 150,
        dayColumnWidth: CGFloat = 40,
        barColor: Color = .blue.opacity(0.3),
        progressColor: Color = .blue,
        gridColor: Color = .gray.opacity(0.2),
        todayMarkerColor: Color = .red,
        showTodayMarker: Bool = true,
        showHorizontalGrid: Bool = true,
        showVerticalGrid: Bool = true,
        barCornerRadius: CGFloat = 4,
        barHeightRatio: CGFloat = 0.6
    ) {
        self.rowHeight = rowHeight
        self.labelColumnWidth = labelColumnWidth
        self.dayColumnWidth = dayColumnWidth
        self.barColor = barColor
        self.progressColor = progressColor
        self.gridColor = gridColor
        self.todayMarkerColor = todayMarkerColor
        self.showTodayMarker = showTodayMarker
        self.showHorizontalGrid = showHorizontalGrid
        self.showVerticalGrid = showVerticalGrid
        self.barCornerRadius = barCornerRadius
        self.barHeightRatio = barHeightRatio
    }

    /// Default configuration
    public static let `default` = GanttChartConfiguration()
}
