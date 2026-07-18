import SwiftUI

struct PieceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let shoulderY = rect.minY + h * 0.22
        let rightShoulder = CGPoint(x: rect.maxX, y: shoulderY)
        let leftShoulder = CGPoint(x: rect.minX, y: shoulderY)
        let rightBase = CGPoint(x: rect.maxX - w * 0.06, y: rect.maxY)
        let leftBase = CGPoint(x: rect.minX + w * 0.06, y: rect.maxY)

        path.move(to: top)
        path.addLine(to: rightShoulder)
        path.addLine(to: rightBase)
        path.addLine(to: leftBase)
        path.addLine(to: leftShoulder)
        path.closeSubpath()
        return path
    }
}

struct PieceView: View {
    let piece: Piece

    var body: some View {
        ZStack {
            PieceShape()
                .fill(Color(red: 0.96, green: 0.91, blue: 0.78))
            PieceShape()
                .stroke(Color(red: 0.35, green: 0.22, blue: 0.1), lineWidth: 1)
            Text(piece.glyph)
                .font(.system(size: 20, weight: piece.promoted ? .bold : .semibold))
                .foregroundStyle(piece.promoted ? Color.red : Color(red: 0.15, green: 0.1, blue: 0.05))
        }
        .rotationEffect(.degrees(piece.owner == .gote ? 180 : 0))
    }
}
