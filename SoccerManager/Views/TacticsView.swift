import SwiftUI

struct TacticsView: View {
    @State var viewModel: GameViewModel
    @State private var startingXI: [Player] = []
    @State private var selectedSlot: Int?
    @State private var selectedTab: TacticsTab = .formations

    private let formations = ["4-4-2", "4-3-3", "3-5-2", "4-2-3-1", "4-1-4-1", "3-4-3", "5-3-2", "4-5-1"]

    enum TacticsTab: String, CaseIterable {
        case formations = "Formations"
        case tactics = "Tactics"
    }

    private var formation: String {
        viewModel.selectedClub?.formation ?? "4-4-2"
    }

    private var averageOVR: Double {
        guard !startingXI.isEmpty else { return 0 }
        return Double(startingXI.reduce(0) { $0 + $1.stats.overall }) / Double(startingXI.count)
    }

    private var benchPlayers: [Player] {
        let xiIds = Set(startingXI.map(\.id))
        return viewModel.myPlayers
            .filter { !xiIds.contains($0.id) && !$0.isInjured }
            .sorted { a, b in
                let orderA = positionSortOrder(a.position)
                let orderB = positionSortOrder(b.position)
                if orderA != orderB { return orderA < orderB }
                return a.stats.overall > b.stats.overall
            }
    }

    private func positionSortOrder(_ pos: PlayerPosition) -> Int {
        switch pos {
        case .goalkeeper: return 0
        case .centerBack: return 1
        case .leftBack: return 2
        case .rightBack: return 3
        case .defensiveMidfield: return 4
        case .centralMidfield: return 5
        case .attackingMidfield: return 6
        case .leftWing: return 7
        case .rightWing: return 8
        case .striker: return 9
        }
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
        VStack(spacing: 0) {
            // Single unified header
            unifiedHeader

            // Main content: tactics | pitch | substitutes
            mainContent
        }
        .animation(.spring(duration: 0.25), value: selectedSlot)
        .background(Color(red: 0.06, green: 0.08, blue: 0.12), ignoresSafeAreaEdges: .all)
        .onAppear { quickPickXI() }
        .onChange(of: viewModel.selectedClub?.formation) { _, _ in
            selectedSlot = nil
            quickPickXI()
        }
    }

    // MARK: - Unified Header

    private var unifiedHeader: some View {
        HStack(spacing: 10) {
            // Back
            Button {
                viewModel.currentScreen = .dashboard
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)

            // Club shield + name
            HStack(spacing: 6) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(viewModel.selectedClub?.primarySwiftUIColor ?? .blue)
                Text(viewModel.selectedClub?.name ?? "Club")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Divider
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1, height: 18)

            // Tabs
            HStack(spacing: 2) {
                ForEach(TacticsTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedTab == tab
                                    ? Color.white.opacity(0.12)
                                    : Color.clear
                            )
                            .clipShape(.rect(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Next match info
            if let match = viewModel.nextMatch {
                let opponent = opponentName(for: match)
                let isHome = match.homeClubId == viewModel.selectedClubId
                HStack(spacing: 4) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Next: vs \(opponent) (\(isHome ? "H" : "A"))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer().frame(width: 8)

            // Auto Pick
            Button {
                selectedSlot = nil
                quickPickXI()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                    Text("Auto Pick")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange)
                .clipShape(.capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color(white: 0.1))
        .fixedSize(horizontal: false, vertical: true)
    }

    private func opponentName(for match: Match) -> String {
        let oppId = match.homeClubId == viewModel.selectedClubId ? match.awayClubId : match.homeClubId
        return viewModel.clubs.first(where: { $0.id == oppId })?.name ?? "Opponent"
    }

    // MARK: - Main Content

    private var mainContent: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Left: Instructions / Settings panel
                leftPanel
                    .frame(width: geo.size.width * 0.18)

                // Center: Football pitch
                pitchSection
                    .frame(width: geo.size.width * 0.58)

                // Right: Substitutes
                rightPanel
                    .frame(width: geo.size.width * 0.24)
            }
        }
    }

    // MARK: - Left Panel (Tactics Settings)

    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Stats summary at top (always visible)
            VStack(spacing: 6) {
                statRow(icon: "chart.bar.fill", label: "AVG OVR", value: String(format: "%.0f", averageOVR), color: .orange)
                statRow(icon: "person.3.fill", label: "Players", value: "\(startingXI.count)/11", color: .green)
                statRow(icon: "heart.fill", label: "Morale",
                        value: startingXI.isEmpty ? "--" :
                            "\(startingXI.reduce(0) { $0 + $1.morale } / max(1, startingXI.count))",
                        color: .pink)
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider().overlay(Color.white.opacity(0.1)).padding(.horizontal, 6)

            // Tab content
            if selectedTab == .formations {
                formationsTabContent
            } else {
                tacticsTabContent
            }
        }
        .background(Color(red: 0.06, green: 0.07, blue: 0.14).opacity(0.9))
    }

