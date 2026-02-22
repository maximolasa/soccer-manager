import Foundation

nonisolated enum MatchType: String, Sendable {
    case friendly = "Friendly"
    case league = "League"
    case nationalCup = "Cup"
    case championsLeague = "Champions League"
    case europaLeague = "Europa League"
}

nonisolated enum MatchEventType: Sendable {
    case goal
    case ownGoal
    case yellowCard
    case redCard
    case injury
    case substitution
    case penalty
    case penaltyMiss
}

struct MatchEvent: Identifiable, Sendable {
    let id = UUID()
    let minute: Int
    let type: MatchEventType
    let playerName: String
    let isHome: Bool
    var assistPlayerName: String?
}

@Observable
class Match: Identifiable {
    let id: UUID
    var homeClubId: UUID
    var awayClubId: UUID
    var homeClubName: String
    var awayClubName: String
    var matchType: MatchType
    var date: Date
    var homeScore: Int
    var awayScore: Int
    var isPlayed: Bool
    var events: [MatchEvent]
    var homePossession: Int
    var awayPossession: Int
    var homeShots: Int
    var awayShots: Int
    var homeShotsOnTarget: Int
    var awayShotsOnTarget: Int
    var leagueId: UUID?

    init(
        homeClubId: UUID,
        awayClubId: UUID,
        homeClubName: String,
        awayClubName: String,
        matchType: MatchType,
        date: Date,
        leagueId: UUID? = nil
    ) {
        self.id = UUID()
        self.homeClubId = homeClubId
        self.awayClubId = awayClubId
        self.homeClubName = homeClubName
        self.awayClubName = awayClubName
        self.matchType = matchType
        self.date = date
        self.homeScore = 0
        self.awayScore = 0
        self.isPlayed = false
        self.events = []
        self.homePossession = 50
        self.awayPossession = 50
        self.homeShots = 0
        self.awayShots = 0
        self.homeShotsOnTarget = 0
        self.awayShotsOnTarget = 0
        self.leagueId = leagueId
    }
}

struct StandingsEntry: Identifiable {
    let id: UUID
    let clubId: UUID
    var clubName: String
    var played: Int = 0
    var won: Int = 0
    var drawn: Int = 0
    var lost: Int = 0
    var goalsFor: Int = 0
    var goalsAgainst: Int = 0
    var points: Int { won * 3 + drawn }
    var goalDifference: Int { goalsFor - goalsAgainst }

    init(clubId: UUID, clubName: String) {
        self.id = clubId
        self.clubId = clubId
        self.clubName = clubName
    }
}
