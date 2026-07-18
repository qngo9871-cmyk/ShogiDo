import Foundation

enum GameOutcome: Equatable {
    case ongoing
    case checkmate(winner: Player)
}

final class GameModel: ObservableObject {
    @Published private(set) var board = Board()
    @Published private(set) var currentPlayer: Player = .sente
    @Published private(set) var outcome: GameOutcome = .ongoing
    @Published private(set) var lastMove: BoardMove?
    @Published var pendingPromotion: BoardMove?

    func legalBoardMoves(from square: Square) -> [BoardMove] {
        guard let piece = board[square], piece.owner == currentPlayer else { return [] }
        return Rules.legalBoardMoves(from: square, board: board)
    }

    func legalDrops(kind: PieceKind) -> [Square] {
        Rules.legalDrops(kind: kind, board: board, player: currentPlayer)
    }

    var isCurrentPlayerInCheck: Bool { Rules.isKingInCheck(currentPlayer, board: board) }

    func canPromote(_ move: BoardMove) -> Bool { Rules.canPromote(move, board: board) }
    func mustPromote(_ move: BoardMove) -> Bool { Rules.mustPromote(move, board: board) }

    /// Applies a board move. If the move is promotion-eligible and not forced,
    /// call with `promote: nil` first — the caller should present the promotion
    /// prompt (see `pendingPromotion`) and re-invoke with the user's choice.
    func makeBoardMove(_ move: BoardMove, promote: Bool?) {
        guard board[move.from] != nil else { return }
        if canPromote(move), promote == nil, !mustPromote(move) {
            pendingPromotion = move
            return
        }
        board = Rules.applying(move, promote: promote ?? false, board: board)
        lastMove = move
        pendingPromotion = nil
        finishTurn()
    }

    func makeDrop(_ drop: DropMove) {
        board = Rules.applying(drop, player: currentPlayer, board: board)
        lastMove = BoardMove(from: drop.to, to: drop.to)
        finishTurn()
    }

    private func finishTurn() {
        currentPlayer = currentPlayer.opponent
        if !Rules.hasAnyLegalMove(board: board, player: currentPlayer) {
            outcome = .checkmate(winner: currentPlayer.opponent)
        }
    }

    func reset() {
        board = Board()
        currentPlayer = .sente
        outcome = .ongoing
        lastMove = nil
        pendingPromotion = nil
    }

    #if DEBUG
    /// Staged positions for App Store screenshots — driven by the SHOGI_CAPTURE env
    /// var (see ShogiDoApp.swift). Not reachable via real play; purely for visual
    /// variety in marketing shots. DEBUG-only, inert in release builds.
    static func captureScenario(_ name: String) -> GameModel {
        let model = GameModel()
        switch name {
        case "hand": model.stageHandScenario()
        case "check": model.stageCheckScenario()
        default: break
        }
        return model
    }

    private func stageHandScenario() {
        var b = Board()
        b[Square(row: 1, col: 7)] = nil   // gote bishop -> sente's hand
        b[Square(row: 0, col: 2)] = nil   // gote silver -> sente's hand
        b[Square(row: 2, col: 0)] = nil   // gote pawn -> sente's hand
        b[Square(row: 6, col: 0)] = nil   // sente pawn -> gote's hand
        b[Square(row: 8, col: 3)] = nil   // sente gold -> gote's hand
        b.addToHand(.sente, .bishop)
        b.addToHand(.sente, .silver)
        b.addToHand(.sente, .pawn)
        b.addToHand(.gote, .pawn)
        b.addToHand(.gote, .gold)
        board = b
        currentPlayer = .sente
    }

    private func stageCheckScenario() {
        var b = Board()
        var rook = b[Square(row: 7, col: 7)]
        rook?.promoted = true
        b[Square(row: 7, col: 7)] = nil
        b[Square(row: 2, col: 4)] = nil
        b[Square(row: 1, col: 4)] = rook
        board = b
        currentPlayer = .gote
    }
    #endif
}
