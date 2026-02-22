import SwiftUI

struct TransferMarketView: View {
    @State var viewModel: GameViewModel
    @State private var selectedTab: TransferTab = .buy
    @State private var searchText: String = ""
    @State private var selectedPlayer: Player?
    @State private var offerAmount: String = ""
    @State private var showingOffer: Bool = false
    @State private var positionFilter: PlayerPosition?

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

        return Array(list.sorted { $0.stats.overall > $1.stats.overall }.prefix(50))
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                tabBar
                filtersRow
                playerTable

                if showingOffer, let player = selectedPlayer {
                    offerPanel(player)
                }
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
        .padding(.vertical, 8)
        .background(Color(white: 0.1))
    }

    private var windowBadge: some View {
        Text(viewModel.transferWindow.label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(viewModel.transferWindow == .open ? .green : .red)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
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
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? .green : .white.opacity(0.4))
                        .padding(.vertical, 8)
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
            HStack(spacing: 6) {
                filterChip("All", isSelected: positionFilter == nil) {
                    positionFilter = nil
                }
                ForEach(PlayerPosition.allCases) { pos in
                    filterChip(pos.rawValue, isSelected: positionFilter == pos) {
                        positionFilter = pos
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(white: 0.06))
    }

    private var playerTable: some View {
        ScrollView {
            HStack(spacing: 0) {
                Text("Player").frame(maxWidth: .infinity, alignment: .leading)
                Text("Pos").frame(width: 32)
                Text("Age").frame(width: 32)
                Text("OVR").frame(width: 36)
                Text("OFF").frame(width: 36)
                Text("DEF").frame(width: 36)
                Text("Club").frame(width: 70)
                Text("Value").frame(width: 60)
                Text("").frame(width: 60)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white.opacity(0.3))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(player.position.rawValue)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.cyan)
                .frame(width: 32)

            Text("\(player.age)")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 32)

            Text("\(player.stats.overall)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(statColor(player.stats.overall))
                .frame(width: 36)

            Text("\(player.stats.offensive)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 36)

            Text("\(player.stats.defensive)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 36)

            Text(player.clubId != nil ? viewModel.clubName(for: player.clubId!) : "Free")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
                .frame(width: 70)

            Text(viewModel.formatCurrency(player.marketValue))
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 60)

            Button {
                selectedPlayer = player
                offerAmount = "\(player.marketValue)"
                showingOffer = true
            } label: {
                Text(actionLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green)
                    .clipShape(.capsule)
            }
            .frame(width: 60)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
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
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.green : Color.white.opacity(0.08))
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private func statColor(_ value: Int) -> Color {
        if value >= 85 { return .green }
        if value >= 70 { return .yellow }
        if value >= 55 { return .orange }
        return .red
    }
}
