import SwiftUI

struct MatchResultView: View {
    @State var viewModel: GameViewModel

    var match: Match? { viewModel.currentMatch }

    var body: some View {
        ZStack {
            if let match {
                VStack(spacing: 16) {
                    Spacer()

                    Text("FULL TIME")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.green)
                        .tracking(4)

                    Text(match.matchType.rawValue.uppercased())
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))

                    HStack(spacing: 30) {
                        VStack(spacing: 6) {
                            clubBadge(match.homeClubName)
                            Text(match.homeClubName)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }

                        HStack(spacing: 12) {
                            Text("\(match.homeScore)")
                                .font(.system(size: 48, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                            Text("-")
                                .font(.title)
                                .foregroundStyle(.white.opacity(0.3))
                            Text("\(match.awayScore)")
                                .font(.system(size: 48, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 6) {
                            clubBadge(match.awayClubName)
                            Text(match.awayClubName)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }

                    HStack(spacing: 24) {
                        VStack(alignment: .trailing, spacing: 4) {
                            ForEach(homeGoalEvents(match)) { event in
                                Text("\(goalLabel(event)) \(event.minute)'")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        Image(systemName: "soccerball")
                            .foregroundStyle(.white.opacity(0.2))

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(awayGoalEvents(match)) { event in
                                Text("\(event.minute)' \(goalLabel(event))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 40)

                    HStack(spacing: 20) {
                        resultStat("Possession", "\(match.homePossession)%", "\(match.awayPossession)%")
                        resultStat("Shots", "\(match.homeShots)", "\(match.awayShots)")
                        resultStat("On Target", "\(match.homeShotsOnTarget)", "\(match.awayShotsOnTarget)")
                    }

                    Spacer()

                    Button {
                        viewModel.continueFromResult()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.fill")
                            Text("Continue")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .clipShape(.capsule)
                    }

                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.06, blue: 0.08), ignoresSafeAreaEdges: .all)
    }

    private func clubBadge(_ name: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 44, height: 44)
            Text(String(name.prefix(2)).uppercased())
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
        }
    }

    private func resultStat(_ label: String, _ home: String, _ away: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Text(home)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(away)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // Goals + penalties by the team, plus own goals by the opponent
    private func homeGoalEvents(_ match: Match) -> [MatchEvent] {
        match.events.filter {
            ($0.isHome && ($0.type == .goal || $0.type == .penalty)) ||
            (!$0.isHome && $0.type == .ownGoal)
        }
    }

    private func awayGoalEvents(_ match: Match) -> [MatchEvent] {
        match.events.filter {
            (!$0.isHome && ($0.type == .goal || $0.type == .penalty)) ||
            ($0.isHome && $0.type == .ownGoal)
        }
    }

    private func goalLabel(_ event: MatchEvent) -> String {
        switch event.type {
        case .penalty:  return "\(event.playerName) (pen)"
        case .ownGoal:  return "\(event.playerName) (OG)"
        default:        return event.playerName
        }
    }
}
