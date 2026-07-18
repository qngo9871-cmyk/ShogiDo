import SwiftUI

struct GameView: View {
    let difficulty: AIDifficulty
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = GameModel()
    @State private var selected: Square?
    @State private var selectedDrop: PieceKind?
    @State private var legalTargets: Set<Square> = []
    @State private var isAIThinking = false

    private let human: Player = .sente
    private let squareSize: CGFloat = 38

    var body: some View {
        VStack(spacing: 12) {
            header

            handTray(for: human.opponent)

            boardGrid

            handTray(for: human)

            if model.isCurrentPlayerInCheck, model.outcome == .ongoing {
                Text(String(localized: "Check"))
                    .font(.headline)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(red: 0.87, green: 0.75, blue: 0.52).ignoresSafeArea())
        .onChange(of: model.currentPlayer) { _ in triggerAIMoveIfNeeded() }
        .confirmationDialog(String(localized: "Promote?"), isPresented: promotionBinding) {
            Button(String(localized: "Promote")) {
                if let move = model.pendingPromotion { model.makeBoardMove(move, promote: true) }
            }
            Button(String(localized: "Don't Promote")) {
                if let move = model.pendingPromotion { model.makeBoardMove(move, promote: false) }
            }
        }
        .alert(isPresented: gameOverBinding) {
            switch model.outcome {
            case .checkmate(let winner):
                return Alert(
                    title: Text(winner == human ? String(localized: "You Win") : String(localized: "You Lose")),
                    dismissButton: .default(Text(String(localized: "Home"))) { dismiss() }
                )
            case .ongoing:
                return Alert(title: Text(""))
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(model.currentPlayer == .sente ? String(localized: "Sente") : String(localized: "Gote"))
                .font(.subheadline.bold())
            Spacer()
            if isAIThinking {
                ProgressView().scaleEffect(0.7)
            } else {
                Color.clear.frame(width: 20)
            }
        }
    }

    private var boardGrid: some View {
        VStack(spacing: 1) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<9, id: \.self) { col in
                        squareView(Square(row: row, col: col))
                    }
                }
            }
        }
        .padding(6)
        .background(Color(red: 0.75, green: 0.58, blue: 0.32))
        .disabled(model.currentPlayer != human || isAIThinking)
    }

    private func squareView(_ square: Square) -> some View {
        ZStack {
            Rectangle()
                .fill(highlightColor(square))
                .frame(width: squareSize, height: squareSize)
                .border(Color.black.opacity(0.25), width: 0.5)
            if let piece = model.board[square] {
                PieceView(piece: piece)
                    .frame(width: squareSize - 4, height: squareSize - 4)
            }
        }
        .onTapGesture { handleTap(square) }
    }

    private func highlightColor(_ square: Square) -> Color {
        if selected == square { return Color.yellow.opacity(0.5) }
        if legalTargets.contains(square) { return Color.green.opacity(0.35) }
        return Color.clear
    }

    private func handTray(for player: Player) -> some View {
        let kinds: [PieceKind] = [.rook, .bishop, .gold, .silver, .knight, .lance, .pawn]
        return HStack(spacing: 6) {
            Text(String(localized: "Hand")).font(.caption).foregroundStyle(.secondary)
            ForEach(kinds, id: \.self) { kind in
                let count = model.board.handCount(player, kind)
                if count > 0 {
                    Button {
                        guard player == human, model.currentPlayer == human else { return }
                        selected = nil
                        selectedDrop = kind
                        legalTargets = Set(model.legalDrops(kind: kind))
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            PieceView(piece: Piece(kind: kind, owner: player))
                                .frame(width: 30, height: 30)
                            if count > 1 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(2)
                                    .background(Circle().fill(Color.white))
                            }
                        }
                    }
                    .disabled(player != human)
                }
            }
            Spacer()
        }
        .frame(minHeight: 34)
    }

    private func handleTap(_ square: Square) {
        guard model.currentPlayer == human, !isAIThinking else { return }

        if let dropKind = selectedDrop {
            if legalTargets.contains(square) {
                model.makeDrop(DropMove(kind: dropKind, to: square))
            }
            selectedDrop = nil
            legalTargets = []
            return
        }

        if let from = selected {
            if legalTargets.contains(square) {
                model.makeBoardMove(BoardMove(from: from, to: square), promote: nil)
                selected = nil
                legalTargets = []
                return
            }
            selected = nil
            legalTargets = []
        }

        if let piece = model.board[square], piece.owner == human {
            selected = square
            legalTargets = Set(model.legalBoardMoves(from: square).map(\.to))
        }
    }

    private func triggerAIMoveIfNeeded() {
        guard model.outcome == .ongoing, model.currentPlayer != human else { return }
        isAIThinking = true
        let boardSnapshot = model.board
        let aiPlayer = model.currentPlayer
        Task.detached(priority: .userInitiated) {
            let move = AIPlayer.bestMove(board: boardSnapshot, player: aiPlayer, difficulty: difficulty)
            await MainActor.run {
                isAIThinking = false
                switch move {
                case .board(let boardMove, let promote):
                    model.makeBoardMove(boardMove, promote: promote)
                case .drop(let drop):
                    model.makeDrop(drop)
                case .none:
                    break
                }
            }
        }
    }

    private var promotionBinding: Binding<Bool> {
        Binding(get: { model.pendingPromotion != nil }, set: { if !$0 { model.pendingPromotion = nil } })
    }

    private var gameOverBinding: Binding<Bool> {
        Binding(get: {
            if case .checkmate = model.outcome { return true }
            return false
        }, set: { _ in })
    }
}
