import SwiftUI

struct TeamSelectionView: View {
    @State var viewModel: GameViewModel
    @State private var selectedCountry: String?
    @State private var selectedLeague: League?
    @State private var previewClub: Club?
    @State private var searchText: String = ""

    // Contract signing animation states
    @State private var showSigningOverlay = false
    @State private var signingPhase: SigningPhase = .fadeIn
    @State private var signingClub: Club?
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0

    enum SigningPhase {
        case fadeIn, reveal, badge, welcome
    }

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
                    if let club = previewClub {
                        clubPreviewPanel(club)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }

            // Contract signing overlay
            if showSigningOverlay, let club = signingClub {
                contractSigningOverlay(club)
            }
        }
        .animation(.spring(duration: 0.35), value: previewClub?.id)
    }

    // MARK: - Header

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

    // MARK: - League Sidebar

    private var leagueSidebar: some View {
        ScrollViewReader { proxy in
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
                                    previewClub = nil
                                }
                                previewClub = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    withAnimation {
                                        proxy.scrollTo(country.name, anchor: .top)
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
                            .id(country.name)

                            if selectedCountry == country.name {
                                VStack(spacing: 2) {
                                    ForEach(countryLeagues) { league in
                                        Button {
                                            withAnimation(.spring(duration: 0.3)) {
                                                selectedLeague = league
                                                previewClub = nil
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(selectedLeague?.id == league.id ? Color.green : Color.white.opacity(0.15))
                                                    .frame(width: 3, height: 20)
                                                Text(league.name)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .lineLimit(1)
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
        }
        .frame(width: 200)
        .background(Color(white: 0.08))
    }

    // MARK: - Club Grid

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
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    if let selected = previewClub {
                        // Show only the selected club centered
                        Spacer()
                        ClubCard(club: selected, isSelected: true) { }
                            .frame(width: 150)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 140), spacing: 10)
                            ], spacing: 10) {
                                ForEach(filteredClubs) { club in
                                    ClubCard(club: club, isSelected: false) {
                                        withAnimation(.spring(duration: 0.3)) {
                                            previewClub = club
                                        }
                                    }
                                }
                            }
                            .padding(12)
                        }
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

    // MARK: - Club Preview Panel

    private func clubPreviewPanel(_ club: Club) -> some View {
        let leagueName = viewModel.leagues.first { $0.id == club.leagueId }?.name ?? ""

        return VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                        previewClub = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 10)
            .padding(.top, 8)

            // Club header
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [club.primarySwiftUIColor.opacity(0.6), club.primarySwiftUIColor.opacity(0.1)],
                                center: .center, startRadius: 0, endRadius: 40
                            )
                        )
                        .frame(width: 64, height: 64)
                    Circle()
                        .stroke(club.primarySwiftUIColor.opacity(0.8), lineWidth: 2)
                        .frame(width: 64, height: 64)
                    Text(club.shortName)
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                }

                Text(club.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(leagueName)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 4)
            .padding(.bottom, 14)

            Divider().overlay(Color.white.opacity(0.1))

            // Stats
            VStack(spacing: 8) {
                previewStatRow("Rating", "\(club.rating)", .yellow, "star.fill")
                previewStatRow("Transfer Budget", formatCurrencyLocal(club.budget), .cyan, "banknote")
                previewStatRow("Salary Budget", formatCurrencyLocal(club.wageBudget / 52) + "/wk", .orange, "creditcard")
                previewStatRow("Stadium", club.stadiumName, .green, "building.2")
                previewStatRow("Capacity", "\(club.stadiumCapacity / 1000)K", .green, "person.3.fill")
                previewStatRow("Formation", club.formation, .purple, "rectangle.split.3x3")
                previewStatRow("League Titles", "\(club.leagueTitles)", .yellow, "trophy.fill")
                previewStatRow("Cup Wins", "\(club.cupWins)", .yellow, "trophy")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Spacer(minLength: 4)

            // Sign contract button
            Button {
                signContract(club)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 14, weight: .bold))
                    Text("Sign Contract")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .clipShape(.rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(16)
        }
        .frame(width: 260)
        .background(Color(white: 0.07))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1),
            alignment: .leading
        )
        .shadow(color: .black.opacity(0.5), radius: 16, x: -6)
    }

    private func previewStatRow(_ label: String, _ value: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .frame(width: 18)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }

    private func formatCurrencyLocal(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            return String(format: "%.1fM", Double(amount) / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "%.0fK", Double(amount) / 1_000)
        }
        return "€\(amount)"
    }

    // MARK: - Contract Signing

    private func signContract(_ club: Club) {
        signingClub = club
        signingPhase = .fadeIn
        ringScale = 0.3
        ringOpacity = 0

        withAnimation(.easeIn(duration: 0.5)) {
            showSigningOverlay = true
        }

        // Phase 1: Color ring expands
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(duration: 0.7, bounce: 0.2)) {
                signingPhase = .reveal
                ringScale = 1.0
                ringOpacity = 1.0
            }
        }
        // Phase 2: Badge appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                signingPhase = .badge
            }
        }
        // Phase 3: Welcome text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.6)) {
                signingPhase = .welcome
            }
        }
        // Start game
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            viewModel.startNewGame(clubId: club.id)
        }
    }

    private func contractSigningOverlay(_ club: Club) -> some View {
        ZStack {
            // Dark background
            Color.black
                .opacity(signingPhase == .fadeIn ? 0.6 : 0.95)
                .ignoresSafeArea()
                .animation(.easeIn(duration: 0.5), value: signingPhase)

            // Expanding color ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            club.primarySwiftUIColor,
                            club.primarySwiftUIColor.opacity(0.3),
                            club.secondarySwiftUIColor,
                            club.secondarySwiftUIColor.opacity(0.3),
                            club.primarySwiftUIColor
                        ],
                        center: .center
                    ),
                    lineWidth: signingPhase == .reveal || signingPhase == .badge || signingPhase == .welcome ? 4 : 60
                )
                .frame(width: 160, height: 160)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .blur(radius: signingPhase == .fadeIn ? 10 : 0)

            // Soft glow behind badge
            if signingPhase == .badge || signingPhase == .welcome {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [club.primarySwiftUIColor.opacity(0.35), .clear],
                            center: .center, startRadius: 0, endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                Spacer()

                // Badge
                if signingPhase == .badge || signingPhase == .welcome {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [club.primarySwiftUIColor.opacity(0.7), club.primarySwiftUIColor.opacity(0.15)],
                                    center: .center, startRadius: 0, endRadius: 55
                                )
                            )
                            .frame(width: 100, height: 100)

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [club.primarySwiftUIColor, club.secondarySwiftUIColor],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 100, height: 100)

                        Text(club.shortName)
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
                }

                // Welcome text
                if signingPhase == .welcome {
                    VStack(spacing: 10) {
                        Text("WELCOME TO")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(6)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 28)

                        Text(club.name.uppercased())
                            .font(.system(size: 24, weight: .black))
                            .tracking(2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, club.primarySwiftUIColor.opacity(0.8)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)

                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(
                                    LinearGradient(colors: [.clear, club.primarySwiftUIColor.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: 60, height: 1)

                            Text("  NEW MANAGER  ")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(3)
                                .foregroundStyle(club.primarySwiftUIColor.opacity(0.7))

                            Rectangle()
                                .fill(
                                    LinearGradient(colors: [club.primarySwiftUIColor.opacity(0.6), .clear], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: 60, height: 1)
                        }
                        .padding(.top, 6)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
            }
        }
    }
}

// MARK: - Club Card

struct ClubCard: View {
    let club: Club
    var isSelected: Bool = false
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [club.primarySwiftUIColor.opacity(0.5), club.primarySwiftUIColor.opacity(0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Circle()
                        .stroke(club.primarySwiftUIColor.opacity(0.7), lineWidth: 2)
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
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.green.opacity(0.15) : Color.white.opacity(0.06))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green.opacity(0.6) : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
