import SwiftUI

struct MainDashboardView: View {
    @State var viewModel: GameViewModel

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM yyyy"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            HStack(spacing: 12) {
                leftColumn
                centerColumn
                rightColumn
            }
            .padding(12)
            .frame(maxHeight: .infinity)
        }
        .background(Color(red: 0.06, green: 0.08, blue: 0.1), ignoresSafeAreaEdges: .all)
    }

    private var topBar: some View {
        HStack {
            if let club = viewModel.selectedClub {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Text(club.shortName)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.green)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(club.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text(viewModel.leagueName(for: club))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            Spacer()

            Text(dateFormatter.string(from: viewModel.currentDate))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            HStack(spacing: 12) {
                if let club = viewModel.selectedClub {
                    Label(viewModel.formatCurrency(club.budget), systemImage: "banknote")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("\(viewModel.selectedClub?.rating ?? 0)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color(white: 0.1))
    }

    private var leftColumn: some View {
        VStack(spacing: 10) {
            nextMatchCard
            upcomingFixturesCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var centerColumn: some View {
        VStack(spacing: 10) {
            teamInfoCard
            transfersCard
            competitionsCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var rightColumn: some View {
        VStack(spacing: 10) {
            mailCard
            quickActionsGrid
            newsCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var nextMatchCard: some View {
        DashboardCard(title: "NEXT MATCH", icon: "sportscourt.fill", accentColor: .green) {
            if let match = viewModel.nextMatch {
                VStack(spacing: 10) {
                    Button {
                        viewModel.currentScreen = .rivalSquad
                    } label: {
                        VStack(spacing: 10) {
                            HStack {
                                Text(match.matchType.rawValue)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .textCase(.uppercase)
                                Spacer()
                                Text(matchDateString(match.date))
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.4))
                            }

                            HStack(spacing: 16) {
                                VStack(spacing: 6) {
                                    clubBadge(match.homeClubName)
                                    Text(match.homeClubName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)

                                Text("vs")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white.opacity(0.4))

                                VStack(spacing: 6) {
                                    clubBadge(match.awayClubName)
                                    Text(match.awayClubName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if viewModel.isMatchDay && viewModel.todayMatch?.id == match.id {
                        Button {
                            viewModel.playMatch(match)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sportscourt.fill")
                                    .font(.system(size: 10))
                                Text("Play Match")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .clipShape(.rect(cornerRadius: 8))
                        }
                    } else {
                        Button {
                            viewModel.advanceToMatchDay()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 9))
                                Text("Skip to Match Day")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.85))
                            .clipShape(.rect(cornerRadius: 8))
                        }
                    }
                }
            } else {
                Text("No upcoming matches")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var upcomingFixturesCard: some View {
        Button {
            viewModel.currentScreen = .calendar
        } label: {
            DashboardCard(title: "UPCOMING", icon: "calendar", accentColor: .blue, expandVertically: true) {
                VStack(spacing: 4) {
                    ForEach(Array(viewModel.upcomingFixtures.prefix(6))) { match in
                        HStack(spacing: 6) {
                            Text(matchDateString(match.date))
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.35))
                                .frame(width: 50, alignment: .leading)
                            Text(match.matchType.rawValue)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.blue)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            Text(upcomingRivalLabel(match))
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                            Spacer()
                            Text(match.homeClubId == viewModel.selectedClubId ? "H" : "A")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(match.homeClubId == viewModel.selectedClubId ? .green.opacity(0.7) : .orange.opacity(0.7))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var teamInfoCard: some View {
        Button {
            viewModel.currentScreen = .squad
        } label: {
            DashboardCard(title: "TEAM", icon: "person.3.fill", accentColor: .cyan) {
                if let club = viewModel.selectedClub {
                    VStack(spacing: 4) {
                        infoRow("Squad Size", "\(viewModel.myPlayers.count)")
                        infoRow("Formation", club.formation)
                        infoRow("Rating", "\(club.rating)")
                        infoRow("Stadium", club.stadiumName)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var transfersCard: some View {
        Button {
            viewModel.currentScreen = .transfers
        } label: {
            DashboardCard(title: "TRANSFERS", icon: "arrow.left.arrow.right", accentColor: .orange) {
                VStack(spacing: 4) {
                    if let club = viewModel.selectedClub {
                        infoRow("Funds", viewModel.formatCurrency(club.budget))
                        infoRow("Window", viewModel.transferWindow.label)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var competitionsCard: some View {
        Button {
            viewModel.currentScreen = .standings
        } label: {
            DashboardCard(title: "STANDINGS", icon: "trophy.fill", accentColor: .yellow, expandVertically: true) {
                VStack(spacing: 1) {
                    ForEach(Array(viewModel.currentLeagueStandings.prefix(7).enumerated()), id: \.element.id) { idx, entry in
                        HStack {
                            Text("\(idx + 1).")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .frame(width: 16, alignment: .trailing)
                            Text(entry.clubName)
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .foregroundStyle(entry.clubId == viewModel.selectedClubId ? .green : .white.opacity(0.7))
                            Spacer()
                            Text("\(entry.points) pts")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxHeight: .infinity)
    }

    private var mailCard: some View {
        Button {
            viewModel.currentScreen = .mail
        } label: {
            DashboardCard(title: "MAIL", icon: "envelope.fill", accentColor: .orange) {
                VStack(spacing: 3) {
                    if viewModel.mailMessages.isEmpty {
                        Text("No mail")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                    } else {
                        ForEach(Array(viewModel.mailMessages.prefix(3))) { mail in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(mail.isRead ? Color.clear : Color.orange)
                                    .frame(width: 5, height: 5)
                                Image(systemName: mail.category.icon)
                                    .font(.system(size: 8))
                                    .foregroundStyle(mail.isRead ? .white.opacity(0.3) : .orange)
                                Text(mail.subject)
                                    .font(.system(size: 9, weight: mail.isRead ? .regular : .bold))
                                    .foregroundStyle(mail.isRead ? .white.opacity(0.4) : .white)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if viewModel.unreadMailCount > 0 {
                Text("\(viewModel.unreadMailCount)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(.capsule)
                    .offset(x: -6, y: 6)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var managerCard: some View {
        Button {
            viewModel.currentScreen = .managerStats
        } label: {
            DashboardCard(title: "MANAGER", icon: "person.fill", accentColor: .purple) {
                VStack(spacing: 4) {
                    infoRow("League Titles", "\(viewModel.managerLeagueTitles)")
                    infoRow("Cup Wins", "\(viewModel.managerCupWins)")
                    infoRow("Season", "\(viewModel.seasonYear)/\(viewModel.seasonYear + 1)")
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            quickActionButton("Manager", icon: "person.fill", color: .purple) {
                viewModel.currentScreen = .managerStats
            }
            quickActionButton("Tactics", icon: "arrow.triangle.branch", color: .orange) {
                viewModel.currentScreen = .tactics
            }
            quickActionButton("Academy", icon: "graduationcap.fill", color: .purple) {
                viewModel.currentScreen = .youthAcademy
            }
            quickActionButton("Calendar", icon: "calendar", color: .blue) {
                viewModel.currentScreen = .calendar
            }
        }
    }

    private var newsCard: some View {
        VStack(spacing: 0) {
            if viewModel.isMatchDay {
                Button {
                    if let match = viewModel.todayMatch {
                        viewModel.playMatch(match)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sportscourt.fill")
                            .font(.caption2)
                        Text("Play Match")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.orange)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    viewModel.advanceDay()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.caption2)
                        Text("Next Day")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.green)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }

    private var bottomBar: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.newsMessages.prefix(5).enumerated()), id: \.offset) { _, msg in
                        Text(msg)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            if viewModel.isMatchDay {
                Button {
                    if let match = viewModel.todayMatch {
                        viewModel.playMatch(match)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sportscourt.fill")
                            .font(.caption2)
                        Text("Play Match")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .clipShape(.capsule)
                }
                .padding(.trailing, 12)
            } else {
                Button {
                    viewModel.advanceDay()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.caption2)
                        Text("Next Day")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(.capsule)
                }
                .padding(.trailing, 12)
            }
        }
        .padding(.vertical, 6)
        .background(Color(white: 0.08))
    }

    private func clubBadge(_ name: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 28, height: 28)
            Text(String(name.prefix(2)).uppercased())
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func upcomingRivalLabel(_ match: Match) -> String {
        let isHome = match.homeClubId == viewModel.selectedClubId
        let rival = isHome ? match.awayClubName : match.homeClubName
        return "vs \(rival)"
    }

    private func matchDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
    }

    private func quickActionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.1))
            .clipShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    var expandVertically: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accentColor)
                    .tracking(1)
            }

            content()

            if expandVertically {
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: expandVertically ? .infinity : nil, alignment: .topLeading)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
    }
}
