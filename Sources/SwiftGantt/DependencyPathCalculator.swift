import SwiftUI

/// Calculates paths for dependency lines between tasks
struct DependencyPathCalculator<Task: GanttTask> where Task.ID: Hashable {
    let tasks: [Task]
    let taskIndexMap: [Task.ID: Int]
    let dateRange: ClosedRange<Date>
    let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    init(tasks: [Task], dateRange: ClosedRange<Date>, configuration: GanttChartConfiguration) {
        self.tasks = tasks
        self.dateRange = dateRange
        self.configuration = configuration

        // Build lookup map for O(1) task index access
        var map: [Task.ID: Int] = [:]
        for (index, task) in tasks.enumerated() {
            map[task.id] = index
        }
        self.taskIndexMap = map
    }

    // MARK: - Task Position Calculations

    func rowIndex(for taskId: Task.ID) -> Int? {
        return taskIndexMap[taskId]
    }

    func taskStartX(for task: Task) -> CGFloat {
        let rangeStart = calendar.startOfDay(for: dateRange.lowerBound)
        let taskStart = calendar.startOfDay(for: task.startDate)
        let days = calendar.dateComponents([.day], from: rangeStart, to: taskStart).day ?? 0
        return CGFloat(days) * configuration.dayColumnWidth
    }

    func taskEndX(for task: Task) -> CGFloat {
        let rangeStart = calendar.startOfDay(for: dateRange.lowerBound)
        let taskEnd = calendar.startOfDay(for: task.endDate)
        let days = calendar.dateComponents([.day], from: rangeStart, to: taskEnd).day ?? 0
        return CGFloat(days + 1) * configuration.dayColumnWidth
    }

    func rowCenterY(for rowIndex: Int) -> CGFloat {
        return CGFloat(rowIndex) * configuration.rowHeight + configuration.rowHeight / 2
    }

    // MARK: - Path Generation

    /// Corner radius for curved dependency lines
    private var cornerRadius: CGFloat { 8 }

    /// Add a rounded corner to the path
    /// - Parameters:
    ///   - path: The path to modify
    ///   - corner: The corner point
    ///   - from: Direction coming from
    ///   - to: Direction going to
    private func addRoundedCorner(to path: inout Path, at corner: CGPoint, from: CGPoint, toward: CGPoint) {
        let radius = cornerRadius

        // Calculate the direction vectors
        let fromDx = corner.x - from.x
        let fromDy = corner.y - from.y
        let toDx = toward.x - corner.x
        let toDy = toward.y - corner.y

        // Normalize and scale by radius
        let fromLen = sqrt(fromDx * fromDx + fromDy * fromDy)
        let toLen = sqrt(toDx * toDx + toDy * toDy)

        guard fromLen > 0 && toLen > 0 else {
            path.addLine(to: corner)
            return
        }

        // Points where the curve starts and ends
        let curveStart = CGPoint(
            x: corner.x - (fromDx / fromLen) * min(radius, fromLen / 2),
            y: corner.y - (fromDy / fromLen) * min(radius, fromLen / 2)
        )
        let curveEnd = CGPoint(
            x: corner.x + (toDx / toLen) * min(radius, toLen / 2),
            y: corner.y + (toDy / toLen) * min(radius, toLen / 2)
        )

        path.addLine(to: curveStart)
        path.addQuadCurve(to: curveEnd, control: corner)
    }

