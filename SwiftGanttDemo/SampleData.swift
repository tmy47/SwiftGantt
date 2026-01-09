import Foundation
import SwiftGantt

struct DemoTask: GanttTask {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    var progress: Double

    init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, progress: Double = 0.0) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.progress = progress
    }
}

enum SampleData {
    private static let calendar = Calendar.current
    private static let today = calendar.startOfDay(for: Date())

    static var dateRange: ClosedRange<Date> {
        let start = calendar.date(byAdding: .day, value: -7, to: today)!
        let end = calendar.date(byAdding: .day, value: 35, to: today)!
        return start...end
    }

    static var tasks: [DemoTask] {
        [
            DemoTask(
                title: "Project Kickoff",
                startDate: calendar.date(byAdding: .day, value: -6, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -6, to: today)!,
                progress: 1.0
            ),
            DemoTask(
                title: "Requirements Gathering",
                startDate: calendar.date(byAdding: .day, value: -5, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -2, to: today)!,
                progress: 1.0
            ),
            DemoTask(
                title: "UI/UX Design",
                startDate: calendar.date(byAdding: .day, value: -3, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 2, to: today)!,
                progress: 0.8
            ),
            DemoTask(
                title: "Architecture Planning",
                startDate: calendar.date(byAdding: .day, value: -1, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 3, to: today)!,
                progress: 0.5
            ),
            DemoTask(
                title: "Backend Development",
                startDate: calendar.date(byAdding: .day, value: 2, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 18, to: today)!,
                progress: 0.1
            ),
            DemoTask(
                title: "Frontend Development",
                startDate: calendar.date(byAdding: .day, value: 5, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 20, to: today)!,
                progress: 0.0
            ),
            DemoTask(
                title: "API Integration",
                startDate: calendar.date(byAdding: .day, value: 12, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 18, to: today)!,
                progress: 0.0
            ),
            DemoTask(
                title: "Unit Testing",
                startDate: calendar.date(byAdding: .day, value: 15, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 22, to: today)!,
                progress: 0.0
            ),
            DemoTask(
                title: "Integration Testing",
                startDate: calendar.date(byAdding: .day, value: 20, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 25, to: today)!,
                progress: 0.0
            ),
            DemoTask(
                title: "UAT",
                startDate: calendar.date(byAdding: .day, value: 24, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 28, to: today)!,
                progress: 0.0
            ),
            DemoTask(
                title: "Deployment",
                startDate: calendar.date(byAdding: .day, value: 28, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 30, to: today)!,
                progress: 0.0
            )
        ]
    }
}
