import Foundation
import SwiftUI

/// Protocol that defines the requirements for a Gantt chart task
public protocol GanttTask: Identifiable {
    /// The display title of the task
    var title: String { get }

    /// Optional subtitle with additional info (date range, location, etc.)
    var subtitle: String? { get }

    /// The start date of the task
    var taskStartDate: Date { get }

    /// The end date of the task
    var taskEndDate: Date { get }

    /// Progress of the task (0.0 to 1.0)
    var progress: Double { get }

    /// Color for the task bar
    var color: Color { get }
}

/// Default implementations
public extension GanttTask {
    var progress: Double { 0.0 }
    var subtitle: String? { nil }
    var color: Color { .blue }
}
