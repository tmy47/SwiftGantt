import Testing
@testable import SwiftGantt
import Foundation
import SwiftUI

struct SampleTask: GanttTask {
    let id = UUID()
    let title: String
    let taskStartDate: Date
    let taskEndDate: Date
    var progress: Double = 0.0
    var subtitle: String? = nil
    var color: Color = .blue
}

@Test func taskConformsToProtocol() async throws {
    let task = SampleTask(
        title: "Test Task",
        taskStartDate: Date(),
        taskEndDate: Date().addingTimeInterval(86400)
    )

    #expect(task.title == "Test Task")
    #expect(task.progress == 0.0)
    #expect(task.subtitle == nil)
    #expect(task.color == .blue)
}
