import SwiftUI

struct TacticsView: View {
    @State var viewModel: GameViewModel
    @State private var startingXI: [Player] = []
    @State private var selectedSlot: Int?

    private let formations = ["4-4-2", "4-3-3", "3-5-2", "4-2-3-1", "4-1-4-1", "3-4-3", "5-3-2", "4-5-1"]

    private var formation: String {
        viewModel.selectedClub?.formation ?? "4-4-2"
    }

    private var averageOVR: Double {
        guard !startingXI.isEmpty else { return 0 }
        return Double(startingXI.reduce(0) { $0 + $1.stats.overall }) / Double(startingXI.count)
    }

    private var benchForSelectedSlot: [Player] {
        let xiIds = Set(startingXI.map(\.id))
        let bench = viewModel.myPlayers.filter { !xiIds.contains($0.id) && !$0.isInjured }
        guard let slot = selectedSlot else {
            return bench.sorted { $0.stats.overall > $1.stats.overall }
        }
        let slots = formationSlots(formation: formation)
        guard slot < slots.count else {
            return bench.sorted { $0.stats.overall > $1.stats.overall }
        }
        let needed = slots[slot]
        return bench.sorted { a, b in
            let aExact = a.position == needed
            let bExact = b.position == needed
            if aExact != bExact { return aExact }
            let aCompat = compatiblePosition(a.position, for: needed)
            let bCompat = compatiblePosition(b.position, for: needed)
            if aCompat != bCompat { return aCompat }
            return a.stats.overall > b.stats.overall
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                formationStrip
                pitchSection
                infoStrip
                if selectedSlot != nil {
                    swapPanel
                } else {
                    instructionsPanel
                }
            }
            .animation(.spring(duration: 0.25), value: selectedSlot)
        }
        .onAppear { quickPickXI() }
        .onChange(of: viewModel.selectedClub?.formation) { _, _ in
            selectedSlot = nil
            quickPickXI()
        }
    }

    // MARK: - Header

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

            Button {
                selectedSlot = nil
                quickPickXI()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                    Text("Quick Pick")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange)
                .clipShape(.capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(white: 0.1))
    }

    // MARK: - Formation Strip

    private var formationStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(formations, id: \.self) { f in
                    Button {
                        viewModel.selectedClub?.formation = f
                    } label: {
                        Text(f)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(formation == f ? .black : .white.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(formation == f ? Color.orange : Color.white.opacity(0.06))
                            .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(white: 0.07))
    }

    // MARK: - Pitch

    private var pitchSection: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let clubColor = viewModel.selectedClub?.primarySwiftUIColor ?? .white
            let slots = formationSlots(formation: formation)
            let coords = formationPositions(formation: formation)

            ZStack {
                // Pitch background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.35, blue: 0.1))

                // Grass stripes
                VStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { i in
                        Rectangle()
                            .fill(i % 2 == 0 ? Color.white.opacity(0.025) : .clear)
                    }
                }
                .clipShape(.rect(cornerRadius: 12))

                // Field markings
                pitchMarkings(w: w, h: h)

                // Player nodes
                ForEach(Array(coords.enumerated()), id: \.offset) { idx, pos in
                    let player = idx < startingXI.count ? startingXI[idx] : nil
                    let posLabel = idx < slots.count ? slots[idx].rawValue : ""
                    playerNode(
                        player: player,
                        slotIndex: idx,
                        posLabel: posLabel,
                        clubColor: clubColor,
                        position: CGPoint(x: pos.x * w, y: pos.y * h)
                    )
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .clipShape(.rect(cornerRadius: 12))
    }

    private func playerNode(player: Player?, slotIndex: Int, posLabel: String, clubColor: Color, position: CGPoint) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) {
                selectedSlot = selectedSlot == slotIndex ? nil : slotIndex
            }
        } label: {
            VStack(spacing: 1) {
                Text(posLabel)
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))

                ZStack {
                    Circle()
                        .fill(clubColor.gradient)
                        .frame(width: 28, height: 28)

                    if selectedSlot == slotIndex {
                        Circle()
                            .strokeBorder(.orange, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    } else {
                        Circle()
                            .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                            .frame(width: 28, height: 28)
                    }

                    Text("\(player?.stats.overall ?? 0)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.4), radius: 3, y: 2)

                Text(player?.lastName ?? "---")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.6), radius: 2)
            }
        }
        .buttonStyle(.plain)
        .position(position)
    }

    private func pitchMarkings(w: CGFloat, h: CGFloat) -> some View {
        Canvas { context, _ in
            let lc = Color.white.opacity(0.18)
            let lw: CGFloat = 1
            let m: CGFloat = 12
            let fw = w - m * 2
            let fh = h - m * 2

            // Outer boundary
            context.stroke(
                Path { p in p.addRect(CGRect(x: m, y: m, width: fw, height: fh)) },
                with: .color(lc), lineWidth: lw
            )

            // Center line
            context.stroke(
                Path { p in
                    p.move(to: CGPoint(x: m, y: h / 2))
                    p.addLine(to: CGPoint(x: w - m, y: h / 2))
                },
                with: .color(lc), lineWidth: lw
            )

            // Center circle
            let cr = min(fw, fh) * 0.12
            context.stroke(
                Path { p in
                    p.addEllipse(in: CGRect(x: w / 2 - cr, y: h / 2 - cr, width: cr * 2, height: cr * 2))
                },
                with: .color(lc), lineWidth: lw
            )

            // Center dot
            context.fill(
                Path { p in p.addEllipse(in: CGRect(x: w / 2 - 2, y: h / 2 - 2, width: 4, height: 4)) },
                with: .color(lc)
            )

            // Penalty area top (attacking)
            let penW = fw * 0.52
            let penH = fh * 0.14
            context.stroke(
                Path { p in p.addRect(CGRect(x: (w - penW) / 2, y: m, width: penW, height: penH)) },
                with: .color(lc), lineWidth: lw
            )

            // Goal area top
            let goalW = fw * 0.22
            let goalH = fh * 0.05
            context.stroke(
                Path { p in p.addRect(CGRect(x: (w - goalW) / 2, y: m, width: goalW, height: goalH)) },
                with: .color(lc), lineWidth: lw
            )

            // Penalty area bottom (defensive)
            context.stroke(
                Path { p in p.addRect(CGRect(x: (w - penW) / 2, y: h - m - penH, width: penW, height: penH)) },
                with: .color(lc), lineWidth: lw
            )

            // Goal area bottom
            context.stroke(
                Path { p in p.addRect(CGRect(x: (w - goalW) / 2, y: h - m - goalH, width: goalW, height: goalH)) },
                with: .color(lc), lineWidth: lw
            )
        }
        .drawingGroup()
    }

    // MARK: - Info Strip

    private var infoStrip: some View {
        HStack(spacing: 0) {
            infoChip(icon: "chart.bar.fill", color: .orange, label: "AVG", value: String(format: "%.1f", averageOVR))
            vertDivider
            infoChip(icon: "person.3.fill", color: .green, label: "XI", value: "\(startingXI.count)/11")
            vertDivider
            infoChip(icon: "rectangle.3.group", color: .orange, label: "FRM", value: formation)
            vertDivider
            infoChip(icon: "heart.fill", color: .pink, label: "MOR",
                     value: startingXI.isEmpty ? "--" :
                        "\(startingXI.reduce(0) { $0 + $1.morale } / max(1, startingXI.count))")
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color(white: 0.08))
    }

    private func infoChip(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
    }

    private var vertDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(width: 1, height: 14)
    }

    // MARK: - Instructions Panel

    private var instructionsPanel: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                instructionRow("MENTALITY", options: ["Defensive", "Balanced", "Attacking"],
                               value: viewModel.selectedClub?.mentality ?? "Balanced") {
                    viewModel.selectedClub?.mentality = $0
                }

                instructionRow("TEMPO", options: ["Slow", "Normal", "Fast"],
                               value: viewModel.selectedClub?.tempo ?? "Normal") {
                    viewModel.selectedClub?.tempo = $0
                }
            }

            HStack(spacing: 12) {
                instructionRow("PRESSING", options: ["Low", "Medium", "High"],
                               value: viewModel.selectedClub?.pressing ?? "Medium") {
                    viewModel.selectedClub?.pressing = $0
                }

                instructionRow("WIDTH", options: ["Narrow", "Normal", "Wide"],
                               value: viewModel.selectedClub?.playWidth ?? "Normal") {
                    viewModel.selectedClub?.playWidth = $0
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.07))
    }

    private func instructionRow(_ label: String, options: [String], value: String,
                                onChange: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(0.5)

            HStack(spacing: 2) {
                ForEach(options, id: \.self) { option in
                    let selected = value == option
                    Button { onChange(option) } label: {
                        Text(shortLabel(option))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(selected ? .black : .white.opacity(0.45))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(selected ? Color.orange : Color.white.opacity(0.06))
                            .clipShape(.rect(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func shortLabel(_ full: String) -> String {
        switch full {
        case "Defensive": return "DEF"
        case "Balanced": return "BAL"
        case "Attacking": return "ATK"
        case "Slow": return "SLW"
        case "Normal": return "NRM"
        case "Fast": return "FST"
        case "Low": return "LOW"
        case "Medium": return "MED"
        case "High": return "HGH"
        case "Narrow": return "NRW"
        case "Wide": return "WDE"
        default: return String(full.prefix(3)).uppercased()
        }
    }

    // MARK: - Swap Panel

    private var swapPanel: some View {
        VStack(spacing: 6) {
            HStack {
                if let slot = selectedSlot, slot < startingXI.count {
                    let player = startingXI[slot]
                    let posSlots = formationSlots(formation: formation)
                    let posLabel = slot < posSlots.count ? posSlots[slot].rawValue : ""

                    HStack(spacing: 6) {
                        Text("REPLACE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                        Text(player.lastName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                        Text("(\(posLabel) · \(player.stats.overall))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.2)) { selectedSlot = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(benchForSelectedSlot) { player in
                        Button {
                            if let slot = selectedSlot {
                                swapPlayer(slot: slot, with: player)
                            }
                        } label: {
                            VStack(spacing: 2) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    Text("\(player.stats.overall)")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundStyle(statColor(player.stats.overall))
                                }
                                Text(player.lastName)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineLimit(1)
                                Text(player.position.rawValue)
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.cyan)
                            }
                            .frame(width: 54)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.05))
                            .clipShape(.rect(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.1))
    }

    private func swapPlayer(slot: Int, with newPlayer: Player) {
        guard slot < startingXI.count else { return }
        if let existingSlot = startingXI.firstIndex(where: { $0.id == newPlayer.id }) {
            startingXI[existingSlot] = startingXI[slot]
        }
        startingXI[slot] = newPlayer
        withAnimation(.spring(duration: 0.2)) { selectedSlot = nil }
    }

    // MARK: - Quick Pick Logic

    private func quickPickXI() {
        let slots = formationSlots(formation: formation)
        var available = viewModel.myPlayers.filter { !$0.isInjured }
        var selected: [Player] = []

        for requiredPos in slots {
            if let best = available
                .filter({ $0.position == requiredPos })
                .max(by: { $0.stats.overall < $1.stats.overall }) {
                selected.append(best)
                available.removeAll { $0.id == best.id }
            } else if let compat = available
                .filter({ compatiblePosition($0.position, for: requiredPos) })
                .max(by: { $0.stats.overall < $1.stats.overall }) {
                selected.append(compat)
                available.removeAll { $0.id == compat.id }
            } else if let fallback = available
                .max(by: { $0.stats.overall < $1.stats.overall }) {
                selected.append(fallback)
                available.removeAll { $0.id == fallback.id }
            }
        }

        startingXI = selected
    }

    private func compatiblePosition(_ playerPos: PlayerPosition, for required: PlayerPosition) -> Bool {
        switch required {
        case .goalkeeper: return playerPos == .goalkeeper
        case .centerBack: return playerPos.isDefender
        case .leftBack: return playerPos == .leftBack || playerPos == .leftWing
        case .rightBack: return playerPos == .rightBack || playerPos == .rightWing
        case .defensiveMidfield: return playerPos.isMidfielder
        case .centralMidfield: return playerPos.isMidfielder
        case .attackingMidfield: return playerPos.isMidfielder || playerPos.isForward
        case .leftWing: return playerPos == .leftWing || playerPos == .leftBack || playerPos.isForward
        case .rightWing: return playerPos == .rightWing || playerPos == .rightBack || playerPos.isForward
        case .striker: return playerPos.isForward || playerPos == .attackingMidfield
        }
    }

    // MARK: - Formation Data

    private func formationSlots(formation: String) -> [PlayerPosition] {
        switch formation {
        case "4-4-2":
            return [.goalkeeper, .leftBack, .centerBack, .centerBack, .rightBack,
                    .leftWing, .centralMidfield, .centralMidfield, .rightWing,
                    .striker, .striker]
        case "4-3-3":
            return [.goalkeeper, .leftBack, .centerBack, .centerBack, .rightBack,
                    .centralMidfield, .centralMidfield, .centralMidfield,
                    .leftWing, .striker, .rightWing]
        case "3-5-2":
            return [.goalkeeper, .centerBack, .centerBack, .centerBack,
                    .leftBack, .centralMidfield, .defensiveMidfield, .centralMidfield, .rightBack,
                    .striker, .striker]
        case "4-2-3-1":
            return [.goalkeeper, .leftBack, .centerBack, .centerBack, .rightBack,
                    .defensiveMidfield, .defensiveMidfield,
                    .leftWing, .attackingMidfield, .rightWing,
                    .striker]
        case "4-1-4-1":
            return [.goalkeeper, .leftBack, .centerBack, .centerBack, .rightBack,
                    .defensiveMidfield,
                    .leftWing, .centralMidfield, .centralMidfield, .rightWing,
                    .striker]
        case "3-4-3":
            return [.goalkeeper, .centerBack, .centerBack, .centerBack,
                    .leftBack, .centralMidfield, .centralMidfield, .rightBack,
                    .leftWing, .striker, .rightWing]
        case "5-3-2":
            return [.goalkeeper, .leftBack, .centerBack, .centerBack, .centerBack, .rightBack,
                    .centralMidfield, .centralMidfield, .centralMidfield,
                    .striker, .striker]
        case "4-5-1":
            return [.goalkeeper, .leftBack, .centerBack, .centerBack, .rightBack,
                    .leftWing, .centralMidfield, .attackingMidfield, .centralMidfield, .rightWing,
                    .striker]
        default:
            return Array(repeating: .centralMidfield, count: 11)
        }
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

    // MARK: - Helpers

    private func statColor(_ value: Int) -> Color {
        ColorHelpers.statColor(value)
    }
}
