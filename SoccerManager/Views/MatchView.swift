import SwiftUI

struct MatchView: View {
    @State var viewModel: GameViewModel
    @State private var currentMinute: Int = 0
    @State private var isPlaying: Bool = false
    @State private var displayedEvents: [MatchEvent] = []
    @State private var selectedTab: MatchTab = .overview
    @State private var simulationSpeed: SimulationSpeed = .normal
    @State private var hasStarted: Bool = false
    @State private var simulationTask: Task<Void, Never>?
    @State private var displayedHomeScore: Int = 0
    @State private var displayedAwayScore: Int = 0

    nonisolated enum MatchTab: String, CaseIterable, Sendable {
        case overview = "Overview"
        case stats = "Match Stats"
        case ratings = "Player Ratings"
    }

    nonisolated enum SimulationSpeed: Sendable {
        case normal   // 1x
        case fast     // 2x
        case veryFast // 4x

        var label: String {
            switch self {
            case .normal: return "1x"
            case .fast: return "2x"
            case .veryFast: return "4x"
            }
        }

        var millisPerMinute: Int {
            switch self {
            case .normal: return 500
            case .fast: return 250
            case .veryFast: return 100
            }
        }

        var next: SimulationSpeed {
            switch self {
            case .normal: return .fast
            case .fast: return .veryFast
            case .veryFast: return .normal
            }
        }
    }

    var match: Match? { viewModel.currentMatch }

    var body: some View {
        ZStack {
            if let match {
                VStack(spacing: 0) {
                    matchHeader(match)

                    HStack(spacing: 0) {
                        matchCenterPanel(match)
                        standingsSidePanel
                    }

                    matchBottomBar(match)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.06, blue: 0.08), ignoresSafeAreaEdges: .all)
    }

    private func matchHeader(_ match: Match) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(match.matchType.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.green)
                    .tracking(1)
            }

