import Foundation

struct GameDataGenerator {
    static let firstNames = [
        "James", "Oliver", "Harry", "Jack", "Charlie", "Thomas", "George", "Oscar",
        "William", "Henry", "Lucas", "Daniel", "Alexander", "Mason", "Ethan",
        "Marco", "Luca", "Giovanni", "Alessandro", "Andrea", "Matteo", "Lorenzo",
        "Pablo", "Carlos", "Miguel", "Alejandro", "Diego", "Sergio", "Luis", "Fernando",
        "Pierre", "Antoine", "Hugo", "Paul", "Kylian", "Ousmane", "Adrien", "Theo",
        "Leon", "Kai", "Joshua", "Florian", "Jamal", "Leroy", "Niklas", "Timo",
        "Bruno", "Diogo", "Bernardo", "Ruben", "Joao", "Rafael", "Goncalo", "Pedro",
        "Robin", "Memphis", "Frenkie", "Matthijs", "Ryan", "Cody", "Daley", "Virgil",
        "Callum", "Connor", "Liam", "Noah", "Ben", "Sam", "Jake", "Alfie",
        "Archie", "Tyler", "Nathan", "Reece", "Kyle", "Aaron", "Jordan", "Declan",
        "Jude", "Bukayo", "Marcus", "Phil", "Cole", "Ebere", "Ivan", "Dominic",
        "Ollie", "Rhys", "Ellis", "Kieffer", "Conor", "Brennan", "Louie", "Jayden"
    ]

    static let lastNames = [
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Wilson", "Taylor", "Davies",
        "Evans", "Walker", "Roberts", "Clark", "Wright", "Hall", "Young",
        "Rossi", "Ferrari", "Bianchi", "Romano", "Colombo", "Ricci", "Marino",
        "Garcia", "Rodriguez", "Martinez", "Lopez", "Hernandez", "Gonzalez", "Perez",
        "Dupont", "Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard",
        "Mueller", "Schmidt", "Schneider", "Fischer", "Weber", "Wagner", "Becker",
        "Silva", "Santos", "Ferreira", "Oliveira", "Costa", "Rodrigues", "Almeida",
        "De Jong", "Van Dijk", "De Ligt", "Bakker", "Visser", "Smit", "Meijer",
        "Moore", "Thompson", "White", "Harris", "Green", "Baker", "King", "Hill",
        "Adams", "Nelson", "Carter", "Mitchell", "Collins", "Turner", "Parker", "Edwards",
        "Morris", "Cook", "Morgan", "Bell", "Murphy", "Bailey", "Cooper", "Ward",
        "Cox", "Richardson", "Wood", "Watson", "Brooks", "Bennett", "Gray", "Hughes",
        "Palmer", "Watkins", "Saka", "Rice", "Foden", "Gordon", "Gibbs", "Gallagher"
    ]

    static func generatePlayer(clubId: UUID?, position: PlayerPosition, quality: Int) -> Player {
        let firstName = firstNames.randomElement()!
        let lastName = lastNames.randomElement()!
        let age = Int.random(in: 17...35)
        let variance = Int.random(in: -12...12)
        let overall = max(25, min(99, quality + variance))

        let offensive: Int
        let defensive: Int
        let physical: Int

        switch position {
        case .goalkeeper:
            offensive = max(10, overall - Int.random(in: 20...35))
            defensive = min(99, overall + Int.random(in: 5...15))
            physical = max(30, overall - Int.random(in: 0...10))
        case .centerBack, .leftBack, .rightBack:
            offensive = max(15, overall - Int.random(in: 10...25))
            defensive = min(99, overall + Int.random(in: 5...15))
            physical = min(99, overall + Int.random(in: 0...10))
        case .defensiveMidfield:
            offensive = max(20, overall - Int.random(in: 5...15))
            defensive = min(99, overall + Int.random(in: 3...10))
            physical = min(99, overall + Int.random(in: 0...8))
        case .centralMidfield, .attackingMidfield:
            offensive = min(99, overall + Int.random(in: 0...10))
            defensive = max(25, overall - Int.random(in: 5...15))
            physical = max(30, overall - Int.random(in: 0...8))
        case .leftWing, .rightWing:
            offensive = min(99, overall + Int.random(in: 5...15))
            defensive = max(15, overall - Int.random(in: 15...30))
            physical = min(99, overall + Int.random(in: 0...10))
        case .striker:
            offensive = min(99, overall + Int.random(in: 8...18))
            defensive = max(10, overall - Int.random(in: 20...35))
            physical = min(99, overall + Int.random(in: 0...8))
        }

        let stats = PlayerStats(
            overall: overall,
            offensive: offensive,
            defensive: defensive,
            physical: physical
        )

        let wage = max(1000, overall * overall * 5)
        let player = Player(
            firstName: firstName,
            lastName: lastName,
            age: age,
            position: position,
            stats: stats,
            wage: wage,
            marketValue: 0,
            clubId: clubId,
            contractYearsLeft: Int.random(in: 1...5)
        )
        player.marketValue = player.calculateMarketValue()
        return player
    }

