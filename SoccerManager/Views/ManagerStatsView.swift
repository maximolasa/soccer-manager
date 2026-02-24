import SwiftUI

struct ManagerStatsView: View {
    @State var viewModel: GameViewModel

    private var matchesPlayed: Int {
        viewModel.recentResults.count
    }

    private var wins: Int {
        viewModel.recentResults.filter { match in
            let isHome = match.homeClubId == viewModel.selectedClubId
            let myGoals = isHome ? match.homeScore : match.awayScore
            let theirGoals = isHome ? match.awayScore : match.homeScore
            return myGoals > theirGoals
        }.count
    }

    private var draws: Int {
        viewModel.recentResults.filter { match in
            match.homeScore == match.awayScore
        }.count
    }

    private var losses: Int {
        matchesPlayed - wins - draws
    }

    private var goalsScored: Int {
        viewModel.recentResults.reduce(0) { sum, match in
            let isHome = match.homeClubId == viewModel.selectedClubId
            return sum + (isHome ? match.homeScore : match.awayScore)
        }
    }

    private var goalsConceded: Int {
        viewModel.recentResults.reduce(0) { sum, match in
            let isHome = match.homeClubId == viewModel.selectedClubId
            return sum + (isHome ? match.awayScore : match.homeScore)
        }
    }

    private var winRate: Double {
        guard matchesPlayed > 0 else { return 0 }
        return Double(wins) / Double(matchesPlayed) * 100
    }

    private var topScorers: [Player] {
        viewModel.myPlayers
            .filter { $0.goals > 0 }
            .sorted { $0.goals > $1.goals }
    }

    private var topAssisters: [Player] {
        viewModel.myPlayers
            .filter { $0.assists > 0 }
            .sorted { $0.assists > $1.assists }
    }

    private var cleanSheets: Int {
        viewModel.recentResults.filter { match in
            let isHome = match.homeClubId == viewModel.selectedClubId
            return isHome ? match.awayScore == 0 : match.homeScore == 0
        }.count
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar

                ScrollView {
                    VStack(spacing: 12) {
                        overviewSection
                        recordSection
                        formSection
                        topScorersSection
                        topAssistersSection
                        squadOverviewSection
                    }
                    .padding(16)
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

            Text("MANAGER STATS")
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

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("SEASON OVERVIEW", icon: "chart.bar.fill", color: .green)

            HStack(spacing: 0) {
                statCard("Season", "\(viewModel.seasonYear)/\(viewModel.seasonYear + 1)", .white)
                statCard("Matches", "\(matchesPlayed)", .cyan)
                statCard("Win Rate", String(format: "%.0f%%", winRate), winRate >= 50 ? .green : .orange)
                statCard("GD", "\(goalsScored - goalsConceded > 0 ? "+" : "")\(goalsScored - goalsConceded)", goalsScored >= goalsConceded ? .green : .red)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var recordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("RECORD", icon: "trophy.fill", color: .yellow)

            HStack(spacing: 0) {
                statCard("Wins", "\(wins)", .green)
                statCard("Draws", "\(draws)", .yellow)
                statCard("Losses", "\(losses)", .red)
                statCard("Clean Sheets", "\(cleanSheets)", .blue)
            }

            HStack(spacing: 0) {
                statCard("Goals For", "\(goalsScored)", .cyan)
                statCard("Goals Against", "\(goalsConceded)", .orange)
                statCard("League Titles", "\(viewModel.managerLeagueTitles)", .yellow)
                statCard("Cup Wins", "\(viewModel.managerCupWins)", .purple)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("RECENT FORM", icon: "chart.line.uptrend.xyaxis", color: .cyan)

            HStack(spacing: 6) {
                ForEach(Array(viewModel.recentResults.prefix(10).enumerated()), id: \.offset) { _, match in
                    formBadge(for: match)
                }

                if viewModel.recentResults.isEmpty {
                    Text("No matches played yet")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func formBadge(for match: Match) -> some View {
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
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(color.opacity(0.8))
            .clipShape(.rect(cornerRadius: 4))
    }

    private var topScorersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("TOP SCORERS", icon: "soccerball", color: .orange)

            if topScorers.isEmpty {
                Text("No goals scored yet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                ForEach(Array(topScorers.prefix(5))) { player in
                    HStack {
                        Text(player.fullName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                        Text(player.position.rawValue)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        Text("\(player.goals) goals")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var topAssistersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("TOP ASSISTS", icon: "arrow.right.circle.fill", color: .cyan)

            if topAssisters.isEmpty {
                Text("No assists recorded yet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                ForEach(Array(topAssisters.prefix(5))) { player in
                    HStack {
                        Text(player.fullName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                        Text(player.position.rawValue)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        Text("\(player.assists) assists")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var squadOverviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("SQUAD OVERVIEW", icon: "person.3.fill", color: .purple)

            let squad = viewModel.myPlayers
            let avgAge = squad.isEmpty ? 0.0 : Double(squad.reduce(0) { $0 + $1.age }) / Double(squad.count)
            let avgOvr = squad.isEmpty ? 0.0 : Double(squad.reduce(0) { $0 + $1.stats.overall }) / Double(squad.count)
            let totalWage = squad.reduce(0) { $0 + $1.wage }
            let injured = squad.filter { $0.isInjured }.count

            HStack(spacing: 0) {
                statCard("Squad Size", "\(squad.count)", .white)
                statCard("Avg Age", String(format: "%.1f", avgAge), .cyan)
                statCard("Avg OVR", String(format: "%.0f", avgOvr), .green)
                statCard("Total Wages", viewModel.formatCurrency(totalWage), .orange)
            }

            HStack(spacing: 0) {
                statCard("Injured", "\(injured)", injured > 0 ? .red : .green)
                statCard("Budget", viewModel.formatCurrency(viewModel.selectedClub?.budget ?? 0), .green)
                Spacer()
                Spacer()
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
                .tracking(1)
        }
    }

    private func statCard(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
