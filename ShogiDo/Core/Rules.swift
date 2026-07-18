import Foundation

/// Pure, stateless legality logic shared by GameModel (UI-facing) and AIPlayer
/// (search) so both operate on the exact same rules.
enum Rules {
    static func isKingInCheck(_ player: Player, board: Board) -> Bool {
        guard let kingSquare = board.kingSquare(player) else { return false }
        return MoveGenerator.attacksSquare(kingSquare, by: player.opponent, board: board)
    }

    static func wouldLeaveOwnKingInCheck(_ move: BoardMove, player: Player, board: Board) -> Bool {
        var trial = board
        let moving = trial[move.from]
        trial[move.from] = nil
        trial[move.to] = moving
        return isKingInCheck(player, board: trial)
    }

    static func legalBoardMoves(from square: Square, board: Board) -> [BoardMove] {
        guard let piece = board[square] else { return [] }
        return MoveGenerator.pseudoLegalMoves(from: square, board: board).filter {
            !wouldLeaveOwnKingInCheck($0, player: piece.owner, board: board)
        }
    }

    static func legalBoardMoves(board: Board, player: Player) -> [BoardMove] {
        var moves: [BoardMove] = []
        for row in 0..<9 {
            for col in 0..<9 {
                guard let piece = board.squares[row][col], piece.owner == player else { continue }
                moves.append(contentsOf: legalBoardMoves(from: Square(row: row, col: col), board: board))
            }
        }
        return moves
    }

    static func isUchifuzume(dropSquare: Square, board: Board, mover: Player) -> Bool {
        guard isKingInCheck(mover.opponent, board: board) else { return false }
        return !hasAnyLegalMove(board: board, player: mover.opponent)
    }

    static func legalDrops(kind: PieceKind, board: Board, player: Player) -> [Square] {
        guard board.handCount(player, kind) > 0 else { return [] }
        return MoveGenerator.pseudoLegalDrops(kind: kind, player: player, board: board).filter { square in
            var trial = board
            trial[square] = Piece(kind: kind, owner: player)
            if isKingInCheck(player, board: trial) { return false }
            if kind == .pawn && isUchifuzume(dropSquare: square, board: trial, mover: player) { return false }
            return true
        }
    }

    static func legalDrops(board: Board, player: Player) -> [DropMove] {
        var drops: [DropMove] = []
        for kind in PieceKind.allCases where kind != .king {
            for square in legalDrops(kind: kind, board: board, player: player) {
                drops.append(DropMove(kind: kind, to: square))
            }
        }
        return drops
    }

    static func hasAnyLegalMove(board: Board, player: Player) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                guard let piece = board.squares[row][col], piece.owner == player else { continue }
                if !legalBoardMoves(from: Square(row: row, col: col), board: board).isEmpty { return true }
            }
        }
        for kind in PieceKind.allCases where kind != .king {
            if !legalDrops(kind: kind, board: board, player: player).isEmpty { return true }
        }
        return false
    }

    static func canPromote(_ move: BoardMove, board: Board) -> Bool {
        guard let piece = board[move.from], piece.kind.canPromote, !piece.promoted else { return false }
        return board.isPromotionZone(move.from, for: piece.owner) || board.isPromotionZone(move.to, for: piece.owner)
    }

    static func mustPromote(_ move: BoardMove, board: Board) -> Bool {
        guard let piece = board[move.from], piece.kind.canPromote else { return false }
        return board.rankFromFar(move.to, for: piece.owner) < piece.kind.forcedRanksFromFar
    }

    /// Applies a board move to a board value, returning the resulting board.
    /// `promote` is ignored (treated false) if promotion isn't legal for this move.
    static func applying(_ move: BoardMove, promote: Bool, board: Board) -> Board {
        var next = board
        guard var piece = next[move.from] else { return next }
        let capturing = next[move.to]
        if canPromote(move, board: board) {
            piece.promoted = piece.promoted || promote || mustPromote(move, board: board)
        }
        next[move.from] = nil
        next[move.to] = piece
        if let capturing {
            next.addToHand(piece.owner, capturing.captured(by: piece.owner).kind)
        }
        return next
    }

    static func applying(_ drop: DropMove, player: Player, board: Board) -> Board {
        var next = board
        next[drop.to] = Piece(kind: drop.kind, owner: player)
        next.removeFromHand(player, drop.kind)
        return next
    }
}
