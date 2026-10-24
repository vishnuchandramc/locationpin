import MapKit
import SwiftUI
import PinHereKit

/// The phone is the filing cabinet: map on top, distance-sorted list below.
/// Placeholder until M1 is built.
struct PinMapView: View {
    var body: some View {
        Map()
            .mapStyle(.standard(emphasis: .muted))
            .safeAreaInset(edge: .bottom) {
                Text("No pins yet. Tap the Pin Here complication on your watch.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
            }
    }
}

#Preview {
    PinMapView()
}
