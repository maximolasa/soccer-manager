import SwiftUI

struct StandingsView: View {
    @State var viewModel: GameViewModel
    @State private var selectedLeague: League?

    var displayStandings: [StandingsEntry] {
        guard let league = selectedLeague ?? viewModel.leagues.first(where: { $0.id == viewModel.selectedClub?.leagueId }) else { return [] }
        return (viewModel.standings[league.id] ?? [])
            .sorted { ($0.points, $0.goalDifference, $0.goalsFor) > ($1.points, $1.goalDifference, $1.goalsFor) }
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                leagueSelector
                standingsTable
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

            Text("STANDINGS")
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(.white)
                .tracking(2)

            Spacer()
            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(white: 0.1))
    }

    private var leagueSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel.leagues) { league in
                    Button {
                        selectedLeague = league
                    } label: {
                        HStack(spacing: 4) {
                            Text(league.countryEmoji)
                            Text(league.name)
                                .lineLimit(1)
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(
                            (selectedLeague?.id ?? viewModel.selectedClub?.leagueId) == league.id
                            ? .black : .white.opacity(0.6)
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            (selectedLeague?.id ?? viewModel.selectedClub?.leagueId) == league.id
                            ? Color.green : Color.white.opacity(0.08)
                        )
                        .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(white: 0.07))
    }

    private var standingsTable: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("#").frame(width: 24, alignment: .center)
                    Text("Club").frame(maxWidth: .infinity, alignment: .leading)
                    Text("P").frame(width: 28)
                    Text("W").frame(width: 28)
                    Text("D").frame(width: 28)
                    Text("L").frame(width: 28)
                    Text("GF").frame(width: 32)
                    Text("GA").frame(width: 32)
                    Text("GD").frame(width: 32)
                    Text("Pts").frame(width: 36)
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.03))

                ForEach(Array(displayStandings.enumerated()), id: \.element.id) { idx, entry in
                    HStack(spacing: 0) {
                        Text("\(idx + 1)")
                            .frame(width: 24, alignment: .center)
                            .foregroundStyle(positionColor(idx, total: displayStandings.count))

                        Text(entry.clubName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fontWeight(entry.clubId == viewModel.selectedClubId ? .bold : .regular)

                        Text("\(entry.played)").frame(width: 28)
                        Text("\(entry.won)").frame(width: 28)
                        Text("\(entry.drawn)").frame(width: 28)
                        Text("\(entry.lost)").frame(width: 28)
                        Text("\(entry.goalsFor)").frame(width: 32)
                        Text("\(entry.goalsAgainst)").frame(width: 32)

                        Text("\(entry.goalDifference)")
                            .foregroundStyle(entry.goalDifference > 0 ? .green : (entry.goalDifference < 0 ? .red : .white.opacity(0.5)))
                            .frame(width: 32)

                        Text("\(entry.points)")
                            .fontWeight(.bold)
                            .frame(width: 36)
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(entry.clubId == viewModel.selectedClubId ? .green : .white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
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
}
