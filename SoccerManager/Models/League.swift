import Foundation

@Observable
class League: Identifiable {
    let id: UUID
    var name: String
    var country: String
    var countryEmoji: String
    var tier: Int
    var maxRating: Int
    var promotionSpots: Int
    var relegationSpots: Int
    var hasNationalCup: Bool
    var relatedLeagueIds: [UUID]

    init(
        name: String,
        country: String,
        countryEmoji: String,
        tier: Int,
        maxRating: Int,
        promotionSpots: Int = 2,
        relegationSpots: Int = 3,
        hasNationalCup: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.country = country
        self.countryEmoji = countryEmoji
        self.tier = tier
        self.maxRating = maxRating
        self.promotionSpots = promotionSpots
        self.relegationSpots = relegationSpots
        self.hasNationalCup = hasNationalCup
        self.relatedLeagueIds = []
    }
}
