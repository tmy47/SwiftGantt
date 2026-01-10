import SwiftUI
import UIKit

// MARK: - Core Graphics Grid View

class GanttGridView: UIView {
    var totalDays: Int = 0
    var rowCount: Int = 0
    var dayColumnWidth: CGFloat = 40
    var rowHeight: CGFloat = 60
    var gridColor: UIColor = UIColor.gray.withAlphaComponent(0.2)
    var weekendColor: UIColor = UIColor.gray.withAlphaComponent(0.15)
    var todayMarkerColor: UIColor = UIColor.systemGreen
    var showVerticalGrid: Bool = true
    var showHorizontalGrid: Bool = true
    var showWeekendHighlight: Bool = true
    var showTodayMarker: Bool = true
    var weekendIndices: Set<Int> = []
    var todayIndex: Int? = nil

    // Cached CGColor values to avoid repeated conversions
    private var cachedGridCGColor: CGColor?
    private var cachedWeekendCGColor: CGColor?
    private var cachedTodayCGColor: CGColor?

    // Track last configuration to avoid unnecessary redraws
    private var lastConfigHash: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayer()
    }

    private func configureLayer() {
        backgroundColor = .clear
        isOpaque = false
        // Enable async drawing for smoother scrolling
        layer.drawsAsynchronously = true
        // Rasterize for better scroll performance
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        contentMode = .redraw
    }

    func invalidateColorCaches() {
        cachedGridCGColor = nil
        cachedWeekendCGColor = nil
        cachedTodayCGColor = nil
    }

    private func currentConfigHash() -> Int {
        var hasher = Hasher()
        hasher.combine(totalDays)
        hasher.combine(rowCount)
        hasher.combine(dayColumnWidth)
        hasher.combine(rowHeight)
        hasher.combine(showVerticalGrid)
        hasher.combine(showHorizontalGrid)
        hasher.combine(showWeekendHighlight)
        hasher.combine(showTodayMarker)
        hasher.combine(weekendIndices)
        hasher.combine(todayIndex)
        return hasher.finalize()
    }

    func setNeedsDisplayIfChanged() {
        let newHash = currentConfigHash()
        if newHash != lastConfigHash {
            lastConfigHash = newHash
            invalidateColorCaches()
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard totalDays > 0 && rowCount > 0 else { return }

        let totalHeight = CGFloat(rowCount) * rowHeight
        let totalWidth = CGFloat(totalDays) * dayColumnWidth

        // Calculate visible range to only draw what's needed
        let visibleMinCol = max(0, Int(floor(rect.minX / dayColumnWidth)))
        let visibleMaxCol = min(totalDays - 1, Int(ceil(rect.maxX / dayColumnWidth)))
        let visibleMinRow = max(0, Int(floor(rect.minY / rowHeight)))
        let visibleMaxRow = min(rowCount - 1, Int(ceil(rect.maxY / rowHeight)))

        // Cache CGColors lazily
        if cachedWeekendCGColor == nil {
            cachedWeekendCGColor = weekendColor.cgColor
        }
        if cachedTodayCGColor == nil {
            cachedTodayCGColor = todayMarkerColor.withAlphaComponent(0.1).cgColor
        }
        if cachedGridCGColor == nil {
            cachedGridCGColor = gridColor.cgColor
        }

        // Draw weekend shading - only visible columns
        if showWeekendHighlight {
            context.setFillColor(cachedWeekendCGColor!)
            for index in visibleMinCol...visibleMaxCol where weekendIndices.contains(index) {
                let x = CGFloat(index) * dayColumnWidth
                let fillRect = CGRect(x: x, y: rect.minY, width: dayColumnWidth, height: rect.height)
                context.fill(fillRect)
            }
        }

        // Draw today highlight - only if visible
        if showTodayMarker, let index = todayIndex, index >= visibleMinCol && index <= visibleMaxCol {
            context.setFillColor(cachedTodayCGColor!)
            let x = CGFloat(index) * dayColumnWidth
            let fillRect = CGRect(x: x, y: rect.minY, width: dayColumnWidth, height: rect.height)
            context.fill(fillRect)
        }

        // Draw grid lines using batched path for better performance
        context.setStrokeColor(cachedGridCGColor!)
        context.setLineWidth(0.5)

        let path = CGMutablePath()

        // Vertical grid lines - only visible range
        if showVerticalGrid {
            let yStart = max(0, rect.minY)
            let yEnd = min(totalHeight, rect.maxY)
            for day in visibleMinCol...(visibleMaxCol + 1) {
                let x = CGFloat(day) * dayColumnWidth
                path.move(to: CGPoint(x: x, y: yStart))
                path.addLine(to: CGPoint(x: x, y: yEnd))
            }
        }

        // Horizontal grid lines - only visible range
        if showHorizontalGrid {
            let xStart = max(0, rect.minX)
            let xEnd = min(totalWidth, rect.maxX)
            for row in visibleMinRow...(visibleMaxRow + 1) {
                let y = CGFloat(row) * rowHeight
                path.move(to: CGPoint(x: xStart, y: y))
                path.addLine(to: CGPoint(x: xEnd, y: y))
            }
        }

        context.addPath(path)
        context.strokePath()
    }
}

