import SwiftUI

@main
struct SoccerStatsMVPApp: App {

    init() {
        // Register DM Sans and DM Mono fonts from Google Fonts bundles
        registerCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    /// Registers all .ttf fonts found in the bundle
    private func registerCustomFonts() {
        let fontExtensions = ["ttf", "otf"]
        for ext in fontExtensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
        }
    }
}
