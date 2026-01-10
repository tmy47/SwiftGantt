import Foundation

/// Types of dependency connections between tasks
public enum DependencyType: String, CaseIterable, Sendable {
    case endToStart   // Finish-to-Start (most common)
    case startToStart // Start-to-Start
    case endToEnd     // Finish-to-Finish
    case startToEnd   // Start-to-Finish
}

/// Represents a dependency relationship between two tasks
public struct GanttDependency<TaskID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let fromId: TaskID
    public let toId: TaskID
    public let type: DependencyType

    public init(
        id: UUID = UUID(),
        fromId: TaskID,
        toId: TaskID,
        type: DependencyType = .endToStart
    ) {
        self.id = id
        self.fromId = fromId
        self.toId = toId
        self.type = type
    }
}

/// Type alias for backwards compatibility with UUID-based tasks
public typealias UUIDGanttDependency = GanttDependency<UUID>
