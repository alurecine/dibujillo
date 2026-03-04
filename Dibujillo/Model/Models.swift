//
//  Models.swift
//  Dibujillo Game
//

import Foundation

// MARK: - Player

struct Player: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var totalScore: Int = 0          // Puntaje acumulado en la partida
    var roundScore: Int = 0          // Puntaje de la ronda actual
    var hasGuessedThisRound: Bool = false
    var isDrawing: Bool = false
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

// MARK: - Guess Result

struct GuessResult: Identifiable {
    let id = UUID()
    let player: Player
    let rank: Int           // 1°, 2°, 3°...
    let pointsEarned: Int
    let timestamp: Date
}

// MARK: - Chat Message (floating chat)

struct ChatMessage: Identifiable {
    let id = UUID()
    let playerName: String
    let text: String
    let isCorrect: Bool
    let timestamp: Date = .now
}

// MARK: - Round

struct Round: Identifiable {
    let id = UUID()
    let roundNumber: Int
    let drawerID: UUID
    let word: String
    var guesses: [GuessResult] = []
    var startedAt: Date = .now
    var isFinished: Bool = false
}

// MARK: - Game Phase

enum GamePhase: Equatable {
    case lobby              // Esperando para empezar
    case roundIntro         // Mostrando quién dibuja
    case drawing            // Ronda activa
    case roundResults       // Resultados de la ronda
    case gameOver           // Fin de partida
}

// MARK: - Game Config

struct GameConfig {
    var roundDurationSeconds: Int = 80
    var wordPool: [String] = WordBank.all
    var maxPlayers: Int = 8
    
    // Scoring: el primero en adivinar gana más, cada siguiente menos
    func pointsForRank(_ rank: Int, totalGuessers: Int) -> Int {
        let base = 100
        let decrement = max(10, base / max(totalGuessers, 1))
        return max(10, base - (rank - 1) * decrement)
    }
    
    // El dibujante gana puntos proporcionales a cuántos adivinaron
    func drawerPoints(guessedCount: Int, totalGuessers: Int) -> Int {
        guard totalGuessers > 0 else { return 0 }
        let ratio = Double(guessedCount) / Double(totalGuessers)
        return Int(ratio * 80)
    }
}

// MARK: - Word Bank

// MARK: - Word Bank

