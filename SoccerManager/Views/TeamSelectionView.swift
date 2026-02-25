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

    enum SigningPhase {
        case fadeIn, penDown, signed, welcome
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

        return ScrollView {
            VStack(spacing: 0) {
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

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
        withAnimation(.easeIn(duration: 0.4)) {
            showSigningOverlay = true
        }

        // Phase sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.5)) {
                signingPhase = .penDown
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.spring(duration: 0.4)) {
                signingPhase = .signed
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                signingPhase = .welcome
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            viewModel.startNewGame(clubId: club.id)
        }
    }

    private func contractSigningOverlay(_ club: Club) -> some View {
        ZStack {
            Color.black
                .opacity(signingPhase == .fadeIn ? 0.7 : 0.92)
                .ignoresSafeArea()
                .animation(.easeIn(duration: 0.4), value: signingPhase)

            VStack(spacing: 24) {
                if signingPhase == .welcome {
                    // Welcome phase — club badge + name
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(club.primarySwiftUIColor.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .scaleEffect(1.2)
                                .blur(radius: 20)
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [club.primarySwiftUIColor.opacity(0.7), club.primarySwiftUIColor.opacity(0.2)],
                                        center: .center, startRadius: 0, endRadius: 50
                                    )
                                )
                                .frame(width: 80, height: 80)
                            Circle()
                                .stroke(club.primarySwiftUIColor, lineWidth: 3)
                                .frame(width: 80, height: 80)
                            Text(club.shortName)
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .transition(.scale.combined(with: .opacity))

                        Text("Welcome to \(club.name)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.opacity)

                        Text("You are the new manager")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                            .transition(.opacity)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    // Contract signing animation
                    VStack(spacing: 20) {
                        // Paper
                        VStack(spacing: 12) {
                            Text("MANAGER CONTRACT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black.opacity(0.3))
                                .tracking(3)

                            Divider().frame(width: 180)

                            VStack(spacing: 6) {
                                Text(club.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.black)

                                Text("hereby appoints")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.black.opacity(0.5))

                                Text("YOU")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(.black)

                                Text("as First Team Manager")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.black.opacity(0.5))
                            }

                            Spacer().frame(height: 8)

                            // Signature line
                            VStack(spacing: 2) {
                                if signingPhase == .penDown || signingPhase == .signed {
                                    // Signature scribble
                                    Text("~ Manager ~")
                                        .font(.system(size: 14, design: .serif))
                                        .italic()
                                        .foregroundStyle(.blue.opacity(0.7))
                                        .transition(.opacity.combined(with: .offset(y: 5)))
                                }
                                Rectangle()
                                    .fill(Color.black.opacity(0.2))
                                    .frame(width: 140, height: 1)
                                Text("Signature")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.black.opacity(0.3))
                            }

                            if signingPhase == .signed {
                                // Stamp
                                Text("✓ SIGNED")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(.red.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(.red.opacity(0.5), lineWidth: 2)
                                    )
                                    .rotationEffect(.degrees(-8))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(24)
                        .frame(width: 260)
                        .background(Color(white: 0.95))
                        .clipShape(.rect(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)

                        // Pen icon
                        if signingPhase == .penDown {
                            Image(systemName: "pencil.and.scribble")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.6))
                                .transition(.opacity.combined(with: .offset(y: 10)))
                        }
                    }
                }
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
