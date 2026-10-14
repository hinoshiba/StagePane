import SwiftUI

/// Native list reordering commits only after a drop. macOS owns the insertion
/// marker, drag cancellation, and scrolling near the list's edges.
struct LayerReorderList<ID: Hashable, Row: View>: View {
    let sourceIDs: [ID]
    let focusedSourceID: ID?
    let canMove: (ID) -> Bool
    let move: (IndexSet, Int, [ID]) -> Void
    @ViewBuilder let row: (ID) -> Row

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(sourceIDs, id: \.self) { sourceID in
                    row(sourceID)
                        .contentShape(Rectangle())
                        .id(sourceID)
                        .listRowInsets(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .moveDisabled(!canMove(sourceID))
                }
                .onMove { offsets, destination in
                    // Preserve the identity/order that these offsets refer to.
                    // The owner rejects the move if its source model changed.
                    move(offsets, destination, sourceIDs)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 1)
            .onChange(of: focusedSourceID) { _, sourceID in
                if let sourceID { proxy.scrollTo(sourceID) }
            }
        }
    }
}
