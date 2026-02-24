import SwiftUI

struct StandingsView: View {
    @State var viewModel: GameViewModel
    @State private var selectedLeague: League?
    @State private var sortBy: SortOption?
    @State private var sortDirection: SortDirection = .descending

    nonisolated enum SortOption: String, CaseIterable, Sendable {
        case played = "P"
        case won = "W"
        case drawn = "D"
        case lost = "L"
        case goalsFor = "GF"
        case goalsAgainst = "GA"
        case goalDifference = "GD"
        case points = "Pts"
    }

    nonisolated enum SortDirection: Sendable {
        case descending, ascending
    }

    var displayStandings: [StandingsEntry] {
        guard let league = selectedLeague ?? viewModel.leagues.first(where: { $0.id == viewModel.selectedClub?.leagueId }) else { return [] }
        var list = viewModel.standings[league.id] ?? []
        if let sortBy {
            let asc = sortDirection == .ascending
            switch sortBy {
            case .played:
                list.sort { asc ? $0.played < $1.played : $0.played > $1.played }
            case .won:
                list.sort { asc ? $0.won < $1.won : $0.won > $1.won }
            case .drawn:
                list.sort { asc ? $0.drawn < $1.drawn : $0.drawn > $1.drawn }
            case .lost:
                list.sort { asc ? $0.lost < $1.lost : $0.lost > $1.lost }
            case .goalsFor:
                list.sort { asc ? $0.goalsFor < $1.goalsFor : $0.goalsFor > $1.goalsFor }
            case .goalsAgainst:
                list.sort { asc ? $0.goalsAgainst < $1.goalsAgainst : $0.goalsAgainst > $1.goalsAgainst }
            case .goalDifference:
                list.sort { asc ? $0.goalDifference < $1.goalDifference : $0.goalDifference > $1.goalDifference }
            case .points:
                list.sort { asc ? $0.points < $1.points : $0.points > $1.points }
            }
        } else {
            list.sort { ($0.points, $0.goalDifference, $0.goalsFor) > ($1.points, $1.goalDifference, $1.goalsFor) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            leagueSelector
            standingsTable
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

            Text("STANDINGS")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .tracking(2)

            Spacer()
            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(white: 0.1))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var leagueSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.leagues) { league in
                    Button {
                        selectedLeague = league
                    } label: {
                        HStack(spacing: 4) {
                            Text(league.countryEmoji)
                            Text(league.name)
                                .lineLimit(1)
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(
                            (selectedLeague?.id ?? viewModel.selectedClub?.leagueId) == league.id
                            ? .black : .white.opacity(0.6)
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            (selectedLeague?.id ?? viewModel.selectedClub?.leagueId) == league.id
                            ? Color.green : Color.white.opacity(0.08)
                        )
                        .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color(white: 0.07))
    }

    private var standingsTable: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("#").frame(width: 28, alignment: .center)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Club").frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white.opacity(0.4))
                    sortableHeader("P", option: .played, width: 32)
                    sortableHeader("W", option: .won, width: 32)
                    sortableHeader("D", option: .drawn, width: 32)
                    sortableHeader("L", option: .lost, width: 32)
                    sortableHeader("GF", option: .goalsFor, width: 36)
                    sortableHeader("GA", option: .goalsAgainst, width: 36)
                    sortableHeader("GD", option: .goalDifference, width: 36)
                    sortableHeader("Pts", option: .points, width: 40)
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.03))

                ForEach(Array(displayStandings.enumerated()), id: \.element.id) { idx, entry in
                    HStack(spacing: 0) {
                        Text("\(idx + 1)")
                            .frame(width: 28, alignment: .center)
                            .foregroundStyle(positionColor(idx, total: displayStandings.count))

                        Text(entry.clubName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fontWeight(entry.clubId == viewModel.selectedClubId ? .bold : .regular)

                        Text("\(entry.played)").frame(width: 32)
                        Text("\(entry.won)").frame(width: 32)
                        Text("\(entry.drawn)").frame(width: 32)
                        Text("\(entry.lost)").frame(width: 32)
                        Text("\(entry.goalsFor)").frame(width: 36)
                        Text("\(entry.goalsAgainst)").frame(width: 36)

                        Text("\(entry.goalDifference)")
                            .foregroundStyle(entry.goalDifference > 0 ? .green : (entry.goalDifference < 0 ? .red : .white.opacity(0.5)))
                            .frame(width: 36)

                        Text("\(entry.points)")
                            .fontWeight(.bold)
                            .frame(width: 40)
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(entry.clubId == viewModel.selectedClubId ? .green : .white.opacity(0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(entry.clubId == viewModel.selectedClubId ? Color.green.opacity(0.06) : .clear)
                }
            }
        }
    }

    private func positionColor(_ idx: Int, total: Int) -> Color {
        if idx < 2 { return .green }
        if idx < 4 { return .blue }
        if idx >= total - 3 { return .red }
        return .white.opacity(0.5)
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
