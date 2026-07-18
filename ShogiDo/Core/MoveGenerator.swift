import Foundation

struct BoardMove: Hashable {
    var from: Square
    var to: Square
}

struct DropMove: Hashable {
    var kind: PieceKind
    var to: Square
}

enum MoveGenerator {
    /// Direction vectors expressed with sente's forward as row delta -1.
    /// `slides == true` means the piece may travel any distance until blocked.
    private struct DirectionSet {
        var vectors: [(row: Int, col: Int)]
        var slides: Bool
    }

    private static func directions(for piece: Piece) -> [DirectionSet] {
        let effectiveKind: PieceKind = piece.promoted ? .gold : piece.kind
        // Promoted bishop/rook keep their slide plus an extra step set, handled separately below.
        switch piece.kind {
        case .pawn where !piece.promoted:
            return [DirectionSet(vectors: [(-1, 0)], slides: false)]
        case .lance where !piece.promoted:
            return [DirectionSet(vectors: [(-1, 0)], slides: true)]
        case .knight where !piece.promoted:
            return [DirectionSet(vectors: [(-2, -1), (-2, 1)], slides: false)]
        case .silver where !piece.promoted:
            return [DirectionSet(vectors: [(-1, -1), (-1, 0), (-1, 1), (1, -1), (1, 1)], slides: false)]
        case .bishop:
            let diag = DirectionSet(vectors: [(-1, -1), (-1, 1), (1, -1), (1, 1)], slides: true)
            if piece.promoted {
                let step = DirectionSet(vectors: [(-1, 0), (1, 0), (0, -1), (0, 1)], slides: false)
                return [diag, step]
            }
            return [diag]
        case .rook:
            let straight = DirectionSet(vectors: [(-1, 0), (1, 0), (0, -1), (0, 1)], slides: true)
            if piece.promoted {
                let step = DirectionSet(vectors: [(-1, -1), (-1, 1), (1, -1), (1, 1)], slides: false)
                return [straight, step]
            }
            return [straight]
        case .king:
            return [DirectionSet(vectors: [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)], slides: false)]
        default:
            // gold, and any promoted minor piece (tokin/narigin/narikei/narikyo) — gold movement
            _ = effectiveKind
            return [DirectionSet(vectors: [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, 0)], slides: false)]
        }
    }

    /// Pseudo-legal board moves for the piece at `from` — doesn't check whether the
    /// move leaves the mover's own king in check.
    static func pseudoLegalMoves(from: Square, board: Board) -> [BoardMove] {
        guard let piece = board[from] else { return [] }
        // Direction vectors above are written in sente's frame (row -1 == forward).
        // Sente uses them as-is; gote's forward is the opposite row direction, so flip.
        let sign = piece.owner == .sente ? 1 : -1
        var moves: [BoardMove] = []

        for set in directions(for: piece) {
            for vector in set.vectors {
                var row = from.row + vector.row * sign
                var col = from.col + vector.col
                repeat {
                    let target = Square(row: row, col: col)
                    guard target.isOnBoard else { break }
                    if let occupant = board[target] {
                        if occupant.owner != piece.owner {
                            moves.append(BoardMove(from: from, to: target))
                        }
                        break
                    }
                    moves.append(BoardMove(from: from, to: target))
                    if !set.slides { break }
                    row += vector.row * sign
                    col += vector.col
                } while true
            }
        }
        return moves
    }

    static func attacksSquare(_ square: Square, by player: Player, board: Board) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                guard let piece = board.squares[row][col], piece.owner == player else { continue }
                let from = Square(row: row, col: col)
                if pseudoLegalMoves(from: from, board: board).contains(where: { $0.to == square }) {
                    return true
                }
            }
        }
        return false
    }

    /// Pseudo-legal drop targets for a hand piece — empty squares only, respecting
    /// nifu (two-pawns-on-a-file) and the no-legal-move-rank restriction. Uchifuzume
    /// (pawn-drop-checkmate) is checked separately by GameModel since it requires
    /// simulating the resulting position.
    static func pseudoLegalDrops(kind: PieceKind, player: Player, board: Board) -> [Square] {
        var targets: [Square] = []
        for row in 0..<9 {
            for col in 0..<9 {
                let square = Square(row: row, col: col)
                guard board[square] == nil else { continue }
                guard board.rankFromFar(square, for: player) >= kind.forcedRanksFromFar else { continue }
                if kind == .pawn {
                    let hasPawnOnFile = (0..<9).contains { r in
                        if let p = board.squares[r][col], p.kind == .pawn, p.owner == player, !p.promoted {
                            return true
                        }
                        return false
                    }
                    if hasPawnOnFile { continue }
                }
                targets.append(square)
            }
        }
        return targets
    }
}
