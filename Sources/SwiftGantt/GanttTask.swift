import Foundation

/// Protocol that defines the requirements for a Gantt chart task
public protocol GanttTask: Identifiable {
    /// The display title of the task
    var title: String { get }

    /// The start date of the task
    var startDate: Date { get }

    /// The end date of the task
    var endDate: Date { get }

    /// Progress of the task (0.0 to 1.0)
    var progress: Double { get }
}

/// Default implementation for progress
public extension GanttTask {
    var progress: Double { 0.0 }
}
