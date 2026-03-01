import SwiftUI

struct YouthAcademyView: View {
    @State var viewModel: GameViewModel
    @State private var selectedPlayer: Player?

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            ScrollView {
                VStack(spacing: 16) {
                    facilitiesSection
                    academyRoster
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea())
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

            HStack(spacing: 6) {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.purple)
                Text("YOUTH ACADEMY")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .tracking(2)
            }

            Spacer()
            Text("\(viewModel.academyPlayers.count) prospects")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(white: 0.1))
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Facilities

    private var facilitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FACILITIES")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)

            HStack(spacing: 10) {
                ForEach(AcademyFacility.allCases, id: \.rawValue) { facility in
                    facilityCard(facility)
                }
            }
        }
    }

    private func facilityCard(_ facility: AcademyFacility) -> some View {
        let club = viewModel.selectedClub
        let level = club?.academyLevel(for: facility) ?? 1
        let cost = club?.academyUpgradeCost(facility)
        let duration = club?.academyUpgradeDuration(facility)
        let canAfford = cost.map { (club?.budget ?? 0) >= $0 } ?? false
        let isUpgrading = club?.isAcademyUpgrading ?? false
        let isThisFacility = club?.academyUpgradeInProgress == facility

        return VStack(spacing: 8) {
            HStack {
                Image(systemName: facility.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(facility.color)
                Text(facility.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("Lv.\(level)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(facility.color)
            }

            // Level bar
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(i < level ? facility.color : Color.white.opacity(0.08))
                        .frame(height: 5)
                }
            }

            // Effect description
            HStack {
                Text(effectDescription(facility, level: level))
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
            }

            // Construction in progress
            if isThisFacility, let daysLeft = club?.academyUpgradeDaysLeft, let dur = duration {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text("Building... \(daysLeft) days left")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                    GeometryReader { geo in
                        let progress = 1.0 - (Double(daysLeft) / Double(dur))
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(Color.orange)
                                .frame(width: geo.size.width * max(0.02, progress))
                        }
                    }
                    .frame(height: 5)
                }
            } else if let cost = cost {
                Button {
                    _ = club?.upgradeAcademy(facility)
                } label: {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 10))
                            Text("Upgrade: \(viewModel.formatCurrency(cost))")
                                .font(.system(size: 10, weight: .bold))
                        }
                        if let duration = duration {
                            Text("⏱ \(duration) days")
                                .font(.system(size: 8))
                                .opacity(0.7)
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(canAfford && !isUpgrading ? facility.color : Color.gray.opacity(0.3))
                    .clipShape(.capsule)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford || isUpgrading)
            } else {
                Text("MAX LEVEL")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(facility.color.opacity(0.5))
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isThisFacility ? Color.orange.opacity(0.3) : facility.color.opacity(0.12), lineWidth: 1)
        )
    }

    private func effectDescription(_ facility: AcademyFacility, level: Int) -> String {
        switch facility {
        case .scouting:
            return "\(min(3, level)) prospect\(level > 1 ? "s" : "") per cycle"
        case .coaching:
            return "Base OVR: \(25 + level * 7)"
        case .facilities:
            let mult = 0.6 + Double(level) * 0.2
            return String(format: "Growth: %.0f%%", mult * 100)
        }
    }

    // MARK: - Academy Roster

    private var academyRoster: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ACADEMY ROSTER")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)
                Spacer()
                Text("Age 14-20 | Auto-promote at 21")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if viewModel.academyPlayers.isEmpty {
                emptyState
            } else {
                // Column header
                HStack(spacing: 0) {
                    Text("Player")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Pos")
                        .frame(width: 40)
                    Text("Age")
                        .frame(width: 35)
                    Text("OVR")
                        .frame(width: 40)
                    Text("POT")
                        .frame(width: 40)
                    Text("Actions")
                        .frame(width: 120)
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.03))

                LazyVStack(spacing: 0) {
                    ForEach(viewModel.academyPlayers.sorted(by: { $0.overall > $1.overall })) { player in
                        playerRow(player)
                        Divider().overlay(Color.white.opacity(0.04))
                    }
                }
            }
        }
        .background(Color.white.opacity(0.03))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.12), lineWidth: 1)
        )
    }

    private func playerRow(_ player: Player) -> some View {
        HStack(spacing: 0) {
            // Name
            VStack(alignment: .leading, spacing: 1) {
                Text(player.fullName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(player.position.fullName)
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Position
            Text(player.position.rawValue)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(positionColor(player.position))
                .frame(width: 40)

            // Age
            Text("\(player.age)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 35)

            // OVR
            Text("\(player.overall)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(ovrColor(player.overall))
                .frame(width: 40)

            // Potential
            Text("\(player.potentialPeak)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.cyan)
                .frame(width: 40)

            // Actions
            HStack(spacing: 6) {
                Button {
                    viewModel.promoteAcademyPlayer(player)
                } label: {
                    Text("Promote")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .clipShape(.capsule)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.releaseAcademyPlayer(player)
                } label: {
                    Text("Release")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.15))
                        .clipShape(.capsule)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 120)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer().frame(height: 20)
            Image(systemName: "person.3.fill")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.06))
            Text("No prospects yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.2))
            Text("Your scouts will find new talent every ~90 days")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.12))
            Spacer().frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func positionColor(_ pos: PlayerPosition) -> Color {
        switch pos {
        case .goalkeeper: return .yellow
        case .centerBack, .leftBack, .rightBack: return .blue
        case .centralMidfield, .attackingMidfield, .defensiveMidfield: return .green
        case .leftWing, .rightWing, .striker: return .red
        }
    }

    private func ovrColor(_ ovr: Int) -> Color {
        if ovr >= 70 { return .green }
        if ovr >= 50 { return .yellow }
        return .orange
    }
}
