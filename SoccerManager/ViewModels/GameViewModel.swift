import Foundation
import SwiftUI

nonisolated enum GameScreen: Sendable {
    case teamSelection
    case dashboard
    case squad
    case match
    case transfers
    case calendar
    case standings
    case youthAcademy
    case clubInfo
    case tactics
    case matchResult
    case rivalSquad
    case managerStats
}

nonisolated enum TransferWindowStatus: Sendable {
    case open
    case closed

    var label: String {
        switch self {
        case .open: return "Open"
        case .closed: return "Closed"
        }
    }
}

@Observable
class GameViewModel {
    var currentScreen: GameScreen = .teamSelection
    var leagues: [League] = []
    var clubs: [Club] = []
    var players: [Player] = []
    var selectedClubId: UUID?
    var currentDate: Date = GameViewModel.seasonStartDate()
    var currentWeek: Int = 0
    var seasonFixtures: [Match] = []
    var cupFixtures: [Match] = []
    var friendlyFixtures: [Match] = []
    var standings: [UUID: [StandingsEntry]] = [:]
    var newsMessages: [String] = ["Welcome to your new club!"]
    var currentMatch: Match?
    var matchSpeed: Double = 1.0
    var isSimulating: Bool = false
    var seasonYear: Int = 2025
    var managerLeagueTitles: Int = 0
    var managerCupWins: Int = 0

    var selectedClub: Club? {
        clubs.first { $0.id == selectedClubId }
    }

    var myPlayers: [Player] {
        guard let clubId = selectedClubId else { return [] }
        return players.filter { $0.clubId == clubId }
    }

    var rivalClubId: UUID? {
        guard let match = nextMatch else { return nil }
        return match.homeClubId == selectedClubId ? match.awayClubId : match.homeClubId
    }

    var rivalClub: Club? {
        guard let rivalId = rivalClubId else { return nil }
        return clubs.first { $0.id == rivalId }
    }

    var rivalPlayers: [Player] {
        guard let rivalId = rivalClubId else { return [] }
        return players.filter { $0.clubId == rivalId }
    }

    var nextMatch: Match? {
        let allFixtures = seasonFixtures + cupFixtures + friendlyFixtures
        return allFixtures
            .filter { !$0.isPlayed && ($0.homeClubId == selectedClubId || $0.awayClubId == selectedClubId) }
            .sorted { $0.date < $1.date }
            .first
    }

    var upcomingFixtures: [Match] {
        let allFixtures = seasonFixtures + cupFixtures + friendlyFixtures
        return allFixtures
            .filter { !$0.isPlayed && ($0.homeClubId == selectedClubId || $0.awayClubId == selectedClubId) }
            .sorted { $0.date < $1.date }
    }

    var recentResults: [Match] {
        let allFixtures = seasonFixtures + cupFixtures + friendlyFixtures
        return allFixtures
            .filter { $0.isPlayed && ($0.homeClubId == selectedClubId || $0.awayClubId == selectedClubId) }
            .sorted { $0.date > $1.date }
    }

    var transferWindow: TransferWindowStatus {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        if (month == 1) || (month >= 6 && month <= 8) {
            return .open
        }
        return .closed
    }

    var currentLeagueStandings: [StandingsEntry] {
        guard let club = selectedClub else { return [] }
        return (standings[club.leagueId] ?? [])
            .sorted { ($0.points, $0.goalDifference, $0.goalsFor) > ($1.points, $1.goalDifference, $1.goalsFor) }
    }

    var freeAgents: [Player] {
        players.filter { $0.clubId == nil }
    }

    /// The player's next unplayed match that falls on today's date
    var todayMatch: Match? {
        let cal = Calendar.current
        let allFixtures = seasonFixtures + cupFixtures + friendlyFixtures
        return allFixtures.first {
            !$0.isPlayed
            && ($0.homeClubId == selectedClubId || $0.awayClubId == selectedClubId)
            && cal.isDate($0.date, inSameDayAs: currentDate)
        }
    }

    /// True when there is an unplayed match on the current date
    var isMatchDay: Bool { todayMatch != nil }

