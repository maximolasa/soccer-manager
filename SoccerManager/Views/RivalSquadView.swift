import SwiftUI

struct RivalSquadView: View {
    @State var viewModel: GameViewModel

    private static let positionOrder: [PlayerPosition] = [
        .goalkeeper, .centerBack, .leftBack, .rightBack,
        .defensiveMidfield, .centralMidfield, .attackingMidfield,
        .leftWing, .rightWing, .striker
    ]

    var sortedRivalPlayers: [Player] {
        let order = Self.positionOrder
        return viewModel.rivalPlayers.sorted {
            let i0 = order.firstIndex(of: $0.position) ?? 99
            let i1 = order.firstIndex(of: $1.position) ?? 99
            return i0 < i1
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                clubInfoBar
                playerList
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

            Text("RIVAL SQUAD")
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(.white)
                .tracking(2)

            Spacer()

            Text("\(viewModel.rivalPlayers.count) players")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(white: 0.1))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var clubInfoBar: some View {
        HStack(spacing: 12) {
            if let club = viewModel.rivalClub {
                ZStack {
                    Circle()
                        .fill(club.primarySwiftUIColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Text(club.shortName)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(club.primarySwiftUIColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(club.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Rating: \(club.rating) • \(club.formation)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                if let match = viewModel.nextMatch {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(match.matchType.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                        Text(matchDateString(match.date))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(white: 0.08))
    }

    private var playerList: some View {
        ScrollView {
            HStack(spacing: 0) {
                Text("Player").frame(maxWidth: .infinity, alignment: .leading)
                Text("Pos").frame(width: 36)
                Text("Age").frame(width: 32)
                Text("OVR").frame(width: 36)
                Text("OFF").frame(width: 36)
                Text("DEF").frame(width: 36)
                Text("PHY").frame(width: 36)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.03))

            LazyVStack(spacing: 0) {
                ForEach(sortedRivalPlayers) { player in
                    playerRow(player)
                }
            }
        }
    }

    private func playerRow(_ player: Player) -> some View {
        HStack(spacing: 0) {
            Text(player.fullName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(player.position.rawValue)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(positionColor(player.position))
                .frame(width: 36)

            Text("\(player.age)")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 32)

            statBadge(player.stats.overall)
                .frame(width: 36)

            Text("\(player.stats.offensive)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 36)

            Text("\(player.stats.defensive)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 36)

            Text("\(player.stats.physical)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 36)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
    }

    private func statBadge(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(statColor(value))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(statColor(value).opacity(0.15))
            .clipShape(.rect(cornerRadius: 4))
    }

    private func positionColor(_ pos: PlayerPosition) -> Color {
        ColorHelpers.positionColor(pos)
    }

    private func statColor(_ value: Int) -> Color {
        ColorHelpers.statColor(value)
    }

    private func matchDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
    }
}
