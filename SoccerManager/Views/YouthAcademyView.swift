import SwiftUI

struct YouthAcademyView: View {
    @State var viewModel: GameViewModel

    var youthPlayers: [Player] {
        viewModel.myPlayers.filter { $0.age <= 21 }.sorted { $0.stats.overall > $1.stats.overall }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            HStack(spacing: 12) {
                academyUpgrades
                youthPlayersPanel
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea())
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

            Text("YOUTH ACADEMY")
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(.white)
                .tracking(2)

            Spacer()
            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .padding(.top, 6)
        .background(Color(white: 0.1))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var academyUpgrades: some View {
        VStack(spacing: 10) {
            if let club = viewModel.selectedClub {
                upgradeCard(
                    title: "Recruiting",
                    icon: "person.badge.plus",
                    level: club.academyRecruitingLevel,
                    description: "\(club.playersPerYear) players/year",
                    cost: club.academyRecruitingLevel * 2_000_000,
                    color: .green
                ) {
                    _ = club.upgradeAcademy(.recruiting)
                }

                upgradeCard(
                    title: "Quality",
                    icon: "star.fill",
                    level: club.academyQualityLevel,
                    description: "Base quality: \(club.academyBaseQuality)",
                    cost: club.academyQualityLevel * 3_000_000,
                    color: .yellow
                ) {
                    _ = club.upgradeAcademy(.quality)
                }

                upgradeCard(
                    title: "Training",
                    icon: "figure.run",
                    level: club.academyTrainingLevel,
                    description: String(format: "Boost: %.0f%%", (club.trainingBoost - 1) * 100),
                    cost: club.academyTrainingLevel * 2_500_000,
                    color: .cyan
                ) {
                    _ = club.upgradeAcademy(.training)
                }
            }

            Spacer()
        }
        .frame(width: 200)
    }

    private var youthPlayersPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("YOUTH PLAYERS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.purple)
                    .tracking(1)
                Spacer()
                Text("\(youthPlayers.count) players (U21)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.03))

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(youthPlayers) { player in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.fullName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                                Text("\(player.position.fullName) | Age \(player.age)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.4))
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                miniStatBadge("OVR", player.stats.overall, .green)
                                miniStatBadge("POT", player.potentialPeak, .cyan)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                    }
                }
            }
        }
        .background(Color.white.opacity(0.04))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func upgradeCard(title: String, icon: String, level: Int, description: String, cost: Int, color: Color, action: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("Lv.\(level)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }

            HStack {
                levelBar(level: level, maxLevel: 10, color: color)
            }

            Text(description)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))

            if level < 10 {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 11))
                        Text("Upgrade: \(viewModel.formatCurrency(cost))")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(color)
                    .clipShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private func levelBar(level: Int, maxLevel: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<maxLevel, id: \.self) { i in
                Capsule()
                    .fill(i < level ? color : Color.white.opacity(0.1))
                    .frame(height: 4)
            }
        }
    }

    private func miniStatBadge(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(.rect(cornerRadius: 6))
    }
}
