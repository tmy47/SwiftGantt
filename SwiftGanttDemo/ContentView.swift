import SwiftUI
import SwiftGantt

struct ContentView: View {
    var body: some View {
        NavigationStack {
            GanttChart(
                tasks: SampleData.tasks,
                dateRange: SampleData.dateRange
            )
            .navigationTitle("SwiftGantt Demo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

#Preview {
    ContentView()
}
