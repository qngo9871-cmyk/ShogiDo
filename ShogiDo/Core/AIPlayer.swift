import Foundation

enum AIDifficulty: String, CaseIterable {
    case easy, normal, hard

    var searchDepth: Int {
        switch self {
        case .easy: return 2
        case .normal: return 3
        case .hard: return 4
        }
    }

    /// Chance [0,1] the AI picks a random legal move instead of the search's best,
    /// to keep lower difficulties beatable.
    var blunderChance: Double {
        switch self {
        case .easy: return 0.35
        case .normal: return 0.12
        case .hard: return 0
        }
    }

    var requiresPro: Bool { self == .hard }
}

enum AIMove {
    case board(BoardMove, promote: Bool)
    case drop(DropMove)
}

enum AIPlayer {
    private static func pieceValue(_ kind: PieceKind, promoted: Bool) -> Int {
        switch (kind, promoted) {
        case (.pawn, false): return 100
        case (.pawn, true): return 500
        case (.lance, false): return 300
        case (.lance, true): return 550
        case (.knight, false): return 350
        case (.knight, true): return 550
        case (.silver, false): return 500
        case (.silver, true): return 550
        case (.gold, _): return 550
        case (.bishop, false): return 800
        case (.bishop, true): return 950
        case (.rook, false): return 1000
        case (.rook, true): return 1150
        case (.king, _): return 0
        }
    }

    private static func evaluate(board: Board, for player: Player) -> Int {
        var score = 0
        for row in 0..<9 {
            for col in 0..<9 {
                guard let piece = board.squares[row][col] else { continue }
                let value = pieceValue(piece.kind, promoted: piece.promoted)
                // Slight bonus for advancing non-gold/king pieces forward, to discourage passivity.
                let advancement = 8 - board.rankFromFar(Square(row: row, col: col), for: piece.owner)
                let positional = (piece.kind == .pawn || piece.kind == .silver) ? advancement : 0
                score += (piece.owner == player ? 1 : -1) * (value + positional)
            }
        }
        for kind in PieceKind.allCases where kind != .king {
            score += board.handCount(player, kind) * pieceValue(kind, promoted: false)
            score -= board.handCount(player.opponent, kind) * pieceValue(kind, promoted: false)
        }
        return score
    }

    private struct SearchMove {
        var boardMove: BoardMove?
        var promote: Bool
        var drop: DropMove?
    }

    private static func candidateMoves(board: Board, player: Player) -> [SearchMove] {
        var moves: [SearchMove] = []
        for move in Rules.legalBoardMoves(board: board, player: player) {
            if Rules.canPromote(move, board: board) {
                moves.append(SearchMove(boardMove: move, promote: true, drop: nil))
                if !Rules.mustPromote(move, board: board) {
                    moves.append(SearchMove(boardMove: move, promote: false, drop: nil))
                }
            } else {
                moves.append(SearchMove(boardMove: move, promote: false, drop: nil))
            }
        }
        for drop in Rules.legalDrops(board: board, player: player) {
            moves.append(SearchMove(boardMove: nil, promote: false, drop: drop))
        }
        // Captures first — cheap move ordering that speeds up alpha-beta a lot.
        return moves.sorted { a, b in
            let aCaptures = a.boardMove.flatMap { board[$0.to] } != nil
            let bCaptures = b.boardMove.flatMap { board[$0.to] } != nil
            return aCaptures && !bCaptures
        }
    }

    private static func resultingBoard(_ move: SearchMove, player: Player, board: Board) -> Board {
        if let boardMove = move.boardMove {
            return Rules.applying(boardMove, promote: move.promote, board: board)
        } else if let drop = move.drop {
            return Rules.applying(drop, player: player, board: board)
        }
        return board
    }

    private static func search(board: Board, player: Player, rootPlayer: Player, depth: Int, alpha: Int, beta: Int) -> Int {
        if depth == 0 || !Rules.hasAnyLegalMove(board: board, player: player) {
            if !Rules.hasAnyLegalMove(board: board, player: player) {
                // Checkmate (or the rare no-legal-move loss) — huge score for the mover's opponent.
                return player == rootPlayer ? -100_000 - depth : 100_000 + depth
            }
            return evaluate(board: board, for: rootPlayer)
        }

        var alpha = alpha
        var beta = beta
        let maximizing = player == rootPlayer
        var best = maximizing ? Int.min : Int.max

        for move in candidateMoves(board: board, player: player) {
            let next = resultingBoard(move, player: player, board: board)
            let value = search(board: next, player: player.opponent, rootPlayer: rootPlayer, depth: depth - 1, alpha: alpha, beta: beta)
            if maximizing {
                best = max(best, value)
                alpha = max(alpha, value)
            } else {
                best = min(best, value)
                beta = min(beta, value)
            }
            if beta <= alpha { break }
        }
        return best
    }

    static func bestMove(board: Board, player: Player, difficulty: AIDifficulty) -> AIMove? {
        let moves = candidateMoves(board: board, player: player)
        guard !moves.isEmpty else { return nil }

        if Double.random(in: 0..<1) < difficulty.blunderChance {
            return toAIMove(moves.randomElement()!)
        }

        var best: SearchMove?
        var bestScore = Int.min
        for move in moves {
            let next = resultingBoard(move, player: player, board: board)
            let score = search(board: next, player: player.opponent, rootPlayer: player, depth: difficulty.searchDepth - 1, alpha: Int.min + 1, beta: Int.max - 1)
            if score > bestScore {
                bestScore = score
                best = move
            }
        }
        return best.map(toAIMove)
    }

    private static func toAIMove(_ move: SearchMove) -> AIMove {
        if let boardMove = move.boardMove {
            return .board(boardMove, promote: move.promote)
        }
        return .drop(move.drop!)
    }
}