    /// Generate a path for a dependency with rounded corners
    func path(for dependency: GanttDependency<Task.ID>) -> Path? {
        guard let fromIndex = rowIndex(for: dependency.fromId),
              let toIndex = rowIndex(for: dependency.toId),
              fromIndex < tasks.count,
              toIndex < tasks.count else {
            return nil
        }

        let fromTask = tasks[fromIndex]
        let toTask = tasks[toIndex]

        let fromY = rowCenterY(for: fromIndex)
        let toY = rowCenterY(for: toIndex)

        // Get connection points based on dependency type
        let startX: CGFloat
        let endX: CGFloat

        switch dependency.type {
        case .endToStart:
            startX = taskEndX(for: fromTask)
            endX = taskStartX(for: toTask)
        case .startToStart:
            startX = taskStartX(for: fromTask)
            endX = taskStartX(for: toTask)
        case .endToEnd:
            startX = taskEndX(for: fromTask)
            endX = taskEndX(for: toTask)
        case .startToEnd:
            startX = taskStartX(for: fromTask)
            endX = taskEndX(for: toTask)
        }

        var path = Path()
        let margin: CGFloat = 12

        // Same row - simple horizontal line
        if fromIndex == toIndex {
            path.move(to: CGPoint(x: startX, y: fromY))
            path.addLine(to: CGPoint(x: endX, y: toY))
            return path
        }

        // Check if there's a clear path: source ends before target starts
        // AND no intervening tasks block the vertical drop
        let minRow = min(fromIndex, toIndex)
        let maxRow = max(fromIndex, toIndex)

        // Find if any task between source and target would block a vertical line at exitX
        let exitX = startX + margin
        var hasBlockingTask = false

        // Check rows BETWEEN source and target (exclusive of source, inclusive of target for end position)
        for rowIndex in (minRow + 1)...maxRow {
            if rowIndex < tasks.count {
                let task = tasks[rowIndex]
                let taskStart = taskStartX(for: task)
                let taskEnd = taskEndX(for: task)
                // If exitX falls within a task's horizontal span, it's blocking
                if exitX >= taskStart && exitX <= taskEnd {
                    hasBlockingTask = true
                    break
                }
            }
        }

        // Simple path: source ends before target starts, and no blocking tasks
        if startX < endX && !hasBlockingTask {
            // Simple 3-segment path with rounded corners:
            // 1. Exit right from source
            // 2. Drop down to target row (with curves)
            // 3. Go right to target
            let p0 = CGPoint(x: startX, y: fromY)
            let p1 = CGPoint(x: exitX, y: fromY)      // Corner 1
            let p2 = CGPoint(x: exitX, y: toY)        // Corner 2
            let p3 = CGPoint(x: endX, y: toY)

            path.move(to: p0)
            addRoundedCorner(to: &path, at: p1, from: p0, toward: p2)
            addRoundedCorner(to: &path, at: p2, from: p1, toward: p3)
            path.addLine(to: p3)
            return path
        }

        // Complex path: need to route around blocking tasks
        // Find the best drop position - as close to target as possible while avoiding task bars
        var dropX = endX - margin  // Ideal: just left of target

        // Check if dropX would hit any task bars in intervening rows
        // If so, move it left to clear them
        for rowIndex in (minRow + 1)..<maxRow {
            if rowIndex < tasks.count {
                let task = tasks[rowIndex]
                let taskStart = taskStartX(for: task)
                let taskEnd = taskEndX(for: task)
                // If dropX falls within this task's span, move left of it
                if dropX >= taskStart && dropX <= taskEnd {
                    dropX = taskStart - margin
                }
            }
        }

        // Route horizontal segment in the gutter between rows, not through task bars
        // Use the row boundary (edge between rows) for the horizontal travel
        let gutterY: CGFloat
        if toIndex > fromIndex {
            // Going down: use bottom edge of source row
            gutterY = CGFloat(fromIndex + 1) * configuration.rowHeight
        } else {
            // Going up: use top edge of source row
            gutterY = CGFloat(fromIndex) * configuration.rowHeight
        }

        // Ensure dropX is not to the right of exitX (would create backwards line)
        let safeX = min(exitX, dropX)

        // 5-segment path with rounded corners
        let p0 = CGPoint(x: startX, y: fromY)
        let p1 = CGPoint(x: exitX, y: fromY)       // Corner 1
        let p2 = CGPoint(x: exitX, y: gutterY)     // Corner 2
        let p3 = CGPoint(x: safeX, y: gutterY)     // Corner 3
        let p4 = CGPoint(x: safeX, y: toY)         // Corner 4
        let p5 = CGPoint(x: endX, y: toY)

        path.move(to: p0)
        addRoundedCorner(to: &path, at: p1, from: p0, toward: p2)
        addRoundedCorner(to: &path, at: p2, from: p1, toward: p3)
        addRoundedCorner(to: &path, at: p3, from: p2, toward: p4)
        addRoundedCorner(to: &path, at: p4, from: p3, toward: p5)
        path.addLine(to: p5)

        return path
    }

    /// Generate arrowhead path at the end point
    func arrowPath(for dependency: GanttDependency<Task.ID>) -> Path? {
        guard let toIndex = rowIndex(for: dependency.toId),
              toIndex < tasks.count else {
            return nil
        }

        let toTask = tasks[toIndex]
        let toY = rowCenterY(for: toIndex)

        let endX: CGFloat
        switch dependency.type {
        case .endToStart, .startToStart:
            endX = taskStartX(for: toTask)
        case .endToEnd, .startToEnd:
            endX = taskEndX(for: toTask)
        }

        let arrowSize: CGFloat = 6

        var arrow = Path()
        arrow.move(to: CGPoint(x: endX, y: toY))
        arrow.addLine(to: CGPoint(x: endX - arrowSize, y: toY - arrowSize / 2))
        arrow.addLine(to: CGPoint(x: endX - arrowSize, y: toY + arrowSize / 2))
        arrow.closeSubpath()

        return arrow
    }
}
