import SwiftUI

struct GanttTaskRow<Item: GanttTask>: View {
    let task: Item
    let dateRange: ClosedRange<Date>
    let configuration: GanttChartConfiguration

    private let calendar = Calendar.current

    private var totalDays: Int {
        let start = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 1
    }

    private var chartWidth: CGFloat {
        CGFloat(totalDays + 1) * configuration.dayColumnWidth
    }

    private var taskStartOffset: CGFloat {
        let rangeStart = calendar.startOfDay(for: dateRange.lowerBound)
        let taskStart = calendar.startOfDay(for: task.startDate)
        let days = calendar.dateComponents([.day], from: rangeStart, to: taskStart).day ?? 0
        return CGFloat(days) * configuration.dayColumnWidth
    }

    private var taskWidth: CGFloat {
        let taskStart = calendar.startOfDay(for: task.startDate)
        let taskEnd = calendar.startOfDay(for: task.endDate)
        let days = calendar.dateComponents([.day], from: taskStart, to: taskEnd).day ?? 0
        return CGFloat(days + 1) * configuration.dayColumnWidth
    }

    private var barHeight: CGFloat {
        configuration.rowHeight * configuration.barHeightRatio
    }

    var body: some View {
        HStack(spacing: 0) {
            // Task label
            Text(task.title)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: configuration.labelColumnWidth, alignment: .leading)
                .padding(.horizontal, 8)

            // Task bar area
            ZStack(alignment: .leading) {
                // Background track
                Color.clear
                    .frame(width: chartWidth, height: configuration.rowHeight)

                // Task bar
                TaskBar(
                    progress: task.progress,
                    configuration: configuration,
                    barHeight: barHeight
                )
                .frame(width: max(taskWidth, configuration.dayColumnWidth / 2), height: barHeight)
                .offset(x: taskStartOffset)
            }
        }
        .frame(height: configuration.rowHeight)
    }
}

private struct TaskBar: View {
    let progress: Double
    let configuration: GanttChartConfiguration
    let barHeight: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: configuration.barCornerRadius)
                    .fill(configuration.barColor)

                // Progress fill
                if progress > 0 {
                    RoundedRectangle(cornerRadius: configuration.barCornerRadius)
                        .fill(configuration.progressColor)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                }
            }
        }
    }
}
