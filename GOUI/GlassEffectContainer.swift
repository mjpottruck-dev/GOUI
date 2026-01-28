import SwiftUI

/// Compatibility wrapper so older "glass" UI code compiles.
/// Supports:
/// - GlassEffectContainer { content }
/// - GlassEffectContainer(_:_:) { content }
/// - GlassEffectContainer(_:_:_: ...) { content }  (extra args ignored)
struct GlassEffectContainer<Content: View>: View {

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // Accept 1–2 extra args (ignored). This fixes "extra arguments" compile errors.
    init<A, B>(_ a: A, _ b: B, @ViewBuilder content: () -> Content) {
        self.content = content()
    }

    init<A>(_ a: A, @ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

