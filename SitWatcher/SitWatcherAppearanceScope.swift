import SwiftUI

/// Injects a resolved `.dark`/`.light` chroma palette and applies forced light/dark only when stored mode is `.dark`/`.light`. `.system` inherits macOS scheme.
struct SitWatcherAppearanceScope<Content: View>: View {
    let stored: SitWatcherPanelAppearance
    @ViewBuilder var content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    private var palette: SitWatcherPanelAppearance {
        stored.resolvedPalette(for: colorScheme)
    }

    var body: some View {
        Group {
            if let override = stored.preferredSchemeOverride {
                content()
                    .environment(\.sitWatcherPanelAppearance, palette)
                    .preferredColorScheme(override)
            } else {
                content()
                    .environment(\.sitWatcherPanelAppearance, palette)
            }
        }
    }
}