            Spacer()

            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text(match.homeClubName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                HStack(spacing: 8) {
                    Text("\(displayedHomeScore)")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("-")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("\(displayedAwayScore)")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 2) {
                    Text(match.awayClubName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(currentMinute)'")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(isPlaying ? .green : .white.opacity(0.5))

                Text(match.isPlayed ? "Full Time" : (isPlaying ? "Live" : "Not Started"))
                    .font(.system(size: 9))
                    .foregroundStyle(isPlaying ? .green : .white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color(white: 0.12), Color(white: 0.08)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    private func matchCenterPanel(_ match: Match) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(MatchTab.allCases, id: \.rawValue) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(selectedTab == tab ? .green : .white.opacity(0.4))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTab == tab ? Color.green.opacity(0.1) : .clear)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .background(Color(white: 0.07))

            ScrollView {
                switch selectedTab {
                case .overview:
                    overviewTab(match)
                case .stats:
                    statsTab(match)
                case .ratings:
                    ratingsTab(match)
                }
            }
        }
    }

    private func overviewTab(_ match: Match) -> some View {
        VStack(spacing: 8) {
            ForEach(displayedEvents) { event in
                eventRow(event, match: match)
            }

            if match.isPlayed && displayedEvents.isEmpty {
                ForEach(match.events) { event in
                    eventRow(event, match: match)
                }
            }

            if !hasStarted && displayedEvents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.1))
                    Text("Press Simulate Match to start")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.top, 40)
            }
        }
        .padding(12)
    }

    private func statsTab(_ match: Match) -> some View {
        VStack(spacing: 8) {
            statBar("Possession", home: match.homePossession, away: match.awayPossession, isPercentage: true)
            statBar("Shots", home: match.homeShots, away: match.awayShots)
            statBar("Shots on Target", home: match.homeShotsOnTarget, away: match.awayShotsOnTarget)
        }
        .padding(12)
    }

    private func ratingsTab(_ match: Match) -> some View {
        VStack(spacing: 4) {
            let homePlayers = viewModel.players.filter { $0.clubId == match.homeClubId }.prefix(11)
            let awayPlayers = viewModel.players.filter { $0.clubId == match.awayClubId }.prefix(11)

            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 3) {
                    Text(match.homeClubName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                    ForEach(Array(homePlayers)) { player in
                        HStack {
                            Text(player.fullName)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                            Spacer()
                            let rating = match.playerRatings[player.id] ?? 6.0
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(ratingColor(rating))
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 3) {
                    Text(match.awayClubName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                    ForEach(Array(awayPlayers)) { player in
                        HStack {
                            Text(player.fullName)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                            Spacer()
                            let rating = match.playerRatings[player.id] ?? 6.0
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(ratingColor(rating))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
    }

    private func ratingColor(_ rating: Double) -> Color {
        if rating >= 8.0 { return .green }
        if rating >= 6.5 { return .yellow }
        if rating >= 5.0 { return .orange }
        return .red
    }

    private var standingsSidePanel: some View {
        VStack(spacing: 0) {
            Text("STANDINGS")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.yellow)
                .tracking(1)
                .padding(.vertical, 6)

            ScrollView {
                VStack(spacing: 2) {
                    HStack(spacing: 0) {
                        Text("#").frame(width: 16, alignment: .center)
                        Text("Team").frame(maxWidth: .infinity, alignment: .leading)
                        Text("P").frame(width: 20)
                        Text("Pts").frame(width: 24)
                    }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.horizontal, 6)

                    ForEach(Array(viewModel.currentLeagueStandings.enumerated()), id: \.element.id) { idx, entry in
                        HStack(spacing: 0) {
                            Text("\(idx + 1)")
                                .frame(width: 16, alignment: .center)
                            Text(entry.clubName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            Text("\(entry.played)")
                                .frame(width: 20)
                            Text("\(entry.points)")
                                .fontWeight(.bold)
                                .frame(width: 24)
                        }
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(entry.clubId == viewModel.selectedClubId ? .green : .white.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(entry.clubId == viewModel.selectedClubId ? Color.green.opacity(0.08) : .clear)
                    }
                }
            }
        }
        .frame(width: 180)
        .background(Color(white: 0.06))
    }

    private func matchBottomBar(_ match: Match) -> some View {
        HStack {
            if !match.isPlayed && !hasStarted {
                // Not started yet — show Simulate Match
                Button {
                    startSimulation(match)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("Simulate Match")
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(.capsule)
                }
            } else if isPlaying {
                // Simulating — show speed toggle + skip to end
                Button {
                    simulationSpeed = simulationSpeed.next
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.medium")
                        Text(simulationSpeed.label)
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cyan)
                    .clipShape(.capsule)
                }

                Button {
                    skipToEnd(match)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.end.fill")
                        Text("Skip to End")
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .clipShape(.capsule)
                }
            } else if match.isPlayed {
                // Match ended — show Continue
                Button {
                    viewModel.continueFromResult()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                        Text("Continue")
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(.capsule)
                }
            }

            Spacer()

            if isPlaying {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.red)
                    Text("Speed: \(simulationSpeed.label)")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                }
            } else if match.isPlayed {
                Text("Full Time")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(white: 0.08))
    }

    private func startSimulation(_ match: Match) {
        hasStarted = true
        isPlaying = true
        currentMinute = 0
        displayedEvents = []
        displayedHomeScore = 0
        displayedAwayScore = 0

        // Pre-compute the match result
        viewModel.simulateMatch(match)
        let allEvents = match.events.sorted { $0.minute < $1.minute }

        // Animate progressively
        simulationTask = Task {
            for minute in 1...90 {
                let ms = simulationSpeed.millisPerMinute
                try? await Task.sleep(for: .milliseconds(ms))
                if Task.isCancelled { return }
                currentMinute = minute
                let newEvents = allEvents.filter { $0.minute == minute }
                for event in newEvents {
                    displayedEvents.append(event)
                    if event.type == .goal {
                        if event.isHome {
                            displayedHomeScore += 1
                        } else {
                            displayedAwayScore += 1
                        }
                    }
                }
            }
            // Simulation finished
            isPlaying = false
            displayedHomeScore = match.homeScore
            displayedAwayScore = match.awayScore
        }
    }

    private func skipToEnd(_ match: Match) {
        simulationTask?.cancel()
        simulationTask = nil
        isPlaying = false
        currentMinute = 90
        displayedEvents = match.events.sorted { $0.minute < $1.minute }
        displayedHomeScore = match.homeScore
        displayedAwayScore = match.awayScore
    }

    private func eventRow(_ event: MatchEvent, match: Match) -> some View {
        HStack(spacing: 8) {
            if event.isHome {
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(event.playerName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                    if let assist = event.assistPlayerName {
                        Text("Assist: \(assist)")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                eventIcon(event.type)
                Text("\(event.minute)'")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 30)
            } else {
                Text("\(event.minute)'")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 30)
                eventIcon(event.type)
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.playerName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                    if let assist = event.assistPlayerName {
                        Text("Assist: \(assist)")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func eventIcon(_ type: MatchEventType) -> some View {
        Group {
            switch type {
            case .goal:
                Image(systemName: "soccerball")
                    .foregroundStyle(.white)
            case .ownGoal:
                Image(systemName: "soccerball")
                    .foregroundStyle(.red)
            case .yellowCard:
                RoundedRectangle(cornerRadius: 1)
                    .fill(.yellow)
                    .frame(width: 8, height: 12)
            case .redCard:
                RoundedRectangle(cornerRadius: 1)
                    .fill(.red)
                    .frame(width: 8, height: 12)
            case .injury:
                Image(systemName: "cross.fill")
                    .foregroundStyle(.red)
            case .substitution:
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(.cyan)
            case .penalty:
                Image(systemName: "soccerball")
                    .foregroundStyle(.green)
            case .penaltyMiss:
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.red)
            }
        }
        .font(.system(size: 12))
    }

    private func statBar(_ label: String, home: Int, away: Int, isPercentage: Bool = false) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("\(home)\(isPercentage ? "%" : "")")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(away)\(isPercentage ? "%" : "")")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            GeometryReader { geo in
                let total = max(home + away, 1)
                let homeWidth = geo.size.width * CGFloat(home) / CGFloat(total)
                HStack(spacing: 2) {
                    Capsule()
                        .fill(Color.green)
                        .frame(width: homeWidth, height: 4)
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}
