import Foundation

func assertTrue(_ condition: Bool, _ message: String, file: StaticString = #file, line: UInt = #line) {
    if !condition {
        print("FAIL (\(file):\(line)): \(message)")
        exitCode = 1
    } else {
        print("ok — \(message)")
    }
}

var exitCode: Int32 = 0

// 1. Initial position: knights can't move (blocked by own pawns), silvers have 2 moves each,
//    total legal moves for sente at the very start should be non-zero and plausible.
do {
    let board = Board()
    let moves = Rules.legalBoardMoves(board: board, player: .sente)
    print("Initial sente legal move count: \(moves.count)")
    assertTrue(moves.count > 0, "sente has legal moves at game start")
    assertTrue(!moves.contains { board[$0.from]?.kind == .knight }, "knights have no legal moves at game start (blocked by own pawns)")
}

// 2. Nifu: two unpromoted pawns of the same player can't sit on the same file —
//    a drop onto a file that already has one of your own pawns must be illegal.
do {
    var board = Board()
    board.addToHand(.sente, .pawn)
    // Sente already has a pawn on every file at the start (row 6). Try dropping onto col 3, row 5 (empty, same file as existing pawn).
    let drops = Rules.legalDrops(kind: .pawn, board: board, player: .sente)
    assertTrue(!drops.contains(Square(row: 5, col: 3)), "nifu blocks a pawn drop on a file that already has your own pawn")
}

// 3. Forced promotion: a pawn moving to the last rank must promote (dropping a pawn there is already illegal; verify move-side rule).
do {
    var board = Board()
    // Clear the board, place a lone sente pawn one step from gote's back rank plus both kings (required for check logic).
    var empty = Array(repeating: Array(repeating: Optional<Piece>.none, count: 9), count: 9)
    empty[1][4] = Piece(kind: .pawn, owner: .sente)
    empty[0][0] = Piece(kind: .king, owner: .gote)
    empty[8][8] = Piece(kind: .king, owner: .sente)
    board = Board(rawSquares: empty, rawHand: [.sente: [:], .gote: [:]])
    let move = BoardMove(from: Square(row: 1, col: 4), to: Square(row: 0, col: 4))
    assertTrue(Rules.mustPromote(move, board: board), "pawn reaching the last rank must promote")
}

// 4. Uchifuzume: dropping a pawn to deliver checkmate is illegal. Classic textbook
//    position: gote king boxed in a corner by its own lance + knight (neither of which
//    can recapture on the drop square), sente pawn drop is itself defended by a sente
//    gold so the king can't safely capture its way out either.
do {
    var empty = Array(repeating: Array(repeating: Optional<Piece>.none, count: 9), count: 9)
    empty[0][0] = Piece(kind: .king, owner: .gote)
    empty[0][1] = Piece(kind: .lance, owner: .gote)    // seals (0,1); lance can't reach (1,0)
    empty[1][1] = Piece(kind: .knight, owner: .gote)   // seals (1,1); knight can't reach (1,0)
    empty[2][0] = Piece(kind: .gold, owner: .sente)    // defends the (1,0) drop square
    empty[8][8] = Piece(kind: .king, owner: .sente)
    let board = Board(rawSquares: empty, rawHand: [.sente: [.pawn: 1], .gote: [:]])
    let drops = Rules.legalDrops(kind: .pawn, board: board, player: .sente)
    assertTrue(!drops.contains(Square(row: 1, col: 0)), "uchifuzume blocks a pawn drop that delivers checkmate")

    // Sanity counter-check: the same drop WITHOUT the defending gold is check but not
    // checkmate (king can safely capture the undefended pawn) — must be legal.
    var undefended = empty
    undefended[2][0] = nil
    let boardUndefended = Board(rawSquares: undefended, rawHand: [.sente: [.pawn: 1], .gote: [:]])
    let dropsUndefended = Rules.legalDrops(kind: .pawn, board: boardUndefended, player: .sente)
    assertTrue(dropsUndefended.contains(Square(row: 1, col: 0)), "a pawn drop giving check (but not mate) is legal — king can capture the undefended pawn")
}

// 5. AI sanity: it must return a move in the starting position and not crash across a short search.
do {
    let board = Board()
    let move = AIPlayer.bestMove(board: board, player: .sente, difficulty: .easy)
    assertTrue(move != nil, "AI returns a move from the starting position")
}

// 6. Full AI-vs-AI playthrough: no crashes, no illegal-state loops, terminates or runs a long stretch cleanly.
do {
    let model = GameModel()
    var plies = 0
    let maxPlies = 60
    while model.outcome == .ongoing && plies < maxPlies {
        let mover = model.currentPlayer
        guard let move = AIPlayer.bestMove(board: model.board, player: mover, difficulty: .easy) else {
            assertTrue(false, "AI found no move but game claims not-over at ply \(plies)")
            break
        }
        switch move {
        case .board(let boardMove, let promote):
            model.makeBoardMove(boardMove, promote: promote)
        case .drop(let drop):
            model.makeDrop(drop)
        }
        plies += 1
    }
    print("AI-vs-AI ran \(plies) plies, outcome: \(model.outcome)")
    assertTrue(plies > 0, "AI-vs-AI game progressed at least one ply without crashing")
}

exit(exitCode)
