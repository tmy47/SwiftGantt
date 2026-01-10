import Foundation

/// Types of dependency connections between tasks
public enum DependencyType: String, CaseIterable, Sendable {
    case endToStart   // Finish-to-Start (most common)
    case startToStart // Start-to-Start
    case endToEnd     // Finish-to-Finish
    case startToEnd   // Start-to-Finish
}

/// Represents a dependency relationship between two tasks
public struct GanttDependency: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let fromId: UUID
    public let toId: UUID
    public let type: DependencyType

    public init(
        id: UUID = UUID(),
        fromId: UUID,
        toId: UUID,
        type: DependencyType = .endToStart
    ) {
        self.id = id
        self.fromId = fromId
        self.toId = toId
        self.type = type
    }
}
