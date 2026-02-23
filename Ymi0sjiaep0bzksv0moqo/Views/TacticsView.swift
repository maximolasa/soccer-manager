import SwiftUI

struct TacticsView: View {
    @State var viewModel: GameViewModel

    private let formations = ["4-4-2", "4-3-3", "3-5-2", "4-2-3-1", "4-1-4-1", "3-4-3", "5-3-2", "4-5-1"]

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                HStack(spacing: 12) {
                    formationSelector
                    pitchVisualization
                }
                .padding(12)
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button {
                viewModel.currentScreen = .dashboard
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.caption)
                .foregroundStyle(.green)
            }

            Spacer()

            Text("TACTICS")
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(.white)
                .tracking(2)

            Spacer()
            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(white: 0.1))
    }

    private var formationSelector: some View {
        VStack(spacing: 8) {
            Text("FORMATION")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.orange)
                .tracking(1)

            ForEach(formations, id: \.self) { formation in
                Button {
                    viewModel.selectedClub?.formation = formation
                } label: {
                    Text(formation)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(viewModel.selectedClub?.formation == formation ? .black : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedClub?.formation == formation
                            ? Color.orange : Color.white.opacity(0.06)
                        )
                        .clipShape(.rect(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(width: 120)
    }

    private var pitchVisualization: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.1, green: 0.35, blue: 0.1), Color(red: 0.08, green: 0.28, blue: 0.08)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                pitchLines(w: w, h: h)

                let positions = formationPositions(formation: viewModel.selectedClub?.formation ?? "4-4-2")
                let squad = viewModel.myPlayers.sorted { $0.stats.overall > $1.stats.overall }

                ForEach(Array(positions.enumerated()), id: \.offset) { idx, pos in
                    let player = idx < squad.count ? squad[idx] : nil
                    VStack(spacing: 2) {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(player?.stats.overall ?? 0)")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(.black)
                            )
                        Text(player?.lastName ?? "---")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .position(x: pos.x * w, y: pos.y * h)
                }
            }
        }
        .clipShape(.rect(cornerRadius: 12))
    }

    private func pitchLines(w: CGFloat, h: CGFloat) -> some View {
        Canvas { context, size in
            let lineColor = Color.white.opacity(0.15)

            context.stroke(
                Path { p in p.addRect(CGRect(x: 20, y: 10, width: w - 40, height: h - 20)) },
                with: .color(lineColor), lineWidth: 1
            )

            context.stroke(
                Path { p in p.move(to: CGPoint(x: 20, y: h / 2)); p.addLine(to: CGPoint(x: w - 20, y: h / 2)) },
                with: .color(lineColor), lineWidth: 1
            )

            context.stroke(
                Path { p in p.addEllipse(in: CGRect(x: w / 2 - 30, y: h / 2 - 30, width: 60, height: 60)) },
                with: .color(lineColor), lineWidth: 1
            )
        }
        .drawingGroup()
    }

    private func formationPositions(formation: String) -> [CGPoint] {
        switch formation {
        case "4-4-2":
            return [
                CGPoint(x: 0.5, y: 0.9),
                CGPoint(x: 0.15, y: 0.72), CGPoint(x: 0.38, y: 0.75), CGPoint(x: 0.62, y: 0.75), CGPoint(x: 0.85, y: 0.72),
                CGPoint(x: 0.15, y: 0.5), CGPoint(x: 0.38, y: 0.5), CGPoint(x: 0.62, y: 0.5), CGPoint(x: 0.85, y: 0.5),
                CGPoint(x: 0.35, y: 0.22), CGPoint(x: 0.65, y: 0.22),
            ]
        case "4-3-3":
            return [
                CGPoint(x: 0.5, y: 0.9),
                CGPoint(x: 0.15, y: 0.72), CGPoint(x: 0.38, y: 0.75), CGPoint(x: 0.62, y: 0.75), CGPoint(x: 0.85, y: 0.72),
                CGPoint(x: 0.25, y: 0.5), CGPoint(x: 0.5, y: 0.48), CGPoint(x: 0.75, y: 0.5),
                CGPoint(x: 0.2, y: 0.22), CGPoint(x: 0.5, y: 0.18), CGPoint(x: 0.8, y: 0.22),
            ]
        case "3-5-2":
            return [
                CGPoint(x: 0.5, y: 0.9),
                CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.5, y: 0.78), CGPoint(x: 0.75, y: 0.75),
                CGPoint(x: 0.1, y: 0.5), CGPoint(x: 0.3, y: 0.52), CGPoint(x: 0.5, y: 0.48), CGPoint(x: 0.7, y: 0.52), CGPoint(x: 0.9, y: 0.5),
                CGPoint(x: 0.35, y: 0.22), CGPoint(x: 0.65, y: 0.22),
            ]
        case "4-2-3-1":
            return [
                CGPoint(x: 0.5, y: 0.9),
                CGPoint(x: 0.15, y: 0.72), CGPoint(x: 0.38, y: 0.75), CGPoint(x: 0.62, y: 0.75), CGPoint(x: 0.85, y: 0.72),
                CGPoint(x: 0.35, y: 0.55), CGPoint(x: 0.65, y: 0.55),
                CGPoint(x: 0.2, y: 0.35), CGPoint(x: 0.5, y: 0.33), CGPoint(x: 0.8, y: 0.35),
                CGPoint(x: 0.5, y: 0.15),
            ]
        case "4-1-4-1":
            return [
                CGPoint(x: 0.5, y: 0.9),
                CGPoint(x: 0.15, y: 0.72), CGPoint(x: 0.38, y: 0.75), CGPoint(x: 0.62, y: 0.75), CGPoint(x: 0.85, y: 0.72),
                CGPoint(x: 0.5, y: 0.58),
                CGPoint(x: 0.15, y: 0.4), CGPoint(x: 0.38, y: 0.38), CGPoint(x: 0.62, y: 0.38), CGPoint(x: 0.85, y: 0.4),
                CGPoint(x: 0.5, y: 0.15),
            ]
        case "3-4-3":
            return [
                CGPoint(x: 0.5, y: 0.9),
                CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.5, y: 0.78), CGPoint(x: 0.75, y: 0.75),
                CGPoint(x: 0.15, y: 0.5), CGPoint(x: 0.38, y: 0.5), CGPoint(x: 0.62, y: 0.5), CGPoint(x: 0.85, y: 0.5),
                CGPoint(x: 0.2, y: 0.22), CGPoint(x: 0.5, y: 0.18), CGPoint(x: 0.8, y: 0.22),
            ]
        case "5-3-2":
            return [
                CGPoint(x: 0.5, y: 0.9),
                CGPoint(x: 0.1, y: 0.7), CGPoint(x: 0.3, y: 0.75), CGPoint(x: 0.5, y: 0.78), CGPoint(x: 0.7, y: 0.75), CGPoint(x: 0.9, y: 0.7),
                CGPoint(x: 0.25, y: 0.5), CGPoint(x: 0.5, y: 0.48), CGPoint(x: 0.75, y: 0.5),
                CGPoint(x: 0.35, y: 0.22), CGPoint(x: 0.65, y: 0.22),
            ]
        case "4-5-1":
            return [
                CGPoint(x: 0.5, y: 0.9),
                CGPoint(x: 0.15, y: 0.72), CGPoint(x: 0.38, y: 0.75), CGPoint(x: 0.62, y: 0.75), CGPoint(x: 0.85, y: 0.72),
                CGPoint(x: 0.1, y: 0.48), CGPoint(x: 0.3, y: 0.45), CGPoint(x: 0.5, y: 0.42), CGPoint(x: 0.7, y: 0.45), CGPoint(x: 0.9, y: 0.48),
                CGPoint(x: 0.5, y: 0.15),
            ]
        default:
            return []
        }
    }
}
