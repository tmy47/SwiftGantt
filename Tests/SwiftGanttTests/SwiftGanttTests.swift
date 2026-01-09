import Testing
@testable import SwiftGantt
import Foundation

struct SampleTask: GanttTask {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    var progress: Double = 0.0
}

@Test func taskConformsToProtocol() async throws {
    let task = SampleTask(
        title: "Test Task",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400)
    )

    #expect(task.title == "Test Task")
    #expect(task.progress == 0.0)
}
