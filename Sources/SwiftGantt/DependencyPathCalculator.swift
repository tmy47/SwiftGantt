import SwiftUI

/// Calculates paths for dependency lines between tasks
struct DependencyPathCalculator<Task: GanttTask> {
    let tasks: [Task]
    let taskIndexMap: [UUID: Int]
    let dateRange: ClosedRange<Date>
    let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    init(tasks: [Task], dateRange: ClosedRange<Date>, configuration: GanttChartConfiguration) {
        self.tasks = tasks
        self.dateRange = dateRange
        self.configuration = configuration

        // Build lookup map for O(1) task index access
        var map: [UUID: Int] = [:]
        for (index, task) in tasks.enumerated() {
            map[task.id as! UUID] = index
        }
        self.taskIndexMap = map
    }

    // MARK: - Task Position Calculations

    func rowIndex(for taskId: UUID) -> Int? {
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

    /// Generate a path for a dependency using straight lines
    func path(for dependency: GanttDependency) -> Path? {
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
            // Simple 3-segment path:
            // 1. Exit right from source
            // 2. Drop down to target row
            // 3. Go right to target
            path.move(to: CGPoint(x: startX, y: fromY))
            path.addLine(to: CGPoint(x: exitX, y: fromY))       // 1. Horizontal exit right
            path.addLine(to: CGPoint(x: exitX, y: toY))         // 2. Down to target row
            path.addLine(to: CGPoint(x: endX, y: toY))          // 3. Approach to target
            return path
        }

        // Complex path: need to route around blocking tasks
        // Find the leftmost task start position to route around
        var minTaskStartX = endX
        for rowIndex in minRow...maxRow {
            if rowIndex < tasks.count {
                let taskStart = taskStartX(for: tasks[rowIndex])
                minTaskStartX = min(minTaskStartX, taskStart)
            }
        }

        // 5-segment path routing around obstacles:
        let safeX = minTaskStartX - margin             // Safe X position left of all tasks

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

        path.move(to: CGPoint(x: startX, y: fromY))
        path.addLine(to: CGPoint(x: exitX, y: fromY))       // 1. Horizontal exit right
        path.addLine(to: CGPoint(x: exitX, y: gutterY))     // 2. Down/up to gutter
        path.addLine(to: CGPoint(x: safeX, y: gutterY))     // 3. Left to safe position (in gutter)
        path.addLine(to: CGPoint(x: safeX, y: toY))         // 4. Down/up to target row
        path.addLine(to: CGPoint(x: endX, y: toY))          // 5. Approach from left

        return path
    }

    /// Generate arrowhead path at the end point
    func arrowPath(for dependency: GanttDependency) -> Path? {
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
