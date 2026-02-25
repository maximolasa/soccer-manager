import SwiftUI

struct TransferMarketView: View {
    @State var viewModel: GameViewModel
    @State private var searchText: String = ""
    @State private var positionFilter: PlayerPosition?
    @State private var specialFilter: SpecialFilter = .all
    @State private var sortBy: SortOption?
    @State private var sortDirection: SortDirection = .descending
    @State private var selectedDetailPlayer: Player?

    // MARK: Enums

    nonisolated enum SpecialFilter: String, CaseIterable, Sendable {
        case all = "All"
        case freeAgents = "Free Agents"
        case listed = "Listed"
        case mySquad = "My Squad"
    }

    nonisolated enum SortOption: String, CaseIterable, Sendable {
        case position = "Pos"
        case age = "Age"
        case overall = "OVR"
        case attack = "ATK"
        case defense = "DEF"
        case value = "Value"
        case wage = "Wage"
    }

    nonisolated enum SortDirection: Sendable {
        case descending, ascending
    }

    static let posOrder: [PlayerPosition] = [
        .goalkeeper, .centerBack, .leftBack, .rightBack,
        .defensiveMidfield, .centralMidfield, .attackingMidfield,
        .leftWing, .rightWing, .striker
    ]

    // MARK: Filtered & Sorted

    var filteredPlayers: [Player] {
        var list: [Player]
        switch specialFilter {
        case .all:
            list = viewModel.players
        case .freeAgents:
            list = viewModel.freeAgents
        case .listed:
            list = viewModel.players.filter { $0.isTransferListed }
        case .mySquad:
            list = viewModel.myPlayers
        }

        if let pos = positionFilter {
            list = list.filter { $0.position == pos }
        }
        if !searchText.isEmpty {
            list = list.filter { $0.fullName.localizedStandardContains(searchText) }
        }

        if let sortBy {
            let asc = sortDirection == .ascending
            switch sortBy {
            case .position:
                let order = Self.posOrder
                list.sort {
                    let i0 = order.firstIndex(of: $0.position) ?? 99
                    let i1 = order.firstIndex(of: $1.position) ?? 99
                    return asc ? i0 > i1 : i0 < i1
                }
            case .age:
                list.sort { asc ? $0.age > $1.age : $0.age < $1.age }
            case .overall:
                list.sort { asc ? $0.overall < $1.overall : $0.overall > $1.overall }
            case .attack:
                list.sort { asc ? $0.stats.attackAvg < $1.stats.attackAvg : $0.stats.attackAvg > $1.stats.attackAvg }
            case .defense:
                list.sort { asc ? $0.stats.defenseAvg < $1.stats.defenseAvg : $0.stats.defenseAvg > $1.stats.defenseAvg }
            case .value:
                list.sort { asc ? $0.marketValue < $1.marketValue : $0.marketValue > $1.marketValue }
            case .wage:
                list.sort { asc ? $0.wage < $1.wage : $0.wage > $1.wage }
            }
        } else {
            list.sort { $0.overall > $1.overall }
        }
        return Array(list.prefix(80))
    }

    // MARK: Context Detection

    private func contextFor(_ player: Player) -> PlayerDetailContext {
        if player.clubId == viewModel.selectedClubId { return .squad }
        if player.clubId == nil { return .freeAgent }
        return .transferBuy
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            searchBar
            filtersRow
            columnHeaders
            playerTable
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea())
        .fullScreenCover(item: $selectedDetailPlayer) { player in
            PlayerDetailView(
                player: player,
                context: contextFor(player),
                viewModel: viewModel
            )
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

            Text("TRANSFER MARKET")
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(.white)
                .tracking(2)

            Spacer()

            HStack(spacing: 8) {
                Label(viewModel.formatCurrency(viewModel.selectedClub?.budget ?? 0), systemImage: "banknote")
                    .font(.caption)
                    .foregroundStyle(.green)
                windowBadge
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.1))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var windowBadge: some View {
        Text(viewModel.transferWindow.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(viewModel.transferWindow == .open ? .green : .red)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                (viewModel.transferWindow == .open ? Color.green : Color.red).opacity(0.15)
            )
            .clipShape(.capsule)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.3))
            TextField("Search players...", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
    }

    // MARK: - Filters

    private var filtersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SpecialFilter.allCases, id: \.rawValue) { filter in
                    chipButton(filter.rawValue, isSelected: specialFilter == filter && positionFilter == nil) {
                        specialFilter = filter
                        positionFilter = nil
                    }
                }

                Divider()
                    .frame(height: 20)
                    .background(Color.white.opacity(0.15))

                ForEach(PlayerPosition.allCases) { pos in
                    chipButton(pos.rawValue, isSelected: positionFilter == pos) {
                        positionFilter = pos
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color(white: 0.06))
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text("Player")
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.white.opacity(0.4))
            sortableCol("Pos", .position, 40)
            sortableCol("Age", .age, 36)
            sortableCol("OVR", .overall, 40)
            Text("Club")
                .frame(width: 65)
                .foregroundStyle(.white.opacity(0.4))
            sortableCol("Value", .value, 60)
        }
        .font(.system(size: 11, weight: .bold))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
    }

    // MARK: - Player Table

    private var playerTable: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredPlayers) { player in
                    Button {
                        selectedDetailPlayer = player
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
            HStack(spacing: 5) {
                Text(player.fullName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if player.isTransferListed {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(player.position.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ColorHelpers.positionColor(player.position))
                .frame(width: 40)

            Text("\(player.age)")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 36)

            Text("\(player.overall)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorHelpers.statColor(player.overall))
                .frame(width: 40)

            Text(clubLabel(player))
                .font(.system(size: 11))
                .foregroundStyle(player.clubId == nil ? .orange : .white.opacity(0.4))
                .lineLimit(1)
                .frame(width: 65)

            Text(viewModel.formatCurrency(player.marketValue))
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 60)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(rowBackground(player))
    }

    // MARK: - Helpers

    private func clubLabel(_ player: Player) -> String {
        if player.clubId == viewModel.selectedClubId { return "My Team" }
        if let cid = player.clubId { return viewModel.clubName(for: cid) }
        return "Free"
    }

    private func rowBackground(_ player: Player) -> Color {
        if player.clubId == viewModel.selectedClubId {
            return Color.green.opacity(0.04)
        }
        if player.isTransferListed {
            return Color.orange.opacity(0.03)
        }
        return Color.white.opacity(0.015)
    }

    private func chipButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color.white.opacity(0.07))
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private func sortableCol(_ label: String, _ option: SortOption, _ width: CGFloat) -> some View {
        Button {
            tapSort(option)
        } label: {
            HStack(spacing: 2) {
                Text(label)
                if sortBy == option {
                    Image(systemName: sortDirection == .descending ? "chevron.down" : "chevron.up")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
            .frame(width: width)
            .frame(minHeight: 28)
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
