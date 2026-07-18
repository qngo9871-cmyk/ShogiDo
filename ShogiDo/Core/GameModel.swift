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
}
