import SwiftUI

struct CalendarView: View {
    @State var viewModel: GameViewModel
    @State private var filterType: MatchType?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f
    }()

    var allFixtures: [Match] {
        var fixtures = viewModel.seasonFixtures + viewModel.cupFixtures + viewModel.friendlyFixtures
        fixtures = fixtures.filter { $0.homeClubId == viewModel.selectedClubId || $0.awayClubId == viewModel.selectedClubId }
        if let filter = filterType {
            fixtures = fixtures.filter { $0.matchType == filter }
        }
        return fixtures.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            filterBar
            fixtureList
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

            Text("CALENDAR")
                .font(.headline)
                .fontWeight(.black)
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

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", isSelected: filterType == nil) { filterType = nil }
                ForEach(MatchType.allCases) { type in
                    filterChip(type.rawValue, isSelected: filterType == type, color: matchTypeColor(type)) {
                        filterType = type
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color(white: 0.07))
    }

    private var fixtureList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(allFixtures) { match in
                    fixtureRow(match)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func fixtureRow(_ match: Match) -> some View {
        HStack(spacing: 8) {
            Text(dateFormatter.string(from: match.date))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 80, alignment: .leading)

            Text(match.matchType.rawValue)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(matchTypeColor(match.matchType))
                .frame(width: 55)

            Text(match.homeClubName)
                .font(.system(size: 11, weight: match.homeClubId == viewModel.selectedClubId ? .bold : .regular))
                .foregroundStyle(match.homeClubId == viewModel.selectedClubId ? .green : .white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)

            if match.isPlayed {
                Text("\(match.homeScore) - \(match.awayScore)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(width: 44, alignment: .center)
            } else {
                Text("vs")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(width: 44, alignment: .center)
            }

            Text(match.awayClubName)
                .font(.system(size: 11, weight: match.awayClubId == viewModel.selectedClubId ? .bold : .regular))
                .foregroundStyle(match.awayClubId == viewModel.selectedClubId ? .green : .white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            if match.isPlayed {
                resultBadge(match)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(match.isPlayed ? 0.02 : 0.04))
        .clipShape(.rect(cornerRadius: 6))
    }

    private func resultBadge(_ match: Match) -> some View {
        let isHome = match.homeClubId == viewModel.selectedClubId
        let myGoals = isHome ? match.homeScore : match.awayScore
        let theirGoals = isHome ? match.awayScore : match.homeScore
        let result: String
        let color: Color
        if myGoals > theirGoals { result = "W"; color = .green }
        else if myGoals < theirGoals { result = "L"; color = .red }
        else { result = "D"; color = .yellow }

        return Text(result)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(color)
            .frame(width: 22, height: 22)
            .background(color.opacity(0.15))
            .clipShape(.rect(cornerRadius: 5))
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

    private func matchTypeColor(_ type: MatchType) -> Color {
        switch type {
        case .league: return .blue
        case .nationalCup: return .yellow
        case .friendly: return .cyan
        case .championsLeague: return .purple
        case .europaLeague: return .orange
        }
    }
}
