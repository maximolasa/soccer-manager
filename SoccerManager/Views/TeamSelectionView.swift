import SwiftUI

struct TeamSelectionView: View {
    @State var viewModel: GameViewModel
    @State private var selectedCountry: String?
    @State private var selectedLeague: League?
    @State private var searchText: String = ""

    var countries: [(name: String, emoji: String)] {
        var seen = Set<String>()
        var result: [(name: String, emoji: String)] = []
        for league in viewModel.leagues {
            if seen.insert(league.country).inserted {
                result.append((name: league.country, emoji: league.countryEmoji))
            }
        }
        return result
    }

    var countryLeagues: [League] {
        guard let country = selectedCountry else { return [] }
        return viewModel.leagues
            .filter { $0.country == country }
            .sorted { $0.tier < $1.tier }
    }

    var filteredClubs: [Club] {
        guard let league = selectedLeague else { return [] }
        let leagueClubs = viewModel.clubs.filter { $0.leagueId == league.id }
        if searchText.isEmpty { return leagueClubs }
        return leagueClubs.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                HStack(spacing: 0) {
                    leagueSidebar
                    clubGrid
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("FOOTBALL MANAGER")
                .font(.system(size: 28, weight: .black, design: .default))
                .tracking(4)
                .foregroundStyle(.white)

            Text("Select your club")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.2), Color(red: 0.05, green: 0.08, blue: 0.12)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    private var leagueSidebar: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(countries, id: \.name) { country in
                    VStack(spacing: 0) {
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                if selectedCountry == country.name {
                                    selectedCountry = nil
                                    selectedLeague = nil
                                } else {
                                    selectedCountry = country.name
                                    selectedLeague = nil
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(country.emoji)
                                    .font(.title3)
                                Text(country.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: selectedCountry == country.name ? "chevron.down" : "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(
                                selectedCountry == country.name
                                ? Color.green.opacity(0.15)
                                : Color.white.opacity(0.05)
                            )
                            .clipShape(.rect(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        if selectedCountry == country.name {
                            VStack(spacing: 2) {
                                ForEach(countryLeagues) { league in
                                    Button {
                                        withAnimation(.spring(duration: 0.3)) {
                                            selectedLeague = league
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(selectedLeague?.id == league.id ? Color.green : Color.white.opacity(0.15))
                                                .frame(width: 3, height: 20)
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(league.name)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .lineLimit(1)
                                                Text("Tier \(league.tier)")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedLeague?.id == league.id
                                            ? Color.green.opacity(0.2)
                                            : Color.clear
                                        )
                                        .clipShape(.rect(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.leading, 16)
                            .padding(.top, 2)
                        }
                    }
                }
            }
            .padding(8)
        }
        .frame(width: 200)
        .background(Color(white: 0.08))
    }

    private var clubGrid: some View {
        Group {
            if let league = selectedLeague {
                VStack(spacing: 0) {
                    HStack {
                        Text(league.countryEmoji)
                            .font(.title2)
                        Text(league.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Max Rating: \(league.maxRating)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 140), spacing: 10)
                        ], spacing: 10) {
                            ForEach(filteredClubs) { club in
                                ClubCard(club: club) {
                                    viewModel.startNewGame(clubId: club.id)
                                }
                            }
                        }
                        .padding(12)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green.opacity(0.3))
                    Text("Select a league to begin")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(white: 0.05))
    }
}

struct ClubCard: View {
    let club: Club
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.3), .green.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Text(club.shortName)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                }

                Text(club.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                    Text("\(club.rating)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                }

                Text(club.countryEmoji)
                    .font(.caption2)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
