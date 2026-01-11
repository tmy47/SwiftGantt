import Foundation
import CoreData
import SwiftGantt

/// Core Data stack for the demo app
class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        container = NSPersistentContainer(name: "SwiftGanttDemo")

        // Use in-memory store for demo
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Sample Data Generation

    /// Creates sample Core Data tasks and dependencies for the Gantt chart demo
    func createSampleData() -> (tasks: [CDTask], dependencies: [GanttDependency<Int64>]) {
        let context = viewContext

        // Clear existing data (use regular delete for in-memory store compatibility)
        let existingTasks = (try? context.fetch(CDTask.fetchRequest())) ?? []
        existingTasks.forEach { context.delete($0) }

        let existingDeps = (try? context.fetch(CDTaskDependency.fetchRequest())) ?? []
        existingDeps.forEach { context.delete($0) }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create 8 sample tasks with Int64 IDs
        let taskData: [(id: Int64, title: String, subtitle: String, startOffset: Int, duration: Int, progress: Double, colorHex: String)] = [
            (1, "Project Kickoff", "Planning Phase", -5, 3, 1.0, "4CAF50"),
            (2, "Requirements Gathering", "Analysis Phase", -2, 5, 0.8, "2196F3"),
            (3, "Database Design", "Technical Design", 2, 4, 0.5, "9C27B0"),
            (4, "API Development", "Backend Work", 5, 8, 0.3, "FF9800"),
            (5, "UI/UX Design", "Design Phase", 3, 6, 0.6, "E91E63"),
            (6, "Frontend Development", "Implementation", 8, 10, 0.1, "00BCD4"),
            (7, "Testing & QA", "Quality Assurance", 16, 5, 0.0, "F44336"),
            (8, "Deployment", "Release", 20, 3, 0.0, "607D8B")
        ]

        var tasks: [CDTask] = []

        for data in taskData {
            let task = CDTask(context: context)
            task.id = data.id
            task.title_ = data.title
            task.subtitle_ = data.subtitle
            task.startDate_ = calendar.date(byAdding: .day, value: data.startOffset, to: today)!
            task.endDate_ = calendar.date(byAdding: .day, value: data.startOffset + data.duration, to: today)!
            task.progress = data.progress
            task.colorHex = data.colorHex
            tasks.append(task)
        }

        // Create 2 dependencies
        let dep1 = CDTaskDependency(context: context)
        dep1.id = 1
        dep1.fromTaskId = 1  // Project Kickoff
        dep1.toTaskId = 2    // Requirements Gathering
        dep1.type = "endToStart"

        let dep2 = CDTaskDependency(context: context)
        dep2.id = 2
        dep2.fromTaskId = 4  // API Development
        dep2.toTaskId = 6    // Frontend Development
        dep2.type = "endToStart"

        try? context.save()

        // Convert dependencies to GanttDependency format
        let ganttDependencies = [dep1, dep2].map { $0.toGanttDependency() }

        return (tasks, ganttDependencies)
    }

    /// Fetches all tasks sorted by start date
    func fetchTasks() -> [CDTask] {
        let request: NSFetchRequest<CDTask> = CDTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTask.startDate_, ascending: true)]
        return (try? viewContext.fetch(request)) ?? []
    }

    /// Fetches all dependencies as GanttDependency objects
    func fetchDependencies() -> [GanttDependency<Int64>] {
        let request: NSFetchRequest<CDTaskDependency> = CDTaskDependency.fetchRequest()
        let deps = (try? viewContext.fetch(request)) ?? []
        return deps.map { $0.toGanttDependency() }
    }
}
