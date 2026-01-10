import SwiftUI

/// A view that renders dependency lines between tasks
struct DependencyLayer<Task: GanttTask>: View where Task.ID: Hashable {
    let dependencies: [GanttDependency<Task.ID>]
    let tasks: [Task]
    let dateRange: ClosedRange<Date>
    let configuration: GanttChartConfiguration

    var body: some View {
        Canvas { context, size in
            let calculator = DependencyPathCalculator(
                tasks: tasks,
                dateRange: dateRange,
                configuration: configuration
            )

            for dependency in dependencies {
                // Draw the line
                if let linePath = calculator.path(for: dependency) {
                    context.stroke(
                        linePath,
                        with: .color(configuration.dependencyLineColor),
                        lineWidth: configuration.dependencyLineWidth
                    )
                }

                // Draw the arrowhead
                if let arrowPath = calculator.arrowPath(for: dependency) {
                    context.fill(
                        arrowPath,
                        with: .color(configuration.dependencyLineColor)
                    )
                }
            }
        }
    }
}
