import Foundation
import SwiftUI
import SwiftGantt

struct DemoTask: GanttTask {
    let id: UUID
    let title: String
    let subtitle: String?
    let startDate: Date
    let endDate: Date
    var progress: Double
    var color: Color

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        startDate: Date,
        endDate: Date,
        progress: Double = 0.0,
        color: Color = .blue
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.startDate = startDate
        self.endDate = endDate
        self.progress = progress
        self.color = color
    }
}

enum SampleData {
    private static let calendar = Calendar.current
    private static let today = calendar.startOfDay(for: Date())

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static func formatDateRange(start: Date, end: Date) -> String {
        "\(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end))"
    }

    static var dateRange: ClosedRange<Date> {
        let start = calendar.date(byAdding: .day, value: -7, to: today)!
        let end = calendar.date(byAdding: .day, value: 35, to: today)!
        return start...end
    }

    static var tasks: [DemoTask] {
        let task1Start = calendar.date(byAdding: .day, value: -6, to: today)!
        let task1End = calendar.date(byAdding: .day, value: 5, to: today)!

        let task2Start = calendar.date(byAdding: .day, value: -4, to: today)!
        let task2End = calendar.date(byAdding: .day, value: 8, to: today)!

        let task3Start = calendar.date(byAdding: .day, value: -2, to: today)!
        let task3End = calendar.date(byAdding: .day, value: 12, to: today)!

        let task4Start = calendar.date(byAdding: .day, value: 0, to: today)!
        let task4End = calendar.date(byAdding: .day, value: 18, to: today)!

        let task5Start = calendar.date(byAdding: .day, value: 8, to: today)!
        let task5End = calendar.date(byAdding: .day, value: 22, to: today)!

        let task6Start = calendar.date(byAdding: .day, value: 2, to: today)!
        let task6End = calendar.date(byAdding: .day, value: 8, to: today)!

        let task7Start = calendar.date(byAdding: .day, value: 5, to: today)!
        let task7End = calendar.date(byAdding: .day, value: 12, to: today)!

        let task8Start = calendar.date(byAdding: .day, value: 10, to: today)!
        let task8End = calendar.date(byAdding: .day, value: 20, to: today)!

        let task9Start = calendar.date(byAdding: .day, value: 18, to: today)!
        let task9End = calendar.date(byAdding: .day, value: 28, to: today)!

        return [
            DemoTask(
                title: "Temporary Environmental Controls a...",
                subtitle: "\(formatDateRange(start: task1Start, end: task1End)) • 24 • Second Floor • Office 305",
                startDate: task1Start,
                endDate: task1End,
                progress: 0.0,
                color: .gray
            ),
            DemoTask(
                title: "MEP Rough-In - Primary Horiz...",
                subtitle: "\(formatDateRange(start: task2Start, end: task2End)) • 10d • Building Interior • L8",
                startDate: task2Start,
                endDate: task2End,
                progress: 0.34,
                color: Color(red: 0.2, green: 0.7, blue: 0.3)
            ),
            DemoTask(
                title: "Metal Stud Framing and Fire-Rated...",
                subtitle: "\(formatDateRange(start: task3Start, end: task3End)) • 12d • Building Interior • L5-7",
                startDate: task3Start,
                endDate: task3End,
                progress: 0.0,
                color: .gray
            ),
            DemoTask(
                title: "Exterior Curtain Wall/Window Wall P...",
                subtitle: "\(formatDateRange(start: task4Start, end: task4End)) • 15d • Building Interior • L10-14",
                startDate: task4Start,
                endDate: task4End,
                progress: 0.34,
                color: .orange
            ),
            DemoTask(
                title: "Concrete/Steel Structure Vertical Pr...",
                subtitle: "\(formatDateRange(start: task5Start, end: task5End)) • 10d • Structure • L20-24",
                startDate: task5Start,
                endDate: task5End,
                progress: 0.34,
                color: .orange
            ),
            DemoTask(
                title: "Firestopping and Penetration Sealan...",
                subtitle: "\(formatDateRange(start: task6Start, end: task6End)) • 5d • Building Interior • L3-4",
                startDate: task6Start,
                endDate: task6End,
                progress: 0.0,
                color: .purple
            ),
            DemoTask(
                title: "Site Logistics - Crane Jump/Climb",
                subtitle: "\(formatDateRange(start: task7Start, end: task7End)) • 2d • Core • Crane Mast",
                startDate: task7Start,
                endDate: task7End,
                progress: 0.34,
                color: Color(red: 0.3, green: 0.6, blue: 0.9)
            ),
            DemoTask(
                title: "Vertical Pipe Insulation and Duct Lag...",
                subtitle: "\(formatDateRange(start: task8Start, end: task8End)) • 8d • Building Interior • L5-7",
                startDate: task8Start,
                endDate: task8End,
                progress: 0.34,
                color: Color(red: 0.9, green: 0.4, blue: 0.6)
            ),
            DemoTask(
                title: "Permitting and Code Review Submis...",
                subtitle: "\(formatDateRange(start: task9Start, end: task9End)) • 4d • Offsite",
                startDate: task9Start,
                endDate: task9End,
                progress: 0.34,
                color: Color(red: 0.9, green: 0.4, blue: 0.6)
            ),
        ]
    }
}
