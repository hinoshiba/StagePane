import SwiftUI

struct SampleBufferDisplayView: NSViewRepresentable {
    let renderer: SampleBufferRenderer

    func makeNSView(context: Context) -> SampleBufferNSView {
        SampleBufferNSView(renderer: renderer)
    }

    func updateNSView(_ nsView: SampleBufferNSView, context: Context) {
        nsView.needsLayout = true
    }
}
