import SwiftUI

// MARK: - Context in which the detail view was opened

enum PlayerDetailContext {
    case squad          // My team
    case transferBuy    // Player in another club
    case freeAgent      // No club
    case rival          // Rival squad / scouting
}

// MARK: - Player Detail View

struct PlayerDetailView: View {
    let player: Player
    let context: PlayerDetailContext
    @State var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showContractSheet = false
    @State private var showClubNegotiation = false

    private var isMyPlayer: Bool { context == .squad }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().background(Color.white.opacity(0.1))
            statsSection
            Divider().background(Color.white.opacity(0.1))
            infoRow
            Divider().background(Color.white.opacity(0.1))
            seasonRow
            Spacer(minLength: 0)
            actionBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea())
        .sheet(isPresented: $showContractSheet) {
            ContractNegotiationView(player: player, viewModel: viewModel)
        }
        .sheet(isPresented: $showClubNegotiation) {
            ClubNegotiationView(player: player, viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Rating badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [ratingColor.opacity(0.7), ratingColor.opacity(0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Text("\(player.overall)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(player.fullName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    positionBadge(player.position)
                    Text("Age \(player.age)")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                    if let clubId = player.clubId, let club = viewModel.clubs.first(where: { $0.id == clubId }) {
                        HStack(spacing: 2) {
                            Circle().fill(club.primarySwiftUIColor).frame(width: 7, height: 7)
                            Text(club.shortName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    } else {
                        Text("Free Agent")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                    if player.isTransferListed {
                        Text("LISTED")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(.capsule)
                    }
                }
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(white: 0.07))
    }

    // MARK: - Stats Section (GK vs Outfield)

    private var statsSection: some View {
        VStack(spacing: 6) {
            if player.position == .goalkeeper {
                gkStatsLayout
            } else {
                outfieldStatsLayout
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(white: 0.05))
    }

    // MARK: Outfield Layout
    private var outfieldStatsLayout: some View {
        VStack(spacing: 6) {
            // Category averages
            HStack(spacing: 0) {
                catBadge("ATK", player.stats.attackAvg, .orange)
                catBadge("DEF", player.stats.defenseAvg, .blue)
                catBadge("PHY", player.stats.physicalAvg, .green)
            }
            // 3-column detail grid
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 0) {
                    statGroupLabel("ATTACK", .orange)
                    statLine("Finishing", player.stats.finishing)
                    statLine("Long Shots", player.stats.longShots)
                    statLine("Dribbling", player.stats.dribbling)
                    statLine("First Touch", player.stats.firstTouch)
                    statLine("Crossing", player.stats.crossing)
                    statLine("Passing", player.stats.passing)
                }
                VStack(spacing: 0) {
                    statGroupLabel("DEFENSE", .blue)
                    statLine("Tackling", player.stats.tackling)
                    statLine("Marking", player.stats.marking)
                    statLine("Heading", player.stats.heading)
                    statLine("Def. Pos.", player.stats.defensivePositioning)
                }
                VStack(spacing: 0) {
                    statGroupLabel("PHYSICAL", .green)
                    statLine("Pace", player.stats.pace)
                    statLine("Stamina", player.stats.stamina)
                    statLine("Strength", player.stats.strength)
                    statLine("Movement", player.stats.movement)
                }
            }
        }
    }

    // MARK: GK Layout
    private var gkStatsLayout: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                catBadge("GK", player.stats.gkAvg, .purple)
                catBadge("PHY", player.stats.physicalAvg, .green)
            }
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 0) {
                    statGroupLabel("GOALKEEPING", .purple)
                    statLine("Reflexes", player.stats.reflexes)
                    statLine("Diving", player.stats.diving)
                    statLine("Handling", player.stats.handling)
                    statLine("Positioning", player.stats.gkPositioning)
                    statLine("Kicking", player.stats.kicking)
                    statLine("1-on-1", player.stats.oneOnOne)
                }
                VStack(spacing: 0) {
                    statGroupLabel("PHYSICAL", .green)
                    statLine("Pace", player.stats.pace)
                    statLine("Stamina", player.stats.stamina)
                    statLine("Strength", player.stats.strength)
                    statLine("Movement", player.stats.movement)
                }
            }
        }
    }

    // MARK: - Info Row

    private var infoRow: some View {
        HStack(spacing: 0) {
            infoCell("Morale", "\(player.morale)%", color: moraleColor(player.morale))
            infoCell("Contract", "\(player.contractYearsLeft)yr", color: player.contractYearsLeft <= 1 ? .red : .white)
            infoCell("Wage", viewModel.formatCurrency(player.wage) + "/w", color: .orange)
            infoCell("Value", viewModel.formatCurrency(player.marketValue), color: .green)
            infoCell("Status", player.isInjured ? "INJ \(player.injuryWeeksLeft)w" : "Fit", color: player.isInjured ? .red : .green)
            infoCell("Potential", "\(player.potentialPeak)", color: .cyan)
        }
        .padding(.vertical, 6)
        .background(Color(white: 0.05))
    }

    // MARK: - Season Row

    private var seasonRow: some View {
        HStack(spacing: 0) {
            seasonCell("Apps", "\(player.matchesPlayed)")
            seasonCell("Goals", "\(player.goals)")
            seasonCell("Assists", "\(player.assists)")
            seasonCell("Yellows", "\(player.yellowCards)")
            seasonCell("Reds", "\(player.redCards)")
        }
        .padding(.vertical, 6)
        .background(Color(white: 0.04))
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            switch context {
            case .squad:
                actionBtn("Contract", icon: "doc.text", color: .cyan) {
                    showContractSheet = true
                }
                actionBtn(
                    player.isTransferListed ? "Unlist" : "List",
                    icon: player.isTransferListed ? "tag.slash" : "tag",
                    color: .orange
                ) {
                    player.isTransferListed.toggle()
                }
                if viewModel.transferWindow == .open {
                    actionBtn("Sell", icon: "cart.badge.minus", color: .yellow) {
                        viewModel.sellMyPlayer(player, fee: player.marketValue)
                        dismiss()
                    }
                }
                actionBtn("Release", icon: "person.badge.minus", color: .red) {
                    viewModel.releasePlayer(player)
                    dismiss()
                }

            case .transferBuy:
                if viewModel.transferWindow == .open {
                    actionBtn("Negotiate Transfer", icon: "handshake", color: .green) {
                        showClubNegotiation = true
                    }
                } else { windowClosed }

            case .freeAgent:
                actionBtn("Offer Contract", icon: "signature", color: .green) {
                    showContractSheet = true
                }

            case .rival:
                Text("Scout mode")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(white: 0.07))
    }

    // MARK: - Reusable Pieces

    private func positionBadge(_ pos: PlayerPosition) -> some View {
        Text(pos.rawValue)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(ColorHelpers.positionColor(pos))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(ColorHelpers.positionColor(pos).opacity(0.15))
            .clipShape(.capsule)
    }

    private func catBadge(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(ColorHelpers.statColor(value))
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(color.opacity(0.7))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func statGroupLabel(_ title: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(color.opacity(0.5))
                .tracking(2)
            Spacer()
        }
        .padding(.bottom, 2)
    }

    private func statLine(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(value)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorHelpers.statColor(value))
                .frame(width: 22, alignment: .trailing)
            // Mini bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(ColorHelpers.statColor(value))
                        .frame(width: geo.size.width * CGFloat(value) / 99.0, height: 3)
                }
            }
            .frame(width: 32, height: 3)
        }
        .padding(.vertical, 1.5)
    }

    private func infoCell(_ label: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
    }

    private func seasonCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 7))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
    }

    private func actionBtn(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(color == .red ? .white : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color)
            .clipShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var windowClosed: some View {
        Text("Window closed")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.red.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.08))
            .clipShape(.rect(cornerRadius: 8))
    }

    // MARK: - Helpers

    private var ratingColor: Color { ColorHelpers.statColor(player.overall) }

    private func moraleColor(_ val: Int) -> Color {
        if val >= 80 { return .green }
        if val >= 50 { return .yellow }
        return .red
    }
}