// MARK: - SwiftUI Wrapper

struct GanttChartGrid: UIViewRepresentable {
    let dateRange: ClosedRange<Date>
    let rowCount: Int
    let configuration: GanttChartConfiguration

    private static let calendar = Calendar.current

    // Pre-computed values passed to the view
    private let computedTotalDays: Int
    private let computedTodayIndex: Int?
    private let computedWeekendIndices: Set<Int>

    init(dateRange: ClosedRange<Date>, rowCount: Int, configuration: GanttChartConfiguration) {
        self.dateRange = dateRange
        self.rowCount = rowCount
        self.configuration = configuration

        // Pre-compute values once during initialization
        let calendar = Self.calendar
        let start = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)

        self.computedTotalDays = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1

        // Compute today index
        let today = calendar.startOfDay(for: Date())
        if today >= start && today <= end {
            self.computedTodayIndex = calendar.dateComponents([.day], from: start, to: today).day
        } else {
            self.computedTodayIndex = nil
        }

        // Compute weekend indices using modular arithmetic for efficiency
        var indices = Set<Int>()
        let startWeekday = calendar.component(.weekday, from: start)
        let totalDays = self.computedTotalDays

        // Calculate first Saturday and Sunday from start date
        // weekday: 1 = Sunday, 7 = Saturday
        let daysToFirstSaturday = (7 - startWeekday + 7) % 7
        let daysToFirstSunday = (1 - startWeekday + 7) % 7

        // Add all Saturdays
        var saturdayIndex = daysToFirstSaturday
        while saturdayIndex < totalDays {
            indices.insert(saturdayIndex)
            saturdayIndex += 7
        }

        // Add all Sundays
        var sundayIndex = daysToFirstSunday
        while sundayIndex < totalDays {
            indices.insert(sundayIndex)
            sundayIndex += 7
        }

        self.computedWeekendIndices = indices
    }

    func makeUIView(context: Context) -> GanttGridView {
        let view = GanttGridView()
        updateView(view)
        return view
    }

    func updateUIView(_ uiView: GanttGridView, context: Context) {
        updateView(uiView)
        // Only redraw if configuration actually changed
        uiView.setNeedsDisplayIfChanged()
    }

    private func updateView(_ view: GanttGridView) {
        view.totalDays = computedTotalDays
        view.rowCount = rowCount
        view.dayColumnWidth = configuration.dayColumnWidth
        view.rowHeight = configuration.rowHeight
        view.gridColor = UIColor(configuration.gridColor)
        view.weekendColor = UIColor(configuration.weekendColor)
        view.todayMarkerColor = UIColor(configuration.todayMarkerColor)
        view.showVerticalGrid = configuration.showVerticalGrid
        view.showHorizontalGrid = configuration.showHorizontalGrid
        view.showWeekendHighlight = configuration.showWeekendHighlight
        view.showTodayMarker = configuration.showTodayMarker
        view.weekendIndices = computedWeekendIndices
        view.todayIndex = computedTodayIndex
    }
}

// MARK: - Today Marker Line

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
