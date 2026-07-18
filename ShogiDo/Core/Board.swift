import Foundation

struct Square: Hashable, Codable {
    var row: Int  // 0...8, row 0 = gote's far back rank
    var col: Int  // 0...8

    var isOnBoard: Bool { (0...8).contains(row) && (0...8).contains(col) }
}

struct Board: Codable {
    static let size = 9

    private(set) var squares: [[Piece?]]
    private(set) var hand: [Player: [PieceKind: Int]]

    init() {
        squares = Array(repeating: Array(repeating: nil, count: Board.size), count: Board.size)
        hand = [.sente: [:], .gote: [:]]
        setupInitialPosition()
    }

    /// Constructs an arbitrary position directly — used by tests and by future
    /// features (puzzle/tsumeshogi setup) that need a non-standard starting board.
    init(rawSquares: [[Piece?]], rawHand: [Player: [PieceKind: Int]]) {
        squares = rawSquares
        hand = rawHand
    }

    subscript(_ square: Square) -> Piece? {
        get { squares[square.row][square.col] }
        set { squares[square.row][square.col] = newValue }
    }

    mutating func setupInitialPosition() {
        let backRank: [PieceKind] = [.lance, .knight, .silver, .gold, .king, .gold, .silver, .knight, .lance]

        for col in 0..<9 {
            squares[0][col] = Piece(kind: backRank[col], owner: .gote)
            squares[8][col] = Piece(kind: backRank[col], owner: .sente)
        }
        squares[1][1] = Piece(kind: .rook, owner: .gote)
        squares[1][7] = Piece(kind: .bishop, owner: .gote)
        squares[7][1] = Piece(kind: .bishop, owner: .sente)
        squares[7][7] = Piece(kind: .rook, owner: .sente)

        for col in 0..<9 {
            squares[2][col] = Piece(kind: .pawn, owner: .gote)
            squares[6][col] = Piece(kind: .pawn, owner: .sente)
        }
    }

    func handCount(_ player: Player, _ kind: PieceKind) -> Int {
        hand[player]?[kind] ?? 0
    }

    mutating func addToHand(_ player: Player, _ kind: PieceKind) {
        hand[player, default: [:]][kind, default: 0] += 1
    }

    mutating func removeFromHand(_ player: Player, _ kind: PieceKind) {
        guard let count = hand[player]?[kind], count > 0 else { return }
        hand[player]?[kind] = count - 1
    }

    func kingSquare(_ player: Player) -> Square? {
        for row in 0..<9 {
            for col in 0..<9 {
                if let piece = squares[row][col], piece.kind == .king, piece.owner == player {
                    return Square(row: row, col: col)
                }
            }
        }
        return nil
    }

    /// Distance (0-indexed) of a square from the given player's far rank —
    /// 0 is the opponent's home back rank, 8 is the player's own home back rank.
    func rankFromFar(_ square: Square, for player: Player) -> Int {
        player == .sente ? square.row : 8 - square.row
    }

    func isPromotionZone(_ square: Square, for player: Player) -> Bool {
        rankFromFar(square, for: player) < 3
    }
}
