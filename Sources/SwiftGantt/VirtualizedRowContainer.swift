import SwiftUI

/// A container that only renders rows visible in the viewport plus a buffer.
/// This enables efficient rendering of large datasets (30k+ items) by keeping
/// only ~50-60 views in memory at any time instead of all items.
struct VirtualizedRowContainer<Item: GanttTask, Content: View>: View {
    let items: [Item]
    let scrollOffset: CGFloat
    let viewportHeight: CGFloat
    let rowHeight: CGFloat
    let bufferCount: Int
    let content: (Item, Int) -> Content

    init(
        items: [Item],
        scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        rowHeight: CGFloat,
        bufferCount: Int = 20,
        @ViewBuilder content: @escaping (Item, Int) -> Content
    ) {
        self.items = items
        self.scrollOffset = scrollOffset
        self.viewportHeight = viewportHeight
        self.rowHeight = rowHeight
        self.bufferCount = bufferCount
        self.content = content
    }

    /// Calculate the range of visible row indices plus buffer
    private var visibleRange: Range<Int> {
        guard !items.isEmpty && rowHeight > 0 else { return 0..<0 }

        let firstVisible = Int(floor(scrollOffset / rowHeight))
        let lastVisible = Int(ceil((scrollOffset + viewportHeight) / rowHeight))

        let firstWithBuffer = max(0, firstVisible - bufferCount)
        let lastWithBuffer = min(items.count, lastVisible + bufferCount)

        return firstWithBuffer..<lastWithBuffer
    }

    var body: some View {
        let range = visibleRange
        let totalHeight = CGFloat(items.count) * rowHeight

        ZStack(alignment: .topLeading) {
            // Render only visible rows + buffer
            ForEach(Array(range), id: \.self) { index in
                content(items[index], index)
                    .frame(height: rowHeight)
                    .offset(y: CGFloat(index) * rowHeight)
            }
        }
        .frame(width: nil, height: totalHeight, alignment: .topLeading)
    }
}

/// A horizontal virtualization container for day columns in the header
struct VirtualizedColumnContainer<Content: View>: View {
    let totalColumns: Int
    let scrollOffset: CGFloat
    let viewportWidth: CGFloat
    let columnWidth: CGFloat
    let bufferCount: Int
    let content: (Int) -> Content

    init(
        totalColumns: Int,
        scrollOffset: CGFloat,
        viewportWidth: CGFloat,
        columnWidth: CGFloat,
        bufferCount: Int = 10,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.totalColumns = totalColumns
        self.scrollOffset = scrollOffset
        self.viewportWidth = viewportWidth
        self.columnWidth = columnWidth
        self.bufferCount = bufferCount
        self.content = content
    }

    /// Calculate the range of visible column indices plus buffer
    private var visibleRange: Range<Int> {
        guard totalColumns > 0 && columnWidth > 0 else { return 0..<0 }

        let firstVisible = Int(floor(scrollOffset / columnWidth))
        let lastVisible = Int(ceil((scrollOffset + viewportWidth) / columnWidth))

        let firstWithBuffer = max(0, firstVisible - bufferCount)
        let lastWithBuffer = min(totalColumns, lastVisible + bufferCount)

        return firstWithBuffer..<lastWithBuffer
    }

    var body: some View {
        let range = visibleRange
        let totalWidth = CGFloat(totalColumns) * columnWidth

        ZStack(alignment: .topLeading) {
            ForEach(Array(range), id: \.self) { index in
                content(index)
                    .frame(width: columnWidth)
                    .offset(x: CGFloat(index) * columnWidth)
            }
        }
        .frame(width: totalWidth, height: nil, alignment: .topLeading)
    }
}