    static func generateSquad(clubId: UUID, quality: Int) -> [Player] {
        var players: [Player] = []
        let positions: [(PlayerPosition, Int)] = [
            (.goalkeeper, 2),
            (.centerBack, 4),
            (.leftBack, 2),
            (.rightBack, 2),
            (.defensiveMidfield, 2),
            (.centralMidfield, 3),
            (.attackingMidfield, 2),
            (.leftWing, 2),
            (.rightWing, 2),
            (.striker, 3)
        ]
        for (pos, count) in positions {
            for _ in 0..<count {
                players.append(generatePlayer(clubId: clubId, position: pos, quality: quality))
            }
        }
        return players
    }

    struct LeagueData {
        let name: String
        let country: String
        let emoji: String
        let tier: Int
        let maxRating: Int
        let clubs: [(name: String, shortName: String, rating: Int, budget: Int, stadium: String, capacity: Int, primary: String, secondary: String)]
    }

    static func createAllLeagues() -> ([League], [Club]) {
        var leagues: [League] = []
        var clubs: [Club] = []

        let leagueDataList: [LeagueData] = [

            // ─── ENGLAND TIER 1: PREMIER LEAGUE (20 teams) ────────────────────
            LeagueData(name: "Premier League", country: "England", emoji: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", tier: 1, maxRating: 100, clubs: [
                ("Manchester City", "MCI", 92, 200_000_000, "Etihad Stadium", 53400, "skyblue", "white"),
                ("Arsenal", "ARS", 89, 150_000_000, "Emirates Stadium", 60704, "red", "white"),
                ("Liverpool", "LIV", 88, 140_000_000, "Anfield", 61276, "red", "red"),
                ("Chelsea", "CHE", 84, 180_000_000, "Stamford Bridge", 40341, "blue", "white"),
                ("Manchester United", "MUN", 82, 160_000_000, "Old Trafford", 74310, "red", "white"),
                ("Tottenham", "TOT", 80, 100_000_000, "Tottenham Stadium", 62850, "white", "navy"),
                ("Newcastle", "NEW", 79, 120_000_000, "St James' Park", 52305, "black", "white"),
                ("Aston Villa", "AVL", 78, 80_000_000, "Villa Park", 42657, "claret", "blue"),
                ("Brighton", "BHA", 76, 60_000_000, "Amex Stadium", 31876, "blue", "white"),
                ("West Ham", "WHU", 74, 70_000_000, "London Stadium", 62500, "claret", "blue"),
                ("Crystal Palace", "CRY", 72, 50_000_000, "Selhurst Park", 25486, "red", "blue"),
                ("Fulham", "FUL", 71, 45_000_000, "Craven Cottage", 25700, "white", "black"),
                ("Brentford", "BRE", 70, 40_000_000, "Brentford Stadium", 17250, "red", "white"),
                ("Wolves", "WOL", 70, 45_000_000, "Molineux", 32050, "orange", "black"),
                ("Bournemouth", "BOU", 69, 35_000_000, "Vitality Stadium", 11364, "red", "black"),
                ("Nottm Forest", "NFO", 69, 40_000_000, "City Ground", 30332, "red", "white"),
                ("Everton", "EVE", 69, 35_000_000, "Goodison Park", 39414, "blue", "white"),
                ("Leicester City", "LEI", 70, 30_000_000, "King Power Stadium", 32261, "blue", "white"),
                ("Ipswich Town", "IPS", 69, 20_000_000, "Portman Road", 30311, "blue", "white"),
                ("Southampton", "SOU", 69, 25_000_000, "St Mary's Stadium", 32384, "red", "white"),
            ]),

            // ─── ENGLAND TIER 2: EFL CHAMPIONSHIP (24 teams) ──────────────────
            LeagueData(name: "EFL Championship", country: "England", emoji: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", tier: 2, maxRating: 80, clubs: [
                ("Leeds United", "LEE", 74, 40_000_000, "Elland Road", 37890, "white", "yellow"),
                ("Burnley", "BUR", 73, 35_000_000, "Turf Moor", 21944, "claret", "blue"),
                ("Sheffield United", "SHU", 72, 30_000_000, "Bramall Lane", 32609, "red", "white"),
                ("Luton Town", "LUT", 70, 20_000_000, "Kenilworth Road", 10356, "orange", "navy"),
                ("Sunderland", "SUN", 70, 25_000_000, "Stadium of Light", 49000, "red", "white"),
                ("Norwich City", "NOR", 69, 25_000_000, "Carrow Road", 27244, "yellow", "green"),
                ("Middlesbrough", "MID", 68, 22_000_000, "Riverside Stadium", 34742, "red", "white"),
                ("Coventry City", "COV", 67, 18_000_000, "Coventry Arena", 32609, "skyblue", "white"),
                ("West Brom", "WBA", 67, 20_000_000, "The Hawthorns", 26850, "navy", "white"),
                ("Watford", "WAT", 66, 20_000_000, "Vicarage Road", 22220, "yellow", "black"),
                ("Stoke City", "STK", 66, 18_000_000, "bet365 Stadium", 30089, "red", "white"),
                ("Swansea City", "SWA", 65, 15_000_000, "Swansea.com Stadium", 21088, "white", "black"),
                ("Bristol City", "BRC", 64, 15_000_000, "Ashton Gate", 27000, "red", "white"),
                ("Hull City", "HUL", 64, 14_000_000, "MKM Stadium", 25586, "orange", "black"),
                ("Millwall", "MIL", 63, 12_000_000, "The Den", 20146, "blue", "white"),
                ("QPR", "QPR", 62, 12_000_000, "Loftus Road", 18439, "blue", "white"),
                ("Preston North End", "PNE", 62, 10_000_000, "Deepdale", 23404, "white", "navy"),
                ("Blackburn Rovers", "BLB", 61, 10_000_000, "Ewood Park", 31367, "blue", "white"),
                ("Cardiff City", "CAR", 61, 10_000_000, "Cardiff Stadium", 33280, "blue", "white"),
                ("Sheffield Wed", "SHW", 60, 10_000_000, "Hillsborough", 39732, "blue", "white"),
                ("Plymouth Argyle", "PLY", 60, 8_000_000, "Home Park", 18600, "green", "white"),
                ("Birmingham City", "BIR", 60, 10_000_000, "St Andrew's", 29409, "blue", "white"),
                ("Rotherham Utd", "ROT", 59, 6_000_000, "New York Stadium", 12021, "red", "white"),
                ("Huddersfield", "HUD", 59, 8_000_000, "John Smith's Stadium", 24121, "blue", "white"),
            ]),

