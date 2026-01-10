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
        let exitMargin: CGFloat = 12

        // Same row - simple horizontal line
        if fromIndex == toIndex {
            path.move(to: CGPoint(x: startX, y: fromY))
            path.addLine(to: CGPoint(x: endX, y: toY))
            return path
        }

        // Routing pattern:
        // 1. Exit source horizontally (small margin)
        // 2. Drop down/up vertically to target row
        // 3. Go horizontally to target

        let exitX = startX + exitMargin

        path.move(to: CGPoint(x: startX, y: fromY))
        path.addLine(to: CGPoint(x: exitX, y: fromY))   // Horizontal exit
        path.addLine(to: CGPoint(x: exitX, y: toY))     // Vertical to target row
        path.addLine(to: CGPoint(x: endX, y: toY))      // Horizontal to target

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
