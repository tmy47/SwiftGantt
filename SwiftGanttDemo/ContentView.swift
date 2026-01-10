import SwiftUI
import SwiftGantt

enum DatasetSize: String, CaseIterable {
    case demo = "Demo (35)"
    case small = "100 Items"
    case large = "30K Items"
}

struct ContentView: View {
    @State private var selectedDataset: DatasetSize = .demo
    @State private var tasks: [DemoTask] = SampleData.tasks
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                GanttChart(
                    tasks: tasks,
                    dateRange: SampleData.dateRange
                )

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
    }

    private func loadDataset(_ size: DatasetSize) {
        guard size != selectedDataset else { return }

        isLoading = true
        selectedDataset = size

        DispatchQueue.global(qos: .userInitiated).async {
            let newTasks: [DemoTask]
            switch size {
            case .demo:
                newTasks = SampleData.tasks
            case .small:
                newTasks = SampleData.generateLargeDataset(count: 100)
            case .large:
                newTasks = SampleData.generateLargeDataset(count: 30_000)
            }
            DispatchQueue.main.async {
                tasks = newTasks
                isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
