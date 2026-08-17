import SwiftUI

struct HomeView: View {
    @StateObject private var purchases = PurchaseManager.shared
    @State private var showUpgrade = false
    @State private var showHowToPlay = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                Text("将棋")
                    .font(.system(size: 44, weight: .bold))
                Text("Shogi Do")
                    .font(.title.bold())

                if !purchases.isPro && purchases.trialActive {
                    Text(String(format: String(localized: "Free trial — %d day(s) left"), purchases.trialDaysRemaining))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                        if isLocked(difficulty) {
                            Button {
                                showUpgrade = true
                            } label: {
                                difficultyRow(difficulty, locked: true)
                            }
                            .foregroundStyle(.primary)
                        } else {
                            NavigationLink(value: difficulty) {
                                difficultyRow(difficulty, locked: false)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.horizontal, 32)

                if !purchases.isPro {
                    Button {
                        showUpgrade = true
                    } label: {
                        Text(purchases.trialActive ? String(localized: "Unlock Pro") : String(localized: "Trial ended — unlock to keep playing"))
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                    }
                }

                Spacer()
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHowToPlay = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .navigationDestination(for: AIDifficulty.self) { difficulty in
                GameView(difficulty: difficulty)
            }
            .sheet(isPresented: $showUpgrade) { UpgradeView() }
            .sheet(isPresented: $showHowToPlay, onDismiss: { hasSeenOnboarding = true }) {
                HowToPlayView(isOnboarding: !hasSeenOnboarding)
            }
            .onAppear {
                if !hasSeenOnboarding { showHowToPlay = true }
            }
        }
    }

    /// Every difficulty locks behind the paywall once the trial expires and
    /// the user isn't Pro — there is no permanently free tier.
    private func isLocked(_ difficulty: AIDifficulty) -> Bool {
        if purchases.isPro { return false }
        if difficulty.requiresPro { return true }
        return !purchases.trialActive
    }

    private func difficultyRow(_ difficulty: AIDifficulty, locked: Bool) -> some View {
        HStack {
            Text(label(for: difficulty))
            Spacer()
            if locked {
                Image(systemName: "lock.fill")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }

    private func label(for difficulty: AIDifficulty) -> String {
        switch difficulty {
        case .easy: return String(localized: "Easy")
        case .normal: return String(localized: "Normal")
        case .hard: return String(localized: "Hard")
        }
    }
}

#Preview {
    HomeView()
}
