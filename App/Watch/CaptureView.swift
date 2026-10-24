import SwiftUI
import PinHereKit

/// Silent-first capture: the tap saves the pin, then a short confirmation card.
/// Placeholder until C1 to C3 are built.
struct CaptureView: View {
    var body: some View {
        Button {
            // C2: save current location before any other input.
        } label: {
            Label("Pin here", systemImage: "mappin")
                .font(.title3)
        }
        .accessibilityHint("Saves where you are standing")
    }
}

#Preview {
    CaptureView()
}
