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
        let start = calendar.date(byAdding: .year, value: -1, to: today)!
        let end = calendar.date(byAdding: .year, value: 1, to: today)!
        return start...end
    }

    private static func makeTask(
        title: String,
        startOffset: Int,
        duration: Int,
        progress: Double,
        color: Color,
        location: String
    ) -> DemoTask {
        let start = calendar.date(byAdding: .day, value: startOffset, to: today)!
        let end = calendar.date(byAdding: .day, value: startOffset + duration, to: today)!
        return DemoTask(
            title: title,
            subtitle: "\(formatDateRange(start: start, end: end)) • \(duration)d • \(location)",
            startDate: start,
            endDate: end,
            progress: progress,
            color: color
        )
    }

    static var tasks: [DemoTask] {
        [
            // Phase 1: Site Preparation
            makeTask(title: "Site Survey and Layout", startOffset: -10, duration: 5, progress: 1.0, color: .green, location: "Site • Ground Level"),
            makeTask(title: "Temporary Environmental Controls", startOffset: -6, duration: 11, progress: 0.85, color: .green, location: "Site • All Areas"),
            makeTask(title: "Demolition and Clearing", startOffset: -8, duration: 6, progress: 1.0, color: .green, location: "Site • North Section"),

            // Phase 2: Foundation
            makeTask(title: "Excavation and Grading", startOffset: -4, duration: 8, progress: 0.65, color: Color(red: 0.2, green: 0.7, blue: 0.3), location: "Foundation • All"),
            makeTask(title: "Foundation Formwork", startOffset: 2, duration: 10, progress: 0.34, color: Color(red: 0.2, green: 0.7, blue: 0.3), location: "Foundation • Core"),
            makeTask(title: "Rebar Installation - Foundation", startOffset: 5, duration: 7, progress: 0.20, color: .orange, location: "Foundation • Grid A-F"),
            makeTask(title: "Concrete Pour - Foundation", startOffset: 10, duration: 4, progress: 0.0, color: .gray, location: "Foundation • All"),

            // Phase 3: Structure
            makeTask(title: "Steel Erection - Phase 1", startOffset: 14, duration: 15, progress: 0.0, color: .gray, location: "Structure • L1-5"),
            makeTask(title: "Concrete/Steel Structure Vertical", startOffset: 8, duration: 14, progress: 0.34, color: .orange, location: "Structure • L20-24"),
            makeTask(title: "Metal Deck Installation", startOffset: 18, duration: 12, progress: 0.0, color: .gray, location: "Structure • L1-10"),
            makeTask(title: "Concrete Slab on Deck", startOffset: 22, duration: 10, progress: 0.0, color: .gray, location: "Structure • L1-5"),

            // Phase 4: Exterior
            makeTask(title: "Exterior Curtain Wall/Window Wall", startOffset: 0, duration: 18, progress: 0.34, color: .orange, location: "Exterior • L10-14"),
            makeTask(title: "Roofing and Waterproofing", startOffset: 28, duration: 14, progress: 0.0, color: .gray, location: "Exterior • Roof"),
            makeTask(title: "Exterior Cladding - North", startOffset: 25, duration: 20, progress: 0.0, color: .gray, location: "Exterior • North Face"),
            makeTask(title: "Exterior Cladding - South", startOffset: 30, duration: 20, progress: 0.0, color: .gray, location: "Exterior • South Face"),

            // Phase 5: MEP Rough-In
            makeTask(title: "MEP Rough-In - Primary Horizontal", startOffset: -4, duration: 12, progress: 0.34, color: Color(red: 0.2, green: 0.7, blue: 0.3), location: "Interior • L8"),
            makeTask(title: "Electrical Rough-In", startOffset: 12, duration: 18, progress: 0.0, color: .purple, location: "Interior • All Floors"),
            makeTask(title: "Plumbing Rough-In", startOffset: 14, duration: 16, progress: 0.0, color: Color(red: 0.3, green: 0.6, blue: 0.9), location: "Interior • L1-10"),
            makeTask(title: "HVAC Ductwork Installation", startOffset: 16, duration: 20, progress: 0.0, color: Color(red: 0.3, green: 0.6, blue: 0.9), location: "Interior • All"),
            makeTask(title: "Fire Sprinkler Installation", startOffset: 20, duration: 14, progress: 0.0, color: Color(red: 0.9, green: 0.3, blue: 0.3), location: "Interior • All"),

            // Phase 6: Interior Framing
            makeTask(title: "Metal Stud Framing and Fire-Rated", startOffset: -2, duration: 14, progress: 0.45, color: Color(red: 0.2, green: 0.7, blue: 0.3), location: "Interior • L5-7"),
            makeTask(title: "Drywall Installation", startOffset: 24, duration: 18, progress: 0.0, color: .gray, location: "Interior • L1-10"),
            makeTask(title: "Ceiling Grid Installation", startOffset: 32, duration: 12, progress: 0.0, color: .gray, location: "Interior • L1-5"),

            // Phase 7: Finishes
            makeTask(title: "Interior Painting", startOffset: 38, duration: 16, progress: 0.0, color: .gray, location: "Interior • All"),
            makeTask(title: "Flooring Installation", startOffset: 42, duration: 14, progress: 0.0, color: .gray, location: "Interior • L1-10"),
            makeTask(title: "Millwork and Casework", startOffset: 45, duration: 12, progress: 0.0, color: .gray, location: "Interior • Common Areas"),

            // Phase 8: MEP Finishes
            makeTask(title: "Vertical Pipe Insulation and Duct", startOffset: 10, duration: 10, progress: 0.34, color: Color(red: 0.9, green: 0.4, blue: 0.6), location: "Interior • L5-7"),
            makeTask(title: "Electrical Trim", startOffset: 48, duration: 10, progress: 0.0, color: .purple, location: "Interior • All"),
            makeTask(title: "Plumbing Fixtures", startOffset: 50, duration: 8, progress: 0.0, color: Color(red: 0.3, green: 0.6, blue: 0.9), location: "Interior • All"),
            makeTask(title: "HVAC Commissioning", startOffset: 52, duration: 10, progress: 0.0, color: Color(red: 0.3, green: 0.6, blue: 0.9), location: "Interior • All"),

            // Phase 9: Site Work
            makeTask(title: "Site Logistics - Crane Jump/Climb", startOffset: 5, duration: 7, progress: 0.34, color: Color(red: 0.3, green: 0.6, blue: 0.9), location: "Core • Crane Mast"),
            makeTask(title: "Landscaping", startOffset: 55, duration: 14, progress: 0.0, color: .green, location: "Site • Exterior"),
            makeTask(title: "Parking Lot Paving", startOffset: 50, duration: 10, progress: 0.0, color: .gray, location: "Site • Parking"),

            // Phase 10: Closeout
            makeTask(title: "Firestopping and Penetration Sealant", startOffset: 2, duration: 6, progress: 0.50, color: .purple, location: "Interior • L3-4"),
            makeTask(title: "Permitting and Code Review", startOffset: 18, duration: 10, progress: 0.34, color: Color(red: 0.9, green: 0.4, blue: 0.6), location: "Offsite"),
            makeTask(title: "Final Inspections", startOffset: 58, duration: 8, progress: 0.0, color: .gray, location: "All Areas"),
            makeTask(title: "Punch List and Closeout", startOffset: 62, duration: 10, progress: 0.0, color: .gray, location: "All Areas"),
        ]
    }

    // MARK: - Large Dataset Generator for Performance Testing

    private static let taskPrefixes = [
        "Install", "Configure", "Review", "Design", "Build", "Test", "Deploy",
        "Inspect", "Repair", "Upgrade", "Replace", "Audit", "Document", "Train"
    ]

    private static let taskSubjects = [
        "Foundation", "Structure", "Electrical", "Plumbing", "HVAC", "Roofing",
        "Flooring", "Walls", "Windows", "Doors", "Lighting", "Fire System",
        "Security", "Network", "Landscaping", "Parking", "Elevator", "Stairs"
    ]

    private static let locations = [
        "Building A", "Building B", "North Wing", "South Wing", "East Section",
        "West Section", "Basement", "Ground Floor", "Mezzanine", "Rooftop"
    ]

    private static let taskColors: [Color] = [
        .blue, .green, .orange, .purple, .red, .cyan, .indigo, .mint, .pink, .teal
    ]

    /// Generates a large dataset for performance testing
    /// - Parameter count: Number of tasks to generate (default: 30,000)
    /// - Returns: Array of DemoTask instances spread across the date range
    static func generateLargeDataset(count: Int = 30_000) -> [DemoTask] {
        // Spread tasks across 2 years (365 * 2 = 730 days)
        let totalDays = 730
        var tasks: [DemoTask] = []
        tasks.reserveCapacity(count)

        for i in 0..<count {
            // Distribute tasks evenly across the timeline
            let baseOffset = (i * totalDays / count) - (totalDays / 2)
            // Add some randomness to start offset
            let randomOffset = (i.hashValue % 30) - 15
            let startOffset = baseOffset + randomOffset

            // Duration between 3 and 30 days (use abs since hashValue can be negative)
            let duration = 3 + abs(i.hashValue % 28)

            // Progress: completed for past tasks, partial for current, 0 for future
            let progress: Double
            if startOffset < -duration {
                progress = 1.0
            } else if startOffset < 0 {
                progress = Double(abs(startOffset)) / Double(duration)
            } else {
                progress = 0.0
            }

            // Generate task name and details
            let prefix = taskPrefixes[i % taskPrefixes.count]
            let subject = taskSubjects[(i / taskPrefixes.count) % taskSubjects.count]
            let location = locations[(i / (taskPrefixes.count * taskSubjects.count)) % locations.count]
            let color = taskColors[i % taskColors.count]

            let title = "\(prefix) \(subject) #\(i + 1)"
            let start = calendar.date(byAdding: .day, value: startOffset, to: today)!
            let end = calendar.date(byAdding: .day, value: startOffset + duration, to: today)!

            tasks.append(DemoTask(
                title: title,
                subtitle: "\(formatDateRange(start: start, end: end)) • \(duration)d • \(location)",
                startDate: start,
                endDate: end,
                progress: min(1.0, max(0.0, progress)),
                color: color
            ))
        }

        return tasks
    }
}