struct WordBank {
    static let all: [String] = [
        
        // MARK: Animales (85)
        "elefante", "jirafa", "pulpo", "tiburón", "mariposa",
        "pingüino", "cocodrilo", "águila", "tortuga", "delfín",
        "cangrejo", "camaleón", "rinoceronte", "flamenco", "murciélago",
        "perro", "gato", "caballo", "vaca", "cerdo",
        "oveja", "conejo", "rana", "serpiente", "loro",
        "búho", "panda", "cebra", "león", "tigre",
        "oso", "mono", "gorila", "canguro", "koala",
        "hipopótamo", "foca", "ballena", "medusa", "erizo",
        "ardilla", "zorro", "lobo", "ciervo", "cabra",
        "llama", "pavo", "pelícano", "tucán", "cuervo",
        "avestruz", "langosta", "abeja", "araña", "escorpión",
        "libélula", "caracol", "pato", "gallo", "burro",
        "toro", "bisonte", "nutria", "mapache", "castor",
        "reno", "morsa", "orca", "colibrí", "iguana",
        "salamandra", "piraña", "mantarraya", "calamar", "jabalí",
        "lince", "guepardo", "jaguar", "búfalo", "armadillo",
        "tapir", "wombat", "caimán", "cacatúa", "narval",
        
        // MARK: Objetos del hogar (40)
        "silla", "mesa", "cama", "sofá", "espejo",
        "escalera", "jarrón", "maceta", "regadera", "escoba",
        "balde", "botella", "jarra", "taza", "plato",
        "tenedor", "cuchillo", "cuchara", "copa", "abanico",
        "vela", "candado", "peine", "cepillo", "bañera",
        "inodoro", "almohada", "cortina", "perchero", "televisor",
        "nevera", "microondas", "lavadora", "aspiradora", "plancha",
        "tostadora", "cafetera", "ventilador", "reloj", "jaula",
        
        // MARK: Herramientas y utensilios (18)
        "martillo", "hacha", "pico", "pala", "rastrillo",
        "serrucho", "destornillador", "llave", "tijeras", "clavo",
        "cadena", "ancla", "timón", "palanca", "pinza",
        "linterna", "brújula", "termómetro",
        
        // MARK: Instrumentos musicales (14)
        "guitarra", "piano", "violín", "batería", "trompeta",
        "acordeón", "flauta", "arpa", "saxofón", "tambor",
        "teclado", "micrófono", "castañuelas", "maracas",
        
        // MARK: Tecnología (12)
        "computadora", "teléfono", "cámara", "impresora", "dron",
        "satélite", "antena", "altavoz", "auriculares", "proyector",
        "pantalla", "ratón",
        
        // MARK: Transporte (30)
        "bicicleta", "moto", "camión", "autobús", "ambulancia",
        "taxi", "helicóptero", "globo aerostático", "velero", "lancha",
        "yate", "canoa", "kayak", "trineo", "carruaje",
        "tractor", "excavadora", "grúa", "montaña rusa", "teleférico",
        "monopatín", "patines", "tabla de surf", "esquís", "avión",
        "tren", "barco", "submarino", "tranvía", "cohete",
        
        // MARK: Comida y bebida (65)
        "pizza", "helado", "hamburguesa", "sushi", "taco",
        "pastel", "banana", "sandía", "chocolate", "donut",
        "manzana", "naranja", "fresa", "uva", "limón",
        "piña", "mango", "kiwi", "cereza", "pera",
        "durazno", "aguacate", "tomate", "zanahoria", "brócoli",
        "maíz", "papa", "cebolla", "pepino", "lechuga",
        "pimiento", "berenjena", "calabaza", "champiñón", "arroz",
        "pasta", "pan", "baguette", "croissant", "hotdog",
        "empanada", "arepa", "tamale", "paella", "ramen",
        "queso", "huevo", "salchicha", "pollo", "camarón",
        "café", "limonada", "batido", "palomitas", "nachos",
        "papas fritas", "waffle", "panqueque", "churro", "alfajor",
        "torta", "sopa", "ensalada", "tarta", "brownie",
        
        // MARK: Lugares y construcciones (40)
        "castillo", "volcán", "isla", "pirámide", "faro",
        "iglesia", "catedral", "torre", "puente", "túnel",
        "cueva", "montaña", "playa", "desierto", "selva",
        "bosque", "lago", "cascada", "glaciar", "cráter",
        "bahía", "puerto", "mercado", "plaza", "parque",
        "jardín", "estadio", "teatro", "museo", "biblioteca",
        "hospital", "escuela", "granja", "molino", "palacio",
        "mansión", "cabaña", "igloo", "rascacielos", "aeropuerto",
        
        // MARK: Naturaleza y clima (18)
        "arcoíris", "rayo", "tornado", "huracán", "nieve",
        "copo de nieve", "sol", "luna", "estrella", "cometa",
        "nube", "ola", "iceberg", "aurora boreal", "eclipse",
        "amanecer", "géiser", "acantilado",
        
        // MARK: Personajes y criaturas fantásticas (30)
        "fantasma", "sirena", "pirata", "dragón", "unicornio",
        "alien", "momia", "hada", "astronauta", "ninja",
        "payaso", "mago", "superhéroe", "bruja", "vampiro",
        "zombie", "gnomo", "duende", "centauro", "minotauro",
        "cíclope", "hombre lobo", "fénix", "kraken", "goblin",
        "elfo", "caballero", "vikingo", "samurái", "robot",
        
        // MARK: Ropa y accesorios (18)
        "sombrero", "corbata", "bufanda", "guantes", "botas",
        "zapatillas", "vestido", "traje", "pijama", "bikini",
        "gafas", "casco", "cinturón", "bolso", "mochila",
        "paraguas", "corona", "capa",
        
        // MARK: Deportes y actividades (22)
        "fútbol", "baloncesto", "tenis", "golf", "surf",
        "esquí", "boxeo", "karate", "yoga", "escalada",
        "hockey", "béisbol", "voleibol", "rugby", "esgrima",
        "paracaidismo", "buceo", "pesca", "camping", "patinaje",
        "natación", "gimnasia",
        
        // MARK: Arte y entretenimiento (18)
        "pintura", "escultura", "títere", "circo", "fuegos artificiales",
        "confeti", "trofeo", "libro", "mapa", "globo terráqueo",
        "ajedrez", "dado", "cartas", "rompecabezas", "muñeca",
        "yoyo", "boomerang", "máscara",
        
        // MARK: Cuerpo y salud (14)
        "corazón", "cerebro", "hueso", "mano", "ojo",
        "oreja", "nariz", "diente", "pierna", "brazo",
        "jeringa", "estetoscopio", "muleta", "vendaje",
        
        // MARK: Espacio y ciencia (12)
        "planeta", "asteroide", "telescopio", "nave espacial", "agujero negro",
        "galaxia", "nebulosa", "traje espacial", "estación espacial", "sonda",
        "microscopio", "probeta",
        
        // MARK: Miscelánea dibujable (63)
        "espada", "lámpara", "sartén", "maleta", "globo",
        "hamaca", "carpa", "imán", "diploma", "monedas",
        "buzón", "semáforo", "columpio", "tobogán", "trampolín",
        "barbacoa", "pecera", "lápida", "farol", "paragüero",
        "hielera", "brocheta",
        // Plantas y naturaleza
        "cactus", "girasol", "rosa", "tulipán", "árbol",
        "hongo", "alga", "bambú", "pino", "palma",
        // Construcción y arquitectura
        "arco", "columna", "cúpula", "balcón", "chimenea",
        "muralla", "foso", "pozo", "fuente", "estatua",
        // Juguetes y juegos
        "kite", "pelota", "trompo", "canica", "volantín",
        "patineta", "soga", "frisbee", "pistola de agua", "lego",
        // Accesorios y complementos
        "arete", "guante", "corbatín", "pulsera", "collar",
        "anillo", "pendiente", "reloj pulsera", "billetera", "cartera",
        // Cocina y gastronomía
        "olla", "wok", "colador", "batidora", "rodillo",
        "delantal", "mandil", "tabla de cortar", "mortero", "especiero",
        // Papelería y escritura
        "lápiz", "bolígrafo", "borrador", "tijera", "regla",
    ]
    
    static func randomWord(excluding used: Set<String> = []) -> String {
        let available = all.filter { !used.contains($0) }
        return available.randomElement() ?? all.randomElement() ?? "dibujo"
    }
}

// MARK: - Scoreboard Entry (para ranking final)

struct ScoreboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let player: Player
    
    var medal: String {
        switch rank {
            case 1: return "🥇"
            case 2: return "🥈"
            case 3: return "🥉"
            default: return "\(rank)°"
        }
    }
}
