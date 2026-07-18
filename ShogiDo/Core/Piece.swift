import Foundation

enum Player: Codable, Hashable {
    case sente, gote

    var opponent: Player { self == .sente ? .gote : .sente }
}

enum PieceKind: String, Codable, CaseIterable, Hashable {
    case pawn, lance, knight, silver, gold, bishop, rook, king

    var canPromote: Bool { self != .gold && self != .king }

    /// Ranks (0-indexed from the mover's own back rank being farthest away) on which
    /// a piece of this kind, if left unpromoted, would have zero legal moves — used
    /// to force promotion (or forbid a drop) on those ranks. 0 = the far rank.
    var forcedRanksFromFar: Int {
        switch self {
        case .pawn, .lance: return 1
        case .knight: return 2
        default: return 0
        }
    }
}

struct Piece: Codable, Hashable {
    var kind: PieceKind
    var owner: Player
    var promoted: Bool = false

    /// Kanji glyph shown on the piece face. King uses the traditional
    /// senior/junior distinction (王 for sente, 玉 for gote).
    var glyph: String {
        switch (kind, promoted) {
        case (.pawn, false): return "歩"
        case (.pawn, true): return "と"
        case (.lance, false): return "香"
        case (.lance, true): return "杏"
        case (.knight, false): return "桂"
        case (.knight, true): return "圭"
        case (.silver, false): return "銀"
        case (.silver, true): return "全"
        case (.gold, _): return "金"
        case (.bishop, false): return "角"
        case (.bishop, true): return "馬"
        case (.rook, false): return "飛"
        case (.rook, true): return "龍"
        case (.king, _): return owner == .sente ? "王" : "玉"
        }
    }

    /// Piece reverts to its unpromoted, current-owner-flipped form when captured.
    func captured(by capturer: Player) -> Piece {
        Piece(kind: kind, owner: capturer, promoted: false)
    }
}
