import SwiftUI
import SwiftGantt

enum DatasetSize: String, CaseIterable {
    case minimal = "2 Items"
    case demo = "Demo (35)"
    case coreData = "Core Data Demo"
    case small = "100 Items"
    case large = "30K Items"
}

struct ContentView: View {
    @State private var selectedDataset: DatasetSize = .minimal
    @State private var tasks: [DemoTask] = SampleData.minimalTasks
    @State private var dependencies: [GanttDependency<UUID>] = SampleData.minimalDependencies
    @State private var coreDataTasks: [CDTask] = []
    @State private var coreDataDependencies: [GanttDependency<Int64>] = []
    @State private var showDependencies = true
    @State private var isLoading = false
    @State private var scrollToTodayTrigger = UUID()
    @State private var selectedTask: DemoTask?
    @State private var selectedCDTask: CDTask?

    private var isUsingCoreData: Bool {
        selectedDataset == .coreData
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isUsingCoreData {
                    GanttChart(
                        tasks: coreDataTasks,
                        dependencies: showDependencies ? coreDataDependencies : [],
                        dateRange: SampleData.dateRange
                    ) { task in
                        selectedCDTask = task
                    }
                    .id(scrollToTodayTrigger)
                } else {
                    GanttChart(
                        tasks: tasks,
                        dependencies: showDependencies ? dependencies : [],
                        dateRange: SampleData.dateRange
                    ) { task in
                        selectedTask = task
                    }
                    .id(scrollToTodayTrigger)
                }

                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Loading \(selectedDataset.rawValue)...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("SwiftGantt Demo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        Button {
                            scrollToTodayTrigger = UUID()
                        } label: {
                            Image(systemName: "calendar.circle")
                        }

                        Button {
                            showDependencies.toggle()
                        } label: {
                            Image(systemName: showDependencies ? "arrow.triangle.branch" : "minus")
                        }

                        Button {
                            sortByColor()
                        } label: {
                            Image(systemName: "paintpalette")
                        }

                        Menu {
                            ForEach(DatasetSize.allCases, id: \.self) { size in
                                Button {
                                    loadDataset(size)
                                } label: {
                                    HStack {
                                        Text(size.rawValue)
                                        if selectedDataset == size {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task)
            }
            .sheet(item: $selectedCDTask) { task in
                CDTaskDetailView(task: task)
            }
        }
    }

    private func loadDataset(_ size: DatasetSize) {
        guard size != selectedDataset else { return }

        isLoading = true
        selectedDataset = size

        DispatchQueue.global(qos: .userInitiated).async {
            if size == .coreData {
                let (cdTasks, cdDeps) = CoreDataStack.shared.createSampleData()
                DispatchQueue.main.async {
                    coreDataTasks = cdTasks
                    coreDataDependencies = cdDeps
                    isLoading = false
                }
            } else {
                let newTasks: [DemoTask]
                let newDependencies: [GanttDependency<UUID>]
                switch size {
                case .minimal:
                    newTasks = SampleData.minimalTasks
                    newDependencies = SampleData.minimalDependencies
                case .demo:
                    newTasks = SampleData.tasks
                    newDependencies = SampleData.demoDependencies
                case .coreData:
                    newTasks = []
                    newDependencies = []
                case .small:
                    newTasks = SampleData.generateLargeDataset(count: 100)
                    newDependencies = []
                case .large:
                    newTasks = SampleData.generateLargeDataset(count: 30_000)
                    newDependencies = []
                }
                DispatchQueue.main.async {
                    tasks = newTasks
                    dependencies = newDependencies
                    isLoading = false
                }
            }
        }
    }

    private func sortByColor() {
        if isUsingCoreData {
            coreDataTasks.sort { task1, task2 in
                let hue1 = UIColor(task1.color).hue
                let hue2 = UIColor(task2.color).hue
                return hue1 < hue2
            }
        } else {
            tasks.sort { task1, task2 in
                let hue1 = UIColor(task1.color).hue
                let hue2 = UIColor(task2.color).hue
                return hue1 < hue2
            }
        }
    }
}

// MARK: - UIColor Hue Extension

extension UIColor {
    var hue: CGFloat {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return hue
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    let task: DemoTask
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var duration: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: task.startDate)
        let end = calendar.startOfDay(for: task.endDate)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(task.color)
                            .frame(width: 12, height: 12)
                        Text(task.title)
                            .font(.headline)
                    }

                    if let subtitle = task.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Schedule") {
                    LabeledContent("Start Date", value: dateFormatter.string(from: task.startDate))
                    LabeledContent("End Date", value: dateFormatter.string(from: task.endDate))
                    LabeledContent("Duration", value: "\(duration) days")
                }

                Section("Progress") {
                    HStack {
                        ProgressView(value: task.progress)
                            .tint(task.color)
                        Text("\(Int(task.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(400), .large])
        .iPadSheet()
    }
}

// MARK: - Core Data Task Detail View

struct CDTaskDetailView: View {
    let task: CDTask
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var duration: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: task.startDate)
        let end = calendar.startOfDay(for: task.endDate)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(task.color)
                            .frame(width: 12, height: 12)
                        Text(task.title)
                            .font(.headline)
                    }

                    if let subtitle = task.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Schedule") {
                    LabeledContent("Start Date", value: dateFormatter.string(from: task.startDate))
                    LabeledContent("End Date", value: dateFormatter.string(from: task.endDate))
                    LabeledContent("Duration", value: "\(duration) days")
                }

                Section("Progress") {
                    HStack {
                        ProgressView(value: task.progress)
                            .tint(task.color)
                        Text("\(Int(task.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Core Data Info") {
                    LabeledContent("ID (Int64)", value: "\(task.id)")
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(450), .large])
        .iPadSheet()
    }
}

// MARK: - iPad Sheet Modifier

extension View {
    @ViewBuilder
    func iPadSheet() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self
                .presentationDetents([.height(500)])
                .frame(minWidth: 400, idealWidth: 500, maxWidth: 600)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
}
