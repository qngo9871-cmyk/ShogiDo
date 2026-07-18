import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    var isOnboarding: Bool = false

    private var sections: [(icon: String, title: String, body: String)] {
        [
            ("hand.tap.fill", String(localized: "Moving a Piece"),
             String(localized: "Tap one of your pieces to see its legal moves highlighted in green, then tap a highlighted square to move there.")),
            ("arrow.down.circle.fill", String(localized: "Dropping a Piece"),
             String(localized: "Captured enemy pieces join your hand, shown below the board. Tap a piece in your hand, then tap an empty square, to drop it back onto the board as your own.")),
            ("arrow.up.forward.circle.fill", String(localized: "Promotion"),
             String(localized: "Most pieces can flip to a stronger form when they move into, within, or out of the far three ranks. The app asks when promotion is optional, and promotes automatically when it's required.")),
            ("checkmark.shield.fill", String(localized: "Two Automatic Pawn Rules"),
             String(localized: "You can't drop a second unpromoted pawn on a file that already has one of your own (nifu), and you can't drop a pawn that delivers checkmate on the spot (uchifuzume). Both are enforced for you.")),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Label(section.title, systemImage: section.icon)
                                .font(.headline)
                            Text(section.body)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "How to Play"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isOnboarding ? String(localized: "Let's Play") : String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview { HowToPlayView() }
