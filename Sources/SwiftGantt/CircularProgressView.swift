import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let size: CGFloat

    private var displayProgress: String {
        let percentage = Int(progress * 100)
        return "\(percentage)"
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Percentage text
            Text(displayProgress)
                .font(.system(size: size * 0.32, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}
