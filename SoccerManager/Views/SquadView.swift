import SwiftUI

struct SquadView: View {
    @State var viewModel: GameViewModel
    @State private var selectedPosition: PlayerPosition?
    @State private var sortBy: SortOption? = nil
    @State private var sortDirection: SortDirection = .descending
    @State private var selectedPlayer: Player?

    nonisolated enum SortOption: String, CaseIterable, Sendable {
        case position = "Pos"
        case overall = "OVR"
        case offensive = "OFF"
        case defensive = "DEF"
        case physical = "PHY"
        case age = "Age"
        case goals = "Goals"
        case value = "Value"
        case wage = "Wage"
    }

    nonisolated enum SortDirection: Sendable {
        case descending
        case ascending
    }

    static let positionOrder: [PlayerPosition] = [
        .goalkeeper, .centerBack, .leftBack, .rightBack,
        .defensiveMidfield, .centralMidfield, .attackingMidfield,
        .leftWing, .rightWing, .striker
    ]

    var filteredPlayers: [Player] {
        var list = viewModel.myPlayers
        if let pos = selectedPosition {
            list = list.filter { $0.position == pos }
        }
        guard let sortBy else {
            let order = Self.positionOrder
            list.sort {
                let i0 = order.firstIndex(of: $0.position) ?? 99
                let i1 = order.firstIndex(of: $1.position) ?? 99
                return i0 < i1
            }
            return list
        }
        let asc = sortDirection == .ascending
        switch sortBy {
        case .position:
            let order = Self.positionOrder
            list.sort {
                let i0 = order.firstIndex(of: $0.position) ?? 99
                let i1 = order.firstIndex(of: $1.position) ?? 99
                return asc ? i0 > i1 : i0 < i1
            }
        case .overall:
            list.sort { asc ? $0.overall < $1.overall : $0.overall > $1.overall }
        case .offensive:
            list.sort { asc ? $0.stats.attackAvg < $1.stats.attackAvg : $0.stats.attackAvg > $1.stats.attackAvg }
        case .defensive:
            list.sort { asc ? $0.stats.defenseAvg < $1.stats.defenseAvg : $0.stats.defenseAvg > $1.stats.defenseAvg }
        case .physical:
            list.sort { asc ? $0.stats.physicalAvg < $1.stats.physicalAvg : $0.stats.physicalAvg > $1.stats.physicalAvg }
        case .age:
            list.sort { asc ? $0.age > $1.age : $0.age < $1.age }
        case .goals:
            list.sort { asc ? $0.goals < $1.goals : $0.goals > $1.goals }
        case .value:
            list.sort { asc ? $0.marketValue < $1.marketValue : $0.marketValue > $1.marketValue }
        case .wage:
            list.sort { asc ? $0.wage < $1.wage : $0.wage > $1.wage }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            filtersBar
            playerList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea())
        .fullScreenCover(item: $selectedPlayer) { player in
            PlayerDetailView(
                player: player,
                context: .squad,
                viewModel: viewModel
            )
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

            Text("SQUAD")
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(.white)
                .tracking(2)

            Spacer()

            Text("\(viewModel.myPlayers.count) players")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(white: 0.1))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var filtersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", isSelected: selectedPosition == nil) {
                    selectedPosition = nil
                }
                ForEach(PlayerPosition.allCases) { pos in
                    filterChip(pos.rawValue, isSelected: selectedPosition == pos) {
                        selectedPosition = pos
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color(white: 0.07))
    }

    private var playerList: some View {
        ScrollView {
            HStack(spacing: 0) {
                Text("Player").frame(maxWidth: .infinity, alignment: .leading)
                sortableHeader("Pos", option: .position, width: 40)
                sortableHeader("Age", option: .age, width: 36)
                sortableHeader("OVR", option: .overall, width: 40)
                sortableHeader("OFF", option: .offensive, width: 40)
                sortableHeader("DEF", option: .defensive, width: 40)
                sortableHeader("PHY", option: .physical, width: 40)
                sortableHeader("Goals", option: .goals, width: 44)
                sortableHeader("Value", option: .value, width: 62)
                sortableHeader("Wage", option: .wage, width: 62)
                Text("Status").frame(width: 44)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.03))

            LazyVStack(spacing: 0) {
                ForEach(filteredPlayers) { player in
                    Button {
                        selectedPlayer = player
                    } label: {
                        playerRow(player)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func playerRow(_ player: Player) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(player.fullName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(player.position.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(positionColor(player.position))
                .frame(width: 40)

            Text("\(player.age)")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 36)

            statBadge(player.overall)
                .frame(width: 40)

            Text("\(player.stats.attackAvg)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 40)

            Text("\(player.stats.defenseAvg)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 40)

            Text("\(player.stats.physicalAvg)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 40)

            Text("\(player.goals)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 44)

            Text(viewModel.formatCurrency(player.marketValue))
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 62)

            Text(viewModel.formatCurrency(player.wage))
                .font(.system(size: 10))
                .foregroundStyle(.orange.opacity(0.7))
                .frame(width: 62)

            statusIcon(player)
                .frame(width: 44)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.02))
    }

    private func filterChip(_ text: String, isSelected: Bool, color: Color = .green, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.white.opacity(0.08))
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private func statBadge(_ value: Int, large: Bool = false) -> some View {
        Text("\(value)")
            .font(.system(size: large ? 20 : 11, weight: .bold, design: .monospaced))
            .foregroundStyle(statColor(value))
            .padding(.horizontal, large ? 10 : 5)
            .padding(.vertical, large ? 4 : 2)
            .background(statColor(value).opacity(0.15))
            .clipShape(.rect(cornerRadius: large ? 8 : 4))
    }

    private func statusIcon(_ player: Player) -> some View {
        Group {
            if player.isInjured {
                Image(systemName: "cross.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            } else if player.yellowCards >= 4 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.green.opacity(0.5))
            }
        }
    }

    private func positionColor(_ pos: PlayerPosition) -> Color {
        ColorHelpers.positionColor(pos)
    }

    private func statColor(_ value: Int) -> Color {
        ColorHelpers.statColor(value)
    }

    private func sortableHeader(_ label: String, option: SortOption, width: CGFloat) -> some View {
        Button {
            tapSort(option)
        } label: {
            HStack(spacing: 2) {
                Text(label)
                if sortBy == option {
                    Image(systemName: sortDirection == .descending ? "chevron.down" : "chevron.up")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
            .frame(width: width)
            .foregroundStyle(sortBy == option ? .green : .white.opacity(0.4))
        }
        .buttonStyle(.plain)
    }

    private func tapSort(_ option: SortOption) {
        if sortBy == option {
            if sortDirection == .descending {
                sortDirection = .ascending
            } else {
                sortBy = nil
                sortDirection = .descending
            }
        } else {
            sortBy = option
            sortDirection = .descending
        }
    }
}
