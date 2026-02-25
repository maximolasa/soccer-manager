import Foundation

// MARK: - Player Stats

nonisolated struct PlayerStats: Codable, Sendable, Equatable {
    // Attack (6)
    var finishing: Int
    var longShots: Int
    var dribbling: Int
    var firstTouch: Int
    var crossing: Int
    var passing: Int

    // Defense (4)
    var tackling: Int
    var marking: Int
    var heading: Int
    var defensivePositioning: Int

    // Physical (4)
    var pace: Int
    var stamina: Int
    var strength: Int
    var movement: Int

    // Goalkeeper (6) — only meaningful for GK position
    var reflexes: Int
    var diving: Int
    var handling: Int
    var gkPositioning: Int
    var kicking: Int
    var oneOnOne: Int

    // MARK: - Category Averages

    var attackAvg: Int {
        (finishing + longShots + dribbling + firstTouch + crossing + passing) / 6
    }

    var defenseAvg: Int {
        (tackling + marking + heading + defensivePositioning) / 4
    }

    var physicalAvg: Int {
        (pace + stamina + strength + movement) / 4
    }

    var gkAvg: Int {
        (reflexes + diving + handling + gkPositioning + kicking + oneOnOne) / 6
    }

    // MARK: - Position-Weighted Overall

    func overall(for position: PlayerPosition) -> Int {
        if position == .goalkeeper {
            // GK overall: 70% GK stats + 20% physical + 10% passing/kicking
            let gk = Double(gkAvg)
            let phy = Double(physicalAvg)
            let dist = Double((passing + kicking) / 2)
            return max(1, min(99, Int((gk * 0.70 + phy * 0.20 + dist * 0.10).rounded())))
        }

        let atk = Double(attackAvg)
        let def = Double(defenseAvg)
        let phy = Double(physicalAvg)

        let (wAtk, wDef, wPhy): (Double, Double, Double)
        switch position {
        case .goalkeeper:
            (wAtk, wDef, wPhy) = (0.05, 0.65, 0.30) // unreachable but needed
        case .centerBack:
            (wAtk, wDef, wPhy) = (0.10, 0.55, 0.35)
        case .leftBack, .rightBack:
            (wAtk, wDef, wPhy) = (0.25, 0.40, 0.35)
        case .defensiveMidfield:
            (wAtk, wDef, wPhy) = (0.20, 0.45, 0.35)
        case .centralMidfield:
            (wAtk, wDef, wPhy) = (0.35, 0.30, 0.35)
        case .attackingMidfield:
            (wAtk, wDef, wPhy) = (0.55, 0.15, 0.30)
        case .leftWing, .rightWing:
            (wAtk, wDef, wPhy) = (0.55, 0.10, 0.35)
        case .striker:
            (wAtk, wDef, wPhy) = (0.60, 0.05, 0.35)
        }

        return max(1, min(99, Int((atk * wAtk + def * wDef + phy * wPhy).rounded())))
    }

    // MARK: - Convenience Init

    /// Creates stats where all values equal `flat`.
    static func flat(_ value: Int) -> PlayerStats {
        PlayerStats(
            finishing: value, longShots: value, dribbling: value,
            firstTouch: value, crossing: value, passing: value,
            tackling: value, marking: value, heading: value,
            defensivePositioning: value,
            pace: value, stamina: value, strength: value, movement: value,
            reflexes: value, diving: value, handling: value,
            gkPositioning: value, kicking: value, oneOnOne: value
        )
    }
}

// MARK: - Position

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

// MARK: - Player

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
    var isTransferListed: Bool

    var fullName: String { "\(firstName) \(lastName)" }

    /// Computed overall based on position weights
    var overall: Int { stats.overall(for: position) }

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
        self.isTransferListed = false
        let ovr = stats.overall(for: position)
        self.potentialPeak = potentialPeak > 0 ? potentialPeak : min(99, ovr + Int.random(in: 5...20))
    }

    func applyAgeProgression() {
        let ovr = overall
        if age < 24 {
            let growthChance = Double.random(in: 0...1)
            if growthChance < 0.6 && ovr < potentialPeak {
                let growth = Int.random(in: 1...3)
                if position == .goalkeeper {
                    stats.reflexes = min(99, stats.reflexes + Int.random(in: 0...growth))
                    stats.diving = min(99, stats.diving + Int.random(in: 0...growth))
                    stats.handling = min(99, stats.handling + Int.random(in: 0...growth))
                    stats.gkPositioning = min(99, stats.gkPositioning + Int.random(in: 0...growth))
                    stats.kicking = min(99, stats.kicking + Int.random(in: 0...growth))
                    stats.oneOnOne = min(99, stats.oneOnOne + Int.random(in: 0...growth))
                } else {
                    stats.finishing = min(99, stats.finishing + Int.random(in: 0...growth))
                    stats.dribbling = min(99, stats.dribbling + Int.random(in: 0...growth))
                    stats.passing = min(99, stats.passing + Int.random(in: 0...growth))
                    stats.tackling = min(99, stats.tackling + Int.random(in: 0...growth))
                    stats.marking = min(99, stats.marking + Int.random(in: 0...growth))
                }
                stats.pace = min(99, stats.pace + Int.random(in: 0...growth))
                stats.stamina = min(99, stats.stamina + Int.random(in: 0...growth))
                stats.strength = min(99, stats.strength + Int.random(in: 0...growth))
            }
        } else if age >= 32 {
            let declineChance = Double.random(in: 0...1)
            let ageFactor = Double(age - 31) * 0.15
            if declineChance < ageFactor {
                let decline = Int.random(in: 1...3)
                stats.pace = max(15, stats.pace - Int.random(in: 1...decline + 1))
                stats.stamina = max(15, stats.stamina - Int.random(in: 1...decline))
                stats.movement = max(15, stats.movement - Int.random(in: 0...decline))
                if position == .goalkeeper {
                    stats.reflexes = max(15, stats.reflexes - Int.random(in: 0...decline))
                    stats.diving = max(15, stats.diving - Int.random(in: 0...decline))
                } else {
                    stats.finishing = max(15, stats.finishing - Int.random(in: 0...decline))
                    stats.dribbling = max(15, stats.dribbling - Int.random(in: 0...decline))
                }
            }
        }
        marketValue = calculateMarketValue()
    }

    /// FIFA-style exponential market value: steep rise with OVR, heavy age modulation.
    func calculateMarketValue() -> Int {
        let ovr = Double(overall)
        let baseValue = 20_000.0 * exp(0.15 * (ovr - 35.0))

        let ageFactor: Double
        switch age {
        case ...19:   ageFactor = 1.5
        case 20...21: ageFactor = 1.8
        case 22...23: ageFactor = 1.6
        case 24...27: ageFactor = 1.4
        case 28...29: ageFactor = 1.0
        case 30...31: ageFactor = 0.6
        case 32...33: ageFactor = 0.35
        case 34...35: ageFactor = 0.15
        default:      ageFactor = 0.05
        }

        return max(25_000, Int(baseValue * ageFactor))
    }
}
