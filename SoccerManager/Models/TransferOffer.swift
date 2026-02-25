import Foundation

@Observable
class TransferOffer: Identifiable {
    let id: UUID
    let date: Date
    let biddingClubId: UUID
    let biddingClubName: String
    let playerId: UUID
    let playerName: String
    var fee: Int
    var status: OfferStatus
    var negotiationRound: Int  // tracks how many rounds of negotiation

    enum OfferStatus {
        case pending
        case accepted
        case rejected
        case countered  // user sent a counter, waiting for response
    }

    init(date: Date, biddingClubId: UUID, biddingClubName: String, playerId: UUID, playerName: String, fee: Int) {
        self.id = UUID()
        self.date = date
        self.biddingClubId = biddingClubId
        self.biddingClubName = biddingClubName
        self.playerId = playerId
        self.playerName = playerName
        self.fee = fee
        self.status = .pending
        self.negotiationRound = 0
    }
}
