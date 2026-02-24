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
            // Default: sort by position order
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
            list.sort { asc ? $0.stats.overall < $1.stats.overall : $0.stats.overall > $1.stats.overall }
        case .offensive:
            list.sort { asc ? $0.stats.offensive < $1.stats.offensive : $0.stats.offensive > $1.stats.offensive }
        case .defensive:
            list.sort { asc ? $0.stats.defensive < $1.stats.defensive : $0.stats.defensive > $1.stats.defensive }
        case .physical:
            list.sort { asc ? $0.stats.physical < $1.stats.physical : $0.stats.physical > $1.stats.physical }
        case .age:
            list.sort { asc ? $0.age > $1.age : $0.age < $1.age }
        case .goals:
            list.sort { asc ? $0.goals < $1.goals : $0.goals > $1.goals }
        case .wage:
            list.sort { asc ? $0.wage < $1.wage : $0.wage > $1.wage }
        }
        return list
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerBar
                filtersBar
                playerList
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let player = selectedPlayer {
                playerDetailOverlay(player)
            }
        }
        .background(Color(red: 0.06, green: 0.08, blue: 0.1), ignoresSafeAreaEdges: .all)
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
            HStack(spacing: 6) {
                filterChip("All", isSelected: selectedPosition == nil) {
                    selectedPosition = nil
                }
                ForEach(PlayerPosition.allCases) { pos in
                    filterChip(pos.rawValue, isSelected: selectedPosition == pos) {
                        selectedPosition = pos
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(white: 0.07))
    }

    private var playerList: some View {
        ScrollView {
            HStack(spacing: 0) {
                Text("Player").frame(maxWidth: .infinity, alignment: .leading)
                sortableHeader("Pos", option: .position, width: 36)
                sortableHeader("Age", option: .age, width: 32)
                sortableHeader("OVR", option: .overall, width: 36)
                sortableHeader("OFF", option: .offensive, width: 36)
                sortableHeader("DEF", option: .defensive, width: 36)
                sortableHeader("PHY", option: .physical, width: 36)
                sortableHeader("Goals", option: .goals, width: 40)
                sortableHeader("Wage", option: .wage, width: 52)
                Text("Status").frame(width: 50)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
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

            Text("\(player.goals)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 40)

            Text(viewModel.formatCurrency(player.wage))
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 52)

            statusIcon(player)
                .frame(width: 50)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
    }

    private func playerDetailOverlay(_ player: Player) -> some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
                .onTapGesture { selectedPlayer = nil }

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.fullName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("\(player.position.fullName) | Age: \(player.age)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    statBadge(player.stats.overall, large: true)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    statBox("Offensive", player.stats.offensive, .orange)
                    statBox("Defensive", player.stats.defensive, .blue)
                    statBox("Physical", player.stats.physical, .green)
                }

                HStack(spacing: 16) {
                    miniStat("Goals", "\(player.goals)")
                    miniStat("Assists", "\(player.assists)")
                    miniStat("Matches", "\(player.matchesPlayed)")
                    miniStat("Morale", "\(player.morale)")
                    miniStat("Contract", "\(player.contractYearsLeft)yr")
                    miniStat("Value", viewModel.formatCurrency(player.marketValue))
                }

                HStack(spacing: 12) {
                    Button {
                        viewModel.releasePlayer(player)
                        selectedPlayer = nil
                    } label: {
                        Text("Release")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.15))
                            .clipShape(.capsule)
                    }

                    Button { selectedPlayer = nil } label: {
                        Text("Close")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15))
                            .clipShape(.capsule)
                    }
                }
            }
            .padding(20)
            .background(Color(white: 0.12))
            .clipShape(.rect(cornerRadius: 16))
            .padding(.horizontal, 40)
        }
    }

    private func filterChip(_ text: String, isSelected: Bool, color: Color = .green, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? color : Color.white.opacity(0.08))
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private func statBadge(_ value: Int, large: Bool = false) -> some View {
        Text("\(value)")
            .font(.system(size: large ? 20 : 10, weight: .bold, design: .monospaced))
            .foregroundStyle(statColor(value))
            .padding(.horizontal, large ? 10 : 4)
            .padding(.vertical, large ? 4 : 2)
            .background(statColor(value).opacity(0.15))
            .clipShape(.rect(cornerRadius: large ? 8 : 4))
    }

    private func statBox(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(.rect(cornerRadius: 8))
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private func statusIcon(_ player: Player) -> some View {
        Group {
            if player.isInjured {
                Image(systemName: "cross.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.red)
            } else if player.yellowCards >= 4 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.yellow)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9))
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
