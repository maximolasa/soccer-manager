import SwiftUI

struct TransferMarketView: View {
    @State var viewModel: GameViewModel
    @State private var selectedTab: TransferTab = .buy
    @State private var searchText: String = ""
    @State private var selectedPlayer: Player?
    @State private var offerAmount: String = ""
    @State private var showingOffer: Bool = false
    @State private var positionFilter: PlayerPosition?
    @State private var sortBy: SortOption?
    @State private var sortDirection: SortDirection = .descending

    nonisolated enum SortOption: String, CaseIterable, Sendable {
        case position = "Pos"
        case age = "Age"
        case overall = "OVR"
        case offensive = "OFF"
        case defensive = "DEF"
        case value = "Value"
    }

    nonisolated enum SortDirection: Sendable {
        case descending, ascending
    }

    static let positionOrder: [PlayerPosition] = [
        .goalkeeper, .centerBack, .leftBack, .rightBack,
        .defensiveMidfield, .centralMidfield, .attackingMidfield,
        .leftWing, .rightWing, .striker
    ]

    nonisolated enum TransferTab: String, CaseIterable, Sendable {
        case buy = "Buy"
        case sell = "Sell"
        case freeAgents = "Free Agents"
        case loans = "Loans"
    }

    var availablePlayers: [Player] {
        var list: [Player]
        switch selectedTab {
        case .buy:
            list = viewModel.players.filter {
                $0.clubId != nil && $0.clubId != viewModel.selectedClubId && !$0.isOnLoan
            }
        case .sell:
            list = viewModel.myPlayers
        case .freeAgents:
            list = viewModel.freeAgents
        case .loans:
            list = viewModel.players.filter {
                $0.clubId != nil && $0.clubId != viewModel.selectedClubId && $0.contractYearsLeft > 1
            }
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
                let order = Self.positionOrder
                list.sort {
                    let i0 = order.firstIndex(of: $0.position) ?? 99
                    let i1 = order.firstIndex(of: $1.position) ?? 99
                    return asc ? i0 > i1 : i0 < i1
                }
            case .age:
                list.sort { asc ? $0.age > $1.age : $0.age < $1.age }
            case .overall:
                list.sort { asc ? $0.stats.overall < $1.stats.overall : $0.stats.overall > $1.stats.overall }
            case .offensive:
                list.sort { asc ? $0.stats.offensive < $1.stats.offensive : $0.stats.offensive > $1.stats.offensive }
            case .defensive:
                list.sort { asc ? $0.stats.defensive < $1.stats.defensive : $0.stats.defensive > $1.stats.defensive }
            case .value:
                list.sort { asc ? $0.marketValue < $1.marketValue : $0.marketValue > $1.marketValue }
            }
        } else {
            list.sort { $0.stats.overall > $1.stats.overall }
        }
        return Array(list.prefix(50))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            tabBar
            filtersRow
            playerTable

            if showingOffer, let player = selectedPlayer {
                offerPanel(player)
            }
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
        .padding(.vertical, 14)
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

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(TransferTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(duration: 0.2)) { selectedTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? .green : .white.opacity(0.4))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selectedTab == tab ? Color.green.opacity(0.1) : .clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(white: 0.07))
    }

    private var filtersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", isSelected: positionFilter == nil) {
                    positionFilter = nil
                }
                ForEach(PlayerPosition.allCases) { pos in
                    filterChip(pos.rawValue, isSelected: positionFilter == pos) {
                        positionFilter = pos
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color(white: 0.06))
    }

    private var playerTable: some View {
        ScrollView {
            HStack(spacing: 0) {
                Text("Player")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.white.opacity(0.4))
                sortableHeader("Pos", option: .position, width: 40)
                sortableHeader("Age", option: .age, width: 36)
                sortableHeader("OVR", option: .overall, width: 40)
                sortableHeader("OFF", option: .offensive, width: 40)
                sortableHeader("DEF", option: .defensive, width: 40)
                Text("Club")
                    .frame(width: 75)
                    .foregroundStyle(.white.opacity(0.4))
                sortableHeader("Value", option: .value, width: 68)
                Text("").frame(width: 64)
            }
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.03))

            LazyVStack(spacing: 0) {
                ForEach(availablePlayers) { player in
                    transferRow(player)
                }
            }
        }
    }

    private func transferRow(_ player: Player) -> some View {
        HStack(spacing: 0) {
            Text(player.fullName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(player.position.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.cyan)
                .frame(width: 40)

            Text("\(player.age)")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 36)

            Text("\(player.stats.overall)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(statColor(player.stats.overall))
                .frame(width: 40)

            Text("\(player.stats.offensive)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 40)

            Text("\(player.stats.defensive)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 40)

            Text(player.clubId != nil ? viewModel.clubName(for: player.clubId!) : "Free")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
                .frame(width: 75)

            Text(viewModel.formatCurrency(player.marketValue))
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 68)

            Button {
                selectedPlayer = player
                offerAmount = "\(player.marketValue)"
                showingOffer = true
            } label: {
                Text(actionLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .clipShape(.capsule)
            }
            .frame(width: 64)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.02))
    }

    private var actionLabel: String {
        switch selectedTab {
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .freeAgents: return "Sign"
        case .loans: return "Loan"
        }
    }

    private func offerPanel(_ player: Player) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(selectedTab == .sell ? "Sell" : "Sign") \(player.fullName)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showingOffer = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            HStack(spacing: 12) {
                if selectedTab != .freeAgents {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fee")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(viewModel.formatCurrency(player.marketValue))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wage")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(viewModel.formatCurrency(player.wage) + "/wk")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    executeTransfer(player)
                } label: {
                    Text("Confirm")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .clipShape(.capsule)
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.12))
    }

    private func executeTransfer(_ player: Player) {
        switch selectedTab {
        case .buy:
            if viewModel.transferWindow == .open {
                _ = viewModel.buyPlayer(player, fee: player.marketValue)
            }
        case .sell:
            if viewModel.transferWindow == .open {
                viewModel.sellPlayer(player, fee: player.marketValue)
            }
        case .freeAgents:
            _ = viewModel.signFreeAgent(player, wage: player.wage)
        case .loans:
            _ = viewModel.buyPlayer(player, fee: 0)
        }
        showingOffer = false
        selectedPlayer = nil
    }

    private func filterChip(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.green : Color.white.opacity(0.08))
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
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