    /// True when the player can press Continue (no unplayed match blocking)
    var canAdvance: Bool { !isMatchDay }

    static func seasonStartDate() -> Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 7
        components.day = 1
        return Calendar.current.date(from: components)!
    }

    func startNewGame(clubId: UUID) {
        selectedClubId = clubId
        generateFriendlies()
        generateSeasonSchedule()
        initializeStandings()
        generateFreeAgents()
        currentScreen = .dashboard
        newsMessages = ["You've been appointed as the new manager! Good luck!"]
    }

    func initializeStandings() {
        standings = [:]
        for league in leagues {
            let leagueClubs = clubs.filter { $0.leagueId == league.id }
            standings[league.id] = leagueClubs.map { StandingsEntry(clubId: $0.id, clubName: $0.name) }
        }
    }

    func generateFreeAgents() {
        for _ in 0..<40 {
            let pos = PlayerPosition.allCases.randomElement()!
            let quality = Int.random(in: 30...70)
            let player = GameDataGenerator.generatePlayer(clubId: nil, position: pos, quality: quality)
            player.contractYearsLeft = 0
            players.append(player)
        }
    }

    func generateFriendlies() {
        guard let clubId = selectedClubId, let club = selectedClub else { return }
        let opponents = clubs.filter { $0.id != clubId }.shuffled().prefix(3)
        var date = currentDate
        for opponent in opponents {
            date = Calendar.current.date(byAdding: .day, value: 7, to: date)!
            let match = Match(
                homeClubId: Bool.random() ? clubId : opponent.id,
                awayClubId: Bool.random() ? opponent.id : clubId,
                homeClubName: Bool.random() ? club.name : opponent.name,
                awayClubName: Bool.random() ? opponent.name : club.name,
                matchType: .friendly,
                date: date
            )
            if match.homeClubId == clubId {
                match.homeClubName = club.name
                match.awayClubName = opponent.name
                match.awayClubId = opponent.id
            } else {
                match.homeClubName = opponent.name
                match.homeClubId = opponent.id
                match.awayClubName = club.name
                match.awayClubId = clubId
            }
            friendlyFixtures.append(match)
        }
    }

    // MARK: - Season Schedule Generation

    /// Generates all league fixtures + cup R16 on a unified, realistic calendar.
    /// - League matchdays every 4-5 days when no cup is scheduled
    /// - Cup rounds interleaved: League → 3 days → Cup → 4 days → League
    /// - All leagues share the same matchday dates
    func generateSeasonSchedule() {
        let cal = Calendar.current
        let seasonStart = cal.date(byAdding: .month, value: 1, to: currentDate)!

        // ---------- 1. Round-robin pairings per league ----------

        struct LeagueRounds {
            let league: League
            let clubs: [Club]
            let rounds: [[(home: Int, away: Int)]]
        }

        var allLeagueRounds: [LeagueRounds] = []

        for league in leagues {
            let leagueClubs = clubs.filter { $0.leagueId == league.id }.shuffled()
            let n = leagueClubs.count
            guard n >= 2 else { continue }

            let hasBye = n % 2 != 0
            let teamCount = hasBye ? n + 1 : n
            let roundsPerHalf = teamCount - 1
            let matchesPerRound = teamCount / 2

            // Circle-method rotation
            var halfRounds: [[(Int, Int)]] = []
            var rotatable = Array(1..<teamCount)

            for _ in 0..<roundsPerHalf {
                var pairings: [(Int, Int)] = []
                pairings.append((0, rotatable[rotatable.count - 1]))
                for m in 0..<(matchesPerRound - 1) {
                    pairings.append((rotatable[m], rotatable[rotatable.count - 2 - m]))
                }
                halfRounds.append(pairings)
                let last = rotatable.removeLast()
                rotatable.insert(last, at: 0)
            }

            // Full season: first half + second half (home/away swapped)
            var fullRounds: [[(Int, Int)]] = []
            for r in halfRounds { fullRounds.append(r) }
            for r in halfRounds { fullRounds.append(r.map { ($0.1, $0.0) }) }

            allLeagueRounds.append(LeagueRounds(
                league: league, clubs: leagueClubs, rounds: fullRounds
            ))
        }

        // ---------- 2. Cup R16 pairings ----------

        var cupR16Pairs: [(home: Club, away: Club)] = []
        if let playerClub = selectedClub,
           let playerLeague = leagues.first(where: { $0.id == playerClub.leagueId }),
           playerLeague.hasNationalCup {
            let leagueClubs = clubs.filter { $0.leagueId == playerLeague.id }.shuffled()
            var roundClubs = Array(leagueClubs.prefix(16))
            if !roundClubs.contains(where: { $0.id == playerClub.id }) {
                roundClubs[roundClubs.count - 1] = playerClub
            }
            for i in stride(from: 0, to: roundClubs.count - 1, by: 2) {
                cupR16Pairs.append((home: roundClubs[i], away: roundClubs[i + 1]))
            }
        }

        // ---------- 3. Walk the calendar and assign dates ----------

        let totalMatchdays = allLeagueRounds.map { $0.rounds.count }.max() ?? 0
        guard totalMatchdays > 0 else { return }

        // Cup R16 inserted after this league matchday
        let cupR16Slot = 8

        var cursor = seasonStart

        for md in 1...totalMatchdays {
            // Create league matches for every league on this date
            for data in allLeagueRounds {
                let idx = md - 1
                guard idx < data.rounds.count else { continue }
                let n = data.clubs.count

                for (homeIdx, awayIdx) in data.rounds[idx] {
                    guard homeIdx < n && awayIdx < n else { continue }
                    let homeClub = data.clubs[homeIdx]
                    let awayClub = data.clubs[awayIdx]

                    let match = Match(
                        homeClubId: homeClub.id,
                        awayClubId: awayClub.id,
                        homeClubName: homeClub.name,
                        awayClubName: awayClub.name,
                        matchType: .league,
                        date: cursor,
                        leagueId: data.league.id,
                        matchday: md
                    )
                    seasonFixtures.append(match)
                }
            }

            // Check if cup round follows this matchday
            if md == cupR16Slot && !cupR16Pairs.isEmpty {
                // League → 3 days → Cup
                cursor = cal.date(byAdding: .day, value: 3, to: cursor)!

                for (home, away) in cupR16Pairs {
                    let match = Match(
                        homeClubId: home.id,
                        awayClubId: away.id,
                        homeClubName: home.name,
                        awayClubName: away.name,
                        matchType: .nationalCup,
                        date: cursor
                    )
                    cupFixtures.append(match)
                }

                // Cup → 4 days → next League
                cursor = cal.date(byAdding: .day, value: 4, to: cursor)!
            } else {
                // Normal gap between league matchdays: 4-5 days
                cursor = cal.date(byAdding: .day, value: Int.random(in: 4...5), to: cursor)!
            }
        }

        seasonFixtures.sort { $0.date < $1.date }
    }

    func simulateMatch(_ match: Match, updateStandingsNow: Bool = true) {
        let homeClub = clubs.first { $0.id == match.homeClubId }
        let awayClub = clubs.first { $0.id == match.awayClubId }
        let homeRating = Double(homeClub?.rating ?? 50)
        let awayRating = Double(awayClub?.rating ?? 50)

        let homePlayers = players.filter { $0.clubId == match.homeClubId && !$0.isInjured }
        let awayPlayers = players.filter { $0.clubId == match.awayClubId && !$0.isInjured }

        let homeStrength = homeRating + Double.random(in: -15...15) + 3
        let awayStrength = awayRating + Double.random(in: -15...15)

        let totalStrength = max(homeStrength + awayStrength, 1.0)
        match.homePossession = min(100, max(0, Int(homeStrength / totalStrength * 100)))
        match.awayPossession = 100 - match.homePossession

        let homeExpectedGoals = max(0, (homeStrength - 30) / 20)
        let awayExpectedGoals = max(0, (awayStrength - 30) / 20)

        match.homeShots = Int.random(in: 5...20)
        match.awayShots = Int.random(in: 5...20)
        match.homeShotsOnTarget = Int.random(in: 2...match.homeShots)
        match.awayShotsOnTarget = Int.random(in: 2...match.awayShots)

        var events: [MatchEvent] = []

        let homeGoals = poissonRandom(lambda: homeExpectedGoals)
        let awayGoals = poissonRandom(lambda: awayExpectedGoals)

        for _ in 0..<homeGoals {
            let minute = Int.random(in: 1...90)
            let scorerName = homePlayers.filter { $0.position.isForward || $0.position.isMidfielder }.randomElement()?.fullName
                ?? homePlayers.randomElement()?.fullName ?? "Unknown"
            let assistName = homePlayers.filter { $0.fullName != scorerName }.randomElement()?.fullName
            events.append(MatchEvent(minute: minute, type: .goal, playerName: scorerName, isHome: true, assistPlayerName: assistName))
            match.homeScore += 1

            if let scorer = homePlayers.first(where: { $0.fullName == scorerName }) {
                scorer.goals += 1
                scorer.matchesPlayed += 1
            }
            if let assister = homePlayers.first(where: { $0.fullName == assistName }) {
                assister.assists += 1
            }
        }

        for _ in 0..<awayGoals {
            let minute = Int.random(in: 1...90)
            let scorerName = awayPlayers.filter { $0.position.isForward || $0.position.isMidfielder }.randomElement()?.fullName
                ?? awayPlayers.randomElement()?.fullName ?? "Unknown"
            let assistName = awayPlayers.filter { $0.fullName != scorerName }.randomElement()?.fullName
            events.append(MatchEvent(minute: minute, type: .goal, playerName: scorerName, isHome: false, assistPlayerName: assistName))
            match.awayScore += 1

            if let scorer = awayPlayers.first(where: { $0.fullName == scorerName }) {
                scorer.goals += 1
                scorer.matchesPlayed += 1
            }
            if let assister = awayPlayers.first(where: { $0.fullName == assistName }) {
                assister.assists += 1
            }
        }

        let cardCount = Int.random(in: 0...6)
        for _ in 0..<cardCount {
            let isHome = Bool.random()
            let pool = isHome ? homePlayers : awayPlayers
            guard let p = pool.randomElement() else { continue }
            let minute = Int.random(in: 1...90)
            let isRed = Double.random(in: 0...1) < 0.05
            events.append(MatchEvent(minute: minute, type: isRed ? .redCard : .yellowCard, playerName: p.fullName, isHome: isHome))
            if isRed { p.redCards += 1 } else { p.yellowCards += 1 }
        }

        match.events = events.sorted { $0.minute < $1.minute }
        match.isPlayed = true

        // Generate persisted player ratings
        var ratings: [UUID: Double] = [:]
        for player in homePlayers.prefix(11) {
            let baseRating = Double(player.stats.overall) / 15.0 + 3.0
            ratings[player.id] = min(10.0, max(1.0, baseRating + Double.random(in: -1.5...1.5)))
        }
        for player in awayPlayers.prefix(11) {
            let baseRating = Double(player.stats.overall) / 15.0 + 3.0
            ratings[player.id] = min(10.0, max(1.0, baseRating + Double.random(in: -1.5...1.5)))
        }
        // Boost scorers' ratings
        for event in match.events where event.type == .goal {
            let scorerPool = event.isHome ? homePlayers : awayPlayers
            if let scorer = scorerPool.first(where: { $0.fullName == event.playerName }) {
                ratings[scorer.id] = min(10.0, (ratings[scorer.id] ?? 7.0) + 0.5)
            }
        }
        match.playerRatings = ratings

        if updateStandingsNow, match.matchType == .league, let leagueId = match.leagueId {
            updateStandings(leagueId: leagueId, match: match)
        }
    }

    func finalizeMatchStandings(_ match: Match) {
        if match.matchType == .league, let leagueId = match.leagueId {
            updateStandings(leagueId: leagueId, match: match)
        }
    }

    func updateStandings(leagueId: UUID, match: Match) {
        guard var leagueStandings = standings[leagueId] else { return }

        if let homeIdx = leagueStandings.firstIndex(where: { $0.clubId == match.homeClubId }) {
            leagueStandings[homeIdx].played += 1
            leagueStandings[homeIdx].goalsFor += match.homeScore
            leagueStandings[homeIdx].goalsAgainst += match.awayScore
            if match.homeScore > match.awayScore {
                leagueStandings[homeIdx].won += 1
            } else if match.homeScore == match.awayScore {
                leagueStandings[homeIdx].drawn += 1
            } else {
                leagueStandings[homeIdx].lost += 1
            }
        }

        if let awayIdx = leagueStandings.firstIndex(where: { $0.clubId == match.awayClubId }) {
            leagueStandings[awayIdx].played += 1
            leagueStandings[awayIdx].goalsFor += match.awayScore
            leagueStandings[awayIdx].goalsAgainst += match.homeScore
            if match.awayScore > match.homeScore {
                leagueStandings[awayIdx].won += 1
            } else if match.awayScore == match.homeScore {
                leagueStandings[awayIdx].drawn += 1
            } else {
                leagueStandings[awayIdx].lost += 1
            }
        }

        standings[leagueId] = leagueStandings
    }

    private var dayCounter: Int = 0

    func advanceDay() {
        // Block if there's an unplayed match today
        guard canAdvance else { return }

        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        dayCounter += 1

        // Simulate AI matches that happened on the new date (or earlier, if missed)
        let cal = Calendar.current
        let allFixtures = seasonFixtures + cupFixtures + friendlyFixtures
        let todayAIMatches = allFixtures.filter {
            !$0.isPlayed
            && $0.homeClubId != selectedClubId
            && $0.awayClubId != selectedClubId
            && cal.isDate($0.date, inSameDayAs: currentDate)
        }
        for match in todayAIMatches {
            simulateMatch(match)
        }

        // Weekly events (every 7 days)
        if dayCounter % 7 == 0 {
            currentWeek += 1
            handleInjuries()
        }

        // Training every ~28 days
        if dayCounter % 28 == 0 {
            applyTraining()
        }

        // Youth academy every ~84 days
        if dayCounter % 84 == 0 {
            checkYouthAcademy()
        }
    }

    func playMatch(_ match: Match) {
        currentMatch = match
        currentScreen = .match
    }

    func finishMatchAndReturn() {
        guard let match = currentMatch else { return }
        simulateMatch(match)

        // Simulate all other matches on the same date (all leagues play together)
        let cal = Calendar.current
        let allFixtures = seasonFixtures + cupFixtures + friendlyFixtures
        let sameDayMatches = allFixtures.filter {
            !$0.isPlayed
            && $0.id != match.id
            && cal.isDate($0.date, inSameDayAs: match.date)
        }
        for m in sameDayMatches {
            simulateMatch(m)
        }

        currentScreen = .matchResult
    }

    func continueFromResult() {
        // Simulate all other matches on the same date (all leagues play together)
        if let match = currentMatch {
            let cal = Calendar.current
            let allFixtures = seasonFixtures + cupFixtures + friendlyFixtures
            let sameDayMatches = allFixtures.filter {
                !$0.isPlayed
                && $0.id != match.id
                && cal.isDate($0.date, inSameDayAs: match.date)
            }
            for m in sameDayMatches {
                simulateMatch(m)
            }
        }
        currentMatch = nil
        currentScreen = .dashboard
    }

    func applyTraining() {
        guard let clubId = selectedClubId, let club = selectedClub else { return }
        let mySquad = players.filter { $0.clubId == clubId }
        for player in mySquad {
            let chance = Double.random(in: 0...1)
            if chance < 0.3 * club.trainingBoost && player.age < 30 {
                let boost = Int.random(in: 1...2)
                player.stats.overall = min(player.potentialPeak, player.stats.overall + boost)
                let statToBoost = Int.random(in: 0...2)
                switch statToBoost {
                case 0: player.stats.offensive = min(99, player.stats.offensive + boost)
                case 1: player.stats.defensive = min(99, player.stats.defensive + boost)
                default: player.stats.physical = min(99, player.stats.physical + boost)
                }
            }
        }
    }

    func checkYouthAcademy() {
        guard let clubId = selectedClubId, let club = selectedClub else { return }
        let shouldGenerate = Double.random(in: 0...1) < Double(club.playersPerYear) * 0.25
        if shouldGenerate {
            let position = PlayerPosition.allCases.randomElement()!
            let quality = club.academyBaseQuality + Int.random(in: -5...10)
            let player = GameDataGenerator.generatePlayer(clubId: clubId, position: position, quality: quality)
            player.age = Int.random(in: 16...19)
            player.contractYearsLeft = 3
            players.append(player)
            newsMessages.insert("Youth academy produced: \(player.fullName) (\(player.position.rawValue), \(player.stats.overall) OVR)", at: 0)
        }
    }

    func handleInjuries() {
        guard let clubId = selectedClubId else { return }
        let mySquad = players.filter { $0.clubId == clubId }
        for player in mySquad {
            if player.isInjured {
                player.injuryWeeksLeft -= 1
                if player.injuryWeeksLeft <= 0 {
                    player.isInjured = false
                    newsMessages.insert("\(player.fullName) has recovered from injury!", at: 0)
                }
            } else {
                if Double.random(in: 0...1) < 0.02 {
                    player.isInjured = true
                    player.injuryWeeksLeft = Int.random(in: 1...8)
                    newsMessages.insert("\(player.fullName) is injured for \(player.injuryWeeksLeft) weeks!", at: 0)
                }
            }
        }
    }

    func buyPlayer(_ player: Player, fee: Int) -> Bool {
        guard let club = selectedClub else { return false }
        guard club.budget >= fee else { return false }
        club.budget -= fee
        if let oldClubId = player.clubId, let oldClub = clubs.first(where: { $0.id == oldClubId }) {
            oldClub.budget += fee
        }
        player.clubId = selectedClubId
        player.contractYearsLeft = Int.random(in: 2...5)
        newsMessages.insert("Signed \(player.fullName) for \(formatCurrency(fee))!", at: 0)
        return true
    }

    func sellPlayer(_ player: Player, fee: Int) {
        guard let club = selectedClub else { return }
        club.budget += fee
        let buyerClubs = clubs.filter { $0.id != selectedClubId }
        if let buyer = buyerClubs.randomElement() {
            player.clubId = buyer.id
            buyer.budget -= min(fee, buyer.budget)
        } else {
            player.clubId = nil
        }
        newsMessages.insert("Sold \(player.fullName) for \(formatCurrency(fee))!", at: 0)
    }

    func releasePlayer(_ player: Player) {
        player.clubId = nil
        player.contractYearsLeft = 0
        newsMessages.insert("Released \(player.fullName) as a free agent.", at: 0)
    }

    func signFreeAgent(_ player: Player, wage: Int) -> Bool {
        guard let club = selectedClub else { return false }
        player.clubId = selectedClubId
        player.contractYearsLeft = Int.random(in: 1...3)
        player.wage = wage
        newsMessages.insert("Signed free agent \(player.fullName)!", at: 0)
        return true
    }

    func formatCurrency(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            return String(format: "%.1fM", Double(amount) / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "%.0fK", Double(amount) / 1_000)
        }
        return "\(amount)"
    }

    func poissonRandom(lambda: Double) -> Int {
        let l = exp(-lambda)
        var k = 0
        var p = 1.0
        repeat {
            k += 1
            p *= Double.random(in: 0...1)
        } while p > l
        return k - 1
    }

    func clubName(for id: UUID) -> String {
        clubs.first { $0.id == id }?.name ?? "Unknown"
    }

    func leagueName(for club: Club) -> String {
        leagues.first { $0.id == club.leagueId }?.name ?? "Unknown League"
    }

    func initializeGame() {
        let (generatedLeagues, generatedClubs, generatedPlayers) = GameDataGenerator.createAllLeagues()
        leagues = generatedLeagues
        clubs = generatedClubs
        players = generatedPlayers
    }
}