// MARK: - Contract Negotiation View

struct ContractNegotiationView: View {
    let player: Player
    @State var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var offeredYears: Int = 3
    @State private var offeredWage: Int = 0
    @State private var result: NegotiationResult?

    enum NegotiationResult {
        case accepted, rejected
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Text("CONTRACT NEGOTIATION")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(2)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }

            // Player info
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.fullName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(player.position.rawValue) · \(player.overall) OVR · Age \(player.age)")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Current: \(viewModel.formatCurrency(player.wage))/wk")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("Contract: \(player.contractYearsLeft)yr left")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .clipShape(.rect(cornerRadius: 8))

            // Wage slider
            VStack(spacing: 4) {
                HStack {
                    Text("Offered Wage")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(viewModel.formatCurrency(offeredWage))/wk")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.orange)
                }
                Slider(
                    value: Binding(
                        get: { Double(offeredWage) },
                        set: { offeredWage = Int($0) }
                    ),
                    in: Double(wageMin)...Double(wageMax),
                    step: Double(wageStep)
                )
                .tint(.orange)
                HStack {
                    Text(viewModel.formatCurrency(wageMin))
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Text(viewModel.formatCurrency(wageMax))
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            // Years stepper
            HStack {
                Text("Contract Length")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        if offeredYears > 1 { offeredYears -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)

                    Text("\(offeredYears) years")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 70)

                    Button {
                        if offeredYears < 5 { offeredYears += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Acceptance indicator
            HStack {
                Text("Acceptance likelihood")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text(acceptanceLikelihood)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(acceptanceColor)
            }
            .padding(8)
            .background(acceptanceColor.opacity(0.08))
            .clipShape(.rect(cornerRadius: 6))

            Spacer()

            // Result
            if let result {
                HStack {
                    Image(systemName: result == .accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result == .accepted ? .green : .red)
                    Text(result == .accepted ? "Contract accepted!" : "Offer rejected.")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(result == .accepted ? .green : .red)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background((result == .accepted ? Color.green : Color.red).opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))

                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .clipShape(.rect(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    negotiate()
                } label: {
                    Text("Submit Offer")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .clipShape(.rect(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.07, green: 0.08, blue: 0.10).ignoresSafeArea())
        .onAppear {
            offeredWage = player.wage
            offeredYears = max(1, min(5, player.contractYearsLeft))
        }
    }

    // MARK: - Wage Bounds

    private var wageMin: Int { max(500, player.wage / 2) }
    private var wageMax: Int { player.wage * 3 }
    private var wageStep: Int { max(500, player.wage / 20) }

    // MARK: - Acceptance Logic

    private var acceptanceScore: Double {
        // Higher wage ratio → more likely to accept
        let wageRatio = Double(offeredWage) / Double(max(1, player.wage))
        // Longer contract slightly reduces acceptance for older players
        let yearsFactor = player.age >= 30 ? 1.0 + Double(offeredYears) * 0.05 : 1.0 - Double(5 - offeredYears) * 0.03
        // Low morale makes player want to leave / renegotiate
        let moraleFactor = player.morale < 50 ? 1.2 : 1.0
        return wageRatio * yearsFactor * moraleFactor
    }

    private var acceptanceLikelihood: String {
        let s = acceptanceScore
        if s >= 1.3 { return "Very Likely" }
        if s >= 1.0 { return "Likely" }
        if s >= 0.8 { return "Uncertain" }
        return "Unlikely"
    }

    private var acceptanceColor: Color {
        let s = acceptanceScore
        if s >= 1.3 { return .green }
        if s >= 1.0 { return .yellow }
        if s >= 0.8 { return .orange }
        return .red
    }

    private func negotiate() {
        let score = acceptanceScore
        let chance = min(0.95, max(0.05, (score - 0.5) / 1.0))
        let roll = Double.random(in: 0...1)
        if roll < chance {
            if player.clubId == nil {
                // Free agent signing
                let success = viewModel.signFreeAgent(player, wage: offeredWage)
                if success {
                    player.contractYearsLeft = offeredYears
                    result = .accepted
                } else {
                    result = .rejected
                }
            } else {
                // Contract renewal
                player.wage = offeredWage
                player.contractYearsLeft = offeredYears
                player.morale = min(100, player.morale + 10)
                viewModel.newsMessages.insert("Contract renewed: \(player.fullName) signed a \(offeredYears)-year deal at \(viewModel.formatCurrency(offeredWage))/wk.", at: 0)
                result = .accepted
            }
        } else {
            result = .rejected
        }
    }
}
