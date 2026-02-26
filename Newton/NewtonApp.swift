import SwiftUI

@main
struct NewtonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Add Help menu info
            CommandGroup(replacing: .help) {
                Link("Isaac Newton - Wikipedia",
                     destination: URL(string: "https://en.wikipedia.org/wiki/Isaac_Newton")!)
            }
        }
    }
}
