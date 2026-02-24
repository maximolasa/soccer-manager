import Foundation

nonisolated struct PlayerStats: Codable, Sendable, Equatable {
    var overall: Int
    var offensive: Int
    var defensive: Int
    var physical: Int
}

nonisolated enum PlayerPosition: String, Codable, Sendable, CaseIterable, Identifiable {
    case goalkeeper = "GK"
    case centerBack = "CB"
    case leftBack = "LB"
    case rightBack = "RB"
    case defensiveMidfield = "CDM"
    case centralMidfield = "CM"
    case attackingMidfield = "CAM"
    case leftWing = "LW"
    case rightWing = "RW"
    case striker = "ST"

    var id: String { rawValue }

    var isDefender: Bool {
        self == .centerBack || self == .leftBack || self == .rightBack
    }

    var isMidfielder: Bool {
        self == .defensiveMidfield || self == .centralMidfield || self == .attackingMidfield
    }

    var isForward: Bool {
        self == .leftWing || self == .rightWing || self == .striker
    }

    var fullName: String {
        switch self {
        case .goalkeeper: return "Goalkeeper"
        case .centerBack: return "Center Back"
        case .leftBack: return "Left Back"
        case .rightBack: return "Right Back"
        case .defensiveMidfield: return "Def. Midfield"
        case .centralMidfield: return "Central Midfield"
        case .attackingMidfield: return "Att. Midfield"
        case .leftWing: return "Left Wing"
        case .rightWing: return "Right Wing"
        case .striker: return "Striker"
        }
    }
}

@Observable
class Player: Identifiable {
    let id: UUID
    var firstName: String
    var lastName: String
    var age: Int
    var position: PlayerPosition
    var stats: PlayerStats
    var wage: Int
    var marketValue: Int
    var clubId: UUID?
    var contractYearsLeft: Int
    var isOnLoan: Bool
    var loanedFromClubId: UUID?
    var morale: Int
    var isInjured: Bool
    var injuryWeeksLeft: Int
    var yellowCards: Int
    var redCards: Int
    var goals: Int
    var assists: Int
    var matchesPlayed: Int
    var potentialPeak: Int

    var fullName: String { "\(firstName) \(lastName)" }

    init(
        firstName: String,
        lastName: String,
        age: Int,
        position: PlayerPosition,
        stats: PlayerStats,
        wage: Int = 5000,
        marketValue: Int = 500000,
        clubId: UUID? = nil,
        contractYearsLeft: Int = 3,
        potentialPeak: Int = 0
    ) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.position = position
        self.stats = stats
        self.wage = wage
        self.marketValue = marketValue
        self.clubId = clubId
        self.contractYearsLeft = contractYearsLeft
        self.isOnLoan = false
        self.loanedFromClubId = nil
        self.morale = 70
        self.isInjured = false
        self.injuryWeeksLeft = 0
        self.yellowCards = 0
        self.redCards = 0
        self.goals = 0
        self.assists = 0
        self.matchesPlayed = 0
        self.potentialPeak = potentialPeak > 0 ? potentialPeak : min(99, stats.overall + Int.random(in: 5...20))
    }

    func applyAgeProgression() {
        if age < 24 {
            let growthChance = Double.random(in: 0...1)
            if growthChance < 0.6 && stats.overall < potentialPeak {
                let growth = Int.random(in: 1...3)
                stats.overall = min(potentialPeak, stats.overall + growth)
                stats.offensive = min(99, stats.offensive + Int.random(in: 0...growth))
                stats.defensive = min(99, stats.defensive + Int.random(in: 0...growth))
                stats.physical = min(99, stats.physical + Int.random(in: 0...growth))
            }
        } else if age >= 32 {
            let declineChance = Double.random(in: 0...1)
            let ageFactor = Double(age - 31) * 0.15
            if declineChance < ageFactor {
                let decline = Int.random(in: 1...3)
                stats.overall = max(20, stats.overall - decline)
                stats.physical = max(15, stats.physical - Int.random(in: 1...decline + 1))
                stats.offensive = max(15, stats.offensive - Int.random(in: 0...decline))
                stats.defensive = max(15, stats.defensive - Int.random(in: 0...decline))
            }
        }
        marketValue = calculateMarketValue()
    }

    /// FIFA-style exponential market value: steep rise with OVR, heavy age modulation.
    /// 90 OVR age 25 ≈ €107M, 80 OVR age 25 ≈ €24M, 70 OVR age 25 ≈ €5.3M
    func calculateMarketValue() -> Int {
        let ovr = Double(stats.overall)
        // Exponential base: ~€20K at OVR 35 → ~€295M at OVR 99
        let baseValue = 20_000.0 * exp(0.15 * (ovr - 35.0))

        // Young = potential premium, old = steep value drop (FIFA-style)
        let ageFactor: Double
        switch age {
        case ...19:   ageFactor = 1.5   // raw potential
        case 20...21: ageFactor = 1.8   // potential + some proof
        case 22...23: ageFactor = 1.6   // proven young star
        case 24...27: ageFactor = 1.4   // prime years
        case 28...29: ageFactor = 1.0   // entering late prime
        case 30...31: ageFactor = 0.6   // resale value drops
        case 32...33: ageFactor = 0.35  // limited years left
        case 34...35: ageFactor = 0.15  // near retirement
        default:      ageFactor = 0.05  // symbolic value
        }

        return max(25_000, Int(baseValue * ageFactor))
    }
}
