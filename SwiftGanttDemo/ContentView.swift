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

                        Menu {
                            Button {
                                sortByDate()
                            } label: {
                                Label("Sort by Date", systemImage: "calendar")
                            }
                            Button {
                                sortByColor()
                            } label: {
                                Label("Sort by Color", systemImage: "paintpalette")
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
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
                TaskDetailView(task: task) { updatedTask in
                    if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                        tasks[index] = updatedTask
                    }
                }
            }
            .sheet(item: $selectedCDTask) { task in
                CDTaskDetailView(task: task) {
                    // Force full chart refresh
                    scrollToTodayTrigger = UUID()
                }
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
                let hue1 = UIColor(task1.taskColor).hue
                let hue2 = UIColor(task2.taskColor).hue
                return hue1 < hue2
            }
        } else {
            tasks.sort { task1, task2 in
                let hue1 = UIColor(task1.taskColor).hue
                let hue2 = UIColor(task2.taskColor).hue
                return hue1 < hue2
            }
        }
    }

    private func sortByDate() {
        if isUsingCoreData {
            coreDataTasks.sort { $0.taskStartDate < $1.taskStartDate }
        } else {
            tasks.sort { $0.taskStartDate < $1.taskStartDate }
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
    let onSave: (DemoTask) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var editedTitle: String = ""
    @State private var editedStartDate: Date = Date()
    @State private var editedEndDate: Date = Date()
    @State private var editedProgress: Double = 0

    private var duration: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: editedStartDate)
        let end = calendar.startOfDay(for: editedEndDate)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Circle()
                            .fill(task.taskColor)
                            .frame(width: 12, height: 12)
                        TextField("Title", text: $editedTitle)
                            .font(.headline)
                            .onSubmit { saveChanges() }
                    }

                    if let subtitle = task.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Schedule") {
                    DatePicker("Start Date", selection: $editedStartDate, displayedComponents: .date)
                        .onChange(of: editedStartDate) { _ in
                            if editedEndDate < editedStartDate {
                                editedEndDate = editedStartDate
                            }
                            saveChanges()
                        }
                    DatePicker("End Date", selection: $editedEndDate, in: editedStartDate..., displayedComponents: .date)
                        .onChange(of: editedEndDate) { _ in saveChanges() }
                    LabeledContent("Duration", value: "\(duration) days")
                }

                Section("Progress") {
                    HStack {
                        Slider(value: $editedProgress, in: 0...1, step: 0.05)
                            .tint(task.taskColor)
                            .onChange(of: editedProgress) { _ in saveChanges() }
                        Text("\(Int(editedProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 40)
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
        .onAppear {
            editedTitle = task.title
            editedStartDate = task.taskStartDate
            editedEndDate = task.taskEndDate
            editedProgress = task.progress
        }
        .fittedSheet()
    }

    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = editedTitle
        updatedTask.taskStartDate = editedStartDate
        updatedTask.taskEndDate = editedEndDate
        updatedTask.progress = editedProgress
        onSave(updatedTask)
    }
}

// MARK: - Core Data Task Detail View

struct CDTaskDetailView: View {
    @ObservedObject var task: CDTask
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var editedTitle: String = ""
    @State private var editedStartDate: Date = Date()
    @State private var editedEndDate: Date = Date()
    @State private var editedProgress: Double = 0

    private var duration: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: editedStartDate)
        let end = calendar.startOfDay(for: editedEndDate)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Circle()
                            .fill(task.taskColor)
                            .frame(width: 12, height: 12)
                        TextField("Title", text: $editedTitle)
                            .font(.headline)
                            .onSubmit { saveChanges() }
                    }

                    if let subtitle = task.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Schedule") {
                    DatePicker("Start Date", selection: $editedStartDate, displayedComponents: .date)
                        .onChange(of: editedStartDate) { _ in
                            if editedEndDate < editedStartDate {
                                editedEndDate = editedStartDate
                            }
                            saveChanges()
                        }
                    DatePicker("End Date", selection: $editedEndDate, in: editedStartDate..., displayedComponents: .date)
                        .onChange(of: editedEndDate) { _ in saveChanges() }
                    LabeledContent("Duration", value: "\(duration) days")
                }

                Section("Progress") {
                    HStack {
                        Slider(value: $editedProgress, in: 0...1, step: 0.05)
                            .tint(task.taskColor)
                            .onChange(of: editedProgress) { _ in saveChanges() }
                        Text("\(Int(editedProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 40)
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
        .onAppear {
            editedTitle = task.title
            editedStartDate = task.taskStartDate
            editedEndDate = task.taskEndDate
            editedProgress = task.progress
        }
        .fittedSheet()
    }

    private func saveChanges() {
        task.title_ = editedTitle
        task.startDate_ = editedStartDate
        task.endDate_ = editedEndDate
        task.progress = editedProgress
        try? task.managedObjectContext?.save()
        onSave()
    }
}

// MARK: - Fitted Sheet Modifier

extension View {
    @ViewBuilder
    func fittedSheet() -> some View {
        if #available(iOS 18.0, *) {
            self
                .presentationSizing(.form)
                .presentationDragIndicator(.visible)
        } else {
            self
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ContentView()
}
