import SwiftUI

@main
struct ShogiDoApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.environment["SHOGI_CAPTURE_GAME"] != nil {
                GameView(difficulty: .easy)
            } else {
                HomeView()
            }
            #else
            HomeView()
            #endif
        }
    }
}
