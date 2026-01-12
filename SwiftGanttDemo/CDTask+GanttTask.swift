import Foundation
import SwiftUI
import CoreData
import SwiftGantt

// MARK: - CDTask NSManagedObject

@objc(CDTask)
public class CDTask: NSManagedObject, Identifiable {
    @NSManaged public var id: Int64
    @NSManaged public var colorHex: String?
    @NSManaged public var endDate_: Date?
    @NSManaged public var progress: Double
    @NSManaged public var startDate_: Date?
    @NSManaged public var subtitle_: String?
    @NSManaged public var title_: String?
}

extension CDTask {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTask> {
        return NSFetchRequest<CDTask>(entityName: "CDTask")
    }
}

// MARK: - CDTask + GanttTask

extension CDTask: GanttTask {
    public var title: String {
        title_ ?? "Untitled"
    }

    public var subtitle: String? {
        subtitle_
    }

    public var taskStartDate: Date {
        startDate_ ?? Date()
    }

    public var taskEndDate: Date {
        endDate_ ?? Date()
    }

    public var color: Color {
        guard let hex = colorHex else { return .blue }
        return Color(hex: hex)
    }
}

// MARK: - CDTaskDependency NSManagedObject

@objc(CDTaskDependency)
public class CDTaskDependency: NSManagedObject {
    @NSManaged public var id: Int64
    @NSManaged public var fromTaskId: Int64
    @NSManaged public var toTaskId: Int64
    @NSManaged public var type: String?
}

extension CDTaskDependency {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTaskDependency> {
        return NSFetchRequest<CDTaskDependency>(entityName: "CDTaskDependency")
    }

    /// Convert to GanttDependency for use with GanttChart
    func toGanttDependency() -> GanttDependency<Int64> {
        let depType: DependencyType
        switch type {
        case "startToStart": depType = .startToStart
        case "endToEnd": depType = .endToEnd
        case "startToEnd": depType = .startToEnd
        default: depType = .endToStart
        }
        return GanttDependency(fromId: fromTaskId, toId: toTaskId, type: depType)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
