import SwiftUI

@main
struct ShogiDoApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.environment["SHOGI_CAPTURE"] == "paywall" {
                UpgradeView()
            } else if let mode = ProcessInfo.processInfo.environment["SHOGI_CAPTURE"], mode != "home" {
                GameView(difficulty: .easy, captureMode: mode)
            } else {
                HomeView()
            }
            #else
            HomeView()
            #endif
        }
    }
}
