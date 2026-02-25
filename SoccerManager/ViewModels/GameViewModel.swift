import Foundation
import SwiftUI

nonisolated enum GameScreen: Sendable {
    case mainMenu
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
    case mail
    case finance
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
    var currentScreen: GameScreen = .mainMenu
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
    var mailMessages: [MailMessage] = []

    var unreadMailCount: Int {
        mailMessages.filter { !$0.isRead }.count
    }

    func sendMail(subject: String, body: String, category: MailCategory = .general) {
        let mail = MailMessage(date: currentDate, subject: subject, body: body, category: category)
        mailMessages.insert(mail, at: 0)
    }

    // ── Lazy generation tracking ──
    /// Leagues that get full simulation (player's league + same-country adjacent tiers)
    var activeLeagueIds: Set<UUID> = []
    /// Clubs whose squads have already been generated
    var clubsWithSquads: Set<UUID> = []

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
        ensureSquadGenerated(for: rivalId)
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
        computeActiveLeagueIds()
        generateActiveSquads()
        generateFriendlies()
        generateSeasonSchedule()
        initializeStandings()
        generateFreeAgents()
        currentScreen = .dashboard
        newsMessages = ["You've been appointed as the new manager! Good luck!"]

        if let club = selectedClub {
            let leagueName = leagues.first { $0.id == club.leagueId }?.name ?? "the league"
            sendMail(
                subject: "Welcome to \(club.name)!",
                body: "Congratulations on your appointment as the new manager of \(club.name). The board expects a strong performance in \(leagueName) this season. Your transfer budget is \(formatCurrency(club.budget)). Good luck!",
                category: .board
            )
        }
    }

    func initializeStandings() {
        standings = [:]
        for league in leagues {
            let leagueClubs = clubs.filter { $0.leagueId == league.id }
            standings[league.id] = leagueClubs.map { StandingsEntry(clubId: $0.id, clubName: $0.name) }
        }
    }

    func generateFreeAgents() {
        // Scale free-agent quality to the player's league tier
        let playerLeague = leagues.first(where: { league in
            clubs.first(where: { $0.id == selectedClubId })?.leagueId == league.id
        })
        let tier = playerLeague?.tier ?? 1
        // Tier 1: 30-70, Tier 2: 25-60, Tier 3: 22-52, Tier 4: 20-45, Tier 5: 18-40
        let qualityLow = max(18, 30 - (tier - 1) * 5)
        let qualityHigh = max(40, 70 - (tier - 1) * 10)

        for _ in 0..<40 {
            let pos = PlayerPosition.allCases.randomElement()!
            let quality = Int.random(in: qualityLow...qualityHigh)
            let player = GameDataGenerator.generatePlayer(clubId: nil, position: pos, quality: quality)
            player.contractYearsLeft = 0
            players.append(player)
        }
    }

    func generateFriendlies() {
        guard let clubId = selectedClubId, let club = selectedClub else { return }
        let playerLeague = leagues.first { $0.id == club.leagueId }
        let playerCountry = playerLeague?.country ?? ""
        let isArgentine = playerCountry == "Argentina"

        let eligible = clubs.filter { c in
            guard c.id != clubId else { return false }
            // Rating within ±25
            guard abs(c.rating - club.rating) <= 25 else { return false }
            // Argentina only plays vs Argentina, rest only vs rest
            let cLeague = leagues.first { $0.id == c.leagueId }
            let cIsArgentine = cLeague?.country == "Argentina"
            return isArgentine == cIsArgentine
        }
        let opponents = eligible.shuffled().prefix(3)
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

        let allHome = players.filter { $0.clubId == match.homeClubId && !$0.isInjured }
        let allAway = players.filter { $0.clubId == match.awayClubId && !$0.isInjured }

        let homeXI = pickBestXI(from: allHome)
        let awayXI = pickBestXI(from: allAway)

        // ── Tactical modifiers ──
        let homeTac = tacticalModifiers(for: homeClub)
        let awayTac = tacticalModifiers(for: awayClub)

        // ── Team strengths from actual player stats ──
        let homeAttack  = weightedAttack(homeXI)
        let homeDefense = weightedDefense(homeXI)
        let homeMid     = weightedMidfield(homeXI)
        let awayAttack  = weightedAttack(awayXI)
        let awayDefense = weightedDefense(awayXI)
        let awayMid     = weightedMidfield(awayXI)

        // ── Possession ──
        let homeMidPower = homeMid + homeTac.possessionBonus + Double.random(in: -4...4)
        let awayMidPower = awayMid + awayTac.possessionBonus + Double.random(in: -4...4)
        let totalMid = max(homeMidPower + awayMidPower, 1.0)
        match.homePossession = min(70, max(30, Int(homeMidPower / totalMid * 100)))
        match.awayPossession = 100 - match.homePossession

        // ── Expected goals (xG) ──
        let homeXG = computeXG(
            attack: homeAttack,
            oppDefense: awayDefense + awayTac.defenseBonus,
            possession: Double(match.homePossession),
            xgBonus: homeTac.xgBonus,
            isHome: true
        )
        let awayXG = computeXG(
            attack: awayAttack,
            oppDefense: homeDefense + homeTac.defenseBonus,
            possession: Double(match.awayPossession),
            xgBonus: awayTac.xgBonus,
            isHome: false
        )

        // ── Shots ──
        match.homeShots = max(2, Int(homeXG * 5.5 + Double.random(in: 2...5) + homeTac.shotsBonus))
        match.awayShots = max(2, Int(awayXG * 5.5 + Double.random(in: 2...5) + awayTac.shotsBonus))
        let homeAcc = min(0.7, 0.3 + homeAttack / 250.0 + Double.random(in: -0.05...0.1))
        let awayAcc = min(0.7, 0.3 + awayAttack / 250.0 + Double.random(in: -0.05...0.1))
        match.homeShotsOnTarget = max(0, min(match.homeShots, Int(Double(match.homeShots) * homeAcc)))
        match.awayShotsOnTarget = max(0, min(match.awayShots, Int(Double(match.awayShots) * awayAcc)))

        // ── Goals ──
        let homeGoals = poissonRandom(lambda: homeXG)
        let awayGoals = poissonRandom(lambda: awayXG)

        var events: [MatchEvent] = []

        for _ in 0..<homeGoals {
            let minute = Int.random(in: 1...90)
            let scorer = weightedScorer(from: homeXI)
            let assist = weightedAssist(from: homeXI, excludingId: scorer.id)
            events.append(MatchEvent(minute: minute, type: .goal, playerName: scorer.fullName, isHome: true, assistPlayerName: assist?.fullName))
            match.homeScore += 1
            scorer.goals += 1
            assist?.assists += 1
        }

        for _ in 0..<awayGoals {
            let minute = Int.random(in: 1...90)
            let scorer = weightedScorer(from: awayXI)
            let assist = weightedAssist(from: awayXI, excludingId: scorer.id)
            events.append(MatchEvent(minute: minute, type: .goal, playerName: scorer.fullName, isHome: false, assistPlayerName: assist?.fullName))
            match.awayScore += 1
            scorer.goals += 1
            assist?.assists += 1
        }

        // ── Penalty (~8 %) ──
        if Double.random(in: 0...1) < 0.08 {
            let isHome = Bool.random()
            let xi = isHome ? homeXI : awayXI
            let minute = Int.random(in: 25...88)
            if let taker = xi.filter({ $0.position.isForward || $0.position == .attackingMidfield })
                .max(by: { $0.stats.offensive < $1.stats.offensive }) ?? xi.randomElement() {
                if Double.random(in: 0...1) < 0.76 {
                    events.append(MatchEvent(minute: minute, type: .penalty, playerName: taker.fullName, isHome: isHome))
                    if isHome { match.homeScore += 1 } else { match.awayScore += 1 }
                    taker.goals += 1
                } else {
                    events.append(MatchEvent(minute: minute, type: .penaltyMiss, playerName: taker.fullName, isHome: isHome))
                }
            }
        }

        // ── Own goal (~3 %) ──
        if Double.random(in: 0...1) < 0.03 {
            let isHome = Bool.random()
            let xi = isHome ? homeXI : awayXI
            let minute = Int.random(in: 1...90)
            if let p = xi.filter({ $0.position.isDefender }).randomElement() ?? xi.randomElement() {
                events.append(MatchEvent(minute: minute, type: .ownGoal, playerName: p.fullName, isHome: isHome))
                // Own goal counts for other team
                if isHome { match.awayScore += 1 } else { match.homeScore += 1 }
            }
        }

        // ── Cards (influenced by pressing & tempo) ──
        let cardBase = 2.5 * (homeTac.cardMultiplier + awayTac.cardMultiplier) / 2.0
        let cardCount = poissonRandom(lambda: cardBase)
        for _ in 0..<cardCount {
            let isHome = Bool.random()
            let pool = isHome ? homeXI : awayXI
            guard let p = pool.randomElement() else { continue }
            let minute = Int.random(in: 1...90)
            let isRed = Double.random(in: 0...1) < 0.04
            events.append(MatchEvent(minute: minute, type: isRed ? .redCard : .yellowCard, playerName: p.fullName, isHome: isHome))
            if isRed { p.redCards += 1 } else { p.yellowCards += 1 }
        }

        // ── In-match injury ──
        let injuryChance = 0.06 + homeTac.injuryBonus + awayTac.injuryBonus
        if Double.random(in: 0...1) < injuryChance {
            let isHome = Bool.random()
            let pool = isHome ? homeXI : awayXI
            if let p = pool.randomElement() {
                let minute = Int.random(in: 10...85)
                events.append(MatchEvent(minute: minute, type: .injury, playerName: p.fullName, isHome: isHome))
                // Apply actual injury to the player
                p.isInjured = true
                p.injuryWeeksLeft = Int.random(in: 1...6)
                // Mail notification if it's our player
                if p.clubId == selectedClubId {
                    let oppName = isHome ? (awayClub?.name ?? "opponent") : (homeClub?.name ?? "opponent")
                    let weeksText = p.injuryWeeksLeft > 1 ? "\(p.injuryWeeksLeft) weeks" : "1 week"
                    sendMail(
                        subject: "\(p.fullName) injured in match",
                        body: "\(p.fullName) was injured during the match against \(oppName) in minute \(minute). He will be out for \(weeksText).",
                        category: .injury
                    )
                }
            }
        }

        match.events = events.sorted { $0.minute < $1.minute }
        match.isPlayed = true

        // ── Player match ratings ──
        var ratings: [UUID: Double] = [:]
        for player in homeXI {
            let base = Double(player.stats.overall) / 15.0 + 3.0
            let goalBonus = Double(events.filter { $0.isHome && ($0.type == .goal || $0.type == .penalty) && $0.playerName == player.fullName }.count) * 0.8
            let assistBonus = Double(events.filter { $0.isHome && $0.assistPlayerName == player.fullName }.count) * 0.4
            let resultBonus: Double = match.homeScore > match.awayScore ? 0.3 : (match.homeScore < match.awayScore ? -0.3 : 0)
            ratings[player.id] = min(10.0, max(1.0, base + goalBonus + assistBonus + resultBonus + Double.random(in: -1.0...1.0)))
        }
        for player in awayXI {
            let base = Double(player.stats.overall) / 15.0 + 3.0
            let goalBonus = Double(events.filter { !$0.isHome && ($0.type == .goal || $0.type == .penalty) && $0.playerName == player.fullName }.count) * 0.8
            let assistBonus = Double(events.filter { !$0.isHome && $0.assistPlayerName == player.fullName }.count) * 0.4
            let resultBonus: Double = match.awayScore > match.homeScore ? 0.3 : (match.awayScore < match.homeScore ? -0.3 : 0)
            ratings[player.id] = min(10.0, max(1.0, base + goalBonus + assistBonus + resultBonus + Double.random(in: -1.0...1.0)))
        }
        match.playerRatings = ratings

        // Matches played – once per player per match
        for player in homeXI + awayXI {
            player.matchesPlayed += 1
        }

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
            if isActiveMatch(match) {
                simulateMatch(match)
            } else {
                simulateMatchLightweight(match)
            }
        }

        // Weekly events (every 7 days)
        if dayCounter % 7 == 0 {
            currentWeek += 1
            handleInjuries()
            paySalaries()
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

    func advanceToMatchDay() {
        guard let match = nextMatch else { return }
        let cal = Calendar.current
        while !cal.isDate(currentDate, inSameDayAs: match.date) {
            guard canAdvance else { return }
            advanceDay()
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
            if isActiveMatch(m) {
                simulateMatch(m)
            } else {
                simulateMatchLightweight(m)
            }
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
                if isActiveMatch(m) {
                    simulateMatch(m)
                } else {
                    simulateMatchLightweight(m)
                }
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
            sendMail(
                subject: "New youth talent: \(player.fullName)",
                body: "The youth academy has produced \(player.fullName), a \(player.position.fullName) rated \(player.stats.overall) OVR. He has been added to your squad.",
                category: .youth
            )
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
                    sendMail(
                        subject: "\(player.fullName) recovered",
                        body: "\(player.fullName) has fully recovered from his injury and is available for selection.",
                        category: .injury
                    )
                }
            } else {
                if Double.random(in: 0...1) < 0.02 {
                    player.isInjured = true
                    player.injuryWeeksLeft = Int.random(in: 1...8)
                    let weeksText = player.injuryWeeksLeft > 1 ? "\(player.injuryWeeksLeft) weeks" : "1 week"
                    sendMail(
                        subject: "\(player.fullName) injured",
                        body: "\(player.fullName) has picked up an injury during training and will be out for \(weeksText).",
                        category: .injury
                    )
                }
            }
        }
    }

    func buyPlayer(_ player: Player, fee: Int) -> Bool {
        guard let club = selectedClub else { return false }
        guard club.budget >= fee else { return false }
        // Check salary budget can cover the player's wage
        guard club.wageBudget >= player.wage else { return false }
        club.budget -= fee
        if let oldClubId = player.clubId, let oldClub = clubs.first(where: { $0.id == oldClubId }) {
            oldClub.budget += fee
        }
        player.clubId = selectedClubId
        player.contractYearsLeft = Int.random(in: 2...5)
        sendMail(
            subject: "Transfer complete: \(player.fullName)",
            body: "You have signed \(player.fullName) (\(player.position.rawValue), \(player.stats.overall) OVR) for \(formatCurrency(fee)). Wage: \(formatCurrency(player.wage))/week. Contract: \(player.contractYearsLeft) years.",
            category: .transfer
        )
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
        sendMail(
            subject: "\(player.fullName) sold",
            body: "You have sold \(player.fullName) for \(formatCurrency(fee)). The funds have been added to your transfer budget.",
            category: .transfer
        )
    }

    func releasePlayer(_ player: Player) {
        player.clubId = nil
        player.contractYearsLeft = 0
        newsMessages.insert("Released \(player.fullName) as a free agent.", at: 0)
        sendMail(
            subject: "\(player.fullName) released",
            body: "\(player.fullName) has been released from the squad and is now a free agent.",
            category: .transfer
        )
    }

    func signFreeAgent(_ player: Player, wage: Int) -> Bool {
        guard let club = selectedClub else { return false }
        // Check salary budget can cover the wage
        guard club.wageBudget >= wage else { return false }
        player.clubId = selectedClubId
        player.contractYearsLeft = Int.random(in: 1...3)
        player.wage = wage
        newsMessages.insert("Signed free agent \(player.fullName)!", at: 0)
        sendMail(
            subject: "Free agent signed: \(player.fullName)",
            body: "You have signed free agent \(player.fullName) (\(player.position.rawValue), \(player.stats.overall) OVR) on a \(player.contractYearsLeft)-year contract at \(formatCurrency(wage))/week.",
            category: .transfer
        )
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

    // MARK: - Finance

    /// Total weekly wages of the player's squad
    var totalWeeklyWages: Int {
        guard let clubId = selectedClubId else { return 0 }
        return players.filter { $0.clubId == clubId }.reduce(0) { $0 + $1.wage }
    }

    /// Remaining salary budget after all current wages
    var remainingSalaryBudget: Int {
        guard let club = selectedClub else { return 0 }
        return club.wageBudget - totalWeeklyWages
    }

    /// Check if we can afford a player's wage
    func canAffordWage(_ wage: Int) -> Bool {
        return remainingSalaryBudget >= wage
    }

    /// Pay weekly salaries — deducts totalWeeklyWages from wageBudget each week
    /// If wageBudget goes negative, the club is in financial trouble
    func paySalaries() {
        guard let club = selectedClub else { return }
        let wages = totalWeeklyWages
        club.wageBudget -= wages
        if club.wageBudget < 0 {
            sendMail(
                subject: "Financial Warning",
                body: "Your salary budget is in the red! Current balance: \(formatCurrency(club.wageBudget)). Weekly wages: \(formatCurrency(wages))/week. Consider selling players or transferring funds.",
                category: .board
            )
        }
    }

    /// Move money from transfer budget to salary fund (1:1, both are cash pools)
    func transferToSalary(amount: Int) -> Bool {
        guard let club = selectedClub else { return false }
        guard amount > 0, club.budget >= amount else { return false }
        club.budget -= amount
        club.wageBudget += amount
        return true
    }

    /// Move money from salary fund to transfer budget (1:1)
    /// Cannot move below current weekly wage obligations
    func salaryToTransfer(amount: Int) -> Bool {
        guard let club = selectedClub else { return false }
        guard amount > 0, club.wageBudget >= amount else { return false }
        guard club.wageBudget - amount >= totalWeeklyWages else { return false }
        club.wageBudget -= amount
        club.budget += amount
        return true
    }

    // MARK: - Simulation Helpers

    /// Tactical modifiers derived from club settings (mentality, tempo, pressing, width)
    struct TacticalModifiers {
        var xgBonus: Double = 0.0
        var defenseBonus: Double = 0.0
        var possessionBonus: Double = 0.0
        var shotsBonus: Double = 0.0
        var cardMultiplier: Double = 1.0
        var injuryBonus: Double = 0.0
    }

    private func tacticalModifiers(for club: Club?) -> TacticalModifiers {
        var m = TacticalModifiers()
        guard let club else { return m }

        switch club.mentality {
        case "Attacking":  m.xgBonus += 0.3;  m.defenseBonus -= 8;  m.shotsBonus += 2
        case "Defensive":  m.xgBonus -= 0.25; m.defenseBonus += 8;  m.shotsBonus -= 2
        default: break
        }
        switch club.tempo {
        case "Fast":  m.xgBonus += 0.1;  m.shotsBonus += 2; m.cardMultiplier *= 1.2
        case "Slow":  m.xgBonus -= 0.1;  m.possessionBonus += 3; m.cardMultiplier *= 0.8
        default: break
        }
        switch club.pressing {
        case "High": m.xgBonus += 0.15; m.possessionBonus += 5; m.cardMultiplier *= 1.15; m.injuryBonus += 0.04
        case "Low":  m.xgBonus -= 0.1;  m.possessionBonus -= 5; m.cardMultiplier *= 0.9
        default: break
        }
        switch club.playWidth {
        case "Wide":   m.shotsBonus += 1
        case "Narrow": m.possessionBonus += 3
        default: break
        }
        return m
    }

    /// Pick best 11: 1 GK + top 10 outfield by overall
    private func pickBestXI(from pool: [Player]) -> [Player] {
        var available = pool
        var xi: [Player] = []
        if let gk = available.filter({ $0.position == .goalkeeper }).max(by: { $0.stats.overall < $1.stats.overall }) {
            xi.append(gk)
            available.removeAll { $0.id == gk.id }
        }
        let outfield = available.sorted { $0.stats.overall > $1.stats.overall }.prefix(max(0, 11 - xi.count))
        xi.append(contentsOf: outfield)
        return xi
    }

    /// Weighted attacking strength – emphasises forwards & offensive stats
    private func weightedAttack(_ xi: [Player]) -> Double {
        guard !xi.isEmpty else { return 30.0 }
        var total = 0.0, wSum = 0.0
        for p in xi {
            let w: Double
            switch p.position {
            case .striker:                      w = 3.0
            case .leftWing, .rightWing:          w = 2.5
            case .attackingMidfield:              w = 2.0
            case .centralMidfield:               w = 1.2
            case .defensiveMidfield:             w = 0.6
            case .leftBack, .rightBack:          w = 0.4
            case .centerBack:                    w = 0.2
            case .goalkeeper:                    w = 0.05
            }
            total += Double(p.stats.offensive) * w
            wSum += w
        }
        return total / max(wSum, 1.0)
    }

    /// Weighted defensive strength – emphasises defenders & GK
    private func weightedDefense(_ xi: [Player]) -> Double {
        guard !xi.isEmpty else { return 30.0 }
        var total = 0.0, wSum = 0.0
        for p in xi {
            let w: Double
            switch p.position {
            case .goalkeeper:                    w = 3.0
            case .centerBack:                    w = 2.5
            case .leftBack, .rightBack:          w = 2.0
            case .defensiveMidfield:             w = 1.8
            case .centralMidfield:               w = 1.0
            case .attackingMidfield:              w = 0.4
            case .leftWing, .rightWing:          w = 0.3
            case .striker:                       w = 0.1
            }
            total += Double(p.stats.defensive) * w
            wSum += w
        }
        return total / max(wSum, 1.0)
    }

    /// Weighted midfield control – for possession calculation
    private func weightedMidfield(_ xi: [Player]) -> Double {
        guard !xi.isEmpty else { return 30.0 }
        var total = 0.0, wSum = 0.0
        for p in xi {
            let w: Double
            switch p.position {
            case .centralMidfield, .attackingMidfield, .defensiveMidfield: w = 3.0
            case .leftWing, .rightWing:          w = 1.5
            case .leftBack, .rightBack:          w = 0.8
            case .centerBack:                    w = 0.5
            case .striker:                       w = 0.4
            case .goalkeeper:                    w = 0.1
            }
            total += Double(p.stats.overall) * w
            wSum += w
        }
        return total / max(wSum, 1.0)
    }

    /// Expected goals from strength, opponent defense, possession, tactics
    private func computeXG(attack: Double, oppDefense: Double, possession: Double, xgBonus: Double, isHome: Bool) -> Double {
        let attackEffect  = (attack - 60.0) / 50.0
        let defenseEffect = (oppDefense - 60.0) / 50.0
        let possEffect    = (possession - 50.0) / 100.0
        let homeBonus: Double = isHome ? 0.2 : 0.0
        return max(0.15, min(4.0, 1.3 + attackEffect - defenseEffect + possEffect + homeBonus + xgBonus + Double.random(in: -0.2...0.2)))
    }

    /// Weighted random scorer: favours forwards with high offensive stats
    private func weightedScorer(from xi: [Player]) -> Player {
        let weights: [(Player, Double)] = xi.map { p in
            let posW: Double
            switch p.position {
            case .striker:                       posW = 5.0
            case .leftWing, .rightWing:          posW = 3.0
            case .attackingMidfield:              posW = 2.5
            case .centralMidfield:               posW = 1.0
            case .defensiveMidfield:             posW = 0.5
            case .centerBack, .leftBack, .rightBack: posW = 0.2
            case .goalkeeper:                    posW = 0.01
            }
            return (p, posW * Double(max(1, p.stats.offensive)) / 50.0)
        }
        return weightedPick(weights) ?? xi.first!
    }

    /// Weighted random assist provider: favours creative midfielders & wingers
    private func weightedAssist(from xi: [Player], excludingId: UUID) -> Player? {
        if Double.random(in: 0...1) < 0.12 { return nil }
        let eligible = xi.filter { $0.id != excludingId }
        guard !eligible.isEmpty else { return nil }
        let weights: [(Player, Double)] = eligible.map { p in
            let posW: Double
            switch p.position {
            case .attackingMidfield:              posW = 4.0
            case .centralMidfield:               posW = 3.0
            case .leftWing, .rightWing:          posW = 3.0
            case .defensiveMidfield:             posW = 2.0
            case .striker:                       posW = 1.5
            case .leftBack, .rightBack:          posW = 1.5
            case .centerBack:                    posW = 0.5
            case .goalkeeper:                    posW = 0.05
            }
            return (p, posW * Double(max(1, p.stats.overall)) / 50.0)
        }
        return weightedPick(weights)
    }

    private func weightedPick(_ items: [(Player, Double)]) -> Player? {
        let total = items.reduce(0.0) { $0 + $1.1 }
        guard total > 0 else { return nil }
        var r = Double.random(in: 0..<total)
        for (player, w) in items {
            r -= w
            if r <= 0 { return player }
        }
        return items.last?.0
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
        let (generatedLeagues, generatedClubs) = GameDataGenerator.createAllLeagues()
        leagues = generatedLeagues
        clubs = generatedClubs
    }

    // MARK: - Lazy Generation

    /// Determine which leagues are "active" (full simulation with squads).
    /// Active = player's league + same-country leagues with adjacent tiers.
    func computeActiveLeagueIds() {
        activeLeagueIds = []
        guard let club = clubs.first(where: { $0.id == selectedClubId }),
              let playerLeague = leagues.first(where: { $0.id == club.leagueId }) else { return }

        let country = playerLeague.country
        let tier = playerLeague.tier

        for league in leagues {
            if league.country == country && abs(league.tier - tier) <= 1 {
                activeLeagueIds.insert(league.id)
            }
        }
    }

    /// Generate squads for all clubs in active leagues.
    func generateActiveSquads() {
        for league in leagues where activeLeagueIds.contains(league.id) {
            let leagueClubs = clubs.filter { $0.leagueId == league.id }
            for club in leagueClubs {
                ensureSquadGenerated(for: club.id)
            }
        }
    }

    /// On-demand squad generation. Only generates once per club.
    /// After generation, club.rating is recalculated as the average of the top 15 players.
    func ensureSquadGenerated(for clubId: UUID) {
        guard !clubsWithSquads.contains(clubId) else { return }
        clubsWithSquads.insert(clubId)

        guard let club = clubs.first(where: { $0.id == clubId }) else { return }
        let squad = GameDataGenerator.generateSquad(clubId: club.id, clubRating: club.rating)
        players.append(contentsOf: squad)

        // Recalculate club rating = average overall of top 15 players
        let topRatings = squad.map { $0.stats.overall }.sorted(by: >).prefix(15)
        if !topRatings.isEmpty {
            club.rating = topRatings.reduce(0, +) / topRatings.count
        }
    }

    /// Check if a match belongs to an active league (needing full sim).
    func isActiveMatch(_ match: Match) -> Bool {
        guard let leagueId = match.leagueId else { return true } // friendlies/cups always full
        return activeLeagueIds.contains(leagueId)
    }

    /// Lightweight simulation: score-only from club ratings, no events/player stats.
    func simulateMatchLightweight(_ match: Match) {
        let homeClub = clubs.first { $0.id == match.homeClubId }
        let awayClub = clubs.first { $0.id == match.awayClubId }
        let homeRating = Double(homeClub?.rating ?? 50)
        let awayRating = Double(awayClub?.rating ?? 50)

        let homeStrength = homeRating + Double.random(in: -15...15) + 3
        let awayStrength = awayRating + Double.random(in: -15...15)

        let homeExpectedGoals = max(0, (homeStrength - 30) / 20)
        let awayExpectedGoals = max(0, (awayStrength - 30) / 20)

        match.homeScore = poissonRandom(lambda: homeExpectedGoals)
        match.awayScore = poissonRandom(lambda: awayExpectedGoals)
        match.isPlayed = true

        if match.matchType == .league, let leagueId = match.leagueId {
            updateStandings(leagueId: leagueId, match: match)
        }
    }
}