            // ─── ENGLAND TIER 3: EFL LEAGUE ONE (24 teams) ────────────────────
            LeagueData(name: "EFL League One", country: "England", emoji: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", tier: 3, maxRating: 65, clubs: [
                ("Derby County", "DER", 64, 12_000_000, "Pride Park", 33597, "white", "black"),
                ("Portsmouth", "POM", 63, 10_000_000, "Fratton Park", 20688, "blue", "white"),
                ("Bolton Wanderers", "BOL", 62, 10_000_000, "Toughsheet Stadium", 28723, "white", "navy"),
                ("Wigan Athletic", "WIG", 61, 8_000_000, "DW Stadium", 25138, "blue", "white"),
                ("Barnsley", "BNS", 60, 7_000_000, "Oakwell", 23287, "red", "white"),
                ("Charlton Athletic", "CHA", 59, 7_000_000, "The Valley", 27111, "red", "white"),
                ("Reading", "REA", 58, 8_000_000, "Select Car Leasing Stadium", 24161, "blue", "white"),
                ("Peterborough", "PET", 57, 6_000_000, "London Road", 15314, "blue", "white"),
                ("Stockport County", "STO", 56, 5_000_000, "Edgeley Park", 10852, "blue", "white"),
                ("Oxford United", "OXF", 56, 5_000_000, "Kassam Stadium", 12500, "yellow", "navy"),
                ("Leyton Orient", "LEY", 55, 4_000_000, "Brisbane Road", 9271, "red", "white"),
                ("Port Vale", "PTV", 54, 3_500_000, "Vale Park", 18947, "white", "black"),
                ("Shrewsbury Town", "SHR", 53, 3_000_000, "Croud Meadow", 9875, "blue", "yellow"),
                ("Cambridge Utd", "CMB", 52, 3_000_000, "Abbey Stadium", 8127, "yellow", "black"),
                ("Lincoln City", "LIN", 52, 3_500_000, "LNER Stadium", 10120, "red", "white"),
                ("Cheltenham Town", "CLT", 51, 2_500_000, "Jonny-Rocks Stadium", 7066, "red", "white"),
                ("Fleetwood Town", "FLE", 50, 2_500_000, "Highbury Stadium", 5327, "red", "white"),
                ("Burton Albion", "BUA", 50, 2_000_000, "Pirelli Stadium", 6912, "yellow", "black"),
                ("Northampton", "NTH", 50, 3_000_000, "Sixfields Stadium", 7798, "claret", "white"),
                ("Exeter City", "EXE", 49, 2_500_000, "St James Park", 8696, "red", "white"),
                ("Stevenage", "STV", 49, 2_000_000, "Lamex Stadium", 7100, "red", "white"),
                ("Wycombe", "WYC", 49, 2_500_000, "Adams Park", 10000, "navy", "skyblue"),
                ("Bristol Rovers", "BRR", 48, 2_500_000, "Memorial Stadium", 11916, "blue", "white"),
                ("Carlisle United", "CAL", 48, 2_000_000, "Brunton Park", 18202, "blue", "white"),
            ]),

            // ─── ENGLAND TIER 4: EFL LEAGUE TWO (24 teams) ────────────────────
            LeagueData(name: "EFL League Two", country: "England", emoji: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", tier: 4, maxRating: 60, clubs: [
                ("Wrexham", "WRE", 56, 6_000_000, "Racecourse Ground", 10771, "red", "white"),
                ("Mansfield Town", "MAN", 54, 3_500_000, "Field Mill", 9186, "yellow", "blue"),
                ("MK Dons", "MKD", 53, 4_000_000, "Stadium MK", 30500, "white", "red"),
                ("Bradford City", "BRA", 52, 3_000_000, "Valley Parade", 25136, "claret", "yellow"),
                ("Notts County", "NTC", 51, 2_500_000, "Meadow Lane", 20211, "black", "white"),
                ("Crewe Alexandra", "CRE", 50, 2_500_000, "Gresty Road", 10153, "red", "white"),
                ("Doncaster Rovers", "DON", 50, 2_500_000, "Keepmoat Stadium", 15231, "red", "white"),
                ("Gillingham", "GIL", 49, 2_000_000, "Priestfield Stadium", 11582, "blue", "white"),
                ("Salford City", "SFD", 49, 3_000_000, "Peninsula Stadium", 5108, "red", "white"),
                ("Tranmere Rovers", "TRA", 48, 2_000_000, "Prenton Park", 16567, "white", "blue"),
                ("Swindon Town", "SWI", 48, 2_000_000, "County Ground", 15728, "red", "white"),
                ("Walsall", "WAS", 47, 1_500_000, "Bescot Stadium", 11300, "red", "white"),
                ("Grimsby Town", "GRI", 46, 1_500_000, "Blundell Park", 9052, "black", "white"),
                ("Newport County", "NWP", 46, 1_500_000, "Rodney Parade", 8500, "yellow", "black"),
                ("Crawley Town", "CRA", 45, 1_500_000, "Broadfield Stadium", 6134, "red", "white"),
                ("Accrington", "ACC", 44, 1_200_000, "Wham Stadium", 5450, "red", "white"),
                ("Harrogate Town", "HGT", 44, 1_200_000, "Wetherby Road", 5000, "yellow", "black"),
                ("Colchester Utd", "COL", 43, 1_500_000, "JobServe Stadium", 10105, "blue", "white"),
                ("AFC Wimbledon", "AFW", 43, 1_500_000, "Plough Lane", 9215, "blue", "yellow"),
                ("Morecambe", "MOR", 42, 1_000_000, "Mazuma Stadium", 6476, "red", "white"),
                ("Sutton United", "SUT", 41, 1_000_000, "VBS Community Stadium", 5013, "yellow", "green"),
                ("Barrow", "BAW", 41, 1_000_000, "Holker Street", 5268, "blue", "white"),
                ("Forest Green", "FGR", 40, 1_000_000, "New Lawn", 5147, "green", "black"),
                ("Rochdale", "ROC", 42, 1_200_000, "Crown Oil Arena", 10249, "blue", "black"),
            ]),

            // ─── ENGLAND TIER 5: NATIONAL LEAGUE (24 teams) ───────────────────
            LeagueData(name: "National League", country: "England", emoji: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", tier: 5, maxRating: 52, clubs: [
                ("Chesterfield", "CHF", 50, 2_000_000, "SMH Group Stadium", 10504, "blue", "white"),
                ("Bromley", "BRM", 48, 900_000, "Hayes Lane", 5150, "white", "black"),
                ("Solihull Moors", "SOL", 47, 1_000_000, "Damson Park", 3050, "yellow", "blue"),
                ("York City", "YOR", 46, 1_200_000, "LNER Community Stadium", 8256, "red", "navy"),
                ("Oldham Athletic", "OLD", 46, 1_500_000, "Boundary Park", 13624, "blue", "white"),
                ("Southend United", "SEN", 45, 1_000_000, "Roots Hall", 12392, "blue", "white"),
                ("Scunthorpe Utd", "SCU", 44, 900_000, "Glanford Park", 9183, "claret", "blue"),
                ("Woking", "WOK", 44, 800_000, "Kingfield Stadium", 6036, "red", "white"),
                ("Hartlepool Utd", "HRT", 43, 800_000, "Suit Direct Stadium", 7856, "blue", "white"),
                ("Eastleigh", "EAS", 42, 700_000, "Silverlake Stadium", 5192, "blue", "white"),
                ("Aldershot Town", "ALD", 42, 700_000, "EBB Stadium", 7100, "red", "blue"),
                ("Halifax Town", "HAL", 41, 800_000, "The Shay", 10762, "blue", "white"),
                ("Boreham Wood", "BOR", 40, 600_000, "Meadow Park", 4502, "white", "black"),
                ("Barnet", "BNT", 40, 600_000, "The Hive", 6500, "orange", "black"),
                ("Dagenham & Red", "DAG", 39, 600_000, "Victoria Road", 6078, "red", "blue"),
                ("Gateshead", "GAT", 39, 500_000, "Gateshead Stadium", 11800, "white", "black"),
                ("Maidenhead Utd", "MAI", 38, 500_000, "York Road", 4500, "black", "white"),
                ("Wealdstone", "WEA", 37, 400_000, "Grosvenor Vale", 4070, "blue", "white"),
                ("Altrincham", "ALT", 37, 500_000, "J.Davidson Stadium", 6085, "red", "white"),
                ("Dorking Wand", "DOR", 36, 400_000, "Meadowbank", 3000, "red", "white"),
                ("Torquay United", "TRQ", 35, 400_000, "Plainmoor", 6104, "yellow", "navy"),
                ("Fylde", "FYL", 35, 400_000, "Mill Farm", 6000, "white", "red"),
                ("Ebbsfleet Utd", "EBB", 34, 350_000, "Stonebridge Road", 4769, "red", "white"),
                ("Kidderminster", "KID", 33, 350_000, "Aggborough", 6444, "red", "white"),
            ]),

            // ─── LA LIGA ──────────────────────────────────────────────────────
            LeagueData(name: "La Liga", country: "Spain", emoji: "🇪🇸", tier: 1, maxRating: 100, clubs: [
                ("Real Madrid", "RMA", 93, 250_000_000, "Santiago Bernabeu", 81044, "white", "white"),
                ("Barcelona", "BAR", 90, 180_000_000, "Camp Nou", 99354, "blue", "red"),
                ("Atletico Madrid", "ATM", 84, 100_000_000, "Metropolitano", 68456, "red", "white"),
                ("Real Sociedad", "RSO", 78, 50_000_000, "Anoeta", 39500, "blue", "white"),
                ("Villarreal", "VIL", 76, 55_000_000, "La Ceramica", 23500, "yellow", "blue"),
                ("Athletic Bilbao", "ATH", 77, 60_000_000, "San Mames", 53289, "red", "white"),
                ("Real Betis", "BET", 75, 45_000_000, "Benito Villamarin", 60721, "green", "white"),
                ("Sevilla", "SEV", 74, 50_000_000, "Ramon Sanchez-Pizjuan", 43883, "white", "red"),
                ("Valencia", "VAL", 72, 40_000_000, "Mestalla", 49430, "white", "orange"),
                ("Girona", "GIR", 73, 35_000_000, "Montilivi", 14286, "red", "white"),
                ("Celta Vigo", "CEL", 68, 25_000_000, "Balaidos", 29000, "skyblue", "white"),
                ("Osasuna", "OSA", 66, 20_000_000, "El Sadar", 23576, "red", "navy"),
                ("Getafe", "GET", 64, 18_000_000, "Coliseum", 17393, "blue", "white"),
                ("Mallorca", "MLL", 65, 18_000_000, "Son Moix", 23142, "red", "black"),
                ("Rayo Vallecano", "RAY", 63, 15_000_000, "Vallecas", 14708, "white", "red"),
                ("Las Palmas", "LPA", 61, 15_000_000, "Gran Canaria", 32392, "yellow", "blue"),
                ("Alaves", "ALA", 60, 12_000_000, "Mendizorroza", 19840, "blue", "white"),
                ("Cadiz", "CAD", 58, 10_000_000, "Nuevo Mirandilla", 25033, "yellow", "blue"),
                ("Granada", "GRA", 57, 10_000_000, "Los Carmenes", 22524, "red", "white"),
                ("Almeria", "ALM", 55, 8_000_000, "Power Horse", 15200, "red", "white"),
            ]),

            // ─── LA LIGA 2 (SEGUNDA DIVISIÓN) ────────────────────────────────
            LeagueData(name: "La Liga 2", country: "Spain", emoji: "🇪🇸", tier: 2, maxRating: 72, clubs: [
                ("Levante", "LEV", 66, 15_000_000, "Ciutat de Valencia", 25354, "blue", "red"),
                ("Real Valladolid", "VLL", 64, 12_000_000, "Jose Zorrilla", 26512, "purple", "white"),
                ("Eibar", "EIB", 63, 10_000_000, "Ipurua", 8164, "blue", "red"),
                ("Sporting Gijon", "SGI", 62, 10_000_000, "El Molinon", 30000, "red", "white"),
                ("Racing Santander", "RAC", 61, 8_000_000, "El Sardinero", 22222, "green", "white"),
                ("Real Zaragoza", "ZAR", 62, 10_000_000, "La Romareda", 34596, "blue", "white"),
                ("Real Oviedo", "OVI", 61, 9_000_000, "Carlos Tartiere", 30500, "blue", "white"),
                ("Tenerife", "TEN", 60, 8_000_000, "Heliodoro Rodriguez", 22824, "blue", "white"),
                ("Huesca", "HUE", 59, 6_000_000, "El Alcoraz", 7638, "blue", "red"),
                ("Leganes", "LEG", 60, 8_000_000, "Butarque", 12454, "blue", "white"),
                ("Elche", "ELC", 59, 7_000_000, "Martinez Valero", 33732, "green", "white"),
                ("Albacete", "ALB", 57, 5_000_000, "Carlos Belmonte", 17300, "white", "red"),
                ("Burgos", "BUR", 56, 4_000_000, "El Plantio", 12200, "black", "white"),
                ("Mirandes", "MIR", 55, 3_500_000, "Anduva", 5766, "red", "black"),
                ("Villarreal B", "VIB", 56, 5_000_000, "Mini Estadi", 6000, "yellow", "blue"),
                ("Cartagena", "CAR", 56, 4_000_000, "Cartagonova", 15105, "white", "black"),
                ("Andorra", "AND", 55, 3_000_000, "Nacional", 3306, "blue", "yellow"),
                ("Ponferradina", "PON", 54, 3_000_000, "El Toralin", 9762, "blue", "white"),
                ("Amorebieta", "AMO", 53, 2_500_000, "Urritxe", 4000, "blue", "white"),
                ("Alcorcon", "ALC", 53, 2_500_000, "Santo Domingo", 5100, "yellow", "blue"),
                ("Eldense", "ELD", 52, 2_000_000, "Nuevo Pepico Amat", 6420, "blue", "white"),
                ("Ferrol", "FER", 52, 2_000_000, "A Malata", 10500, "green", "white"),
            ]),

            // ─── SERIE A ─────────────────────────────────────────────────────
            LeagueData(name: "Serie A", country: "Italy", emoji: "🇮🇹", tier: 1, maxRating: 100, clubs: [
                ("Inter Milan", "INT", 88, 140_000_000, "San Siro", 75923, "blue", "black"),
                ("AC Milan", "MIL", 83, 120_000_000, "San Siro", 75923, "red", "black"),
                ("Juventus", "JUV", 84, 150_000_000, "Allianz Stadium", 41507, "white", "black"),
                ("Napoli", "NAP", 82, 100_000_000, "Diego Maradona", 54726, "blue", "white"),
                ("Roma", "ROM", 79, 80_000_000, "Stadio Olimpico", 72698, "orange", "red"),
                ("Lazio", "LAZ", 77, 60_000_000, "Stadio Olimpico", 72698, "skyblue", "white"),
                ("Atalanta", "ATA", 80, 70_000_000, "Gewiss Stadium", 21300, "blue", "black"),
                ("Fiorentina", "FIO", 75, 50_000_000, "Artemio Franchi", 43147, "purple", "white"),
                ("Bologna", "BOL", 74, 40_000_000, "Renato Dall'Ara", 38279, "red", "blue"),
                ("Torino", "TOR", 70, 35_000_000, "Stadio Olimpico GT", 28177, "maroon", "white"),
                ("Monza", "MON", 66, 30_000_000, "U-Power Stadium", 18568, "red", "white"),
                ("Udinese", "UDI", 67, 25_000_000, "Dacia Arena", 25144, "white", "black"),
                ("Sassuolo", "SAS", 64, 20_000_000, "Mapei Stadium", 21525, "green", "black"),
                ("Empoli", "EMP", 62, 15_000_000, "Carlo Castellani", 16284, "blue", "white"),
                ("Cagliari", "CAG", 63, 18_000_000, "Unipol Domus", 16416, "red", "blue"),
                ("Genoa", "GEN", 65, 20_000_000, "Luigi Ferraris", 36536, "red", "blue"),
                ("Verona", "VER", 61, 15_000_000, "Bentegodi", 39211, "yellow", "blue"),
                ("Lecce", "LEC", 60, 12_000_000, "Via del Mare", 33876, "yellow", "red"),
                ("Frosinone", "FRO", 56, 8_000_000, "Benito Stirpe", 16227, "yellow", "blue"),
                ("Salernitana", "SAL", 54, 8_000_000, "Arechi", 37245, "maroon", "white"),
            ]),

            // ─── SERIE B ─────────────────────────────────────────────────────
            LeagueData(name: "Serie B", country: "Italy", emoji: "🇮🇹", tier: 2, maxRating: 70, clubs: [
                ("Parma", "PAR", 67, 18_000_000, "Ennio Tardini", 27906, "yellow", "blue"),
                ("Como", "COM", 65, 12_000_000, "Giuseppe Sinigaglia", 13602, "blue", "white"),
                ("Venezia", "VEN", 64, 12_000_000, "Pier Luigi Penzo", 11150, "black", "green"),
                ("Cremonese", "CRE", 63, 10_000_000, "Giovanni Zini", 20641, "red", "white"),
                ("Palermo", "PAL", 64, 14_000_000, "Renzo Barbera", 36349, "pink", "black"),
                ("Sampdoria", "SAM", 62, 10_000_000, "Luigi Ferraris", 36536, "blue", "white"),
                ("Catanzaro", "CTZ", 60, 5_000_000, "Nicola Ceravolo", 19787, "yellow", "red"),
                ("Brescia", "BRE", 61, 8_000_000, "Mario Rigamonti", 19066, "blue", "white"),
                ("Bari", "BRI", 62, 8_000_000, "San Nicola", 58270, "white", "red"),
                ("Modena", "MOD", 59, 5_000_000, "Alberto Braglia", 21151, "yellow", "blue"),
                ("Spezia", "SPE", 60, 7_000_000, "Alberto Picco", 10336, "white", "black"),
                ("Pisa", "PIS", 61, 7_000_000, "Arena Garibaldi", 12067, "blue", "black"),
                ("Reggiana", "REG", 58, 4_000_000, "Mapei Stadium", 21525, "maroon", "white"),
                ("Sudtirol", "SUD", 57, 3_500_000, "Druso", 5000, "red", "white"),
                ("Ascoli", "ASC", 57, 4_000_000, "Cino e Lillo Del Duca", 20396, "white", "black"),
                ("Cittadella", "CIT", 56, 3_000_000, "Tombolato", 7623, "red", "blue"),
                ("Ternana", "TER", 55, 3_000_000, "Libero Liberati", 22500, "red", "green"),
                ("Cosenza", "COS", 55, 2_500_000, "San Vito", 24479, "red", "blue"),
                ("Feralpisalo", "FER", 54, 2_000_000, "Lino Turina", 4500, "blue", "green"),
                ("Perugia", "PER", 56, 4_000_000, "Renato Curi", 28000, "red", "white"),
            ]),

            // ─── BUNDESLIGA ──────────────────────────────────────────────────
            LeagueData(name: "Bundesliga", country: "Germany", emoji: "🇩🇪", tier: 1, maxRating: 100, clubs: [
                ("Bayern Munich", "BAY", 91, 200_000_000, "Allianz Arena", 75024, "red", "white"),
                ("Borussia Dortmund", "BVB", 84, 100_000_000, "Signal Iduna Park", 81365, "yellow", "black"),
                ("RB Leipzig", "RBL", 80, 80_000_000, "Red Bull Arena", 42558, "red", "white"),
                ("Bayer Leverkusen", "B04", 85, 90_000_000, "BayArena", 30210, "red", "black"),
                ("Eintracht Frankfurt", "SGE", 76, 50_000_000, "Waldstadion", 51500, "black", "red"),
                ("VfB Stuttgart", "VFB", 77, 50_000_000, "MHPArena", 60449, "white", "red"),
                ("Wolfsburg", "WOB", 72, 45_000_000, "Volkswagen Arena", 30000, "green", "white"),
                ("Freiburg", "SCF", 74, 40_000_000, "Europa-Park Stadion", 34700, "red", "white"),
                ("Hoffenheim", "TSG", 71, 35_000_000, "PreZero Arena", 30150, "blue", "white"),
                ("Union Berlin", "FCU", 70, 30_000_000, "Alte Forsterei", 22012, "red", "white"),
                ("Monchengladbach", "BMG", 69, 30_000_000, "Borussia-Park", 54042, "black", "green"),
                ("Werder Bremen", "SVW", 68, 25_000_000, "Weserstadion", 42100, "green", "white"),
                ("Mainz", "M05", 66, 20_000_000, "Mewa Arena", 34034, "red", "white"),
                ("Augsburg", "FCA", 64, 18_000_000, "WWK Arena", 30660, "red", "green"),
                ("Heidenheim", "HDH", 62, 12_000_000, "Voith-Arena", 15000, "red", "blue"),
                ("Koln", "KOE", 63, 20_000_000, "RheinEnergieStadion", 50000, "white", "red"),
                ("Bochum", "BOC", 60, 12_000_000, "Vonovia Ruhrstadion", 27599, "blue", "white"),
                ("Darmstadt", "D98", 55, 8_000_000, "Merck-Stadion", 17000, "blue", "white"),
            ]),

            // ─── 2. BUNDESLIGA ───────────────────────────────────────────────
            LeagueData(name: "2. Bundesliga", country: "Germany", emoji: "🇩🇪", tier: 2, maxRating: 72, clubs: [
                ("Hamburg", "HSV", 68, 20_000_000, "Volksparkstadion", 57000, "blue", "white"),
                ("Schalke 04", "S04", 66, 18_000_000, "Veltins-Arena", 62271, "blue", "white"),
                ("Hertha Berlin", "BSC", 65, 15_000_000, "Olympiastadion", 74475, "blue", "white"),
                ("Hannover 96", "H96", 64, 12_000_000, "Heinz von Heiden Arena", 49200, "green", "white"),
                ("Fortuna Dusseldorf", "F95", 63, 10_000_000, "Merkur Spiel-Arena", 54600, "red", "white"),
                ("Nurnberg", "FCN", 63, 10_000_000, "Max-Morlock-Stadion", 50000, "red", "white"),
                ("Kaiserslautern", "FCK", 62, 8_000_000, "Fritz-Walter-Stadion", 49780, "red", "white"),
                ("Paderborn", "SCP", 61, 7_000_000, "Home Deluxe Arena", 15000, "blue", "black"),
                ("Greuther Furth", "SGF", 60, 6_000_000, "Sportpark Ronhof", 18000, "green", "white"),
                ("St. Pauli", "STP", 64, 10_000_000, "Millerntor-Stadion", 29546, "maroon", "white"),
                ("Braunschweig", "BSG", 59, 5_000_000, "Eintracht-Stadion", 25540, "blue", "yellow"),
                ("Rostock", "FCR", 58, 4_000_000, "Ostseestadion", 29000, "blue", "white"),
                ("Elversberg", "SVE", 58, 3_500_000, "Ursapharm-Arena", 6800, "yellow", "blue"),
                ("Magdeburg", "FCM", 59, 4_000_000, "MDCC-Arena", 30098, "blue", "white"),
                ("Karlsruher", "KSC", 60, 5_000_000, "BBBank Wildpark", 34302, "blue", "white"),
                ("Wiesbaden", "SVW", 57, 3_000_000, "Brita-Arena", 12566, "red", "black"),
                ("Osnabruck", "VFO", 56, 3_000_000, "Bremer Brucke", 16100, "purple", "white"),
                ("Sandhausen", "SVS", 55, 2_500_000, "BWT-Stadion", 15414, "black", "white"),
            ]),

            // ─── LIGUE 1 ─────────────────────────────────────────────────────
            LeagueData(name: "Ligue 1", country: "France", emoji: "🇫🇷", tier: 1, maxRating: 100, clubs: [
                ("Paris Saint-Germain", "PSG", 89, 250_000_000, "Parc des Princes", 47929, "blue", "red"),
                ("Marseille", "OM", 79, 60_000_000, "Velodrome", 67394, "white", "blue"),
                ("Monaco", "MON", 78, 70_000_000, "Louis II", 18523, "red", "white"),
                ("Lyon", "OL", 76, 55_000_000, "Groupama Stadium", 59186, "white", "blue"),
                ("Lille", "LIL", 77, 50_000_000, "Pierre-Mauroy", 50157, "red", "white"),
                ("Nice", "NIC", 74, 40_000_000, "Allianz Riviera", 36178, "red", "black"),
                ("Rennes", "REN", 73, 45_000_000, "Roazhon Park", 29778, "red", "black"),
                ("Lens", "RCL", 75, 40_000_000, "Bollaert-Delelis", 38223, "red", "yellow"),
                ("Strasbourg", "RCS", 68, 25_000_000, "La Meinau", 26109, "blue", "white"),
                ("Toulouse", "TFC", 67, 22_000_000, "Stadium de Toulouse", 33150, "purple", "white"),
                ("Montpellier", "MHP", 66, 20_000_000, "La Mosson", 32939, "blue", "orange"),
                ("Nantes", "NAN", 65, 20_000_000, "La Beaujoire", 37473, "yellow", "green"),
                ("Reims", "REI", 64, 18_000_000, "Auguste-Delaune", 21684, "red", "white"),
                ("Brest", "B29", 72, 25_000_000, "Francis-Le Ble", 15220, "white", "red"),
                ("Le Havre", "HAC", 60, 10_000_000, "Oceane", 25178, "skyblue", "navy"),
                ("Metz", "FCM", 58, 10_000_000, "Saint-Symphorien", 30000, "maroon", "white"),
                ("Lorient", "FCL", 57, 10_000_000, "Moustoir", 18500, "orange", "black"),
                ("Clermont", "CF63", 56, 8_000_000, "Gabriel-Montpied", 12000, "red", "blue"),
            ]),

            // ─── LIGUE 2 ─────────────────────────────────────────────────────
            LeagueData(name: "Ligue 2", country: "France", emoji: "🇫🇷", tier: 2, maxRating: 68, clubs: [
                ("Saint-Etienne", "STE", 64, 12_000_000, "Geoffroy-Guichard", 41965, "green", "white"),
                ("Bordeaux", "BOR", 62, 10_000_000, "Matmut Atlantique", 42115, "navy", "white"),
                ("Caen", "SMC", 61, 8_000_000, "Michel d'Ornano", 21500, "blue", "red"),
                ("Auxerre", "AJA", 62, 8_000_000, "Abbe-Deschamps", 23467, "white", "blue"),
                ("Guingamp", "EAG", 60, 6_000_000, "Roudourou", 18214, "red", "black"),
                ("Paris FC", "PFC", 59, 5_000_000, "Charlety", 20000, "blue", "white"),
                ("Sochaux", "FCS", 58, 5_000_000, "Auguste Bonal", 20005, "yellow", "blue"),
                ("Bastia", "SCB", 58, 4_000_000, "Armand Cesari", 16480, "blue", "white"),
                ("Amiens", "ASC", 59, 5_000_000, "Licorne", 12097, "white", "black"),
                ("Rodez", "RAF", 57, 3_000_000, "Paul Lignon", 6000, "red", "yellow"),
                ("Pau FC", "PAU", 56, 3_000_000, "Nouste Camp", 4974, "yellow", "blue"),
                ("Troyes", "EST", 58, 4_500_000, "Aube", 21684, "blue", "white"),
                ("Valenciennes", "VAF", 55, 3_000_000, "Hainaut", 25172, "red", "white"),
                ("Laval", "STL", 56, 3_000_000, "Francis Le Basser", 17893, "orange", "black"),
                ("Grenoble", "GF3", 57, 3_500_000, "Stade des Alpes", 20068, "blue", "white"),
                ("Quevilly Rouen", "QRM", 55, 2_500_000, "Robert Diochon", 12018, "red", "yellow"),
                ("Ajaccio", "ACA", 55, 3_000_000, "Francois Coty", 10660, "red", "white"),
                ("Annecy", "FCA", 54, 2_000_000, "Parc des Sports", 15000, "red", "blue"),
            ]),
        ]

        for data in leagueDataList {
            let league = League(
                name: data.name,
                country: data.country,
                countryEmoji: data.emoji,
                tier: data.tier,
                maxRating: data.maxRating
            )
            leagues.append(league)

            for clubData in data.clubs {
                let club = Club(
                    name: clubData.name,
                    shortName: clubData.shortName,
                    leagueId: league.id,
                    rating: clubData.rating,
                    budget: clubData.budget,
                    wageBudget: clubData.budget / 3,
                    stadiumName: clubData.stadium,
                    stadiumCapacity: clubData.capacity,
                    primaryColor: clubData.primary,
                    secondaryColor: clubData.secondary,
                    countryEmoji: data.emoji
                )
                clubs.append(club)
            }
        }

        return (leagues, clubs)
    }
}