    // MARK: - Formations Tab

    private var formationsTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 5) {
                ForEach(formations, id: \.self) { f in
                    Button {
                        viewModel.selectedClub?.formation = f
                    } label: {
                        Text(f)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(formation == f ? .black : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(formation == f ? Color.orange : Color.white.opacity(0.06))
                            .clipShape(.rect(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Tactics Tab

    private var tacticsTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                tacticsOptionRow("MENTALITY",
                                 icon: "flame.fill",
                                 options: ["Defensive", "Balanced", "Attacking"],
                                 shorts: ["DEF", "BAL", "ATK"],
                                 value: viewModel.selectedClub?.mentality ?? "Balanced") {
                    viewModel.selectedClub?.mentality = $0
                }

                tacticsOptionRow("TEMPO",
                                 icon: "gauge.open.with.lines.needle.33percent",
                                 options: ["Slow", "Normal", "Fast"],
                                 shorts: ["SLW", "NRM", "FST"],
                                 value: viewModel.selectedClub?.tempo ?? "Normal") {
                    viewModel.selectedClub?.tempo = $0
                }

                tacticsOptionRow("PRESSING",
                                 icon: "arrow.up.forward.circle.fill",
                                 options: ["Low", "Medium", "High"],
                                 shorts: ["LOW", "MED", "HGH"],
                                 value: viewModel.selectedClub?.pressing ?? "Medium") {
                    viewModel.selectedClub?.pressing = $0
                }

                tacticsOptionRow("WIDTH",
                                 icon: "arrow.left.and.right",
                                 options: ["Narrow", "Normal", "Wide"],
                                 shorts: ["NRW", "NRM", "WDE"],
                                 value: viewModel.selectedClub?.playWidth ?? "Normal") {
                    viewModel.selectedClub?.playWidth = $0
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
    }

    private func tacticsOptionRow(_ label: String, icon: String, options: [String],
                                   shorts: [String], value: String,
                                   onChange: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 7))
                    .foregroundStyle(.orange)
                Text(label)
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(0.5)
            }

            HStack(spacing: 3) {
                ForEach(Array(zip(shorts.indices, shorts)), id: \.0) { idx, short in
                    let full = idx < options.count ? options[idx] : short
                    let isSelected = value == full
                    Button { onChange(full) } label: {
                        Text(short)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(isSelected ? .black : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(isSelected ? Color.orange : Color.white.opacity(0.06))
                            .clipShape(.rect(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 7))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Pitch Section

    private var pitchSection: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let clubColor = viewModel.selectedClub?.primarySwiftUIColor ?? .white
            let slots = formationSlots(formation: formation)
            let coords = formationPositions(formation: formation)

            ZStack {
                // Pitch background
                pitchBackground(in: geo.size)

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
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .clipShape(.rect(cornerRadius: 10))
    }

    private func pitchBackground(in size: CGSize) -> some View {
        ZStack {
            // Base field color
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.28, blue: 0.15),
                                 Color(red: 0.05, green: 0.2, blue: 0.1),
                                 Color(red: 0.08, green: 0.28, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Grass stripes
            VStack(spacing: 0) {
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)
                        .frame(height: size.height / 12)
                }
            }
            .clipShape(.rect(cornerRadius: 10))

            // Field markings
            pitchMarkings(w: size.width, h: size.height)
        }
    }

    private func playerNode(player: Player?, slotIndex: Int, posLabel: String,
                             clubColor: Color, position: CGPoint) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) {
                selectedSlot = selectedSlot == slotIndex ? nil : slotIndex
            }
        } label: {
            VStack(spacing: 2) {
                // Position label above
                Text(posLabel)
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(posLabel == "GK" ? Color(red: 0.2, green: 0.6, blue: 0.3) : clubColor.opacity(0.85))
                    )

                // Player circle with rating inside
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [clubColor, clubColor.opacity(0.7)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 36, height: 36)

                    if selectedSlot == slotIndex {
                        Circle()
                            .strokeBorder(Color.yellow, lineWidth: 2.5)
                            .frame(width: 40, height: 40)
                    } else {
                        Circle()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 36, height: 36)
                    }

                    Text("\(player?.stats.overall ?? 0)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: selectedSlot == slotIndex ? .yellow.opacity(0.4) : .black.opacity(0.5), radius: 4, y: 2)

                // Player name below
                Text(player?.lastName ?? "---")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
        }
        .buttonStyle(.plain)
        .position(position)
    }

    private func pitchMarkings(w: CGFloat, h: CGFloat) -> some View {
        Canvas { context, _ in
            let lc = Color.white.opacity(0.2)
            let lw: CGFloat = 1
            let m: CGFloat = 10
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
            let cr = min(fw, fh) * 0.11
            context.stroke(
                Path { p in
                    p.addEllipse(in: CGRect(x: w / 2 - cr, y: h / 2 - cr, width: cr * 2, height: cr * 2))
                },
                with: .color(lc), lineWidth: lw
            )

            // Center dot
            context.fill(
                Path { p in p.addEllipse(in: CGRect(x: w / 2 - 3, y: h / 2 - 3, width: 6, height: 6)) },
                with: .color(lc)
            )

            // Penalty area top (attacking)
            let penW = fw * 0.52
            let penH = fh * 0.15
            context.stroke(
                Path { p in p.addRect(CGRect(x: (w - penW) / 2, y: m, width: penW, height: penH)) },
                with: .color(lc), lineWidth: lw
            )

            // 6-yard box top
            let goalW = fw * 0.24
            let goalH = fh * 0.06
            context.stroke(
                Path { p in p.addRect(CGRect(x: (w - goalW) / 2, y: m, width: goalW, height: goalH)) },
                with: .color(lc), lineWidth: lw
            )

            // Penalty area bottom (defensive)
            context.stroke(
                Path { p in p.addRect(CGRect(x: (w - penW) / 2, y: h - m - penH, width: penW, height: penH)) },
                with: .color(lc), lineWidth: lw
            )

            // 6-yard box bottom
            context.stroke(
                Path { p in p.addRect(CGRect(x: (w - goalW) / 2, y: h - m - goalH, width: goalW, height: goalH)) },
                with: .color(lc), lineWidth: lw
            )

            // Penalty arcs
            let arcRadius = fh * 0.06
            // Top arc
            context.stroke(
                Path { p in
                    p.addArc(center: CGPoint(x: w / 2, y: m + penH),
                             radius: arcRadius, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
                },
                with: .color(lc), lineWidth: lw
            )
            // Bottom arc
            context.stroke(
                Path { p in
                    p.addArc(center: CGPoint(x: w / 2, y: h - m - penH),
                             radius: arcRadius, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                },
                with: .color(lc), lineWidth: lw
            )
        }
        .drawingGroup()
    }

    // MARK: - Right Panel (Substitutes)

    private var rightPanel: some View {
        VStack(spacing: 0) {
            Text("SUBSTITUTES")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(1)
                .padding(.top, 10)
                .padding(.bottom, 8)

            if selectedSlot != nil {
                // Show sorted bench for swapping
                selectedSlotHeader
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(benchForSelectedSlot) { player in
                            substituteCard(player, canSwap: true)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 10)
                }
            } else {
                // Just show bench
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(benchPlayers.prefix(9)) { player in
                            substituteCard(player, canSwap: false)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 10)
                }
            }
        }
        .background(Color(red: 0.06, green: 0.07, blue: 0.14).opacity(0.9))
    }

    private var selectedSlotHeader: some View {
        Group {
            if let slot = selectedSlot, slot < startingXI.count {
                let player = startingXI[slot]
                let posSlots = formationSlots(formation: formation)
                let posLabel = slot < posSlots.count ? posSlots[slot].rawValue : ""

                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text("SWAP")
                            .font(.system(size: 7, weight: .black))
                            .foregroundStyle(.orange)
                        Text(player.lastName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text("\(posLabel) · \(player.stats.overall)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .clipShape(.rect(cornerRadius: 5))
                .onTapGesture {
                    withAnimation(.spring(duration: 0.2)) { selectedSlot = nil }
                }
            }
        }
    }

    private func substituteCard(_ player: Player, canSwap: Bool) -> some View {
        Button {
            if canSwap, let slot = selectedSlot {
                swapPlayer(slot: slot, with: player)
            }
        } label: {
            HStack(spacing: 8) {
                // Position badge
                ZStack {
                    Circle()
                        .fill(positionBadgeColor(player.position))
                        .frame(width: 26, height: 26)

                    Text(player.position.rawValue)
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundStyle(.white)
                }

                // Name + Age
                VStack(alignment: .leading, spacing: 1) {
                    Text(player.lastName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("Age \(player.age)")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                // Rating
                Text("\(player.stats.overall)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(statColor(player.stats.overall))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(canSwap ? 0.06 : 0.03))
            )
        }
        .buttonStyle(.plain)
    }



    // MARK: - Swap Logic

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

    private func ratingBarColor(_ rating: Int) -> Color {
        if rating >= 75 { return Color(red: 0.18, green: 0.8, blue: 0.44) }
        if rating >= 60 { return Color(red: 0.95, green: 0.77, blue: 0.06) }
        return Color(red: 0.91, green: 0.3, blue: 0.24)
    }

    private func positionBadgeColor(_ pos: PlayerPosition) -> Color {
        if pos == .goalkeeper { return Color(red: 0.2, green: 0.6, blue: 0.3) }
        if pos.isDefender { return Color(red: 0.2, green: 0.35, blue: 0.65) }
        if pos.isMidfielder { return Color(red: 0.5, green: 0.18, blue: 0.35) }
        return Color(red: 0.75, green: 0.2, blue: 0.2) // Forwards
    }
}
