import SwiftUI

public enum MonsterMood: String, CaseIterable, Sendable {
    case chill       // Optimal Wi-Fi & cool battery
    case happy       // High throughput / charging happily
    case fever       // Battery warm (>38.5°C) or pulling high power
    case laggy       // Latency high (>90ms router or >150ms internet)
    case offline     // Disconnected from Wi-Fi
    case sleepy      // Low power idle (<6W)

    public var title: String {
        switch self {
        case .chill: return "Chilling & Stable"
        case .happy: return "Super Fast & Charging"
        case .fever: return "Running Warm"
        case .laggy: return "Experiencing Lag"
        case .offline: return "Searching for Wi-Fi"
        case .sleepy: return "Power Sipping"
        }
    }

    public var emoji: String {
        switch self {
        case .chill: return "😎"
        case .happy: return "⚡"
        case .fever: return "🌡️"
        case .laggy: return "📡"
        case .offline: return "😴"
        case .sleepy: return "🌙"
        }
    }

    public var moodColor: Color {
        switch self {
        case .chill: return Color.cyan
        case .happy: return Color.green
        case .fever: return Color.orange
        case .laggy: return Color.pink
        case .offline: return Color.gray
        case .sleepy: return Color.purple
        }
    }

    public var gradientColors: [Color] {
        switch self {
        case .chill:
            return [Color(red: 0.1, green: 0.85, blue: 0.95), Color(red: 0.55, green: 0.25, blue: 0.95)]
        case .happy:
            return [Color(red: 0.2, green: 0.95, blue: 0.6), Color(red: 0.05, green: 0.75, blue: 0.95)]
        case .fever:
            return [Color(red: 1.0, green: 0.5, blue: 0.1), Color(red: 0.95, green: 0.2, blue: 0.3)]
        case .laggy:
            return [Color(red: 0.95, green: 0.2, blue: 0.5), Color(red: 0.65, green: 0.15, blue: 0.85)]
        case .offline:
            return [Color(red: 0.5, green: 0.55, blue: 0.65), Color(red: 0.35, green: 0.38, blue: 0.45)]
        case .sleepy:
            return [Color(red: 0.45, green: 0.35, blue: 0.85), Color(red: 0.25, green: 0.15, blue: 0.6)]
        }
    }
}

